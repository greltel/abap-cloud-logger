"! <p class="shorttext synchronized" lang="en">Cloud Logger Main</p>
"! Multiton implementation of {@link zif_cloud_logger} on top of
"! {@link cl_bali_log}. Instances are shared per object / subobject /
"! external id and obtained through {@link zcl_cloud_logger.METH:get_instance}.
"! Environment and database access go through {@link zif_cloud_logger_system}
"! and {@link zif_cloud_logger_persistence}, so the class is unit-testable
"! without a clock or a database. Severities, free text, exception keys and
"! searches are handled by {@link zcl_cloud_logger_conversion}, which the test
"! double {@link zcl_cloud_logger_fake} uses as well.
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
    "! @parameter enable_emergency_log   | abap_true mirrors every entry into a second, immediately
    "!                                     persisted log via XCO BAL (best-effort, one commit on a
    "!                                     second connection per entry, see README)
    "! @parameter object                 | Application Log object (BAL); always required - the
    "!                                     Application Log accepts no header without it
    "! @parameter subobject              | Application Log subobject
    "! @parameter ext_number             | External ID; also part of the multiton key
    "! @parameter db_save                | abap_true persists on save_application_log; abap_false makes save a no-op
    "! @parameter expiry_date            | Log expiry date (default = today + c_default_expiry_days)
    "! @parameter trim_limit             | Max trail entries, FIFO (default 100; 0 = no trail; negative raises,
    "!                                     also when the key is already in use)
    "! @parameter result                 | Shared logger for the object / subobject / ext_number key
    "! @raising   zcx_cloud_logger_error | Invalid value, config conflict with an existing instance,
    "!                                     or creation failure
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

    "! <p class="shorttext synchronized" lang="en">Attach to a persisted Application Log</p>
    "!
    "! <p>Loads the log with the given handle from the database and returns a logger
    "! that continues writing to it: the persisted items become internal log
    "! entries (their <em>item</em> and <em>context</em> stay initial, date and
    "! time are UTC, as the Application Log stores them), further
    "! <em>log_*</em> calls append, <em>save_application_log( )</em> updates the
    "! same log. A log that was saved without entries loads empty. The instance is
    "! registered under the log's own object / subobject / external id, so
    "! <em>get_instance( )</em> with that key returns it. Loaded loggers always
    "! persist (db_save) and never mirror to an emergency log. Reading needs the
    "! display authorization for the log object (S_APPL_LOG, activity 03).</p>
    "!
    "! @parameter handle                 | Application Log handle (BALLOGHNDL) of a saved log
    "! @parameter trim_limit             | Max trail entries, FIFO (default 100; 0 = no trail; negative raises)
    "! @parameter result                 | Logger attached to the persisted log
    "! @raising   zcx_cloud_logger_error | Negative trim_limit (invalid_trim_limit), no log with this
    "!                                     handle (error_in_loading), or a logger with the same handle
    "!                                     or key is active (already_active)
    CLASS-METHODS load
      IMPORTING handle        TYPE balloghndl
                trim_limit    TYPE i DEFAULT zif_cloud_logger=>c_default_trim_limit
      RETURNING VALUE(result) TYPE REF TO zif_cloud_logger
      RAISING   zcx_cloud_logger_error.

    "! <p class="shorttext synchronized" lang="en">Initialize a logger instance</p>
    "!
    "! <p>Public so that CREATE PRIVATE governs instantiation instead of the
    "! constructor's visibility (Clean ABAP). Mirrors get_instance and shares its
    "! documented rule #2366 deviation. The two collaborators are optional with
    "! production defaults: the multiton factory stays unchanged while tests
    "! (local friends) inject doubles.</p>
    "!
    "! @parameter enable_emergency_log   | abap_true mirrors entries via the persistence's emergency log
    "! @parameter object                 | Application Log object (BAL); always required - the
    "!                                     Application Log accepts no header without it
    "! @parameter subobject              | Application Log subobject
    "! @parameter ext_number             | External ID for the log
    "! @parameter db_save                | abap_true persists on save_application_log
    "! @parameter expiry_date            | Log expiry date (default = today + c_default_expiry_days)
    "! @parameter trim_limit             | Max internal-error trail entries (FIFO)
    "! @parameter system                 | Environment access; defaults to {@link zcl_cloud_logger_system}
    "! @parameter persistence            | Database access; defaults to {@link zcl_cloud_logger_persistence}
    "! @parameter loaded_log             | A log read back from the database: the instance attaches to
    "!                                     it instead of creating a new Application Log (see load)
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
                loaded_log           TYPE zif_cloud_logger_persistence=>loaded_log OPTIONAL
      RAISING   zcx_cloud_logger_error.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF severity_count,
        type    TYPE symsgty,
        entries TYPE i,
      END OF severity_count.
    TYPES severity_counts TYPE HASHED TABLE OF severity_count WITH UNIQUE KEY type.

    CONSTANTS seconds_per_day   TYPE i VALUE 86400.
    " YYYYMMDDhhmmss DIV / MOD this value separates the date from the time part
    CONSTANTS time_part_divisor TYPE i VALUE 1000000.

    CLASS-DATA logger_instances TYPE logger_instances_type.

    DATA trim_limit           TYPE i.
    DATA user_name            TYPE syuname.
    DATA log_handle           TYPE REF TO if_bali_log.
    DATA log_messages         TYPE log_messages_type.
    " Entries per severity, kept in step with log_messages so the queries need no scan
    DATA counts               TYPE severity_counts.
    DATA internal_errors      TYPE zif_cloud_logger=>internal_errors.
    DATA db_save              TYPE abap_boolean.
    DATA object               TYPE cl_bali_header_setter=>ty_object.
    DATA subobject            TYPE cl_bali_header_setter=>ty_subobject.
    DATA ext_number           TYPE cl_bali_header_setter=>ty_external_id.
    DATA expiry_date          TYPE xsddate_d.
    DATA enable_emergency_log TYPE abap_boolean.
    " abap_true while the persistence holds an emergency log for the current main log
    DATA emergency_log_open   TYPE abap_boolean.
    DATA timer_start          TYPE timestampl.
    DATA context              TYPE string.
    DATA system               TYPE REF TO zif_cloud_logger_system.
    DATA persistence          TYPE REF TO zif_cloud_logger_persistence.
    DATA released             TYPE abap_boolean.
    DATA effective_expiry     TYPE d.

    " load( ) with the database access handed in, so tests can load without a database
    CLASS-METHODS load_from
      IMPORTING handle        TYPE balloghndl
                trim_limit    TYPE i
                persistence   TYPE REF TO zif_cloud_logger_persistence
      RETURNING VALUE(result) TYPE REF TO zif_cloud_logger
      RAISING   zcx_cloud_logger_error.

    " Enters an instance into the multiton registry with its effective configuration
    CLASS-METHODS register
      IMPORTING logger TYPE REF TO zcl_cloud_logger.

    " Guards every writing method: a released instance is a caller bug, not a silent no-op
    METHODS ensure_active
      RAISING zcx_cloud_logger_error.

    " Expiry of a log created now: the configured date, else today plus the default retention
    METHODS default_expiry
      RETURNING VALUE(result) TYPE d.

    " A new, empty Application Log with the header of this logger
    METHODS create_log
      IMPORTING expiry        TYPE d
      RETURNING VALUE(result) TYPE REF TO if_bali_log
      RAISING   zcx_cloud_logger_error.

    " Adds a prepared entry to the internal log, stamping context, user, date and time
    METHODS record_entry
      IMPORTING entry TYPE zif_cloud_logger=>t_log_messages.

    METHODS count_entry
      IMPORTING !type TYPE symsgty.

    METHODS count_entries
      IMPORTING entries TYPE zif_cloud_logger=>log_messages.

    METHODS count_of
      IMPORTING !type         TYPE symsgty
      RETURNING VALUE(result) TYPE i.

    " Resolves the T100 text; never raises. A message that cannot be resolved
    " falls back to the given text, else to the raw message components
    METHODS resolve_message_text
      IMPORTING symsg         TYPE symsg
                fallback      TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE string.

    " Renders one entry as "[context] TNNN(CLASS) - text" (or the plain text)
    METHODS render_entry
      IMPORTING entry         TYPE zif_cloud_logger=>t_log_messages
      RETURNING VALUE(result) TYPE flat_message.

    " Prefixes the sticky context, if any
    METHODS apply_context
      IMPORTING !text         TYPE string
      RETURNING VALUE(result) TYPE string.

    " Opens the emergency log for the current main log, if one was asked for
    METHODS open_emergency_log
      RAISING zcx_cloud_logger_error.

    " After a reset the emergency log is opened again; a failure is only trailed
    METHODS reopen_emergency_log.

    " Best-effort mirrors to the emergency log; failures go to the internal error trail
    METHODS mirror_message
      IMPORTING symsg TYPE symsg.

    METHODS mirror_exception
      IMPORTING !exception TYPE REF TO cx_root
                severity   TYPE symsgty.

    METHODS delete_from_database.

    " Removes a log from Application Log memory - dropping the reference frees nothing
    CLASS-METHODS release_from_memory
      IMPORTING !log TYPE REF TO if_bali_log.

    " Keeps the registry in step with the expiry of the log created by a reset
    METHODS update_registered_expiry.

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

    " Date and time part of a UTC packed time stamp
    METHODS stamp_date
      IMPORTING stamp         TYPE timestampl
      RETURNING VALUE(result) TYPE d.

    METHODS stamp_time
      IMPORTING stamp         TYPE timestampl
      RETURNING VALUE(result) TYPE t.

ENDCLASS.


CLASS zcl_cloud_logger IMPLEMENTATION.

  METHOD get_instance.
    " An invalid value is reported as such, whether or not the key is already in use
    IF trim_limit < 0.
      RAISE EXCEPTION NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>invalid_trim_limit
                                                  log_object = object ).
    ENDIF.

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
          RAISE EXCEPTION NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>config_mismatch
                                                      log_object = object ).
        ENDIF.

        result = instance-logger.
        RETURN.

      CATCH cx_sy_itab_line_not_found.
        " no existing instance - fall through to creation
    ENDTRY.

    DATA(logger) = NEW zcl_cloud_logger( object               = object
                                         subobject            = subobject
                                         ext_number           = ext_number
                                         db_save              = db_save
                                         enable_emergency_log = enable_emergency_log
                                         expiry_date          = expiry_date
                                         trim_limit           = trim_limit ).

    register( logger ).
    result = logger.
  ENDMETHOD.

  METHOD constructor.
    DATA effective_system TYPE REF TO zif_cloud_logger_system.

    " The Application Log refuses a header without object, also for a log that is
    " never saved; reported here by name instead of as a creation failure
    IF object IS INITIAL.
      RAISE EXCEPTION NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>object_required
                                                  log_object = object ).
    ENDIF.

    IF trim_limit < 0.
      RAISE EXCEPTION NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>invalid_trim_limit
                                                  log_object = object ).
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
    user_name                = effective_system->user_name( ).

    IF loaded_log-log IS BOUND.
      " Attach: the persisted log is the log, its items are the history
      log_handle       = loaded_log-log.
      log_messages     = loaded_log-entries.
      effective_expiry = loaded_log-expiry_date.
      count_entries( log_messages ).
      RETURN.
    ENDIF.

    DATA(expiry) = default_expiry( ).

    log_handle       = create_log( expiry ).
    effective_expiry = expiry.

    open_emergency_log( ).
  ENDMETHOD.

  METHOD load.
    result = load_from( handle      = handle
                        trim_limit  = trim_limit
                        persistence = NEW zcl_cloud_logger_persistence( ) ).
  ENDMETHOD.

  METHOD load_from.
    " Checked before the database is read: an invalid value needs no round trip
    IF trim_limit < 0.
      RAISE EXCEPTION NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>invalid_trim_limit
                                                  log_handle = handle ).
    ENDIF.

    " A log that is still held by a live logger cannot be loaded a second time -
    " the Application Log itself refuses it - so the session check comes first,
    " by handle, to report the real reason instead of a generic load failure.
    LOOP AT logger_instances REFERENCE INTO DATA(active).
      IF active->logger->get_handle( ) = handle.
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>already_active
                                                    log_object = active->log_object
                                                    log_handle = handle ).
      ENDIF.
    ENDLOOP.

    TRY.
        DATA(loaded) = persistence->load_log( handle ).

      CATCH cx_bali_runtime INTO DATA(error).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>error_in_loading
                                                    previous   = error
                                                    log_handle = handle ).
    ENDTRY.

    IF line_exists( logger_instances[ log_object    = loaded-object
                                      log_subobject = loaded-subobject
                                      extnumber     = loaded-external_id ] ).
      " The log is in memory by now and nobody will own it: give it back
      release_from_memory( loaded-log ).

      RAISE EXCEPTION NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>already_active
                                                  log_object = loaded-object
                                                  log_handle = handle ).
    ENDIF.

    DATA(logger) = NEW zcl_cloud_logger( object      = loaded-object
                                         subobject   = loaded-subobject
                                         ext_number  = loaded-external_id
                                         db_save     = abap_true
                                         expiry_date = loaded-expiry_date
                                         trim_limit  = trim_limit
                                         persistence = persistence
                                         loaded_log  = loaded ).

    register( logger ).
    result = logger.
  ENDMETHOD.

  METHOD register.
    " The registry keeps the effective expiry, so a later caller who spells out
    " the default explicitly is not reported as a configuration conflict
    INSERT VALUE #( log_object           = logger->object
                    log_subobject        = logger->subobject
                    extnumber            = logger->ext_number
                    db_save              = logger->db_save
                    enable_emergency_log = logger->enable_emergency_log
                    expiry_date          = logger->effective_expiry
                    trim_limit           = logger->trim_limit
                    logger               = logger ) INTO TABLE logger_instances.
  ENDMETHOD.

  METHOD zif_cloud_logger~log_string_add.
    self = me.
    ensure_active( ).

    DATA(severity) = zcl_cloud_logger_conversion=>normalized_severity(
                         msgty    = msgty
                         fallback = c_default_message_attributes-type ).

    TRY.
        DATA(item) = cl_bali_free_text_setter=>create( severity = severity
                                                       text     = CONV #( apply_context( string ) ) ).

        log_handle->add_item( item ).

        record_entry( VALUE #( symsg   = VALUE #( msgty = severity )
                               item    = item
                               message = string ) ).

        " Mirrored as the carrier message, not as free text: XCO's add_text has no
        " severity, and an emergency log where errors show as green is useless.
        mirror_message( zcl_cloud_logger_conversion=>text_to_symsg( text  = string
                                                                    msgty = severity ) ).

      CATCH cx_bali_runtime INTO DATA(error).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>error_in_logging
                                                    previous   = error
                                                    log_object = object ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_cloud_logger~log_message_add.
    self = me.
    ensure_active( ).

    IF symsg IS INITIAL.
      RETURN.
    ENDIF.

    " A message without a valid severity would be invisible to every log_contains_* query
    DATA(message) = VALUE symsg( BASE symsg
                                 msgty = zcl_cloud_logger_conversion=>normalized_severity(
                                             msgty    = symsg-msgty
                                             fallback = c_default_message_attributes-type ) ).

    TRY.
        DATA(item) = cl_bali_message_setter=>create( severity   = message-msgty
                                                     id         = message-msgid
                                                     number     = message-msgno
                                                     variable_1 = message-msgv1
                                                     variable_2 = message-msgv2
                                                     variable_3 = message-msgv3
                                                     variable_4 = message-msgv4 ).

        log_handle->add_item( item ).

        record_entry( VALUE #( symsg   = message
                               item    = item
                               message = resolve_message_text( message ) ) ).

        mirror_message( message ).

      CATCH cx_bali_runtime INTO DATA(error).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>error_in_logging
                                                    previous   = error
                                                    log_object = object ).
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

    DATA(entry_severity) = zcl_cloud_logger_conversion=>normalized_severity( msgty    = severity
                                                                             fallback = c_message_type-error ).

    TRY.
        DATA(item) = cl_bali_exception_setter=>create( severity  = entry_severity
                                                       exception = exception ).

        log_handle->add_item( item ).

        " Keep the T100 key so that search, RAP and BAPIRET2 conversions see the
        " real message instead of free text; the resolved text comes from the
        " exception itself.
        record_entry( VALUE #( symsg   = zcl_cloud_logger_conversion=>symsg_from_exception(
                                             exception = exception
                                             severity  = entry_severity )
                               item    = item
                               message = exception->get_text( ) ) ).

        mirror_exception( exception = exception
                          severity  = entry_severity ).

      CATCH cx_bali_runtime INTO DATA(error).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>error_in_logging
                                                    previous   = error
                                                    log_object = object ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_cloud_logger~log_bapiret2_structure_add.
    self = me.
    ensure_active( ).

    " BAPIs leave the type of a success message blank now and then
    DATA(row) = VALUE bapiret2( BASE bapiret2
                                type = zcl_cloud_logger_conversion=>normalized_severity(
                                           msgty    = bapiret2-type
                                           fallback = c_message_type-success ) ).

    IF row-id IS INITIAL.
      " No message class, no T100 message: the text of the BAPI is all there is.
      " A row without class and without text says nothing and is ignored.
      IF row-message IS NOT INITIAL.
        log_string_add( string = CONV #( row-message )
                        msgty  = row-type ).
      ENDIF.
      RETURN.
    ENDIF.

    TRY.
        DATA(item)  = cl_bali_message_setter=>create_from_bapiret2( row ).
        DATA(symsg) = VALUE symsg( msgid = row-id
                                   msgno = row-number
                                   msgty = row-type
                                   msgv1 = row-message_v1
                                   msgv2 = row-message_v2
                                   msgv3 = row-message_v3
                                   msgv4 = row-message_v4 ).

        log_handle->add_item( item ).

        record_entry( VALUE #( symsg   = symsg
                               item    = item
                               message = resolve_message_text( symsg    = symsg
                                                               fallback = CONV #( row-message ) ) ) ).

        mirror_message( symsg ).

      CATCH cx_bali_runtime INTO DATA(error).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>error_in_logging
                                                    previous   = error
                                                    log_object = object ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_cloud_logger~log_bapiret2_table_add.
    DATA first_error TYPE REF TO zcx_cloud_logger_error.

    self = me.
    ensure_active( ).

    LOOP AT bapiret2_t REFERENCE INTO DATA(row).
      DATA(severity) = zcl_cloud_logger_conversion=>normalized_severity( msgty    = row->type
                                                                         fallback = c_message_type-success ).

      IF zcl_cloud_logger_conversion=>reaches_severity( severity = severity
                                                        minimum  = min_severity ) = abap_true.
        TRY.
            log_bapiret2_structure_add( row->* ).

          CATCH zcx_cloud_logger_error INTO DATA(error).
            " One rejected row must not cost the caller the rows behind it
            IF first_error IS NOT BOUND.
              first_error = error.
            ENDIF.
        ENDTRY.
      ENDIF.
    ENDLOOP.

    IF first_error IS BOUND.
      RAISE EXCEPTION first_error.
    ENDIF.
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
        safe_log_string( string      = |{ 'Error serializing data to JSON:'(008) } { error->get_text( ) }|
                         msgty       = c_message_type-error
                         caller_name = `log_data_add (fallback emit)` ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_cloud_logger~merge_logs.
    self = me.
    ensure_active( ).

    IF external_log IS NOT BOUND OR external_log = me.
      RETURN.
    ENDIF.

    TRY.
        DATA(external_handle) = external_log->get_log_handle( ).

        IF external_handle IS BOUND.
          log_handle->add_all_items_from_other_log( external_handle ).
        ENDIF.

        DATA(merged) = external_log->get_messages( ).

        INSERT LINES OF merged                               INTO TABLE log_messages.
        INSERT LINES OF external_log->get_internal_errors( ) INTO TABLE internal_errors.
        count_entries( merged ).

        " Keep the merged trail chronological so trimming evicts the oldest entries;
        " STABLE, because entries of the same instant must keep their order
        SORT internal_errors STABLE BY timestamp.
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
                             error_text  = CONV #( 'db_save is disabled - no-op'(007) ) ).
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
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>error_release
                                                    previous   = error
                                                    log_object = object ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_cloud_logger~reset_appl_log.
    ensure_active( ).

    DATA(new_expiry) = default_expiry( ).

    TRY.
        DATA(new_log) = create_log( new_expiry ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        record_internal_error( method_name = `reset_appl_log`
                               exception   = error->previous ).
        RAISE EXCEPTION error.
    ENDTRY.

    " The persisted log goes only now that its successor exists: a failure above
    " leaves the old log intact, in memory and on the database
    IF delete_from_db = abap_true.
      delete_from_database( ).
    ENDIF.

    " After the delete: the Application Log refuses to delete a released log
    release_from_memory( log_handle ).

    log_handle       = new_log.
    effective_expiry = new_expiry.
    CLEAR log_messages.
    CLEAR counts.
    CLEAR timer_start.
    CLEAR context.
    CLEAR emergency_log_open.

    update_registered_expiry( ).
    reopen_emergency_log( ).
  ENDMETHOD.

  METHOD zif_cloud_logger~free.
    " Only the instance that owns the registry entry may drop it. A second free( )
    " on a stale reference must not orphan the instance created in the meantime.
    DATA(registered) = VALUE #( logger_instances[ log_object    = object
                                                  log_subobject = subobject
                                                  extnumber     = ext_number ]-logger OPTIONAL ).
    IF registered = me.
      DELETE logger_instances WHERE log_object    = object
                                AND log_subobject = subobject
                                AND extnumber     = ext_number.
    ENDIF.

    released = abap_true.
    release_from_memory( log_handle ).
    CLEAR log_handle.
    CLEAR log_messages.
    CLEAR counts.
    CLEAR emergency_log_open.
    CLEAR timer_start.
    CLEAR context.
    CLEAR internal_errors.
    " Last: the adapter holds the emergency log, and every method that uses it
    " is behind ensure_active( )
    CLEAR persistence.
  ENDMETHOD.

  METHOD zif_cloud_logger~get_messages.
    result = zcl_cloud_logger_conversion=>entries_reaching( entries = log_messages
                                                            minimum = min_severity ).
  ENDMETHOD.

  METHOD zif_cloud_logger~get_messages_flat.
    result = VALUE #( FOR msg IN zif_cloud_logger~get_messages( min_severity )
                      ( render_entry( msg ) ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~get_messages_as_bapiret2.
    result = VALUE #( FOR msg IN zif_cloud_logger~get_messages( min_severity )
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
    result = VALUE #( FOR msg IN zif_cloud_logger~get_messages( min_severity )
                      ( COND #( WHEN msg-symsg-msgid IS NOT INITIAL
                                THEN zcx_cloud_logger_message=>new_message_from_symsg( msg-symsg )
                                ELSE zcx_cloud_logger_message=>new_message_from_symsg(
                                         zcl_cloud_logger_conversion=>text_to_symsg(
                                             text  = msg-message
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
                     ELSE count_of( to_upper( msgty ) ) ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_is_empty.
    result = xsdbool( log_messages IS INITIAL ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_contains_messages.
    result = xsdbool( log_messages IS NOT INITIAL ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_contains_error.
    DATA(errors) = count_of( c_message_type-error )
                 + count_of( c_message_type-abandon )
                 + count_of( c_message_type-terminate ).

    result = xsdbool( errors > 0 ).
  ENDMETHOD.

  METHOD zif_cloud_logger~log_contains_warning.
    result = xsdbool( log_contains_error( ) = abap_true OR count_of( c_message_type-warning ) > 0 ).
  ENDMETHOD.

  METHOD zif_cloud_logger~search_message.
    LOOP AT log_messages REFERENCE INTO DATA(entry).
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

    IF timer_start IS NOT INITIAL.
      safe_log_string( string      = CONV #( 'start_timer called twice without stop_timer - previous timer reset'(006) )
                       msgty       = c_message_type-warning
                       caller_name = `start_timer` ).
    ENDIF.

    timer_start = system->now( ).
  ENDMETHOD.

  METHOD zif_cloud_logger~stop_timer.
    self = me.
    ensure_active( ).

    IF timer_start IS INITIAL.
      safe_log_string( string      = CONV #( 'Timer stopped but never started.'(002) )
                       msgty       = c_message_type-warning
                       caller_name = `stop_timer` ).
      RETURN.
    ENDIF.

    DATA(elapsed_seconds) = seconds_between( started_at = timer_start
                                             stopped_at = system->now( ) ).
    DATA(timer_text)      = |{ 'Timer Result:'(003) } { text } { 'took'(004) } | &&
                            |{ elapsed_seconds DECIMALS = 3 } { 'seconds.'(005) }|.

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
      RAISE EXCEPTION NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>instance_released
                                                  log_object = object ).
    ENDIF.
  ENDMETHOD.

  METHOD default_expiry.
    result = COND #( WHEN expiry_date IS NOT INITIAL
                     THEN expiry_date
                     ELSE system->system_date( ) + zif_cloud_logger=>c_default_expiry_days ).
  ENDMETHOD.

  METHOD create_log.
    TRY.
        result = cl_bali_log=>create( ).
        result->set_header( cl_bali_header_setter=>create( object      = object
                                                           subobject   = subobject
                                                           external_id = ext_number
                              )->set_expiry( expiry_date       = expiry
                                             keep_until_expiry = abap_true ) ).

      CATCH cx_bali_runtime cx_uuid_error INTO DATA(error).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>error_in_creation
                                                    previous   = error
                                                    log_object = object ).
    ENDTRY.
  ENDMETHOD.

  METHOD record_entry.
    " System date and time, read as one moment: they cannot disagree around midnight
    DATA(moment) = system->system_moment( ).

    INSERT VALUE #( BASE entry
                    type      = entry-symsg-msgty
                    context   = context
                    user_name = user_name
                    date      = moment-date
                    time      = moment-time ) INTO TABLE log_messages.

    count_entry( entry-symsg-msgty ).
  ENDMETHOD.

  METHOD count_entry.
    IF line_exists( counts[ type = type ] ).
      counts[ type = type ]-entries += 1.
    ELSE.
      INSERT VALUE #( type    = type
                      entries = 1 ) INTO TABLE counts.
    ENDIF.
  ENDMETHOD.

  METHOD count_entries.
    LOOP AT entries REFERENCE INTO DATA(entry).
      count_entry( entry->type ).
    ENDLOOP.
  ENDMETHOD.

  METHOD count_of.
    result = VALUE #( counts[ type = type ]-entries OPTIONAL ).
  ENDMETHOD.

  METHOD resolve_message_text.
    TRY.
        DATA(resolved) = xco_cp=>message( symsg )->get_text( ).

      CATCH cx_root INTO DATA(error).
        " An unknown or malformed message class must never bring the logger down
        " (audit #19). XCO's exception hierarchy is not narrowed here on purpose -
        " verify in ADT which cx_xco_* class applies before tightening the CATCH.
        record_internal_error( method_name = `resolve_message_text`
                               exception   = error ).
    ENDTRY.

    result = zcl_cloud_logger_conversion=>text_or_fallback( symsg    = symsg
                                                            resolved = resolved
                                                            fallback = fallback ).
  ENDMETHOD.

  METHOD render_entry.
    DATA(base) = COND string(
      WHEN entry-symsg-msgid IS INITIAL
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

  METHOD open_emergency_log.
    IF enable_emergency_log = abap_false.
      RETURN.
    ENDIF.

    " Without external id the handle of the main log ties the two logs together
    TRY.
        persistence->open_emergency_log(
            object      = object
            subobject   = subobject
            external_id = COND #( WHEN ext_number IS NOT INITIAL
                                  THEN ext_number
                                  ELSE log_handle->get_handle( ) ) ).
        emergency_log_open = abap_true.

      CATCH cx_root INTO DATA(error).
        RAISE EXCEPTION NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>error_in_emergency_log
                                                    previous   = error
                                                    log_object = object ).
    ENDTRY.
  ENDMETHOD.

  METHOD reopen_emergency_log.
    " At creation a failing emergency log raises (an explicit request that cannot
    " be honoured); during a reset it is only trailed so the main log survives.
    TRY.
        open_emergency_log( ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        record_internal_error( method_name = `reset_appl_log (emergency log recreation)`
                               exception   = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD mirror_message.
    IF emergency_log_open = abap_false.
      RETURN.
    ENDIF.

    TRY.
        persistence->mirror_message( symsg ).

      CATCH cx_root INTO DATA(error).
        " The emergency log is best-effort and must never break the main flow;
        " the trail makes an "all mirrors failed" situation visible.
        record_internal_error( method_name = `mirror_to_emergency_log`
                               exception   = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD mirror_exception.
    IF emergency_log_open = abap_false.
      RETURN.
    ENDIF.

    TRY.
        persistence->mirror_exception( exception = exception
                                       severity  = severity ).

      CATCH cx_root INTO DATA(error).
        record_internal_error( method_name = `mirror_to_emergency_log`
                               exception   = error ).
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

  METHOD release_from_memory.
    IF log IS BOUND.
      log->release_memory( ).
    ENDIF.
  ENDMETHOD.

  METHOD update_registered_expiry.
    " Like free( ): only the instance that owns the registry entry touches it
    DATA(registered) = VALUE #( logger_instances[ log_object    = object
                                                  log_subobject = subobject
                                                  extnumber     = ext_number ]-logger OPTIONAL ).
    IF registered = me.
      logger_instances[ log_object    = object
                        log_subobject = subobject
                        extnumber     = ext_number ]-expiry_date = effective_expiry.
    ENDIF.
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
    result = ( stamp_date( stopped_at ) - stamp_date( started_at ) ) * seconds_per_day
           + ( stamp_time( stopped_at ) - stamp_time( started_at ) )
           + ( frac( stopped_at ) - frac( started_at ) ).
  ENDMETHOD.

  METHOD stamp_date.
    result = |{ CONV int8( trunc( stamp ) ) DIV time_part_divisor }|.
  ENDMETHOD.

  METHOD stamp_time.
    result = |{ CONV int8( trunc( stamp ) ) MOD time_part_divisor WIDTH = 6 PAD = '0' ALIGN = RIGHT }|.
  ENDMETHOD.

ENDCLASS.
