"! <p class="shorttext synchronized" lang="en">Cloud Logger persistence</p>
"! Database access of the logger, isolated so that unit tests never write an
"! Application Log. Production uses {@link zcl_cloud_logger_persistence}.
"! The emergency log is part of it: an adapter keeps the emergency log it
"! opened, so one adapter serves one logger.
INTERFACE zif_cloud_logger_persistence
  PUBLIC.

  TYPES:
    "! A persisted log read back from the database, in the logger's own terms
    BEGIN OF loaded_log,
      "! The Application Log object, ready to receive further items
      log         TYPE REF TO if_bali_log,
      object      TYPE cl_bali_header_setter=>ty_object,
      subobject   TYPE cl_bali_header_setter=>ty_subobject,
      external_id TYPE cl_bali_header_setter=>ty_external_id,
      expiry_date TYPE d,
      "! One entry per persisted item; <em>item</em> and <em>context</em> stay initial
      entries     TYPE zif_cloud_logger=>log_messages,
    END OF loaded_log.

  "! Loads a persisted log by its handle and maps the items to internal log entries.
  "! @parameter handle          | Application Log handle (BALLOGHNDL)
  "! @parameter result          | Log object, header data and entries
  "! @raising   cx_bali_runtime | No log with this handle, or it could not be read
  METHODS load_log
    IMPORTING handle        TYPE balloghndl
    RETURNING VALUE(result) TYPE loaded_log
    RAISING   cx_bali_runtime.

  "! Persists the log. The caller owns the commit.
  "! @parameter log                        | Application Log to save
  "! @parameter use_2nd_db_connection      | Save on a separate DB connection (own commit)
  "! @parameter assign_to_current_appl_job | Attach the log to the running application job
  "! @raising   cx_bali_runtime            | The Application Log could not be saved
  METHODS save_log
    IMPORTING log                        TYPE REF TO if_bali_log
              use_2nd_db_connection      TYPE abap_boolean DEFAULT abap_false
              assign_to_current_appl_job TYPE abap_boolean DEFAULT abap_false
    RAISING   cx_bali_runtime.

  "! Deletes a previously saved log from the database.
  "! @parameter log             | Application Log to delete
  "! @raising   cx_bali_runtime | The log is unknown to the database or could not be deleted
  METHODS delete_log
    IMPORTING log TYPE REF TO if_bali_log
    RAISING   cx_bali_runtime.

  "! Opens the emergency log: a second log that is written to the database
  "! entry by entry, with its own commit, independent of the caller's LUW.
  "! The following mirror calls write to it; opening again starts a new one.
  "! Failures surface as exceptions of the cx_no_check family (XCO), so the
  "! caller catches cx_root.
  "! @parameter object      | Application Log object
  "! @parameter subobject   | Application Log subobject
  "! @parameter external_id | External id of the emergency log
  METHODS open_emergency_log
    IMPORTING !object     TYPE cl_bali_header_setter=>ty_object
              subobject   TYPE cl_bali_header_setter=>ty_subobject
              external_id TYPE cl_bali_header_setter=>ty_external_id.

  "! Writes a T100 message to the emergency log opened before.
  "! @parameter symsg | Message type, class, number and variables
  METHODS mirror_message
    IMPORTING symsg TYPE symsg.

  "! Writes an exception to the emergency log opened before.
  "! @parameter exception | Exception to write
  "! @parameter severity  | Severity of the entry
  METHODS mirror_exception
    IMPORTING !exception TYPE REF TO cx_root
              severity   TYPE symsgty.

ENDINTERFACE.
