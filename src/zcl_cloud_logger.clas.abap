"! <p class="shorttext synchronized" lang="en">Cloud Logger Main</p>
"! Multiton implementation of {@link zif_cloud_logger} on top of
"! {@link cl_bali_log}. Instances are shared per object / subobject /
"! external id and obtained through {@link zcl_cloud_logger.METH:get_instance}.
"! Environment and database access go through {@link zif_cloud_logger_system}
"! and {@link zif_cloud_logger_persistence}, so the class is unit-testable
"! without a clock or a database.
CLASS zcl_cloud_logger DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_cloud_logger.

    ALIASES clear_internal_errors        FOR zif_cloud_logger~clear_internal_errors.
    ALIASES get_internal_errors          FOR zif_cloud_logger~get_internal_errors.
    ALIASES c_default_message_attributes FOR zif_cloud_logger~c_default_message_attributes.
    ALIASES c_message_type               FOR zif_cloud_logger~c_message_type.
    ALIASES c_select_options             FOR zif_cloud_logger~c_select_options.
    ALIASES free                         FOR zif_cloud_logger~free.
    ALIASES get_handle                   FOR zif_cloud_logger~get_handle.
    ALIASES get_log_handle               FOR zif_cloud_logger~get_log_handle.
    ALIASES get_messages                 FOR zif_cloud_logger~get_messages.
    ALIASES get_messages_as_bapiret2     FOR zif_cloud_logger~get_messages_as_bapiret2.
    ALIASES get_messages_flat            FOR zif_cloud_logger~get_messages_flat.
    ALIASES get_messages_rap             FOR zif_cloud_logger~get_messages_rap.
    ALIASES get_message_count            FOR zif_cloud_logger~get_message_count.
    ALIASES log_bapiret2_structure_add   FOR zif_cloud_logger~log_bapiret2_structure_add.
    ALIASES log_bapiret2_table_add       FOR zif_cloud_logger~log_bapiret2_table_add.
    ALIASES log_contains_error           FOR zif_cloud_logger~log_contains_error.
    ALIASES log_contains_messages        FOR zif_cloud_logger~log_contains_messages.
    ALIASES log_contains_warning         FOR zif_cloud_logger~log_contains_warning.
    ALIASES log_data_add                 FOR zif_cloud_logger~log_data_add.
    ALIASES log_exception_add            FOR zif_cloud_logger~log_exception_add.
    ALIASES log_is_empty                 FOR zif_cloud_logger~log_is_empty.
    ALIASES log_message_add              FOR zif_cloud_logger~log_message_add.
    ALIASES log_string_add               FOR zif_cloud_logger~log_string_add.
    ALIASES log_syst_add                 FOR zif_cloud_logger~log_syst_add.
    ALIASES merge_logs                   FOR zif_cloud_logger~merge_logs.
    ALIASES reset_appl_log               FOR zif_cloud_logger~reset_appl_log.
    ALIASES save_application_log         FOR zif_cloud_logger~save_application_log.
    ALIASES search_message               FOR zif_cloud_logger~search_message.
    ALIASES bapiret2_messages            FOR zif_cloud_logger~bapiret2_messages.
    ALIASES flat_message                 FOR zif_cloud_logger~flat_message.
    ALIASES flat_messages                FOR zif_cloud_logger~flat_messages.
    ALIASES logger_instance              FOR zif_cloud_logger~t_logger_instance.
    ALIASES logger_instances_type        FOR zif_cloud_logger~logger_instances.
    ALIASES log_messages_type            FOR zif_cloud_logger~log_messages.
    ALIASES rap_messages                 FOR zif_cloud_logger~rap_messages.

    "! <p class="shorttext synchronized" lang="en">Get or create the multiton logger instance</p>
    "!
    "! <p>Clean ABAP rule #2366: this factory intentionally exposes &gt; 3 optional
    "! parameters. They are genuinely independent configuration switches and the
    "! per-parameter IS SUPPLIED semantics drive the config-conflict detection;
    "! collapsing them into a single structure would lose that distinction and
    "! break the public API. Documented, accepted deviation.</p>
    "!
    "! @parameter enable_emergency_log   | abap_true mirrors every entry via XCO BAL (best-effort)
    "! @parameter object                 | Application Log object (BAL); required when db_save = abap_true
    "! @parameter subobject              | Application Log subobject
    "! @parameter ext_number             | External ID; also part of the multiton key
    "! @parameter db_save                | abap_true persists on save_application_log; abap_false makes save a no-op
    "! @parameter expiry_date            | Log expiry date (default = today + c_default_expiry_days)
    "! @parameter trim_limit             | Max internal-error trail entries, FIFO (default 100; negative raises)
    "! @parameter result                 | Shared logger for the object / subobject / ext_number key
    "! @raising   zcx_cloud_logger_error | Config conflict with an existing instance, or creation failure
    CLASS-METHODS get_instance
      IMPORTING enable_emergency_log TYPE abap_boolean                          DEFAULT abap_false
                !object              TYPE cl_bali_header_setter=>ty_object      OPTIONAL
                subobject            TYPE cl_bali_header_setter=>ty_subobject   OPTIONAL
                ext_number           TYPE cl_bali_header_setter=>ty_external_id OPTIONAL
                db_save              TYPE abap_boolean                          DEFAULT abap_true
                expiry_date          TYPE xsddate_d                             OPTIONAL
                trim_limit           TYPE i DEFAULT zif_cloud_logger=>c_default_trim_limit
      RETURNING VALUE(result)        TYPE REF TO zif_cloud_logger
      RAISING   zcx_cloud_logger_error.

    "! <p class="shorttext synchronized" lang="en">Initialize a logger instance</p>
    "!
    "! <p>Public so that CREATE PRIVATE governs instantiation instead of the
    "! constructor's visibility (Clean ABAP). Mirrors get_instance and shares its
    "! documented rule #2366 deviation. The two collaborators are optional with
    "! production defaults: the multiton factory stays unchanged while tests
    "! (local friends) inject doubles.</p>
    "!
    "! @parameter enable_emergency_log   | abap_true mirrors entries via XCO BAL
    "! @parameter object                 | Application Log object (BAL)
    "! @parameter subobject              | Application Log subobject
    "! @parameter ext_number             | External ID for the log
    "! @parameter db_save                | abap_true persists on save_application_log
    "! @parameter expiry_date            | Log expiry date (default = today + c_default_expiry_days)
    "! @parameter trim_limit             | Max internal-error trail entries (FIFO)
    "! @parameter system                 | Environment access; defaults to {@link zcl_cloud_logger_system}
    "! @parameter persistence            | Database access; defaults to {@link zcl_cloud_logger_persistence}
    "! @raising   zcx_cloud_logger_error | Invalid configuration or creation failure
    METHODS constructor
      IMPORTING enable_emergency_log TYPE abap_boolean                          DEFAULT abap_false
                !object              TYPE cl_bali_header_setter=>ty_object      OPTIONAL
                subobject            TYPE cl_bali_header_setter=>ty_subobject   OPTIONAL
                ext_number           TYPE cl_bali_header_setter=>ty_external_id OPTIONAL
                db_save              TYPE abap_boolean                          DEFAULT abap_true
                expiry_date          TYPE xsddate_d                             OPTIONAL
                trim_limit           TYPE i DEFAULT zif_cloud_logger=>c_default_trim_limit
                !system              TYPE REF TO zif_cloud_logger_system        OPTIONAL
                persistence          TYPE REF TO zif_cloud_logger_persistence   OPTIONAL
      RAISING   zcx_cloud_logger_error.

  PRIVATE SECTION.
    TYPES severity_filter_range TYPE RANGE OF symsgty.
    TYPES message_class_range   TYPE RANGE OF symsgid.
    TYPES message_number_range  TYPE RANGE OF symsgno.
    TYPES message_types         TYPE STANDARD TABLE OF symsgty WITH EMPTY KEY.
    TYPES free_text_buffer      TYPE c LENGTH 200.

    CONSTANTS seconds_per_day   TYPE i VALUE 86400.
    " YYYYMMDDhhmmss DIV / MOD this value separates the date from the time part
    CONSTANTS time_part_divisor TYPE i VALUE 1000000.

    CLASS-DATA logger_instances TYPE logger_instances_type.

    DATA trim_limit           TYPE i.
    DATA user_alias           TYPE syuname.
    DATA log_handle           TYPE REF TO if_bali_log.
    DATA header               TYPE REF TO if_bali_header_setter.
    DATA emergency_log        TYPE REF TO if_xco_cp_bal_log.
    DATA log_messages         TYPE log_messages_type.
    DATA internal_errors      TYPE zif_cloud_logger=>internal_errors.
    DATA db_save              TYPE abap_boolean.
    DATA object               TYPE cl_bali_header_setter=>ty_object.
    DATA subobject            TYPE cl_bali_header_setter=>ty_subobject.
    DATA ext_number           TYPE cl_bali_header_setter=>ty_external_id.
    DATA expiry_date          TYPE xsddate_d.
    DATA enable_emergency_log TYPE abap_boolean.
    DATA timer_start          TYPE timestampl.
    DATA context              TYPE string.
    DATA system               TYPE REF TO zif_cloud_logger_system.
    DATA persistence          TYPE REF TO zif_cloud_logger_persistence.
    DATA released             TYPE abap_boolean.

    " Guards every writing method: a released instance is a caller bug, not a silent no-op
    METHODS ensure_active
      RAISING zcx_cloud_logger_error.

    " Adds a prepared entry to the internal log, stamping context, user, date and time
    METHODS record_entry
      IMPORTING entry TYPE zif_cloud_logger=>t_log_messages.

    " Resolves the T100 text; never raises, falls back to the raw message components
    METHODS resolve_message_text
      IMPORTING symsg         TYPE symsg
      RETURNING VALUE(result) TYPE string.

    " Renders one entry as "[context] TNNN(CLASS) - text" (or the plain text)
    METHODS render_entry
      IMPORTING entry         TYPE zif_cloud_logger=>t_log_messages
      RETURNING VALUE(result) TYPE flat_message.

    " Prefixes the sticky context, if any
    METHODS apply_context
      IMPORTING !text         TYPE string
      RETURNING VALUE(result) TYPE string.

    " Packs free text into the &1&2&3&4 carrier message for RAP consumers
    CLASS-METHODS text_to_symsg
      IMPORTING !text         TYPE string
                msgty         TYPE symsgty
      RETURNING VALUE(result) TYPE symsg.

    METHODS create_emergency_log
      RAISING zcx_cloud_logger_error.

    METHODS recreate_emergency_log.

    METHODS create_header
      RETURNING VALUE(result) TYPE REF TO if_bali_header_setter
      RAISING   zcx_cloud_logger_error.

    METHODS delete_from_database.

    " Range of severities kept for a minimum severity; empty range = keep everything
    METHODS get_severity_filter
      IMPORTING msgty         TYPE symsgty
      RETURNING VALUE(result) TYPE severity_filter_range.

    " Best-effort mirror to the XCO emergency log; picks add_exception, add_message
    " or add_text depending on the input. Failures go to the internal error trail.
    METHODS mirror_to_emergency_log
      IMPORTING !exception TYPE REF TO cx_root OPTIONAL
                symsg      TYPE symsg          OPTIONAL
                !text      TYPE string         OPTIONAL.

    " Records a swallowed problem; either an exception or a plain text is supplied
    METHODS record_internal_error
      IMPORTING method_name TYPE string
                !exception  TYPE REF TO cx_root OPTIONAL
                error_text  TYPE string         OPTIONAL.

    " log_string_add for the logger's own diagnostics; never propagates to the caller
    METHODS safe_log_string
      IMPORTING !string     TYPE string
                msgty       TYPE symsgty DEFAULT c_message_type-information
                caller_name TYPE string.

    METHODS trim_internal_errors.

    " Difference of two UTC packed time stamps in seconds, fractions included
    METHODS seconds_between
      IMPORTING started_at    TYPE timestampl
                stopped_at    TYPE timestampl
      RETURNING VALUE(result) TYPE tzntstmpl.

ENDCLASS.


CLASS zcl_cloud_logger IMPLEMENTATION.

  METHOD get_instance.
    TRY.
        DATA(instance) = logger_instances[ log_object    = object
                                           log_subobject = subobject
                                           extnumber     = ext_number ].

        " Existing instance found - a supplied parameter that differs from the
        " stored value is a configuration conflict. Omitted parameters mean
        " "no preference" and are therefore compatible.
        DATA(mismatch) = xsdbool(
             (     db_save              IS SUPPLIED
               AND db_save              <> instance-db_save )
          OR (     enable_emergency_log IS SUPPLIED
               AND enable_emergency_log <> instance-enable_emergency_log )
          OR (     expiry_date          IS SUPPLIED
               AND expiry_date          IS NOT INITIAL
               AND expiry_date          <> instance-expiry_date )
          OR (     trim_limit           IS SUPPLIED
               AND trim_limit           <> instance-trim_limit ) ).

        IF mismatch = abap_true.
          RAISE EXCEPTION NEW zcx_cloud_logger_error( textid = zcx_cloud_logger_error=>config_mismatch ).
        ENDIF.

        result = instance-logger.
        RETURN.

      CATCH cx_sy_itab_line_not_found.
        " no existing instance - fall through to creation
    ENDTRY.

    result = NEW zcl_cloud_logger( object               = object
                                   subobject            = subobject
                                   ext_number           = ext_number
                                   db_save              = db_save
                                   enable_emergency_log = enable_emergency_log
                                   expiry_date          = expiry_date
                                   trim_limit           = trim_limit ).

    INSERT VALUE #( log_object           = object
                    log_subobject        = subobject
                    extnumber            = ext_number
                    db_save              = db_save
                    enable_emergency_log = enable_emergency_log
                    expiry_date          = expiry_date
                    trim_limit           = trim_limit
                    logger               = result ) INTO TABLE logger_instances.
  ENDMETHOD.

  METHOD constructor.
    DATA effective_system TYPE REF TO zif_cloud_logger_system.

    IF db_save = abap_true AND object IS INITIAL.
      RAISE EXCEPTION NEW zcx_cloud_logger_error( textid = zcx_cloud_logger_error=>object_required ).
    ENDIF.

    IF trim_limit < 0.
      RAISE EXCEPTION NEW zcx_cloud_logger_error( textid = zcx_cloud_logger_error=>invalid_trim_limit ).
    ENDIF.

    effective_system = COND #( WHEN system IS BOUND
                               THEN system
                               ELSE NEW zcl_cloud_logger_system( ) ).
    me->system      = effective_system.
    me->persistence = COND #( WHEN persistence IS BOUND
                              THEN persistence
                              ELSE NEW zcl_cloud_logger_persistence( ) ).

    me->object               = object.
    me->subobject            = subobject.
    me->ext_number           = ext_number.
    me->expiry_date          = expiry_date.
    me->enable_emergency_log = enable_emergency_log.
    me->db_save              = db_save.
    me->trim_limit           = trim_limit.
    user_alias               = effective_system->user_name( ).

    TRY.
        log_handle = cl_bali_log=>create( ).
        header     = create_header( ).
        log_handle->set_header( header ).

      CATCH cx_bali_runtime cx_uuid_error INTO DATA(error).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_creation
                                                    previous = error ).
    ENDTRY.

    create_emergency_log( ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_string_add.
    self = me.
    ensure_active( ).

    TRY.
        DATA(item) = cl_bali_free_text_setter=>create( severity = msgty
                                                       text     = CONV #( apply_context( string ) ) ).

        log_handle->add_item( item ).

        record_entry( VALUE #( symsg   = VALUE #( msgty = msgty )
                               item    = item
                               message = string ) ).

        mirror_to_emergency_log( text = string ).

      CATCH cx_bali_runtime INTO DATA(error).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_logging
                                                    previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_cloud_logger~log_message_add.
    self = me.
    ensure_active( ).

    IF symsg IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(item) = cl_bali_message_setter=>create( severity   = symsg-msgty
                                                     id         = symsg-msgid
                                                     number     = symsg-msgno
                                                     variable_1 = symsg-msgv1
                                                     variable_2 = symsg-msgv2
                                                     variable_3 = symsg-msgv3
                                                     variable_4 = symsg-msgv4 ).

        log_handle->add_item( item ).

        record_entry( VALUE #( symsg   = symsg
                               item    = item
                               message = resolve_message_text( symsg ) ) ).

        mirror_to_emergency_log( symsg = symsg ).

      CATCH cx_bali_runtime INTO DATA(error).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_logging
                                                    previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_cloud_logger~log_syst_add.
    " The system fields are read in exactly one place; an empty SY message is
    " ignored by log_message_add instead of producing a blank entry.
    self = log_message_add( system->current_message( ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_exception_add.
    self = me.
    ensure_active( ).

    IF exception IS NOT BOUND.
      RETURN.
    ENDIF.

    TRY.
        DATA(item) = cl_bali_exception_setter=>create( severity  = severity
                                                       exception = exception ).

        log_handle->add_item( item ).

        record_entry( VALUE #( symsg   = VALUE #( msgty = severity )
                               item    = item
                               message = exception->get_text( ) ) ).

        mirror_to_emergency_log( exception = exception ).

      CATCH cx_bali_runtime INTO DATA(error).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_logging
                                                    previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_cloud_logger~log_bapiret2_structure_add.
    self = me.
    ensure_active( ).

    IF bapiret2 IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(item)  = cl_bali_message_setter=>create_from_bapiret2( bapiret2 ).
        DATA(symsg) = VALUE symsg( msgid = bapiret2-id
                                   msgno = bapiret2-number
                                   msgty = bapiret2-type
                                   msgv1 = bapiret2-message_v1
                                   msgv2 = bapiret2-message_v2
                                   msgv3 = bapiret2-message_v3
                                   msgv4 = bapiret2-message_v4 ).

        log_handle->add_item( item ).

        record_entry( VALUE #( symsg   = symsg
                               item    = item
                               message = resolve_message_text( symsg ) ) ).

        mirror_to_emergency_log( symsg = symsg ).

      CATCH cx_bali_runtime INTO DATA(error).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_logging
                                                    previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_cloud_logger~log_bapiret2_table_add.
    self = me.
    ensure_active( ).

    DATA(severity_filter) = get_severity_filter( min_severity ).

    LOOP AT bapiret2_t REFERENCE INTO DATA(bapiret2) WHERE type IN severity_filter.
      log_bapiret2_structure_add( bapiret2->* ).
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_cloud_logger~log_data_add.
    self = me.
    ensure_active( ).

    TRY.
        log_string_add( string = xco_cp_json=>data->from_abap( data )->to_string( )
                        msgty  = msgty ).

      CATCH cx_root INTO DATA(error).
        " Serialization and logging problems must not break the caller's chain;
        " they are logged as an error entry and, if even that fails, trailed.
        safe_log_string( string      = |{ TEXT-008 } { error->get_text( ) }|
                         msgty       = c_message_type-error
                         caller_name = `log_data_add (fallback emit)` ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_cloud_logger~merge_logs.
    self = me.
    ensure_active( ).

    IF external_log IS NOT BOUND.
      RETURN.
    ENDIF.

    TRY.
        DATA(external_handle) = external_log->get_log_handle( ).

        IF external_handle IS BOUND.
          log_handle->add_all_items_from_other_log( external_handle ).
        ENDIF.

        INSERT LINES OF external_log->get_messages( )        INTO TABLE log_messages.
        INSERT LINES OF external_log->get_internal_errors( ) INTO TABLE internal_errors.

        trim_internal_errors( ).

      CATCH cx_bali_runtime INTO DATA(error).
        record_internal_error( method_name = `merge_logs`
                               exception   = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_cloud_logger~save_application_log.
    self = me.
    ensure_active( ).

    IF db_save = abap_false.
      " Record the no-op in the internal diagnostic trail. We deliberately do NOT
      " write to the user-facing log here: callers may invoke save_application_log
      " in a loop, and a per-call warning would flood log_messages with noise.
      record_internal_error( method_name = `save_application_log`
                             error_text  = CONV #( TEXT-007 ) ).
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
        persistence->save_log( log                        = log_handle
                               use_2nd_db_connection      = use_2nd_db_connection
                               assign_to_current_appl_job = assign_to_current_appl_job ).

      CATCH cx_bali_runtime INTO DATA(error).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_release
                                                    previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_cloud_logger~reset_appl_log.
    ensure_active( ).

    IF delete_from_db = abap_true.
      delete_from_database( ).
    ENDIF.

    TRY.
        DATA(new_handle) = cl_bali_log=>create( ).
        DATA(new_header) = create_header( ).
        new_handle->set_header( new_header ).

      CATCH cx_bali_runtime cx_uuid_error INTO DATA(error).
        record_internal_error( method_name = `reset_appl_log`
                               exception   = error ).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_creation
                                                    previous = error ).
    ENDTRY.

    " Swap only after the new log exists, so a failure above leaves the old log intact
    log_handle = new_handle.
    header     = new_header.
    CLEAR log_messages.
    CLEAR timer_start.
    CLEAR context.
    CLEAR emergency_log.

    recreate_emergency_log( ).
  ENDMETHOD.

  METHOD zif_cloud_logger~free.
    DELETE TABLE logger_instances
           WITH TABLE KEY log_object    = object
                          log_subobject = subobject
                          extnumber     = ext_number.

    released = abap_true.
    CLEAR log_handle.
    CLEAR header.
    CLEAR log_messages.
    CLEAR emergency_log.
    CLEAR timer_start.
    CLEAR context.
    CLEAR internal_errors.
  ENDMETHOD.

  METHOD zif_cloud_logger~get_messages.
    result = log_messages.
  ENDMETHOD.

  METHOD zif_cloud_logger~get_messages_flat.
    result = VALUE #( FOR msg IN log_messages
                      ( render_entry( msg ) ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~get_messages_as_bapiret2.
    result = VALUE #( FOR msg IN log_messages
                      ( id         = msg-symsg-msgid
                        number     = msg-symsg-msgno
                        type       = msg-symsg-msgty
                        message_v1 = msg-symsg-msgv1
                        message_v2 = msg-symsg-msgv2
                        message_v3 = msg-symsg-msgv3
                        message_v4 = msg-symsg-msgv4
                        message    = msg-message ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~get_messages_rap.
    result = VALUE #( FOR msg IN log_messages
                      ( COND #( WHEN msg-symsg-msgid IS NOT INITIAL AND msg-symsg-msgno IS NOT INITIAL
                                THEN zcx_cloud_logger_message=>new_message_from_symsg( msg-symsg )
                                ELSE zcx_cloud_logger_message=>new_message_from_symsg(
                                         text_to_symsg( text  = msg-message
                                                        msgty = msg-symsg-msgty ) ) ) ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~get_handle.
    IF log_handle IS BOUND.
      result = log_handle->get_handle( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_cloud_logger~get_log_handle.
    result = log_handle.
  ENDMETHOD.

  METHOD zif_cloud_logger~get_message_count.
    result = COND #( WHEN msgty IS INITIAL
                     THEN lines( log_messages )
                     ELSE REDUCE int4( INIT count = 0
                                       FOR msg IN log_messages WHERE ( type = msgty )
                                       NEXT count = count + 1 ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_is_empty.
    result = xsdbool( log_messages IS INITIAL ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_contains_messages.
    result = xsdbool( log_messages IS NOT INITIAL ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_contains_error.
    result = xsdbool(
         line_exists( log_messages[ type = c_message_type-error ] )
      OR line_exists( log_messages[ type = c_message_type-abandon ] )
      OR line_exists( log_messages[ type = c_message_type-terminate ] ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_contains_warning.
    result = xsdbool(
         log_contains_error( ) = abap_true
      OR line_exists( log_messages[ type = c_message_type-warning ] ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~search_message.
    IF search IS INITIAL.
      result = xsdbool( log_messages IS NOT INITIAL ).
      RETURN.
    ENDIF.

    " An initial search component is not compared: its range stays empty,
    " and IN <empty range> is true for every line.
    DATA(class_range)  = COND message_class_range(
      WHEN search-msgid IS NOT INITIAL
      THEN VALUE #( ( sign   = c_select_options-sign_include
                      option = c_select_options-option_equal
                      low    = search-msgid ) ) ).
    DATA(number_range) = COND message_number_range(
      WHEN search-msgno IS NOT INITIAL
      THEN VALUE #( ( sign   = c_select_options-sign_include
                      option = c_select_options-option_equal
                      low    = search-msgno ) ) ).
    DATA(type_range)   = COND severity_filter_range(
      WHEN search-msgty IS NOT INITIAL
      THEN VALUE #( ( sign   = c_select_options-sign_include
                      option = c_select_options-option_equal
                      low    = search-msgty ) ) ).

    LOOP AT log_messages TRANSPORTING NO FIELDS
         WHERE symsg-msgid IN class_range
           AND symsg-msgno IN number_range
           AND symsg-msgty IN type_range.
      result = abap_true.
      RETURN.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_cloud_logger~start_timer.
    self = me.
    ensure_active( ).

    IF timer_start IS NOT INITIAL.
      safe_log_string( string      = CONV #( TEXT-006 )
                       msgty       = c_message_type-warning
                       caller_name = `start_timer` ).
    ENDIF.

    timer_start = system->now( ).
  ENDMETHOD.

  METHOD zif_cloud_logger~stop_timer.
    self = me.
    ensure_active( ).

    IF timer_start IS INITIAL.
      safe_log_string( string      = CONV #( TEXT-002 )
                       msgty       = c_message_type-warning
                       caller_name = `stop_timer` ).
      RETURN.
    ENDIF.

    DATA(elapsed_seconds) = seconds_between( started_at = timer_start
                                             stopped_at = system->now( ) ).
    DATA(timer_text)      = |{ TEXT-003 } { text } { TEXT-004 } { elapsed_seconds DECIMALS = 3 } { TEXT-005 }|.

    safe_log_string( string      = timer_text
                     msgty       = c_message_type-information
                     caller_name = `stop_timer (result emit)` ).

    CLEAR timer_start.
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

  METHOD record_entry.
    INSERT VALUE #( BASE entry
                    type      = entry-symsg-msgty
                    context   = context
                    user_name = user_alias
                    date      = system->system_date( )
                    time      = system->system_time( ) ) INTO TABLE log_messages.
  ENDMETHOD.

  METHOD resolve_message_text.
    TRY.
        result = xco_cp=>message( symsg )->get_text( ).

      CATCH cx_root INTO DATA(error).
        " An unknown or malformed message class must never bring the logger down
        " (audit #19). Fall back to the raw components and leave a trace. XCO's
        " exception hierarchy is not narrowed here on purpose - verify in ADT
        " which cx_xco_* class applies before tightening the CATCH.
        result = condense( |{ symsg-msgid } { symsg-msgno } { symsg-msgv1 } { symsg-msgv2 }| &&
                           | { symsg-msgv3 } { symsg-msgv4 }| ).
        record_internal_error( method_name = `resolve_message_text`
                               exception   = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD render_entry.
    DATA(base) = COND string(
      WHEN entry-symsg-msgid IS INITIAL OR entry-symsg-msgno IS INITIAL
      THEN entry-message
      ELSE |{ entry-symsg-msgty }{ entry-symsg-msgno }({ entry-symsg-msgid }) - { entry-message }| ).

    result = COND #( WHEN entry-context IS NOT INITIAL
                     THEN |[{ entry-context }] { base }|
                     ELSE base ).
  ENDMETHOD.

  METHOD apply_context.
    result = COND #( WHEN context IS NOT INITIAL
                     THEN |[{ context }] { text }|
                     ELSE text ).
  ENDMETHOD.

  METHOD text_to_symsg.
    " symsgv holds 50 characters and message 001 concatenates &1&2&3&4, so the text
    " is cut into four fixed slices; anything beyond 200 characters is dropped.
    DATA(buffer) = CONV free_text_buffer( text ).

    result = VALUE #( msgid = zif_cloud_logger=>c_free_text_message-msgid
                      msgno = zif_cloud_logger=>c_free_text_message-msgno
                      msgty = COND #( WHEN msgty IS NOT INITIAL
                                      THEN msgty
                                      ELSE c_message_type-information )
                      msgv1 = buffer(50)
                      msgv2 = buffer+50(50)
                      msgv3 = buffer+100(50)
                      msgv4 = buffer+150(50) ).
  ENDMETHOD.

  METHOD create_emergency_log.
    IF enable_emergency_log = abap_false.
      RETURN.
    ENDIF.

    DATA(emergency_ext_number) = COND cl_bali_header_setter=>ty_external_id(
      WHEN ext_number IS INITIAL
      THEN xco_cp=>uuid( )->as( xco_cp_uuid=>format->c36 )->value
      ELSE ext_number ).

    TRY.
        emergency_log = xco_cp_bal=>for->database( )->log->create( iv_object      = object
                                                                   iv_subobject   = subobject
                                                                   iv_external_id = emergency_ext_number ).

      CATCH cx_root INTO DATA(error).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_emergency_log
                                                    previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD recreate_emergency_log.
    TRY.
        create_emergency_log( ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        record_internal_error( method_name = `reset_appl_log (emergency log recreation)`
                               exception   = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD create_header.
    DATA(effective_expiry) = COND d( WHEN expiry_date IS NOT INITIAL
                                     THEN expiry_date
                                     ELSE system->system_date( ) + zif_cloud_logger=>c_default_expiry_days ).

    TRY.
        result = cl_bali_header_setter=>create( object      = object
                                                subobject   = subobject
                                                external_id = ext_number
                    )->set_expiry( expiry_date       = effective_expiry
                                   keep_until_expiry = abap_true ).

      CATCH cx_bali_runtime cx_uuid_error INTO DATA(error).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid   = zcx_cloud_logger_error=>error_in_creation
                                                    previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD delete_from_database.
    TRY.
        persistence->delete_log( log_handle ).

      CATCH cx_bali_runtime INTO DATA(error).
        " A log that was never saved cannot be deleted - not fatal for a reset
        record_internal_error( method_name = `reset_appl_log (db delete - log not persisted?)`
                               exception   = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD get_severity_filter.
    DATA(kept_types) = SWITCH message_types( msgty
      WHEN c_message_type-abandon OR c_message_type-terminate
        THEN VALUE #( ( c_message_type-abandon ) ( c_message_type-terminate ) )
      WHEN c_message_type-error
        THEN VALUE #( ( c_message_type-error ) ( c_message_type-abandon ) ( c_message_type-terminate ) )
      WHEN c_message_type-warning
        THEN VALUE #( ( c_message_type-warning ) ( c_message_type-error )
                      ( c_message_type-abandon ) ( c_message_type-terminate ) )
      ELSE VALUE #( ) ).

    result = VALUE #( FOR kept_type IN kept_types
                      ( sign   = c_select_options-sign_include
                        option = c_select_options-option_equal
                        low    = kept_type ) ).
  ENDMETHOD.

  METHOD mirror_to_emergency_log.
    IF emergency_log IS NOT BOUND OR enable_emergency_log = abap_false.
      RETURN.
    ENDIF.

    TRY.
        IF exception IS BOUND.
          emergency_log->add_exception( exception ).

        ELSEIF symsg-msgid IS NOT INITIAL.
          emergency_log->add_message( symsg ).

        ELSEIF text IS NOT INITIAL.
          emergency_log->add_text( xco_cp=>string( text ) ).
        ENDIF.

      CATCH cx_root INTO DATA(error).
        " Emergency log is best-effort and must never break the main flow,
        " but a silent failure used to be invisible. Record it in the
        " diagnostic trail so an "all mirrors failed" situation is surfaced.
        record_internal_error( method_name = `mirror_to_emergency_log`
                               exception   = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD record_internal_error.
    INSERT VALUE #( timestamp  = system->now( )
                    method     = method_name
                    error_text = COND #( WHEN exception IS BOUND
                                         THEN exception->get_text( )
                                         ELSE error_text ) ) INTO TABLE internal_errors.

    trim_internal_errors( ).
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

  METHOD trim_internal_errors.
    IF lines( internal_errors ) > trim_limit.
      DELETE internal_errors FROM 1 TO ( lines( internal_errors ) - trim_limit ).
    ENDIF.
  ENDMETHOD.

  METHOD seconds_between.
    " Both stamps are UTC by definition (GET TIME STAMP), so the packed digits
    " YYYYMMDDhhmmss.fffffff are split numerically and the parts are subtracted
    " with plain date/time arithmetic. cl_abap_tstmp=>subtract is not used: it
    " rejected these long stamps with cx_parameter_invalid_* during the 2.0.0
    " verification on S/4HANA 2023.
    DATA(started_whole) = CONV int8( trunc( started_at ) ).
    DATA(stopped_whole) = CONV int8( trunc( stopped_at ) ).

    DATA(started_date) = CONV d( |{ started_whole DIV time_part_divisor }| ).
    DATA(stopped_date) = CONV d( |{ stopped_whole DIV time_part_divisor }| ).
    DATA(started_time) = CONV t( |{ started_whole MOD time_part_divisor WIDTH = 6 PAD = '0' ALIGN = RIGHT }| ).
    DATA(stopped_time) = CONV t( |{ stopped_whole MOD time_part_divisor WIDTH = 6 PAD = '0' ALIGN = RIGHT }| ).

    result = ( stopped_date - started_date ) * seconds_per_day
           + ( stopped_time - started_time )
           + ( frac( stopped_at ) - frac( started_at ) ).
  ENDMETHOD.

ENDCLASS.


