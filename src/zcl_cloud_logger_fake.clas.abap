"! <p class="shorttext synchronized" lang="en">Cloud Logger test double for consumers</p>
"! In-memory implementation of {@link zif_cloud_logger} for unit tests of code
"! that logs. Nothing touches the Application Log or the database: entries are
"! kept in a table you can inspect through the normal query methods, saves and
"! resets are counted. Inject it where production code receives a
"! {@link zif_cloud_logger}; no <em>cl_abap_testdouble</em> configuration needed.
"! The fake treats severities, BAPI return rows, exception keys, free text
"! and searches exactly like {@link zcl_cloud_logger} - both use
"! {@link zcl_cloud_logger_conversion}, and a contract test runs the same
"! scenarios against both. T100 texts are resolved, so the text of an entry is
"! the text production shows. What the fake does not have: an Application Log
"! (handle and log object stay initial), a clock (<em>user_name</em>,
"! <em>date</em> and <em>time</em> of an entry stay initial, the timer reports
"! 0.000 seconds) and a text pool (its own diagnostics are English).
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
    DATA entries         TYPE zif_cloud_logger=>log_messages.
    DATA internal_errors TYPE zif_cloud_logger=>internal_errors.
    DATA context         TYPE string.
    DATA timer_running   TYPE abap_boolean.

    METHODS ensure_active
      RAISING zcx_cloud_logger_error.

    METHODS add
      IMPORTING symsg TYPE symsg
                !text TYPE string.

    " Text of a T100 message, with the fallback rule of the real logger
    METHODS message_text
      IMPORTING symsg         TYPE symsg
                fallback      TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE string.

    METHODS count_of
      IMPORTING !type         TYPE symsgty
      RETURNING VALUE(result) TYPE i.

    METHODS render
      IMPORTING entry         TYPE zif_cloud_logger=>t_log_messages
      RETURNING VALUE(result) TYPE zif_cloud_logger=>flat_message.

ENDCLASS.


CLASS zcl_cloud_logger_fake IMPLEMENTATION.

  METHOD zif_cloud_logger~log_string_add.
    self = me.
    ensure_active( ).
    add( symsg = VALUE #( msgty = zcl_cloud_logger_conversion=>normalized_severity(
                                      msgty    = msgty
                                      fallback = zif_cloud_logger=>c_default_message_attributes-type ) )
         text  = string ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_message_add.
    self = me.
    ensure_active( ).

    IF symsg IS INITIAL.
      RETURN.
    ENDIF.

    DATA(message) = VALUE symsg( BASE symsg
                                 msgty = zcl_cloud_logger_conversion=>normalized_severity(
                                             msgty    = symsg-msgty
                                             fallback = zif_cloud_logger=>c_default_message_attributes-type ) ).

    add( symsg = message
         text  = message_text( message ) ).
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

    add( symsg = zcl_cloud_logger_conversion=>symsg_from_exception(
                     exception = exception
                     severity  = zcl_cloud_logger_conversion=>normalized_severity(
                                     msgty    = severity
                                     fallback = zif_cloud_logger=>c_message_type-error ) )
         text  = exception->get_text( ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_bapiret2_structure_add.
    self = me.
    ensure_active( ).

    DATA(severity) = zcl_cloud_logger_conversion=>normalized_severity(
                         msgty    = bapiret2-type
                         fallback = zif_cloud_logger=>c_message_type-success ).

    IF bapiret2-id IS INITIAL.
      " As in the real logger: the text is all there is, and a row without text is ignored
      IF bapiret2-message IS NOT INITIAL.
        zif_cloud_logger~log_string_add( string = CONV #( bapiret2-message )
                                         msgty  = severity ).
      ENDIF.
      RETURN.
    ENDIF.

    DATA(symsg) = VALUE symsg( msgid = bapiret2-id
                               msgno = bapiret2-number
                               msgty = severity
                               msgv1 = bapiret2-message_v1
                               msgv2 = bapiret2-message_v2
                               msgv3 = bapiret2-message_v3
                               msgv4 = bapiret2-message_v4 ).

    add( symsg = symsg
         text  = message_text( symsg    = symsg
                               fallback = CONV #( bapiret2-message ) ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_bapiret2_table_add.
    self = me.
    ensure_active( ).

    LOOP AT bapiret2_t REFERENCE INTO DATA(row).
      DATA(severity) = zcl_cloud_logger_conversion=>normalized_severity(
                           msgty    = row->type
                           fallback = zif_cloud_logger=>c_message_type-success ).

      IF zcl_cloud_logger_conversion=>reaches_severity( severity = severity
                                                        minimum  = min_severity ) = abap_true.
        zif_cloud_logger~log_bapiret2_structure_add( row->* ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_cloud_logger~log_data_add.
    self = me.
    ensure_active( ).

    TRY.
        zif_cloud_logger~log_string_add( string = xco_cp_json=>data->from_abap( data )->to_string( )
                                         msgty  = msgty ).

      CATCH cx_root INTO DATA(error).
        " As in the real logger, bad data becomes an error entry instead of an exception
        add( symsg = VALUE #( msgty = zif_cloud_logger=>c_message_type-error )
             text  = |Error serializing data to JSON: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_cloud_logger~merge_logs.
    self = me.
    ensure_active( ).

    IF external_log IS NOT BOUND OR external_log = me.
      RETURN.
    ENDIF.

    INSERT LINES OF external_log->get_messages( )        INTO TABLE entries.
    INSERT LINES OF external_log->get_internal_errors( ) INTO TABLE internal_errors.

    SORT internal_errors STABLE BY timestamp.
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
                                         zcl_cloud_logger_conversion=>text_to_symsg(
                                             text  = entry-message
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
                     ELSE count_of( to_upper( msgty ) ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_is_empty.
    result = xsdbool( entries IS INITIAL ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_contains_messages.
    result = xsdbool( entries IS NOT INITIAL ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_contains_error.
    DATA(errors) = count_of( zif_cloud_logger=>c_message_type-error )
                 + count_of( zif_cloud_logger=>c_message_type-abandon )
                 + count_of( zif_cloud_logger=>c_message_type-terminate ).

    result = xsdbool( errors > 0 ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_contains_warning.
    DATA(warnings) = count_of( zif_cloud_logger=>c_message_type-warning ).

    result = xsdbool( zif_cloud_logger~log_contains_error( ) = abap_true OR warnings > 0 ).
  ENDMETHOD.

  METHOD zif_cloud_logger~search_message.
    LOOP AT entries REFERENCE INTO DATA(entry).
      IF zcl_cloud_logger_conversion=>matches_search( symsg  = entry->symsg
                                                      search = search ) = abap_true.
        result = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_cloud_logger~start_timer.
    self = me.
    ensure_active( ).

    IF timer_running = abap_true.
      add( symsg = VALUE #( msgty = zif_cloud_logger=>c_message_type-warning )
           text  = `start_timer called twice without stop_timer - previous timer reset` ).
    ENDIF.

    timer_running = abap_true.
  ENDMETHOD.

  METHOD zif_cloud_logger~stop_timer.
    self = me.
    ensure_active( ).

    IF timer_running = abap_false.
      add( symsg = VALUE #( msgty = zif_cloud_logger=>c_message_type-warning )
           text  = `Timer stopped but never started.` ).
      RETURN.
    ENDIF.

    " No clock behind the fake: the measured block always took no time
    add( symsg = VALUE #( msgty = zif_cloud_logger=>c_message_type-information )
         text  = |Timer Result: { text } took 0.000 seconds.| ).

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

  METHOD message_text.
    TRY.
        DATA(resolved) = xco_cp=>message( symsg )->get_text( ).

      CATCH cx_root INTO DATA(error).
        " Trailed like in the real logger; the fake has no clock, the time stamp stays initial
        INSERT VALUE #( method     = `resolve_message_text`
                        error_text = error->get_text( ) ) INTO TABLE internal_errors.
    ENDTRY.

    result = zcl_cloud_logger_conversion=>text_or_fallback( symsg    = symsg
                                                            resolved = resolved
                                                            fallback = fallback ).
  ENDMETHOD.

  METHOD count_of.
    result = REDUCE #( INIT count = 0
                       FOR entry IN entries WHERE ( type = type )
                       NEXT count = count + 1 ).
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

ENDCLASS.
