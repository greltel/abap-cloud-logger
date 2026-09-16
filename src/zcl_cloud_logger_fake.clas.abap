"! <p class="shorttext synchronized" lang="en">Cloud Logger test double for consumers</p>
"! In-memory implementation of {@link zif_cloud_logger} for unit tests of code
"! that logs. Nothing touches the Application Log or the database: entries are
"! kept in a table you can inspect through the normal query methods, saves and
"! resets are counted. Inject it where production code receives a
"! {@link zif_cloud_logger}; no <em>cl_abap_testdouble</em> configuration needed.
"! The released-instance contract of the real logger is mimicked: after
"! {@link zif_cloud_logger.METH:free} writing methods raise <em>instance_released</em>.
CLASS zcl_cloud_logger_fake DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_cloud_logger.

    "! Number of save_application_log( ) calls
    DATA save_calls  TYPE i READ-ONLY.
    "! Number of reset_appl_log( ) calls
    DATA reset_calls TYPE i READ-ONLY.
    "! abap_true after free( )
    DATA released    TYPE abap_boolean READ-ONLY.

  PRIVATE SECTION.
    TYPES free_text_buffer TYPE c LENGTH 200.

    DATA entries         TYPE zif_cloud_logger=>log_messages.
    DATA internal_errors TYPE zif_cloud_logger=>internal_errors.
    DATA context         TYPE string.
    DATA timer_running   TYPE abap_boolean.

    METHODS ensure_active
      RAISING zcx_cloud_logger_error.

    METHODS add
      IMPORTING symsg TYPE symsg
                !text TYPE string.

    METHODS render
      IMPORTING entry         TYPE zif_cloud_logger=>t_log_messages
      RETURNING VALUE(result) TYPE zif_cloud_logger=>flat_message.

    METHODS text_to_symsg
      IMPORTING !text         TYPE string
                msgty         TYPE symsgty
      RETURNING VALUE(result) TYPE symsg.

ENDCLASS.


CLASS zcl_cloud_logger_fake IMPLEMENTATION.

  METHOD zif_cloud_logger~log_string_add.
    self = me.
    ensure_active( ).
    add( symsg = VALUE #( msgty = msgty )
         text  = string ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_message_add.
    self = me.
    ensure_active( ).

    IF symsg IS INITIAL.
      RETURN.
    ENDIF.

    add( symsg = VALUE #( BASE symsg
                          msgty = COND #( WHEN symsg-msgty IS NOT INITIAL
                                          THEN symsg-msgty
                                          ELSE zif_cloud_logger=>c_default_message_attributes-type ) )
         text  = |{ symsg-msgid } { symsg-msgno } { symsg-msgv1 } { symsg-msgv2 } { symsg-msgv3 } { symsg-msgv4 }| ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_syst_add.
    self = zif_cloud_logger~log_message_add( VALUE #( msgty = sy-msgty
                                                      msgid = sy-msgid
                                                      msgno = sy-msgno
                                                      msgv1 = sy-msgv1
                                                      msgv2 = sy-msgv2
                                                      msgv3 = sy-msgv3
                                                      msgv4 = sy-msgv4 ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_exception_add.
    self = me.
    ensure_active( ).

    IF exception IS NOT BOUND.
      RETURN.
    ENDIF.

    add( symsg = VALUE #( msgty = severity )
         text  = exception->get_text( ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_bapiret2_structure_add.
    self = me.
    ensure_active( ).

    IF bapiret2 IS INITIAL.
      RETURN.
    ENDIF.

    add( symsg = VALUE #( msgid = bapiret2-id
                          msgno = bapiret2-number
                          msgty = bapiret2-type
                          msgv1 = bapiret2-message_v1
                          msgv2 = bapiret2-message_v2
                          msgv3 = bapiret2-message_v3
                          msgv4 = bapiret2-message_v4 )
         text  = CONV #( bapiret2-message ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_bapiret2_table_add.
    self = me.
    ensure_active( ).

    " Same filter as the real logger: W keeps W/E/A/X, E keeps E/A/X, A or X keeps A/X
    DATA(kept_types) = SWITCH string( min_severity
      WHEN zif_cloud_logger=>c_message_type-abandon OR zif_cloud_logger=>c_message_type-terminate
        THEN |{ zif_cloud_logger=>c_message_type-abandon }{ zif_cloud_logger=>c_message_type-terminate }|
      WHEN zif_cloud_logger=>c_message_type-error
        THEN |{ zif_cloud_logger=>c_message_type-error }{ zif_cloud_logger=>c_message_type-abandon }| &&
             |{ zif_cloud_logger=>c_message_type-terminate }|
      WHEN zif_cloud_logger=>c_message_type-warning
        THEN |{ zif_cloud_logger=>c_message_type-warning }{ zif_cloud_logger=>c_message_type-error }| &&
             |{ zif_cloud_logger=>c_message_type-abandon }{ zif_cloud_logger=>c_message_type-terminate }|
      ELSE `` ).

    LOOP AT bapiret2_t REFERENCE INTO DATA(bapiret2).
      IF kept_types IS INITIAL OR bapiret2->type CA kept_types.
        zif_cloud_logger~log_bapiret2_structure_add( bapiret2->* ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_cloud_logger~log_data_add.
    self = me.
    ensure_active( ).
    add( symsg = VALUE #( msgty = msgty )
         text  = xco_cp_json=>data->from_abap( data )->to_string( ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~merge_logs.
    self = me.
    ensure_active( ).

    IF external_log IS NOT BOUND OR external_log = me.
      RETURN.
    ENDIF.

    INSERT LINES OF external_log->get_messages( )        INTO TABLE entries.
    INSERT LINES OF external_log->get_internal_errors( ) INTO TABLE internal_errors.
  ENDMETHOD.

  METHOD zif_cloud_logger~save_application_log.
    self = me.
    ensure_active( ).
    save_calls += 1.
  ENDMETHOD.

  METHOD zif_cloud_logger~reset_appl_log.
    ensure_active( ).
    reset_calls += 1.
    CLEAR entries.
    CLEAR context.
    CLEAR timer_running.
  ENDMETHOD.

  METHOD zif_cloud_logger~free.
    released = abap_true.
    CLEAR entries.
    CLEAR internal_errors.
    CLEAR context.
    CLEAR timer_running.
  ENDMETHOD.

  METHOD zif_cloud_logger~get_messages.
    result = entries.
  ENDMETHOD.

  METHOD zif_cloud_logger~get_messages_flat.
    result = VALUE #( FOR entry IN entries
                      ( render( entry ) ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~get_messages_as_bapiret2.
    result = VALUE #( FOR entry IN entries
                      ( id         = entry-symsg-msgid
                        number     = entry-symsg-msgno
                        type       = entry-symsg-msgty
                        message_v1 = entry-symsg-msgv1
                        message_v2 = entry-symsg-msgv2
                        message_v3 = entry-symsg-msgv3
                        message_v4 = entry-symsg-msgv4
                        message    = entry-message ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~get_messages_rap.
    result = VALUE #( FOR entry IN entries
                      ( COND #( WHEN entry-symsg-msgid IS NOT INITIAL
                                THEN zcx_cloud_logger_message=>new_message_from_symsg( entry-symsg )
                                ELSE zcx_cloud_logger_message=>new_message_from_symsg(
                                         text_to_symsg( text  = entry-message
                                                        msgty = entry-symsg-msgty ) ) ) ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~get_handle.
    " No Application Log behind the fake
    CLEAR result.
  ENDMETHOD.

  METHOD zif_cloud_logger~get_log_handle.
    " No Application Log behind the fake
    CLEAR result.
  ENDMETHOD.

  METHOD zif_cloud_logger~get_message_count.
    result = COND #( WHEN msgty IS INITIAL
                     THEN lines( entries )
                     ELSE REDUCE int4( INIT count = 0
                                       FOR entry IN entries WHERE ( type = msgty )
                                       NEXT count = count + 1 ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_is_empty.
    result = xsdbool( entries IS INITIAL ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_contains_messages.
    result = xsdbool( entries IS NOT INITIAL ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_contains_error.
    result = xsdbool(
         line_exists( entries[ type = zif_cloud_logger=>c_message_type-error ] )
      OR line_exists( entries[ type = zif_cloud_logger=>c_message_type-abandon ] )
      OR line_exists( entries[ type = zif_cloud_logger=>c_message_type-terminate ] ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_contains_warning.
    result = xsdbool(
         zif_cloud_logger~log_contains_error( ) = abap_true
      OR line_exists( entries[ type = zif_cloud_logger=>c_message_type-warning ] ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~search_message.
    IF search IS INITIAL.
      result = xsdbool( entries IS NOT INITIAL ).
      RETURN.
    ENDIF.

    LOOP AT entries REFERENCE INTO DATA(entry).
      DATA(class_matches)  = xsdbool( search-msgid IS INITIAL OR entry->symsg-msgid = search-msgid ).
      DATA(number_matches) = xsdbool( search-msgno IS INITIAL OR entry->symsg-msgno = search-msgno ).
      DATA(type_matches)   = xsdbool( search-msgty IS INITIAL OR entry->symsg-msgty = search-msgty ).

      IF class_matches = abap_true AND number_matches = abap_true AND type_matches = abap_true.
        result = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_cloud_logger~start_timer.
    self = me.
    ensure_active( ).
    timer_running = abap_true.
  ENDMETHOD.

  METHOD zif_cloud_logger~stop_timer.
    self = me.
    ensure_active( ).

    IF timer_running = abap_true.
      add( symsg = VALUE #( msgty = zif_cloud_logger=>c_message_type-information )
           text  = |Timer Result: { text } took 0.000 seconds.| ).
    ENDIF.

    CLEAR timer_running.
  ENDMETHOD.

  METHOD zif_cloud_logger~display.
    IF viewer IS BOUND.
      viewer->view( me ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_cloud_logger~set_context.
    self        = me.
    me->context = context.
  ENDMETHOD.

  METHOD zif_cloud_logger~clear_context.
    self = me.
    CLEAR context.
  ENDMETHOD.

  METHOD zif_cloud_logger~get_internal_errors.
    result = internal_errors.
  ENDMETHOD.

  METHOD zif_cloud_logger~clear_internal_errors.
    self = me.
    CLEAR internal_errors.
  ENDMETHOD.

  METHOD ensure_active.
    IF released = abap_true.
      RAISE EXCEPTION NEW zcx_cloud_logger_error( textid = zcx_cloud_logger_error=>instance_released ).
    ENDIF.
  ENDMETHOD.

  METHOD add.
    INSERT VALUE #( symsg   = symsg
                    message = text
                    type    = symsg-msgty
                    context = context ) INTO TABLE entries.
  ENDMETHOD.

  METHOD render.
    DATA(base) = COND string(
      WHEN entry-symsg-msgid IS INITIAL
      THEN entry-message
      ELSE |{ entry-symsg-msgty }{ entry-symsg-msgno }({ entry-symsg-msgid }) - { entry-message }| ).

    result = COND #( WHEN entry-context IS NOT INITIAL
                     THEN |[{ entry-context }] { base }|
                     ELSE base ).
  ENDMETHOD.

  METHOD text_to_symsg.
    DATA(buffer) = CONV free_text_buffer( text ).

    result = VALUE #( msgid = zif_cloud_logger=>c_free_text_message-msgid
                      msgno = zif_cloud_logger=>c_free_text_message-msgno
                      msgty = COND #( WHEN msgty IS NOT INITIAL
                                      THEN msgty
                                      ELSE zif_cloud_logger=>c_message_type-information )
                      msgv1 = buffer(50)
                      msgv2 = buffer+50(50)
                      msgv3 = buffer+100(50)
                      msgv4 = buffer+150(50) ).
  ENDMETHOD.

ENDCLASS.
