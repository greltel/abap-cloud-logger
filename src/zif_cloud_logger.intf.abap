"! <p class="shorttext synchronized" lang="en">ABAP Cloud Logger</p>
"! Fluent, Clean-Core-compliant logger on top of the Application Log
"! ({@link cl_bali_log}). Obtain an instance via
"! {@link zcl_cloud_logger.METH:get_instance}; every <em>log_*</em> method
"! returns the logger itself so calls can be chained.
"! After {@link zif_cloud_logger.METH:free} an instance is dead: every writing method raises
"! {@link zcx_cloud_logger_error} with textid <em>instance_released</em>,
"! queries return empty results.
INTERFACE zif_cloud_logger
  PUBLIC.

  "! Library version (semantic versioning).
  CONSTANTS c_version TYPE string VALUE `2.2.0`.

  "! Table of BAPI return structures.
  TYPES bapiret2_messages TYPE STANDARD TABLE OF bapiret2 WITH EMPTY KEY.
  "! Table of RAP behavior messages, ready for the <em>reported</em> response.
  TYPES rap_messages      TYPE STANDARD TABLE OF REF TO if_abap_behv_message WITH EMPTY KEY.
  "! One rendered message line, e.g. <em>[context] E001(ZMSG) - text</em>.
  TYPES flat_message      TYPE string.
  "! Table of rendered message lines.
  TYPES flat_messages     TYPE STANDARD TABLE OF flat_message WITH EMPTY KEY.

  TYPES:
    "! One entry of the internal (in-memory) log.
    BEGIN OF t_log_messages,
      "! Message key and variables; only msgty is filled for free text and exceptions
      symsg     TYPE symsg,
      "! Resolved message text, never truncated
      message   TYPE string,
      "! Severity (I, S, W, E, A, X)
      type      TYPE symsgty,
      "! Sticky context active when the entry was added (see {@link zif_cloud_logger.METH:set_context})
      context   TYPE string,
      "! User that added the entry (alias when maintained, technical name otherwise)
      user_name TYPE syuname,
      "! System date when the entry was added
      date      TYPE xsddate_d,
      "! System time when the entry was added
      time      TYPE xsdtime_t,
      "! The Application Log item that was written for this entry
      item      TYPE REF TO if_bali_item_setter,
    END OF t_log_messages.
  "! Internal log, in insertion order.
  TYPES log_messages TYPE STANDARD TABLE OF t_log_messages WITH EMPTY KEY.

  TYPES:
    "! One entry of the internal error trail (problems the logger swallowed on purpose).
    BEGIN OF t_internal_error,
      "! When the problem occurred
      timestamp  TYPE timestampl,
      "! Logger method that recorded the problem
      method     TYPE string,
      "! Text of the swallowed exception or a diagnostic note
      error_text TYPE string,
    END OF t_internal_error.
  "! Internal error trail, oldest first, capped at the configured trim limit.
  TYPES internal_errors TYPE STANDARD TABLE OF t_internal_error WITH EMPTY KEY.

  TYPES:
    "! Registry entry of the multiton: configuration plus the shared instance.
    BEGIN OF t_logger_instance,
      log_object           TYPE cl_bali_header_setter=>ty_object,
      log_subobject        TYPE cl_bali_header_setter=>ty_subobject,
      extnumber            TYPE cl_bali_header_setter=>ty_external_id,
      db_save              TYPE abap_boolean,
      enable_emergency_log TYPE abap_boolean,
      expiry_date          TYPE xsddate_d,
      trim_limit           TYPE i,
      logger               TYPE REF TO zif_cloud_logger,
    END OF t_logger_instance.
  "! Multiton registry keyed by object / subobject / external id.
  TYPES logger_instances TYPE HASHED TABLE OF t_logger_instance
                              WITH UNIQUE KEY log_object log_subobject extnumber.

  "! Default cap of the internal error trail (entries, FIFO eviction).
  CONSTANTS c_default_trim_limit TYPE i VALUE 100.

  "! Default retention of a persisted log in days when no expiry date is given.
  CONSTANTS c_default_expiry_days TYPE i VALUE 5.

  CONSTANTS:
    "! Message severities.
    BEGIN OF c_message_type,
      information TYPE symsgty VALUE 'I',
      error       TYPE symsgty VALUE 'E',
      success     TYPE symsgty VALUE 'S',
      warning     TYPE symsgty VALUE 'W',
      abandon     TYPE symsgty VALUE 'A',
      terminate   TYPE symsgty VALUE 'X',
    END OF c_message_type.

  CONSTANTS:
    "! Defaults applied when a caller does not specify a severity or message key.
    "! type is a literal on purpose: the off-stack transpiler does not resolve a
    "! constant whose VALUE refers to another constant.
    BEGIN OF c_default_message_attributes,
      type TYPE symsgty VALUE 'W',
      id   TYPE symsgid VALUE 'CL',
      no   TYPE symsgno VALUE '000',
    END OF c_default_message_attributes.

  CONSTANTS:
    "! Message used to carry free text through a T100 key (&amp;1&amp;2&amp;3&amp;4),
    "! e.g. when free-text entries are converted for RAP.
    BEGIN OF c_free_text_message,
      msgid TYPE symsgid VALUE 'Z_CLOUD_LOGGER',
      msgno TYPE symsgno VALUE '001',
    END OF c_free_text_message.

  CONSTANTS:
    "! Range sign / option values used when building selection ranges.
    BEGIN OF c_select_options,
      option_between              TYPE ddoption VALUE 'BT',
      option_contains_pattern     TYPE ddoption VALUE 'CP',
      option_equal                TYPE ddoption VALUE 'EQ',
      option_greater              TYPE ddoption VALUE 'GT',
      option_greater_equal        TYPE ddoption VALUE 'GE',
      option_less                 TYPE ddoption VALUE 'LT',
      option_less_equal           TYPE ddoption VALUE 'LE',
      option_not_between          TYPE ddoption VALUE 'NB',
      option_not_contains_pattern TYPE ddoption VALUE 'NP',
      option_not_equal            TYPE ddoption VALUE 'NE',
      sign_exclude                TYPE ddsign   VALUE 'E',
      sign_include                TYPE ddsign   VALUE 'I',
    END OF c_select_options.

  "! Appends all entries of another logger (Application Log items, internal log
  "! and internal error trail) to this one. The other logger is left unchanged.
  "! An unbound reference or the logger itself is ignored; Application Log
  "! failures go to the internal error trail.
  "! @parameter external_log           | Logger whose entries are copied
  "! @parameter self                   | This logger, for chaining
  "! @raising   zcx_cloud_logger_error | The instance was released with free( )
  METHODS merge_logs
    IMPORTING external_log TYPE REF TO zif_cloud_logger
    RETURNING VALUE(self)  TYPE REF TO zif_cloud_logger
    RAISING   zcx_cloud_logger_error.

  "! Adds a free-text entry. The active context (see {@link zif_cloud_logger.METH:set_context})
  "! is prefixed to the persisted text; the internal log keeps the text as given.
  "! The Application Log stores at most 200 characters of free text (prefix included);
  "! longer texts are cut there, never in the internal log.
  "! @parameter string                 | Text to log (not truncated internally)
  "! @parameter msgty                  | Severity, defaults to warning
  "! @parameter self                   | This logger, for chaining
  "! @raising   zcx_cloud_logger_error | The Application Log rejected the entry, or the instance was released
  METHODS log_string_add
    IMPORTING !string     TYPE string
              msgty       TYPE symsgty DEFAULT c_default_message_attributes-type
    RETURNING VALUE(self) TYPE REF TO zif_cloud_logger
    RAISING   zcx_cloud_logger_error.

  "! Adds a T100 message given as SYMSG structure. An initial structure is ignored;
  "! a missing severity defaults to warning.
  "! @parameter symsg                  | Message type, class, number and variables
  "! @parameter self                   | This logger, for chaining
  "! @raising   zcx_cloud_logger_error | The Application Log rejected the entry, or the instance was released
  METHODS log_message_add
    IMPORTING symsg       TYPE symsg
    RETURNING VALUE(self) TYPE REF TO zif_cloud_logger
    RAISING   zcx_cloud_logger_error.

  "! Adds the message currently held in the system fields SY-MSG*,
  "! typically right after <em>MESSAGE ... INTO</em>. An empty SY message is ignored.
  "! @parameter self                   | This logger, for chaining
  "! @raising   zcx_cloud_logger_error | The Application Log rejected the entry, or the instance was released
  METHODS log_syst_add
    RETURNING VALUE(self) TYPE REF TO zif_cloud_logger
    RAISING   zcx_cloud_logger_error.

  "! Adds an exception. The full exception text is kept in the internal log;
  "! the Application Log receives the exception object itself. For exceptions with
  "! a T100 key ({@link if_t100_message}) the key and its variables are kept, so
  "! {@link zif_cloud_logger.METH:search_message}, the RAP and the BAPIRET2
  "! conversions see the real message. An unbound reference is ignored.
  "! @parameter severity               | Severity, defaults to error
  "! @parameter exception              | Exception to log
  "! @parameter self                   | This logger, for chaining
  "! @raising   zcx_cloud_logger_error | The Application Log rejected the entry, or the instance was released
  METHODS log_exception_add
    IMPORTING severity    TYPE symsgty DEFAULT c_message_type-error
              !exception  TYPE REF TO cx_root
    RETURNING VALUE(self) TYPE REF TO zif_cloud_logger
    RAISING   zcx_cloud_logger_error.

  "! Adds a table of BAPI return structures, optionally keeping only entries at
  "! or above a severity: <em>W</em> keeps W/E/A/X, <em>E</em> keeps E/A/X,
  "! <em>A</em> or <em>X</em> keeps A/X. No filter (or I/S) keeps everything.
  "! @parameter bapiret2_t             | BAPI return table
  "! @parameter min_severity           | Lowest severity to keep
  "! @parameter self                   | This logger, for chaining
  "! @raising   zcx_cloud_logger_error | The Application Log rejected an entry, or the instance was released
  METHODS log_bapiret2_table_add
    IMPORTING bapiret2_t   TYPE bapiret2_messages
              min_severity TYPE symsgty OPTIONAL
    RETURNING VALUE(self)  TYPE REF TO zif_cloud_logger
    RAISING   zcx_cloud_logger_error.

  "! Adds one BAPI return structure. An initial structure is ignored.
  "! @parameter bapiret2               | BAPI return structure
  "! @parameter self                   | This logger, for chaining
  "! @raising   zcx_cloud_logger_error | The Application Log rejected the entry, or the instance was released
  METHODS log_bapiret2_structure_add
    IMPORTING bapiret2    TYPE bapiret2
    RETURNING VALUE(self) TYPE REF TO zif_cloud_logger
    RAISING   zcx_cloud_logger_error.

  "! Serializes any data object (elementary, structure, table) to JSON via XCO
  "! and logs it as free text (200 characters in the Application Log, complete in
  "! the internal log). Serialization and logging problems are logged as an error
  "! entry instead of being raised, so a chain is not broken by bad data.
  "! @parameter data                   | Data object to serialize
  "! @parameter msgty                  | Severity, defaults to warning
  "! @parameter self                   | This logger, for chaining
  "! @raising   zcx_cloud_logger_error | The instance was released with free( )
  METHODS log_data_add
    IMPORTING !data       TYPE data
              msgty       TYPE symsgty DEFAULT c_default_message_attributes-type
    RETURNING VALUE(self) TYPE REF TO zif_cloud_logger
    RAISING   zcx_cloud_logger_error.

  "! Persists the log via {@link cl_bali_log_db}. The caller owns the commit.
  "! With <em>db_save = abap_false</em> the call is a no-op that is recorded in
  "! the internal error trail only.
  "! @parameter use_2nd_db_connection      | Save on a separate DB connection (own commit)
  "! @parameter assign_to_current_appl_job | Attach the log to the running application job
  "! @parameter self                       | This logger, for chaining
  "! @raising   zcx_cloud_logger_error     | The Application Log could not be saved, or the instance was released
  METHODS save_application_log
    IMPORTING use_2nd_db_connection      TYPE abap_boolean DEFAULT abap_false
              assign_to_current_appl_job TYPE abap_boolean DEFAULT abap_false
    RETURNING VALUE(self)                TYPE REF TO zif_cloud_logger
    RAISING   zcx_cloud_logger_error.

  "! Returns the internal log with all details, in insertion order.
  "! @parameter result | Internal log entries
  METHODS get_messages
    RETURNING VALUE(result) TYPE log_messages.

  "! Returns one rendered line per entry: <em>[context] TNNN(CLASS) - text</em>
  "! for T100 messages, the plain text otherwise.
  "! @parameter result | Rendered lines
  METHODS get_messages_flat
    RETURNING VALUE(result) TYPE flat_messages.

  "! Returns the entries as BAPI return table. The <em>message</em> field is
  "! limited to its native 220 characters.
  "! @parameter result | BAPI return table
  METHODS get_messages_as_bapiret2
    RETURNING VALUE(result) TYPE bapiret2_messages.

  "! Returns the entries as RAP behavior messages. Free-text and exception
  "! entries are wrapped in {@link zif_cloud_logger.DATA:c_free_text_message} (200 characters).
  "! @parameter result | Messages for a RAP <em>reported</em> response
  METHODS get_messages_rap
    RETURNING VALUE(result) TYPE rap_messages.

  "! Returns the Application Log handle (BALLOGHNDL); initial after {@link zif_cloud_logger.METH:free}.
  "! @parameter result | Log handle
  METHODS get_handle
    RETURNING VALUE(result) TYPE balloghndl.

  "! Returns the underlying {@link if_bali_log} object for direct access.
  "! @parameter result | Application Log object, unbound after {@link zif_cloud_logger.METH:free}
  METHODS get_log_handle
    RETURNING VALUE(result) TYPE REF TO if_bali_log.

  "! Counts entries, optionally of one severity only.
  "! @parameter msgty  | Severity to count; initial counts all entries
  "! @parameter result | Number of matching entries
  METHODS get_message_count
    IMPORTING msgty         TYPE symsgty OPTIONAL
    RETURNING VALUE(result) TYPE int4.

  "! Discards all entries and starts a fresh Application Log with the same
  "! configuration. Timer and context are cleared as well. The instance stays
  "! registered and usable.
  "! @parameter delete_from_db         | Also delete the persisted log, if it was saved
  "! @raising   zcx_cloud_logger_error | A fresh Application Log could not be created, or the instance was released
  METHODS reset_appl_log
    IMPORTING delete_from_db TYPE abap_bool DEFAULT abap_false
    RAISING   zcx_cloud_logger_error.

  "! @parameter result | abap_true when the log has no entries
  METHODS log_is_empty
    RETURNING VALUE(result) TYPE abap_boolean.

  "! @parameter result | abap_true when the log has at least one entry
  METHODS log_contains_messages
    RETURNING VALUE(result) TYPE abap_boolean.

  "! @parameter result | abap_true when the log has an entry of severity E, A or X
  METHODS log_contains_error
    RETURNING VALUE(result) TYPE abap_boolean.

  "! @parameter result | abap_true when the log has an entry of severity W, E, A or X
  METHODS log_contains_warning
    RETURNING VALUE(result) TYPE abap_boolean.

  "! Checks whether an entry matches the given message class, number and/or
  "! severity. Initial components are not compared; a completely initial
  "! search matches any entry. Message number 000 is the initial value of the
  "! NUMC field and therefore means "any number".
  "! @parameter search | Message key parts to match
  "! @parameter result | abap_true when at least one entry matches
  METHODS search_message
    IMPORTING !search       TYPE symsg
    RETURNING VALUE(result) TYPE abap_boolean.

  "! Removes the instance from the multiton registry and releases its
  "! Application Log. The instance is dead afterwards: writing methods raise
  "! <em>instance_released</em>, queries return empty results. The next
  "! {@link zcl_cloud_logger.METH:get_instance} with the same key creates a
  "! new instance. Calling free( ) twice is harmless, also on a stale reference
  "! after a new instance was created.
  METHODS free.

  "! Starts the stopwatch. Calling it again before {@link zif_cloud_logger.METH:stop_timer}
  "! restarts it and logs a warning.
  "! @parameter self                   | This logger, for chaining
  "! @raising   zcx_cloud_logger_error | The instance was released with free( )
  METHODS start_timer
    RETURNING VALUE(self) TYPE REF TO zif_cloud_logger
    RAISING   zcx_cloud_logger_error.

  "! Stops the stopwatch and logs the elapsed seconds as an information entry.
  "! Without a preceding {@link zif_cloud_logger.METH:start_timer} a warning is logged instead.
  "! @parameter text                   | Label for the measured block
  "! @parameter self                   | This logger, for chaining
  "! @raising   zcx_cloud_logger_error | The instance was released with free( )
  METHODS stop_timer
    IMPORTING !text       TYPE string OPTIONAL
    RETURNING VALUE(self) TYPE REF TO zif_cloud_logger
    RAISING   zcx_cloud_logger_error.

  "! Hands the logger to a viewer (Strategy pattern). An unbound viewer is ignored.
  "! @parameter viewer | Viewer implementation, see {@link zif_cloud_logger_viewer}
  METHODS display
    IMPORTING viewer TYPE REF TO zif_cloud_logger_viewer.

  "! Sets a sticky context that is attached to every following entry until
  "! {@link zif_cloud_logger.METH:clear_context}, e.g. the document currently processed.
  "! @parameter context | Context text, shown as <em>[context]</em> prefix
  "! @parameter self    | This logger, for chaining
  METHODS set_context
    IMPORTING !context    TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_cloud_logger.

  "! Removes the sticky context.
  "! @parameter self | This logger, for chaining
  METHODS clear_context
    RETURNING VALUE(self) TYPE REF TO zif_cloud_logger.

  "! Returns the problems the logger swallowed on purpose (failed emergency
  "! mirror, no-op save, unresolvable message text, ...). Oldest first, capped at
  "! the instance's <em>trim_limit</em>; a trim_limit of 0 switches the trail off.
  "! @parameter result | Internal error trail
  METHODS get_internal_errors
    RETURNING VALUE(result) TYPE internal_errors.

  "! Empties the internal error trail.
  "! @parameter self | This logger, for chaining
  METHODS clear_internal_errors
    RETURNING VALUE(self) TYPE REF TO zif_cloud_logger.

ENDINTERFACE.
