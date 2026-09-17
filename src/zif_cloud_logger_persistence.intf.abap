"! <p class="shorttext synchronized" lang="en">Cloud Logger persistence</p>
"! Database access of the logger, isolated so that unit tests never write an
"! Application Log. Production uses {@link zcl_cloud_logger_persistence}.
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

ENDINTERFACE.
