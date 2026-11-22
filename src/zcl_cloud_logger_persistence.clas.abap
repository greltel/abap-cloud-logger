"! <p class="shorttext synchronized" lang="en">Cloud Logger persistence (production)</p>
"! Thin adapter over {@link cl_bali_log_db} and, for the emergency log, over
"! XCO BAL. The only place that reads Application Log items back from the
"! database and the only place that writes the emergency log.
CLASS zcl_cloud_logger_persistence DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_cloud_logger_persistence.

  PRIVATE SECTION.
    " The Application Log stores item time stamps in UTC; loaded entries keep it
    CONSTANTS utc_time_zone TYPE c LENGTH 6 VALUE 'UTC'.

    " The emergency log opened last; one adapter serves one logger
    DATA emergency_log TYPE REF TO if_xco_cp_bal_log.

    " Maps one persisted item to an internal log entry; a T100 item keeps its key
    METHODS entry_from_item
      IMPORTING item          TYPE REF TO if_bali_item_getter
                log_user      TYPE syuname
      RETURNING VALUE(result) TYPE zif_cloud_logger=>t_log_messages.

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

  METHOD zif_cloud_logger_persistence~load_log.
    result-log = cl_bali_log_db=>get_instance( )->load_log( handle ).

    DATA(header) = result-log->get_header( ).

    result-object      = header->object.
    result-subobject   = header->subobject.
    result-external_id = header->external_id.
    result-expiry_date = header->expiry_date.

    TRY.
        DATA(items) = result-log->get_all_items( ).
      CATCH cx_bali_not_found.
        " A log that was saved without entries is a valid log: it loads empty
        RETURN.
    ENDTRY.

    LOOP AT items REFERENCE INTO DATA(item_entry).
      INSERT entry_from_item( item     = item_entry->item
                              log_user = header->log_user ) INTO TABLE result-entries.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_cloud_logger_persistence~open_emergency_log.
    emergency_log = xco_cp_bal=>for->database( )->log->create( iv_object      = object
                                                               iv_subobject   = subobject
                                                               iv_external_id = external_id ).
  ENDMETHOD.

  METHOD zif_cloud_logger_persistence~mirror_message.
    emergency_log->add_message( symsg ).
  ENDMETHOD.

  METHOD zif_cloud_logger_persistence~mirror_exception.
    " XCO knows error, warning, information and success: A and X are errors there
    DATA(xco_severity) = SWITCH symsgty( severity
                                         WHEN zif_cloud_logger=>c_message_type-abandon
                                           OR zif_cloud_logger=>c_message_type-terminate
                                           THEN zif_cloud_logger=>c_message_type-error
                                         ELSE severity ).

    emergency_log->add_exception(
        ix_exception = exception
        io_severity  = xco_cp=>message( VALUE #( msgty = xco_severity ) )->get_type( ) ).
  ENDMETHOD.

  METHOD entry_from_item.
    result-type        = item->severity.
    result-symsg-msgty = item->severity.
    result-user_name   = log_user.

    CONVERT UTCLONG item->timestamp
            INTO DATE result-date TIME result-time
            TIME ZONE utc_time_zone.

    TRY.
        result-message = item->get_message_text( ).
      CATCH cx_bali_runtime.
        " One unreadable text must not prevent the rest of the log from loading
        CLEAR result-message.
    ENDTRY.

    IF item->category = if_bali_constants=>c_category_message.
      DATA(message) = CAST if_bali_message_getter( item ).
      result-symsg-msgid = message->id.
      result-symsg-msgno = message->number.
      result-symsg-msgv1 = message->variable_1.
      result-symsg-msgv2 = message->variable_2.
      result-symsg-msgv3 = message->variable_3.
      result-symsg-msgv4 = message->variable_4.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

