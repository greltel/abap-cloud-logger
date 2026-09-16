"! <p class="shorttext synchronized" lang="en">Cloud Logger system access (production)</p>
"! Reads the system context through the released Cloud APIs.
CLASS zcl_cloud_logger_system DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_cloud_logger_system.

ENDCLASS.


CLASS zcl_cloud_logger_system IMPLEMENTATION.

  METHOD zif_cloud_logger_system~system_date.
    result = cl_abap_context_info=>get_system_date( ).
  ENDMETHOD.

  METHOD zif_cloud_logger_system~system_time.
    result = cl_abap_context_info=>get_system_time( ).
  ENDMETHOD.

  METHOD zif_cloud_logger_system~now.
    GET TIME STAMP FIELD result.
  ENDMETHOD.

  METHOD zif_cloud_logger_system~user_name.
    " The alias is the readable name on SAP BTP but is often not maintained
    " on-premise; the technical name is always filled.
    result = cl_abap_context_info=>get_user_alias( ).

    IF result IS INITIAL.
      result = cl_abap_context_info=>get_user_technical_name( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_cloud_logger_system~current_message.
    " The SY message fields are on the Cloud allow-list; this adapter is the
    " single place in the library that reads them.
    result = VALUE #( msgty = sy-msgty
                      msgid = sy-msgid
                      msgno = sy-msgno
                      msgv1 = sy-msgv1
                      msgv2 = sy-msgv2
                      msgv3 = sy-msgv3
                      msgv4 = sy-msgv4 ).
  ENDMETHOD.

ENDCLASS.
