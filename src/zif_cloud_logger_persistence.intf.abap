"! <p class="shorttext synchronized" lang="en">Cloud Logger persistence</p>
"! Database access of the logger, isolated so that unit tests never write an
"! Application Log. Production uses {@link zcl_cloud_logger_persistence}.
INTERFACE zif_cloud_logger_persistence
  PUBLIC.

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
