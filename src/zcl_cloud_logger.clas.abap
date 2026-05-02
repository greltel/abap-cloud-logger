"! <p class="shorttext synchronized" lang="en">Cloud Logger Main</p>
"!
CLASS zcl_cloud_logger DEFINITION
  PUBLIC
  CREATE PRIVATE .

  PUBLIC SECTION.

    INTERFACES zif_cloud_logger .

    ALIASES clear_internal_errors
      FOR zif_cloud_logger~clear_internal_errors.
    ALIASES get_internal_errors
      FOR zif_cloud_logger~get_internal_errors .
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
    ALIASES flat_message
      FOR zif_cloud_logger~flat_message .
    ALIASES flat_messages
      FOR zif_cloud_logger~flat_messages .
    ALIASES logger_instance
      FOR zif_cloud_logger~t_logger_instance .
    ALIASES logger_instances_type
      FOR zif_cloud_logger~logger_instances .
    ALIASES log_messages_type
      FOR zif_cloud_logger~log_messages .
    ALIASES rap_messages
      FOR zif_cloud_logger~rap_messages .

    "! <p class="shorttext synchronized">Get Cloud Logger Instance</p>
    "!
    "! @parameter object          | <p class="shorttext synchronized">IV_OBJECT</p>
    "! @parameter subobject       | <p class="shorttext synchronized">IV_SUBOBJECT</p>
    "! @parameter ext_number      | <p class="shorttext synchronized">IV_EXT_NUMBER</p>
    "! @parameter db_save         | <p class="shorttext synchronized">IV_DB_SAVE</p>
    "! @parameter expiry_date     | <p class="shorttext synchronized">Application Log: Expiration Date</p>
    "! @parameter logger_instance | <p class="shorttext synchronized">RE_LOGGER_INSTANCE</p>
    CLASS-METHODS get_instance
      IMPORTING
        !enable_emergency_log  TYPE abap_boolean DEFAULT abap_false
        !object                TYPE cl_bali_header_setter=>ty_object OPTIONAL
        !subobject             TYPE cl_bali_header_setter=>ty_subobject OPTIONAL
        !ext_number            TYPE cl_bali_header_setter=>ty_external_id OPTIONAL
        !db_save               TYPE abap_boolean DEFAULT abap_true
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
    DATA internal_errors TYPE zif_cloud_logger=>internal_errors .
    DATA db_save TYPE abap_boolean .
    DATA object TYPE cl_bali_header_setter=>ty_object .
    DATA subobject TYPE cl_bali_header_setter=>ty_subobject .
    DATA ext_number TYPE cl_bali_header_setter=>ty_external_id .
    DATA expiry_date TYPE xsddate_d .
    DATA enable_emergency_log TYPE abap_boolean .
    DATA timer_start TYPE timestampl .
    DATA context TYPE string .

    "! <p class="shorttext synchronized">CONSTRUCTOR</p>
    "!
    "! @parameter object      | <p class="shorttext synchronized">IV_OBJECT</p>
    "! @parameter subobject   | <p class="shorttext synchronized">IV_SUBOBJECT</p>
    "! @parameter ext_number  | <p class="shorttext synchronized">IV_EXT_NUMBER</p>
    "! @parameter db_save     | <p class="shorttext synchronized">IV_DB_SAVE</p>
    "! @parameter expiry_date | <p class="shorttext synchronized">Application Log: Expiration Date</p>
    METHODS constructor
      IMPORTING
        !enable_emergency_log TYPE abap_boolean DEFAULT abap_false
        !object               TYPE cl_bali_header_setter=>ty_object OPTIONAL
        !subobject            TYPE cl_bali_header_setter=>ty_subobject OPTIONAL
        !ext_number           TYPE cl_bali_header_setter=>ty_external_id OPTIONAL
        !db_save              TYPE abap_boolean DEFAULT abap_true
        !expiry_date          TYPE xsddate_d OPTIONAL .
    "! <p class="shorttext synchronized">Add Message to Internal Log</p>
    "!
    "! @parameter symsg | <p class="shorttext synchronized">IV_MSGV3</p>
    "! @parameter item  | <p class="shorttext synchronized">Application Log Item Data (e.g. Message; for Writing)</p>
    METHODS add_message_internal_log
      IMPORTING
        !symsg     TYPE symsg OPTIONAL
        !item      TYPE REF TO if_bali_item_setter OPTIONAL
        !full_text TYPE string OPTIONAL
        !exception TYPE REF TO cx_root OPTIONAL .
    "! <p class="shorttext synchronized">Get Long Text from Message</p>
    "!
    "! @parameter symsg     | <p class="shorttext synchronized">IV_MSGV4</p>
    "! @parameter long_text | <p class="shorttext synchronized">RE_LONG_TEXT</p>
    CLASS-METHODS get_long_text_from_message
      IMPORTING
        !symsg           TYPE symsg
      RETURNING
        VALUE(long_text) TYPE bapiret2-message .
    "! <p class="shorttext synchronized">Get String from Message</p>
    "!
    "! @parameter message | <p class="shorttext synchronized">Structure of message variables</p>
    CLASS-METHODS get_string_from_message
      IMPORTING
        !message      TYPE symsg
      RETURNING
        VALUE(result) TYPE flat_message .
    "! <p class="shorttext synchronized">Create Emergency Log</p>
    METHODS create_emergency_log .
    "! <p class="shorttext synchronized">Create Header Object</p>
    "!
    "! @parameter header | <p class="shorttext synchronized">Application Log Header Data (for Writing)</p>
    METHODS create_header
      RETURNING
        VALUE(header) TYPE REF TO if_bali_header_setter .
    "! <p class="shorttext synchronized">Get Severity Level of Message Type</p>
    "!
    "! @parameter msgty | <p class="shorttext synchronized">Message Type</p>
    METHODS get_severity_filter
      IMPORTING
        !msgty        TYPE symsgty
      RETURNING
        VALUE(filter) TYPE zcl_cloud_logger=>severity_filter_range .
    "! <p class="shorttext synchronized">Mirror message to emergency log via XCO</p>
    "!
    "! <p>Best-effort dispatch to the appropriate if_xco_cp_bal_log method based
    "! on which input is provided. Picks add_exception for exceptions,
    "! add_message for symsg-based input, add_text for plain strings.
    "! Failures are swallowed — the emergency log must never break the main flow.</p>
    "!
    "! @parameter exception | Optional exception to mirror via add_exception
    "! @parameter symsg     | Optional symsg-based message to mirror via add_message
    "! @parameter text      | Optional free-text string to mirror via add_text
    METHODS mirror_to_emergency_log
      IMPORTING
        !exception TYPE REF TO cx_root OPTIONAL
        !symsg     TYPE symsg OPTIONAL
        !text      TYPE string OPTIONAL .
    "! <p class="shorttext synchronized">Record a diagnostic entry in the internal error trail</p>
    "!
    "! <p>Used by read-only methods to surface swallowed exceptions, and by
    "! self-logging code paths (e.g. save_application_log no-op) to leave a
    "! trace without polluting the user-facing log. Either an exception or
    "! a plain error_text must be supplied.</p>
    "!
    "! @parameter method_name | Method that produced the diagnostic
    "! @parameter exception   | Optional exception (its get_text is used)
    "! @parameter error_text  | Optional plain text (used when no exception is available)
    METHODS record_internal_error
      IMPORTING method_name TYPE string
                exception   TYPE REF TO cx_root OPTIONAL
                error_text  TYPE string         OPTIONAL.
    "! <p class="shorttext synchronized">Best-effort log_string_add for internal/self-logging</p>
    "!
    "! <p>Wraps log_string_add so internal callers (start_timer, stop_timer,
    "! log_data_add fallback) never propagate logging exceptions to the user.
    "! On failure, the error is recorded in the internal trail.</p>
    "!
    "! @parameter string      | Message text
    "! @parameter msgty       | Severity (defaults to information)
    "! @parameter caller_name | Method that requested the safe emit (for diagnostics)
    METHODS safe_log_string
      IMPORTING string      TYPE string
                msgty       TYPE symsgty DEFAULT c_message_type-information
                caller_name TYPE string.
ENDCLASS.



CLASS ZCL_CLOUD_LOGGER IMPLEMENTATION.


  METHOD add_message_internal_log.
    DATA(message_text) = COND string(
      WHEN full_text IS SUPPLIED AND full_text IS NOT INITIAL
      THEN full_text
      ELSE CONV string( get_long_text_from_message( symsg ) ) ).

    INSERT VALUE #( item      = item
                    symsg     = symsg
                    message   = message_text
                    type      = symsg-msgty
                    context   = me->context
                    user_name = cl_abap_context_info=>get_user_alias( )
                    date      = cl_abap_context_info=>get_system_date( )
                    time      = cl_abap_context_info=>get_system_time( ) ) INTO TABLE log_messages.

    mirror_to_emergency_log( exception = exception
                             symsg     = symsg
                             text      = message_text ).

  ENDMETHOD.


  METHOD constructor.

    IF db_save = abap_true AND object IS INITIAL.
      RAISE EXCEPTION NEW zcx_cloud_logger_error( textid = zcx_cloud_logger_error=>error_in_creation ).
    ENDIF.

    TRY.

        me->log_handle           = cl_bali_log=>create( ).
        me->object               = object.
        me->subobject            = subobject.
        me->ext_number           = ext_number.
        me->expiry_date          = expiry_date.
        me->enable_emergency_log = enable_emergency_log.

        TRY.
            header = create_header( ).

            log_handle->set_header( header ).

          CATCH cx_bali_runtime cx_uuid_error INTO DATA(exception).
            RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_creation
                                                        previous = exception ).
        ENDTRY.

        me->db_save = db_save.

        create_emergency_log( ).

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

    IF sy-subrc IS INITIAL.

      " Existing instance found - validate that the caller's request is compatible.
      " A non-initial parameter that differs from the stored value is a mismatch.
      " Initial parameters are treated as "no preference" and therefore compatible.

      DATA mismatch TYPE abap_boolean VALUE abap_false.

      IF db_save IS SUPPLIED AND db_save <> instance-db_save.
        mismatch = abap_true.
      ENDIF.

      IF     enable_emergency_log IS SUPPLIED
         AND enable_emergency_log <> instance-enable_emergency_log.
        mismatch = abap_true.
      ENDIF.

      IF     expiry_date IS SUPPLIED
         AND expiry_date IS NOT INITIAL
         AND expiry_date <> instance-expiry_date.
        mismatch = abap_true.
      ENDIF.

      IF mismatch = abap_true.
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid = zcx_cloud_logger_error=>config_mismatch ).
      ENDIF.

      logger_instance = instance-logger.
      RETURN.
    ENDIF.

    " No existing instance - create a new one
    logger_instance = NEW zcl_cloud_logger( object               = object
                                            subobject            = subobject
                                            ext_number           = ext_number
                                            db_save              = db_save
                                            enable_emergency_log = enable_emergency_log
                                            expiry_date          = expiry_date ).

    INSERT VALUE #( log_object           = object
                    log_subobject        = subobject
                    extnumber            = ext_number
                    db_save              = db_save
                    enable_emergency_log = enable_emergency_log
                    expiry_date          = expiry_date
                    logger               = logger_instance ) INTO TABLE logger_instances.
  ENDMETHOD.


  METHOD get_long_text_from_message.

    RETURN xco_cp=>message( symsg )->get_text( ).

  ENDMETHOD.


  METHOD get_string_from_message.

    RETURN |{ message-msgty }{ message-msgno }({ message-msgid }) - { xco_cp=>message( message )->get_text( ) }|.

  ENDMETHOD.


  METHOD zif_cloud_logger~get_handle.

    RETURN log_handle->get_handle( ).

  ENDMETHOD.


  METHOD zif_cloud_logger~get_log_handle.

    RETURN log_handle.

  ENDMETHOD.


  METHOD zif_cloud_logger~get_messages.

    RETURN log_messages.

  ENDMETHOD.


  METHOD zif_cloud_logger~get_messages_as_bapiret2.

    RETURN VALUE #( FOR <msg> IN log_messages
              ( id         = <msg>-symsg-msgid
                number     = <msg>-symsg-msgno
                type       = <msg>-symsg-msgty
                message_v1 = <msg>-symsg-msgv1
                message_v2 = <msg>-symsg-msgv2
                message_v3 = <msg>-symsg-msgv3
                message_v4 = <msg>-symsg-msgv4
                message    = <msg>-message ) ).


  ENDMETHOD.


  METHOD zif_cloud_logger~get_messages_flat.

    RETURN VALUE #( FOR msg IN log_messages
                    ( COND flat_message(
                        LET base = COND string(
                            WHEN msg-symsg-msgid IS INITIAL OR msg-symsg-msgno IS INITIAL
                            THEN |{ msg-message }|
                            ELSE get_string_from_message( msg-symsg ) )
                        IN
                        WHEN msg-context IS NOT INITIAL
                        THEN |[{ msg-context }] { base }|
                        ELSE base ) ) ).

  ENDMETHOD.


  METHOD zif_cloud_logger~get_messages_rap.

    RETURN VALUE #( FOR message IN log_messages
                  ( zcx_cloud_logger_message=>new_message_from_symsg( message-symsg ) ) ).

  ENDMETHOD.


  METHOD zif_cloud_logger~get_message_count.

    CHECK log_handle IS BOUND.

    TRY.
        RETURN lines( log_handle->get_all_items( ) ).
      CATCH cx_bali_runtime INTO DATA(exception).
        record_internal_error( method_name = 'get_message_count'
                               exception   = exception ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~log_bapiret2_structure_add.

    CHECK bapiret2 IS NOT INITIAL.

    TRY.
        DATA(item) = cl_bali_message_setter=>create_from_bapiret2( bapiret2 ).

        log_handle->add_item( item ).

        add_message_internal_log( symsg =  VALUE #( msgid = bapiret2-id
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
      log_bapiret2_structure_add( bapiret2_structure->* ).
    ENDLOOP.

    logger = me.

  ENDMETHOD.


  METHOD zif_cloud_logger~log_contains_error.

    CLEAR result.
    CHECK log_handle IS BOUND.

    TRY.

        LOOP AT log_handle->get_all_items( ) ASSIGNING FIELD-SYMBOL(<fs>) WHERE item->severity CA c_message_type-error_pattern.
          RETURN abap_true.
        ENDLOOP.

      CATCH cx_bali_runtime INTO DATA(exception).
        record_internal_error( method_name = 'log_contains_error'
                               exception   = exception ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~log_contains_messages.

    CLEAR result.
    CHECK log_handle IS BOUND.

    TRY.
        RETURN xsdbool( get_message_count( ) > 0 ).
      CATCH cx_bali_runtime INTO DATA(exception).
        record_internal_error( method_name = 'log_contains_messages'
                               exception   = exception ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~log_contains_warning.

    CLEAR result.
    CHECK log_handle IS BOUND.

    TRY.

        LOOP AT log_handle->get_all_items( ) ASSIGNING FIELD-SYMBOL(<fs>) WHERE item->severity CA c_message_type-warning_pattern.
          RETURN abap_true.
        ENDLOOP.

      CATCH cx_bali_runtime INTO DATA(exception).
        record_internal_error( method_name = 'log_contains_warning'
                               exception   = exception ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~log_exception_add.
    CHECK exception IS BOUND AND log_handle IS BOUND.

    TRY.

        DATA(item) = cl_bali_exception_setter=>create( severity  = severity
                                                       exception = exception ).

        log_handle->add_item( item ).

        add_message_internal_log( symsg     = VALUE #( msgty = severity )
                                  item      = item
                                  full_text = exception->get_text( )
                                  exception = exception ).

        logger = me.

      CATCH cx_bali_runtime INTO DATA(exception_local).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_logging
                                                    previous = exception_local ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_cloud_logger~log_is_empty.

    CHECK log_handle IS BOUND.

    TRY.
        RETURN xsdbool( get_message_count( ) IS INITIAL ).
      CATCH cx_bali_runtime INTO DATA(exception).
        record_internal_error( method_name = 'log_is_empty'
                               exception   = exception ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~log_message_add.

    CHECK log_handle IS BOUND.

    TRY.

        DATA(item) = cl_bali_message_setter=>create( severity   = symsg-msgty
                                                     id         = symsg-msgid
                                                     number     = symsg-msgno
                                                     variable_1 = symsg-msgv1
                                                     variable_2 = symsg-msgv2
                                                     variable_3 = symsg-msgv3
                                                     variable_4 = symsg-msgv4 ).

        log_handle->add_item( item ).

        add_message_internal_log( symsg = symsg
                                      item  = item ).

        logger = me.

      CATCH cx_bali_runtime INTO DATA(exception).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_logging
                                                    previous = exception ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~log_string_add.
    CHECK log_handle IS BOUND.

    TRY.

        DATA(persisted_text) = COND string( WHEN context IS NOT INITIAL
                                            THEN |[{ context }] { string }|
                                            ELSE string ).

        DATA(item) = cl_bali_free_text_setter=>create( severity = msgty
                                                       text     = CONV #( persisted_text ) ).

        log_handle->add_item( item ).

        add_message_internal_log( symsg     = VALUE #( msgty = msgty )
                                  item      = item
                                  full_text = string ).

        logger = me.

      CATCH cx_bali_runtime INTO DATA(exception).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_logging
                                                    previous = exception ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_cloud_logger~log_syst_add.

    CHECK log_handle IS BOUND.

    TRY.

        DATA(xco_message) = xco_cp=>sy->message( ).
        DATA(item)        = cl_bali_message_setter=>create_from_sy( ).

        log_handle->add_item( item ).

        add_message_internal_log( symsg = VALUE #( msgid = xco_message->value-msgid
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
    CHECK external_log IS BOUND.

    TRY.
        log_handle->add_all_items_from_other_log( external_log->get_log_handle( ) ).
        INSERT LINES OF external_log->get_messages( )        INTO TABLE log_messages.
        INSERT LINES OF external_log->get_internal_errors( ) INTO TABLE internal_errors.

      CATCH cx_bali_runtime INTO DATA(exception).
        record_internal_error( method_name = 'merge_logs'
                               exception   = exception ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_cloud_logger~reset_appl_log.
    TRY.

        " Delete from Database
        IF log_handle IS BOUND AND delete_from_db = abap_true.
          cl_bali_log_db=>get_instance( )->delete_log( log_handle ).
        ENDIF.

        " Handle Recreation
        CLEAR log_handle.
        log_handle = cl_bali_log=>create( ).

        header = COND #( WHEN header IS BOUND
                         THEN header
                         ELSE create_header( ) ).

        log_handle->set_header( header ).

        CLEAR log_messages.

        CLEAR: timer_start,
               context.

        CLEAR emergency_log.
        TRY.
            create_emergency_log( ).
          CATCH zcx_cloud_logger_error INTO DATA(emerg_error).
            record_internal_error( method_name = 'reset_appl_log (emergency log recreation)'
                                   exception   = emerg_error ).
        ENDTRY.

      CATCH cx_bali_runtime INTO DATA(exception).
        record_internal_error( method_name = 'reset_appl_log'
                               exception   = exception ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_cloud_logger~save_application_log.
    CHECK log_handle IS BOUND.

    IF db_save = abap_false.
      " Record the no-op in the internal diagnostic trail. We deliberately do NOT
      " write to the user-facing log here: callers may invoke save_application_log
      " in a loop, and a per-call warning would flood log_messages with noise.
      record_internal_error( method_name = 'save_application_log'
                             error_text  = 'db_save is disabled - no-op' ).
      RETURN.
    ENDIF.

    "TO-BE IMPLEMENTED WITH BGPF
*    IF async EQ abap_true.
*
*      TRY.
*          DATA(lo_bg_op) = NEW zcl_cloud_logger_save_bg( iv_object      = object
*                                                         iv_subobject   = subobject
*                                                         iv_ext_number  = ext_number
*                                                         iv_expiry_date = expiry_date
*                                                         it_messages    = log_messages ).
*
*          DATA(lo_process) = cl_bgmc_process_factory=>get_default( )->create( ).
*          lo_process->set_name( async_name ).
*          lo_process->set_operation_tx_uncontrolled( lo_bg_op ).
*          lo_process->save_for_execution( ).
*
*          RETURN.
*
*        CATCH cx_bgmc INTO DATA(lx_bgmc).
*          RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_release
*                                                      previous = lx_bgmc ).
*      ENDTRY.
*
*    ENDIF.

    TRY.
        cl_bali_log_db=>get_instance( )->save_log( log                        = log_handle
                                                   use_2nd_db_connection      = use_2nd_db_connection
                                                   assign_to_current_appl_job = assign_to_current_appl_job ).

      CATCH cx_bali_runtime INTO DATA(exception).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_release
                                                    previous = exception ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_cloud_logger~search_message.

    IF search IS INITIAL.
      RETURN xsdbool( log_messages IS NOT INITIAL ).
    ENDIF.

    DATA search_class  TYPE RANGE OF symsgid.
    DATA search_number TYPE RANGE OF symsgno.
    DATA search_type   TYPE RANGE OF symsgty.

    IF search-msgid IS NOT INITIAL.
      search_class = VALUE #( ( sign   = c_select_options-sign_include
                                option = c_select_options-option_equal
                                low    = search-msgid ) ).
    ENDIF.

    IF search-msgno IS NOT INITIAL.
      search_number = VALUE #( ( sign   = c_select_options-sign_include
                                 option = c_select_options-option_equal
                                 low    = search-msgno ) ).
    ENDIF.

    IF search-msgty IS NOT INITIAL.
      search_type = VALUE #( ( sign   = c_select_options-sign_include
                               option = c_select_options-option_equal
                               low    = search-msgty ) ).
    ENDIF.

    LOOP AT log_messages ASSIGNING FIELD-SYMBOL(<msg>)
         WHERE symsg-msgid IN search_class
           AND symsg-msgno IN search_number
           AND symsg-msgty IN search_type.
      RETURN abap_true.
    ENDLOOP.

  ENDMETHOD.


  METHOD create_emergency_log.
    CHECK enable_emergency_log = abap_true.

    DATA(emergency_ext_number) = COND cl_bali_header_setter=>ty_external_id(
      WHEN ext_number IS INITIAL
      THEN xco_cp=>uuid( )->as( xco_cp_uuid=>format->c36 )->value
      ELSE ext_number ).

    TRY.
        emergency_log = xco_cp_bal=>for->database( )->log->create( iv_object      = object
                                                                   iv_subobject   = subobject
                                                                   iv_external_id = emergency_ext_number ).

      CATCH cx_root INTO DATA(xco_error).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_emergency_log
                                                    previous = xco_error ).
    ENDTRY.
  ENDMETHOD.


  METHOD create_header.

    TRY.

        header = cl_bali_header_setter=>create( object      = object
                                                subobject   = subobject
                                                external_id = ext_number
                    )->set_expiry( expiry_date       = COND #( WHEN expiry_date IS NOT INITIAL
                                                               THEN expiry_date
                                                               ELSE CONV d( cl_abap_context_info=>get_system_date( ) + 5 ) )
                                   keep_until_expiry = abap_true ).

      CATCH cx_bali_runtime cx_uuid_error INTO DATA(exception).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_creation
                                                    previous = exception ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_cloud_logger~free.
    DELETE TABLE logger_instances
           WITH TABLE KEY log_object    = object
                          log_subobject = subobject
                          extnumber     = ext_number.

    CLEAR: log_handle,
           header,
           log_messages,
           emergency_log,
           timer_start,
           context,
           internal_errors.
  ENDMETHOD.


  METHOD zif_cloud_logger~log_data_add.

    TRY.

        DATA(json_string) = xco_cp_json=>data->from_abap( data )->to_string( ).

        log_string_add( string = json_string
                            msgty  = msgty ).

      CATCH cx_root INTO DATA(error).
        safe_log_string( string      = |Error serializing data to JSON: { error->get_text( ) }|
                         msgty       = c_message_type-error
                         caller_name = 'log_data_add (fallback emit)' ).
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

    IF timer_start IS NOT INITIAL.
      safe_log_string( string      = 'start_timer called twice without stop_timer - previous timer reset'
                       msgty       = c_message_type-warning
                       caller_name = 'start_timer' ).
    ENDIF.

    GET TIME STAMP FIELD timer_start.
    logger = me.

  ENDMETHOD.


  METHOD zif_cloud_logger~stop_timer.

    IF timer_start IS INITIAL.
      safe_log_string( string      = CONV #( TEXT-002 )
                       msgty       = zif_cloud_logger=>c_message_type-warning
                       caller_name = 'stop_timer' ).
      logger = me.
      RETURN.
    ENDIF.

    GET TIME STAMP FIELD DATA(now).

    TRY.
        DATA(diff) = cl_abap_tstmp=>subtract( tstmp1 = now
                                              tstmp2 = timer_start ).

        log_string_add( string = |{ TEXT-003 } { text } { TEXT-004 } { diff DECIMALS = 3 } { TEXT-005 }|
                            msgty  = zif_cloud_logger=>c_message_type-information ).

        CLEAR timer_start.

      CATCH cx_parameter_invalid_range cx_parameter_invalid_type.
        safe_log_string( string      = CONV #( TEXT-001 )
                         msgty       = zif_cloud_logger=>c_message_type-error
                         caller_name = 'stop_timer (timer arithmetic)' ).
    ENDTRY.

    logger = me.

  ENDMETHOD.


  METHOD zif_cloud_logger~display.

    viewer->view( me ).

  ENDMETHOD.


  METHOD zif_cloud_logger~clear_context.
    CLEAR context.
    logger = me.
  ENDMETHOD.


  METHOD zif_cloud_logger~set_context.
    me->context = context.
    logger = me.
  ENDMETHOD.


  METHOD mirror_to_emergency_log.

    CHECK emergency_log IS BOUND AND enable_emergency_log = abap_true.

    TRY.
        IF exception IS BOUND.
          emergency_log->add_exception( ix_exception = exception ).

        ELSEIF symsg-msgid IS NOT INITIAL.
          emergency_log->add_message( is_symsg = symsg ).

        ELSEIF text IS NOT INITIAL.
          emergency_log->add_text( io_text = xco_cp=>string( text ) ).
        ENDIF.

      CATCH cx_root.
        " Emergency log is best-effort. Failures here must never break the main flow.
    ENDTRY.

  ENDMETHOD.


  METHOD record_internal_error.

    GET TIME STAMP FIELD DATA(now).

    DATA(text) = COND string( WHEN exception IS BOUND
                              THEN exception->get_text( )
                              ELSE error_text ).

    INSERT VALUE #( timestamp  = now
                    method     = method_name
                    error_text = text ) INTO TABLE internal_errors.

    " Bound the trail. Drop in batches for amortized O(1) on overflow.
    IF lines( internal_errors ) > 100.
      DELETE internal_errors FROM 1 TO ( lines( internal_errors ) - 100 ).
    ENDIF.

  ENDMETHOD.


  METHOD zif_cloud_logger~get_internal_errors.
    RETURN internal_errors.
  ENDMETHOD.


  METHOD zif_cloud_logger~clear_internal_errors.
    CLEAR internal_errors.
    logger = me.
  ENDMETHOD.


  METHOD safe_log_string.

    TRY.
        log_string_add( string = string
                        msgty  = msgty ).
      CATCH zcx_cloud_logger_error INTO DATA(error).
        record_internal_error( method_name = caller_name
                               exception   = error ).
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
