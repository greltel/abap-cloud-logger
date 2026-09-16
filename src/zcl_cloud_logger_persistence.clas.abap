"! <p class="shorttext synchronized" lang="en">Cloud Logger persistence (production)</p>
"! Thin adapter over {@link cl_bali_log_db}.
CLASS zcl_cloud_logger_persistence DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_cloud_logger_persistence.

ENDCLASS.


CLASS zcl_cloud_logger_persistence IMPLEMENTATION.

  METHOD zif_cloud_logger_persistence~save_log.
    cl_bali_log_db=>get_instance( )->save_log( log                        = log
                                               use_2nd_db_connection      = use_2nd_db_connection
                                               assign_to_current_appl_job = assign_to_current_appl_job ).
  ENDMETHOD.

  METHOD zif_cloud_logger_persistence~delete_log.
    cl_bali_log_db=>get_instance( )->delete_log( log ).
  ENDMETHOD.

ENDCLASS.

