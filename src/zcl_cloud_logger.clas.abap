"! <p class="shorttext synchronized" lang="en"></p>
"!
CLASS zcl_cloud_logger DEFINITION
  PUBLIC
  CREATE PRIVATE .

  PUBLIC SECTION.

    INTERFACES zif_cloud_logger .

    ALIASES c_default_message_attributes
      FOR zif_cloud_logger~c_default_message_attributes .
    ALIASES c_message_type
      FOR zif_cloud_logger~c_message_type .
    ALIASES c_select_options
      FOR zif_cloud_logger~c_select_options .
    ALIASES free
      FOR zif_cloud_logger~free .
    ALIASES get_handle
      FOR zif_cloud_logger~get_handle .
    ALIASES get_log_handle
      FOR zif_cloud_logger~get_log_handle .
    ALIASES get_messages
      FOR zif_cloud_logger~get_messages .
    ALIASES get_messages_as_bapiret2
      FOR zif_cloud_logger~get_messages_as_bapiret2 .
    ALIASES get_messages_flat
      FOR zif_cloud_logger~get_messages_flat .
    ALIASES get_messages_rap
      FOR zif_cloud_logger~get_messages_rap .
    ALIASES get_message_count
      FOR zif_cloud_logger~get_message_count .
    ALIASES log_bapiret2_structure_add
      FOR zif_cloud_logger~log_bapiret2_structure_add .
    ALIASES log_bapiret2_table_add
      FOR zif_cloud_logger~log_bapiret2_table_add .
    ALIASES log_contains_error
      FOR zif_cloud_logger~log_contains_error .
    ALIASES log_contains_messages
      FOR zif_cloud_logger~log_contains_messages .
    ALIASES log_contains_warning
      FOR zif_cloud_logger~log_contains_warning .
    ALIASES log_data_add
      FOR zif_cloud_logger~log_data_add .
    ALIASES log_exception_add
      FOR zif_cloud_logger~log_exception_add .
    ALIASES log_is_empty
      FOR zif_cloud_logger~log_is_empty .
    ALIASES log_message_add
      FOR zif_cloud_logger~log_message_add .
    ALIASES log_string_add
      FOR zif_cloud_logger~log_string_add .
    ALIASES log_syst_add
      FOR zif_cloud_logger~log_syst_add .
    ALIASES merge_logs
      FOR zif_cloud_logger~merge_logs .
    ALIASES reset_appl_log
      FOR zif_cloud_logger~reset_appl_log .
    ALIASES save_application_log
      FOR zif_cloud_logger~save_application_log .
    ALIASES search_message
      FOR zif_cloud_logger~search_message .
    ALIASES bapiret2_messages
      FOR zif_cloud_logger~bapiret2_messages .
    ALIASES flat_messages
      FOR zif_cloud_logger~flat_messages .
    ALIASES logger_instances_type
      FOR zif_cloud_logger~logger_instances.
    ALIASES log_messages_type
      FOR zif_cloud_logger~log_messages .
    ALIASES rap_messages
      FOR zif_cloud_logger~rap_messages .
    ALIASES flat_message
      FOR zif_cloud_logger~flat_message .
    ALIASES logger_instance
      FOR zif_cloud_logger~t_logger_instance .

    "! <p class="shorttext synchronized" lang="en">Get Cloud Logger Instance</p>
    "!
    "! @parameter object          | <p class="shorttext synchronized" lang="en">IV_OBJECT</p>
    "! @parameter subobject       | <p class="shorttext synchronized" lang="en">IV_SUBOBJECT</p>
    "! @parameter ext_number      | <p class="shorttext synchronized" lang="en">IV_EXT_NUMBER</p>
    "! @parameter db_save         | <p class="shorttext synchronized" lang="en">IV_DB_SAVE</p>
    "! @parameter expiry_date     | <p class="shorttext synchronized" lang="en">Application Log: Expiration Date</p>
    "! @parameter logger_instance | <p class="shorttext synchronized" lang="en">RE_LOGGER_INSTANCE</p>
    CLASS-METHODS get_instance
      IMPORTING
        !enable_emergency_log  TYPE abap_boolean DEFAULT abap_false
        !object                TYPE cl_bali_header_setter=>ty_object OPTIONAL
        !subobject             TYPE cl_bali_header_setter=>ty_subobject OPTIONAL
        !ext_number            TYPE cl_bali_header_setter=>ty_external_id OPTIONAL
        !db_save               TYPE abap_boolean DEFAULT abap_false
        !expiry_date           TYPE xsddate_d OPTIONAL
      RETURNING
        VALUE(logger_instance) TYPE REF TO zif_cloud_logger .
  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES:
      severity_filter_range TYPE RANGE OF symsgty .

    CLASS-DATA logger_instances TYPE logger_instances_type .
    DATA log_handle TYPE REF TO if_bali_log .
    DATA header TYPE REF TO if_bali_header_setter .
    DATA emergency_log TYPE REF TO if_xco_cp_bal_log .
    DATA log_messages TYPE log_messages_type .
    DATA db_save TYPE abap_boolean .
    DATA object TYPE cl_bali_header_setter=>ty_object .
    DATA subobject TYPE cl_bali_header_setter=>ty_subobject .
    DATA ext_number TYPE cl_bali_header_setter=>ty_external_id .
    DATA expiry_date TYPE xsddate_d .
    DATA enable_emergency_log TYPE abap_boolean .
    DATA timer_start TYPE timestampl.
    DATA context TYPE string.

    "! <p class="shorttext synchronized" lang="en">CONSTRUCTOR</p>
    "!
    "! @parameter object      | <p class="shorttext synchronized" lang="en">IV_OBJECT</p>
    "! @parameter subobject   | <p class="shorttext synchronized" lang="en">IV_SUBOBJECT</p>
    "! @parameter ext_number  | <p class="shorttext synchronized" lang="en">IV_EXT_NUMBER</p>
    "! @parameter db_save     | <p class="shorttext synchronized" lang="en">IV_DB_SAVE</p>
    "! @parameter expiry_date | <p class="shorttext synchronized" lang="en">Application Log: Expiration Date</p>
    METHODS constructor
      IMPORTING
        !enable_emergency_log TYPE abap_boolean DEFAULT abap_false
        !object               TYPE cl_bali_header_setter=>ty_object OPTIONAL
        !subobject            TYPE cl_bali_header_setter=>ty_subobject OPTIONAL
        !ext_number           TYPE cl_bali_header_setter=>ty_external_id OPTIONAL
        !db_save              TYPE abap_boolean DEFAULT abap_true
        !expiry_date          TYPE xsddate_d OPTIONAL .
    "! <p class="shorttext synchronized" lang="en">Add Message to Internal Log</p>
    "!
    "! @parameter symsg | <p class="shorttext synchronized" lang="en">IV_MSGV3</p>
    "! @parameter item  | <p class="shorttext synchronized" lang="en">Application Log Item Data (e.g. Message; for Writing)</p>
    METHODS add_message_internal_log
      IMPORTING
        !symsg TYPE symsg OPTIONAL
        !item  TYPE REF TO if_bali_item_setter OPTIONAL .
    "! <p class="shorttext synchronized" lang="en">Get Long Text from Message</p>
    "!
    "! @parameter symsg     | <p class="shorttext synchronized" lang="en">IV_MSGV4</p>
    "! @parameter long_text | <p class="shorttext synchronized" lang="en">RE_LONG_TEXT</p>
    CLASS-METHODS get_long_text_from_message
      IMPORTING
        !symsg           TYPE symsg
      RETURNING
        VALUE(long_text) TYPE bapiret2-message .
    "! <p class="shorttext synchronized" lang="en">Get String from Message</p>
    "!
    "! @parameter message | <p class="shorttext synchronized" lang="en">Structure of message variables</p>
    CLASS-METHODS get_string_from_message
      IMPORTING
        !message      TYPE symsg
      RETURNING
        VALUE(result) TYPE flat_message .
    "! <p class="shorttext synchronized" lang="en">Create Emergency Log</p>
    METHODS create_emergency_log .
    "! <p class="shorttext synchronized" lang="en">Create Header Object</p>
    "!
    "! @parameter header | <p class="shorttext synchronized" lang="en">Application Log Header Data (for Writing)</p>
    METHODS create_header
      RETURNING
        VALUE(header) TYPE REF TO if_bali_header_setter .
    "! <p class="shorttext synchronized" lang="en">Get Severity Level of Message Type</p>
    "!
    "! @parameter msgty | <p class="shorttext synchronized" lang="en">Message Type</p>
    METHODS get_severity_filter
      IMPORTING
        !msgty        TYPE symsgty
      RETURNING
        VALUE(filter) TYPE zcl_cloud_logger=>severity_filter_range .
ENDCLASS.



CLASS ZCL_CLOUD_LOGGER IMPLEMENTATION.


  METHOD add_message_internal_log.

    INSERT VALUE #( item         = item
                    symsg        = symsg
                    message      = get_long_text_from_message( symsg )
                    type         = symsg-msgty
                    user_name    = cl_abap_context_info=>get_user_alias( )
                    date         = cl_abap_context_info=>get_system_date( )
                    time         = cl_abap_context_info=>get_system_time( ) ) INTO TABLE me->log_messages.

    IF emergency_log IS BOUND AND me->enable_emergency_log EQ abap_true.

      emergency_log->add_message( is_symsg = symsg ).

    ENDIF.

  ENDMETHOD.


  METHOD constructor.

    TRY.

        me->log_handle           = cl_bali_log=>create( ).
        me->object               = object.
        me->subobject            = subobject.
        me->ext_number           = ext_number.
        me->expiry_date          = expiry_date.
        me->enable_emergency_log = enable_emergency_log.

        TRY.
            me->header = create_header( ).

            me->log_handle->set_header( header ).

          CATCH cx_bali_runtime cx_uuid_error INTO DATA(exception).
            DATA(exception_text) = exception->get_text( ).
            RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_creation
                                                        previous = exception ).
        ENDTRY.

        me->db_save          = COND #( WHEN object IS SUPPLIED AND object IS NOT INITIAL THEN db_save
                                       ELSE abap_false ).

        me->create_emergency_log( ).

      CATCH cx_bali_runtime cx_uuid_error INTO DATA(exception_new).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_creation
                                                    previous = exception_new ).
    ENDTRY.

  ENDMETHOD.


  METHOD get_instance.

    READ TABLE logger_instances INTO DATA(instance)
      WITH TABLE KEY log_object    = object
                     log_subobject = subobject
                     extnumber     = ext_number.

    IF syst-subrc IS INITIAL.
      logger_instance = instance-logger.
      RETURN.
    ENDIF.

    logger_instance = NEW zcl_cloud_logger( object                   = object
                                               subobject             = subobject
                                               ext_number            = ext_number
                                               db_save               = db_save
                                               enable_emergency_log  = enable_emergency_log
                                               expiry_date           = expiry_date  ).

    INSERT VALUE #( log_object    = object
                    log_subobject = subobject
                    extnumber     = ext_number
                    logger        = logger_instance ) INTO TABLE logger_instances.

  ENDMETHOD.


  METHOD get_long_text_from_message.

    RETURN xco_cp=>message( symsg )->get_text( ).

  ENDMETHOD.


  METHOD get_string_from_message.

    RETURN |{ message-msgty }{ message-msgno }({ message-msgid }) - { xco_cp=>message( message )->get_text( ) }|.

  ENDMETHOD.


  METHOD zif_cloud_logger~get_handle.

    RETURN me->log_handle->get_handle( ).

  ENDMETHOD.


  METHOD zif_cloud_logger~get_log_handle.

    RETURN me->log_handle.

  ENDMETHOD.


  METHOD zif_cloud_logger~get_messages.

    RETURN me->log_messages.

  ENDMETHOD.


  METHOD zif_cloud_logger~get_messages_as_bapiret2.

    RETURN VALUE #( FOR message IN me->log_messages
              ( id         = message-symsg-msgid
                number     = message-symsg-msgno
                type       = message-symsg-msgty
                message_v1 = message-symsg-msgv1
                message_v2 = message-symsg-msgv2
                message_v3 = message-symsg-msgv3
                message_v4 = message-symsg-msgv4
                message    = message-message ) ).


  ENDMETHOD.


  METHOD zif_cloud_logger~get_messages_flat.

    RETURN VALUE #( FOR message IN me->log_messages
                   ( get_string_from_message( message = VALUE #( msgty = message-symsg-msgty
                                                                 msgid = message-symsg-msgid
                                                                 msgno = message-symsg-msgno
                                                                 msgv1 = message-symsg-msgv1
                                                                 msgv2 = message-symsg-msgv2
                                                                 msgv3 = message-symsg-msgv3
                                                                 msgv4 = message-symsg-msgv4
                                                                  )
                                             )
                    )
                   ).

  ENDMETHOD.


  METHOD zif_cloud_logger~get_messages_rap.

    RETURN VALUE #( FOR message IN me->log_messages
                  ( zcx_cloud_logger_message=>new_message_from_symsg( message-symsg ) ) ).

  ENDMETHOD.


  METHOD zif_cloud_logger~get_message_count.

    CHECK me->log_handle IS BOUND.

    TRY.
        RETURN lines( me->log_handle->get_all_items( ) ).
      CATCH cx_bali_runtime INTO DATA(exception).
        DATA(exception_text) = exception->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~log_bapiret2_structure_add.

    CHECK bapiret2 IS NOT INITIAL.

    TRY.
        DATA(item) = cl_bali_message_setter=>create_from_bapiret2( bapiret2 ).

        me->log_handle->add_item( item ).

        me->add_message_internal_log( symsg =  VALUE #( msgid = bapiret2-id
                                                        msgno = bapiret2-number
                                                        msgty = bapiret2-type
                                                        msgv1 = bapiret2-message_v1
                                                        msgv2 = bapiret2-message_v2
                                                        msgv3 = bapiret2-message_v3
                                                        msgv4 = bapiret2-message_v4 )
                                      item  = item ).

        logger = me.

      CATCH cx_bali_runtime INTO DATA(exception).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_logging
                                                    previous = exception ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~log_bapiret2_table_add.

    DATA(severity_filter) = COND #( WHEN min_severity IS NOT INITIAL THEN get_severity_filter( min_severity )
                                    ELSE VALUE #( ) ).

    LOOP AT bapiret2_t REFERENCE INTO DATA(bapiret2_structure) WHERE type IN severity_filter.
      me->log_bapiret2_structure_add( bapiret2_structure->* ).
    ENDLOOP.

    logger = me.

  ENDMETHOD.


  METHOD zif_cloud_logger~log_contains_error.

    CLEAR result.
    CHECK me->log_handle IS BOUND.

    TRY.

        LOOP AT me->log_handle->get_all_items( ) ASSIGNING FIELD-SYMBOL(<fs>) WHERE item->severity CA c_message_type-error_pattern.
          RETURN abap_true.
        ENDLOOP.

      CATCH cx_bali_runtime INTO DATA(exception).
        DATA(exception_text) = exception->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~log_contains_messages.

    CLEAR result.
    CHECK me->log_handle IS BOUND.

    TRY.

        RETURN COND #( WHEN me->log_handle->get_all_items( ) IS NOT INITIAL THEN abap_true
                       ELSE abap_false ).

      CATCH cx_bali_runtime INTO DATA(exception).
        DATA(exception_text) = exception->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~log_contains_warning.

    CLEAR result.
    CHECK me->log_handle IS BOUND.

    TRY.

        LOOP AT me->log_handle->get_all_items( ) ASSIGNING FIELD-SYMBOL(<fs>) WHERE item->severity CA c_message_type-warning_pattern.
          RETURN abap_true.
        ENDLOOP.

      CATCH cx_bali_runtime INTO DATA(exception).
        DATA(exception_text) = exception->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~log_exception_add.

    CHECK exception IS BOUND AND me->log_handle IS BOUND.

    TRY.

        DATA(item) =  cl_bali_exception_setter=>create( severity  = severity
                                                        exception = exception ).

        me->log_handle->add_item( item ).

        me->add_message_internal_log( symsg =  VALUE #( msgty = severity
                                                        msgv1 = CONV #( exception->get_text( ) ) )
                                      item  = item   ).

        logger = me.

      CATCH cx_bali_runtime INTO DATA(exception_local).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_logging
                                                    previous = exception_local ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~log_is_empty.

    CHECK me->log_handle IS BOUND.

    TRY.
        RETURN COND #( WHEN me->get_message_count( ) IS INITIAL THEN abap_true
                       ELSE abap_false ).

      CATCH cx_bali_runtime INTO DATA(exception).
        DATA(exception_text) = exception->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~log_message_add.

    CHECK me->log_handle IS BOUND.

    TRY.

        DATA(item) = cl_bali_message_setter=>create( severity   = symsg-msgty
                                                     id         = symsg-msgid
                                                     number     = symsg-msgno
                                                     variable_1 = symsg-msgv1
                                                     variable_2 = symsg-msgv2
                                                     variable_3 = symsg-msgv3
                                                     variable_4 = symsg-msgv4 ).

        me->log_handle->add_item( item ).

        me->add_message_internal_log( symsg = symsg
                                      item  = item ).

        logger = me.

      CATCH cx_bali_runtime INTO DATA(exception).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_logging
                                                    previous = exception ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~log_string_add.

    CHECK me->log_handle IS BOUND.

    TRY.

        DATA(final_string) = COND #( WHEN me->context IS NOT INITIAL THEN |[{ me->context }] { string }|
                                        ELSE string ).

        DATA(item) = cl_bali_free_text_setter=>create( severity = msgty
                                                       text     = CONV #( final_string ) ).

        me->log_handle->add_item( item ).

        me->add_message_internal_log( symsg = VALUE #( msgty = msgty msgv1 = CONV #( final_string ) )
                                      item  = item ).

        logger = me.

      CATCH cx_bali_runtime INTO DATA(exception).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_logging
                                                    previous = exception ).
    ENDTRY.


  ENDMETHOD.


  METHOD zif_cloud_logger~log_syst_add.

    CHECK me->log_handle IS BOUND.

    TRY.

        DATA(xco_message) = xco_cp=>sy->message( ).
        DATA(item)        = cl_bali_message_setter=>create_from_sy( ).

        log_handle->add_item( item ).

        me->add_message_internal_log( symsg = VALUE #( msgid = xco_message->value-msgid
                                                       msgno = xco_message->value-msgno
                                                       msgty = xco_message->value-msgty
                                                       msgv1 = xco_message->value-msgv1
                                                       msgv2 = xco_message->value-msgv2
                                                       msgv3 = xco_message->value-msgv3
                                                       msgv4 = xco_message->value-msgv4 )
                                      item  = item ).

        logger = me.

      CATCH cx_bali_runtime INTO DATA(exception).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_logging
                                                    previous = exception ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~merge_logs.

    "Add to Internal Log
    INSERT LINES OF external_log->get_messages( ) INTO TABLE me->log_messages.

    "Add to Handle
    TRY.
        me->log_handle->add_all_items_from_other_log( external_log->get_log_handle( ) ).
      CATCH cx_bali_runtime INTO DATA(exception).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~reset_appl_log.

    TRY.

        "Delete from Database
        IF me->log_handle IS BOUND AND delete_from_db EQ abap_true.
          cl_bali_log_db=>get_instance( )->delete_log( me->log_handle ).
        ENDIF.

        "Handle Recreation
        CLEAR me->log_handle.
        me->log_handle = cl_bali_log=>create( ).

        me->header = COND #( WHEN me->header IS BOUND THEN me->header
                             ELSE create_header( ) ).

        me->log_handle->set_header( me->header ).

        CLEAR me->log_messages.

      CATCH cx_bali_runtime INTO DATA(exception).
        DATA(exception_text) = exception->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~save_application_log.

    CHECK me->enable_emergency_log NE abap_true.
    CHECK me->log_handle IS BOUND AND me->db_save EQ abap_true.

    TRY.
        cl_bali_log_db=>get_instance( )->save_log( log                        = me->log_handle
                                                   use_2nd_db_connection      = im_use_2nd_db_connection
                                                   assign_to_current_appl_job = im_assign_to_current_appl_job ).

      CATCH cx_bali_runtime INTO DATA(exception).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_release
                                                    previous = exception ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~search_message.

    DATA search_class  TYPE RANGE OF symsgid VALUE IS INITIAL.
    DATA search_number TYPE RANGE OF symsgno VALUE IS INITIAL.
    DATA search_type   TYPE RANGE OF symsgty VALUE IS INITIAL.

    search_class = COND #( WHEN search-msgid IS NOT INITIAL
                           THEN VALUE #( ( sign   = zcl_cloud_logger=>c_select_options-sign_include
                                          option = zcl_cloud_logger=>c_select_options-option_equal
                                          low    = search-msgid ) )
                           ELSE VALUE #( ) ).

    search_number = COND #( WHEN search-msgno IS NOT INITIAL
                            THEN VALUE #( ( sign  = zcl_cloud_logger=>c_select_options-sign_include
                                            option = zcl_cloud_logger=>c_select_options-option_equal
                                            low    = search-msgno ) )
                            ELSE VALUE #( ) ).

    search_type = COND #( WHEN search-msgty IS NOT INITIAL
                          THEN VALUE #( ( sign   = zcl_cloud_logger=>c_select_options-sign_include
                                          option = zcl_cloud_logger=>c_select_options-option_equal
                                          low    = search-msgty ) )
                          ELSE VALUE #( ) ).

    LOOP AT me->log_messages INTO DATA(found_message) WHERE    symsg-msgid    IN search_class
                                                              AND symsg-msgno IN search_number
                                                              AND symsg-msgty IN search_type.
      RETURN abap_true.
    ENDLOOP.

  ENDMETHOD.


  METHOD create_emergency_log.

    CHECK me->enable_emergency_log EQ abap_true.

    me->ext_number = COND #( WHEN me->ext_number IS INITIAL
                             THEN  xco_cp=>uuid( )->as( xco_cp_uuid=>format->c36 )->value
                             ELSE me->ext_number ).

    TRY.

        emergency_log = xco_cp_bal=>for->database( )->log->create( iv_object      = me->object
                                                                   iv_subobject   = me->subobject
                                                                   iv_external_id = me->ext_number ).

      CATCH cx_root INTO DATA(xco_error).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_emergency_log
                                                    previous = xco_error ).
    ENDTRY.

  ENDMETHOD.


  METHOD create_header.

    TRY.

        header = cl_bali_header_setter=>create( object      = me->object
                                                subobject   = me->subobject
                                                external_id = me->ext_number
                    )->set_expiry( expiry_date       = COND #( WHEN me->expiry_date IS NOT INITIAL
                                                               THEN me->expiry_date
                                                               ELSE CONV d( cl_abap_context_info=>get_system_date( ) + 5 ) )
                                   keep_until_expiry = abap_true ).

      CATCH cx_bali_runtime cx_uuid_error INTO DATA(exception).
        DATA(exception_text) = exception->get_text( ).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_creation
                                                    previous = exception ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~free.

    DELETE TABLE logger_instances
      WITH TABLE KEY log_object    = me->object
                     log_subobject = me->subobject
                     extnumber     = me->ext_number.

    CLEAR: me->log_handle,
           me->header,
           me->log_messages.

  ENDMETHOD.


  METHOD zif_cloud_logger~log_data_add.

    TRY.

        DATA(json_string) = xco_cp_json=>data->from_abap( data )->to_string( ).

        me->log_string_add( string = json_string
                            msgty  = msgty ).

      CATCH cx_root INTO DATA(error).
        me->log_string_add( string = |Error serializing data to JSON: { error->get_text( ) }|
                            msgty  = 'E' ).
    ENDTRY.

    logger = me.

  ENDMETHOD.


  METHOD get_severity_filter.

    RETURN SWITCH #( msgty
                       WHEN zif_cloud_logger~c_message_type-abandon OR zif_cloud_logger~c_message_type-terminate
                       THEN VALUE #( sign   = zcl_cloud_logger=>c_select_options-sign_include
                                     option = zcl_cloud_logger=>c_select_options-option_equal
                                    ( low = zif_cloud_logger~c_message_type-abandon )
                                     ( low = zif_cloud_logger~c_message_type-terminate ) )
                       WHEN zif_cloud_logger~c_message_type-error
                       THEN VALUE #( sign   = zcl_cloud_logger=>c_select_options-sign_include
                                     option = zcl_cloud_logger=>c_select_options-option_equal
                                   ( low = zif_cloud_logger~c_message_type-error )
                                   ( low = zif_cloud_logger~c_message_type-abandon )
                                   ( low = zif_cloud_logger~c_message_type-terminate ) )
                       WHEN zif_cloud_logger~c_message_type-warning
                       THEN VALUE #( sign   = zcl_cloud_logger=>c_select_options-sign_include
                                     option = zcl_cloud_logger=>c_select_options-option_equal
                                   ( low = zif_cloud_logger~c_message_type-warning )
                                   ( low = zif_cloud_logger~c_message_type-error )
                                   ( low = zif_cloud_logger~c_message_type-abandon )
                                   ( low = zif_cloud_logger~c_message_type-terminate ) )
                       ELSE VALUE #( ) ).

  ENDMETHOD.


  METHOD zif_cloud_logger~start_timer.

    GET TIME STAMP FIELD me->timer_start.
    logger = me.

  ENDMETHOD.


  METHOD zif_cloud_logger~stop_timer.

    IF me->timer_start IS INITIAL.
      me->log_string_add( string = CONV #( TEXT-002 )
                          msgty  = zif_cloud_logger=>c_message_type-warning ).
      logger = me.
      RETURN.
    ENDIF.

    GET TIME STAMP FIELD DATA(now).

    TRY.
        DATA(diff) = cl_abap_tstmp=>subtract( tstmp1 = now
                                              tstmp2 = me->timer_start ).

        me->log_string_add( string = |{ TEXT-003 } { text } { TEXT-004 } { diff } { TEXT-005 }|
                            msgty  = zif_cloud_logger=>c_message_type-information ).

        CLEAR me->timer_start.

      CATCH cx_parameter_invalid_range cx_parameter_invalid_type.
        me->log_string_add( string = CONV #( TEXT-001 )
                            msgty  = zif_cloud_logger=>c_message_type-error ).
    ENDTRY.

    logger = me.

  ENDMETHOD.


  METHOD zif_cloud_logger~display.

    viewer->view( me ).

  ENDMETHOD.


  METHOD zif_cloud_logger~clear_context.
    CLEAR me->context.
    logger = me.
  ENDMETHOD.


  METHOD zif_cloud_logger~set_context.
    me->context = context.
    logger = me.
  ENDMETHOD.
ENDCLASS.
