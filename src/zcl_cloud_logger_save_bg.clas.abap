CLASS zcl_cloud_logger_save_bg DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_bgmc_op_single_tx_uncontr.

    METHODS constructor
      IMPORTING
        iv_object      TYPE cl_bali_header_setter=>ty_object
        iv_subobject   TYPE cl_bali_header_setter=>ty_subobject
        iv_ext_number  TYPE cl_bali_header_setter=>ty_external_id
        iv_expiry_date TYPE d OPTIONAL
        it_messages    TYPE ZIF_CLOUD_LOGGER=>LOG_MESSAGES.

  PRIVATE SECTION.
    DATA: mv_object      TYPE cl_bali_header_setter=>ty_object,
          mv_subobject   TYPE cl_bali_header_setter=>ty_subobject,
          mv_ext_number  TYPE cl_bali_header_setter=>ty_external_id,
          mv_expiry_date TYPE d,
          mt_messages    TYPE ZIF_CLOUD_LOGGER=>LOG_MESSAGES.

ENDCLASS.



CLASS ZCL_CLOUD_LOGGER_SAVE_BG IMPLEMENTATION.


  METHOD constructor.
    mv_object      = iv_object.
    mv_subobject   = iv_subobject.
    mv_ext_number  = iv_ext_number.
    mv_expiry_date = iv_expiry_date.
    mt_messages    = it_messages.
  ENDMETHOD.

  METHOD if_bgmc_op_single_tx_uncontr~execute.
    TRY.
        DATA(lo_log)    = cl_bali_log=>create( ).
        DATA(lo_header) = cl_bali_header_setter=>create( object      = mv_object
                                                         subobject   = mv_subobject
                                                         external_id = mv_ext_number ).

        IF mv_expiry_date IS NOT INITIAL.
          lo_header->set_expiry( mv_expiry_date ).
        ENDIF.

        lo_log->set_header( lo_header ).

        LOOP AT mt_messages INTO DATA(ls_msg).
          IF ls_msg-symsg-msgid IS INITIAL.
            lo_log->add_item( cl_bali_free_text_setter=>create( severity = ls_msg-symsg-msgty
                                                                text     = CONV #( ls_msg-message ) ) ).
          ELSE.
            lo_log->add_item( cl_bali_message_setter=>create( severity   = ls_msg-symsg-msgty
                                                              id         = ls_msg-symsg-msgid
                                                              number     = ls_msg-symsg-msgno
                                                              variable_1 = ls_msg-symsg-msgv1
                                                              variable_2 = ls_msg-symsg-msgv2
                                                              variable_3 = ls_msg-symsg-msgv3
                                                              variable_4 = ls_msg-symsg-msgv4 ) ).
          ENDIF.
        ENDLOOP.

        cl_bali_log_db=>get_instance( )->save_log( lo_log ).

      CATCH cx_bali_runtime INTO DATA(lx_bali). " TODO: variable is assigned but never used (ABAP cleaner)
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
