
CLASS ltc_external_methods DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.

    DATA mo_log TYPE REF TO zif_cloud_logger.

    METHODS setup.
    METHODS teardown.
    METHODS test_instantiation            FOR TESTING RAISING cx_static_check.
    METHODS add_messages                  FOR TESTING RAISING cx_static_check.
    METHODS create_and_save_log           FOR TESTING RAISING cx_static_check.
    METHODS create_wrong_log              FOR TESTING RAISING cx_static_check.
    METHODS empty_log                     FOR TESTING RAISING cx_static_check.
    METHODS log_contain_messages          FOR TESTING RAISING cx_static_check.
    METHODS merge_logs                    FOR TESTING RAISING cx_static_check.
    METHODS check_error_in_log            FOR TESTING RAISING cx_static_check.
    METHODS check_warning_in_log          FOR TESTING RAISING cx_static_check.
    METHODS search_message_found          FOR TESTING RAISING cx_static_check.
    METHODS search_message_not_found      FOR TESTING RAISING cx_static_check.
    METHODS search_message_with_type      FOR TESTING RAISING cx_static_check.
    METHODS test_fluent_chaining_1        FOR TESTING RAISING cx_static_check.
    METHODS free_and_reset_log            FOR TESTING RAISING cx_static_check.
    METHODS test_log_data_as_json         FOR TESTING RAISING cx_static_check.
    METHODS use_same_instance             FOR TESTING RAISING cx_static_check.
    METHODS handle_not_initial            FOR TESTING RAISING cx_static_check.
    METHODS bapiret2_smart_filtering      FOR TESTING RAISING cx_static_check.
    METHODS test_timer                    FOR TESTING RAISING cx_static_check.
    METHODS test_sticky_context           FOR TESTING RAISING cx_static_check.
    METHODS get_instance_same_params       FOR TESTING RAISING cx_static_check.
    METHODS get_instance_omitted_params    FOR TESTING RAISING cx_static_check.
    METHODS get_instance_conflict_db_save  FOR TESTING RAISING cx_static_check.
    METHODS get_instance_conflict_expiry   FOR TESTING RAISING cx_static_check.
    METHODS long_string_not_truncated  FOR TESTING RAISING cx_static_check.
    METHODS long_exception_not_trunc   FOR TESTING RAISING cx_static_check.
    METHODS context_applies_to_all_methods FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_external_methods IMPLEMENTATION.

  METHOD setup.

    mo_log = zcl_cloud_logger=>get_instance(
      object    = 'Z_CLOUD_LOG_SAMPLE'
      subobject = 'SETUP'
      db_save   = abap_true ).

    mo_log->reset_appl_log( delete_from_db = abap_true ).

  ENDMETHOD.

  METHOD teardown.
    mo_log->free( ).
    FREE mo_log.
  ENDMETHOD.

  METHOD test_instantiation.

    cl_abap_unit_assert=>assert_bound(
      act = mo_log
      msg = 'Logger instance should be created' ).

  ENDMETHOD.

  METHOD add_messages.

    TRY.

        mo_log->log_message_add( symsg = VALUE #( msgty = 'W'
                                                     msgid = 'CL'
                                                     msgno = '000'
                                                     msgv1 = 'Test Message'
                                                     msgv2 = ''
                                                     msgv3 = ''
                                                     msgv4 = '' ) ).

        mo_log->log_bapiret2_structure_add( VALUE #( id         = 'Z_CLOUD_LOGGER'
                                                     type       = 'W'
                                                     number     = '002'
                                                     message_v1 = 'TEST' ) ).

        mo_log->log_bapiret2_table_add( VALUE #( id     = 'Z_CLOUD_LOGGER'
                                                 type   = 'W'
                                                 number = '002'
                                                 ( message_v1 = 'BAPIS' )
                                                 ( message_v1 = 'More' ) ) ).

        mo_log->log_exception_add( exception = NEW cx_sy_itab_line_not_found( ) ).

        MESSAGE s003(z_aml) INTO DATA(dummy) ##NEEDED.
        mo_log->log_syst_add( ).

        mo_log->log_string_add( 'Some Freestyle text' ).

        cl_abap_unit_assert=>assert_equals( exp = 7
                                            act = mo_log->get_message_count( ) ).

        cl_abap_unit_assert=>assert_equals( exp = 7
                                            act = lines( mo_log->get_messages_as_bapiret2( ) ) ).

        mo_log->reset_appl_log( ).

      CATCH zcx_cloud_logger_error INTO DATA(lo_exception).
        DATA(lv_exception_text) = lo_exception->get_text( ).
        cl_abap_unit_assert=>fail( ).
    ENDTRY.

  ENDMETHOD.

  METHOD create_wrong_log.

    TRY.
        DATA(mo_log_error) = zcl_cloud_logger=>get_instance( db_save = abap_true object = 'Z_DUMMY_WRONG' subobject = 'Z_DUMMY_WRONG' ).

        cl_abap_unit_assert=>fail( ).

      CATCH zcx_cloud_logger_error INTO DATA(lo_exception).
        DATA(lv_exception_text) = lo_exception->get_text( ).
        cl_abap_unit_assert=>assert_true( abap_true ).
    ENDTRY.

  ENDMETHOD.

  METHOD create_and_save_log.

    TRY.

        mo_log->log_string_add( 'Message to save' ).

        mo_log->save_application_log( use_2nd_db_connection = abap_false ).

        cl_abap_unit_assert=>assert_true( abap_true ).

      CATCH zcx_cloud_logger_error INTO DATA(lo_exception).
        DATA(lv_exception_text) = lo_exception->get_text( ).
        cl_abap_unit_assert=>fail( ).
    ENDTRY.

  ENDMETHOD.

  METHOD merge_logs.

    DATA lo_second_logger TYPE REF TO zif_cloud_logger.

    TRY.

        lo_second_logger = zcl_cloud_logger=>get_instance(
          object     = 'Z_CLOUD_LOG_SAMPLE'
          subobject  = 'SETUP'
          ext_number = '1234'
          db_save    = abap_false ).

        MESSAGE e005(z_cloud_logger) INTO DATA(dummy2).
        lo_second_logger->log_syst_add( ).

        mo_log->merge_logs( lo_second_logger ).

        cl_abap_unit_assert=>assert_equals( exp = 1
                                            act = mo_log->get_message_count( ) ).

      CATCH zcx_cloud_logger_error INTO DATA(lo_exception).
        DATA(lv_exception_text) = lo_exception->get_text( ).
        cl_abap_unit_assert=>fail( ).
    ENDTRY.

    " Cleanup: free the secondary logger so the static logger_instances
    " table doesn't accumulate stale entries between test runs.
    IF lo_second_logger IS BOUND.
      lo_second_logger->free( ).
    ENDIF.

  ENDMETHOD.


  METHOD check_error_in_log.

    TRY.

        mo_log->log_message_add( symsg = VALUE #( msgty = 'W'
                                                msgid = 'CL'
                                                msgno = '000'
                                                msgv1 = 'Test Message 1'
                                                msgv2 = ''
                                                msgv3 = ''
                                                msgv4 = '' ) ).

        mo_log->log_message_add( symsg = VALUE #( msgty = 'E'
                                                        msgid = 'CL'
                                                        msgno = '000'
                                                        msgv1 = 'Test Message 2'
                                                        msgv2 = ''
                                                        msgv3 = ''
                                                        msgv4 = '' ) ).

        cl_abap_unit_assert=>assert_true( mo_log->log_contains_error( ) ).
        mo_log->reset_appl_log( ).

      CATCH zcx_cloud_logger_error INTO DATA(lo_exception).
        DATA(lv_exception_text) = lo_exception->get_text( ).
        cl_abap_unit_assert=>fail( ).
    ENDTRY.

  ENDMETHOD.


  METHOD check_warning_in_log.

    TRY.

        mo_log->log_message_add( symsg = VALUE #( msgty = 'W'
                                                msgid = 'CL'
                                                msgno = '000'
                                                msgv1 = 'Test Message 1'
                                                msgv2 = ''
                                                msgv3 = ''
                                                msgv4 = '' ) ).

        mo_log->log_message_add( symsg = VALUE #( msgty = 'E'
                                                        msgid = 'CL'
                                                        msgno = '000'
                                                        msgv1 = 'Test Message 2'
                                                        msgv2 = ''
                                                        msgv3 = ''
                                                        msgv4 = '' ) ).

        cl_abap_unit_assert=>assert_true( mo_log->log_contains_warning( ) ).
        mo_log->reset_appl_log( ).

      CATCH zcx_cloud_logger_error INTO DATA(lo_exception).
        DATA(lv_exception_text) = lo_exception->get_text( ).
        cl_abap_unit_assert=>fail( ).
    ENDTRY.

  ENDMETHOD.

  METHOD search_message_found.


    TRY.

        mo_log->log_message_add( symsg = VALUE #( msgty = 'W'
                                                msgid = 'CL'
                                                msgno = '000'
                                                msgv1 = 'Test Message 1'
                                                msgv2 = ''
                                                msgv3 = ''
                                                msgv4 = '' ) ).

        DATA(lv_result) = mo_log->search_message( search = VALUE #( msgid = 'CL' ) ).

        cl_abap_unit_assert=>assert_true( lv_result ).
        mo_log->reset_appl_log( ).

      CATCH zcx_cloud_logger_error INTO DATA(lo_exception).
        DATA(lv_exception_text) = lo_exception->get_text( ).
        cl_abap_unit_assert=>fail( ).
    ENDTRY.

  ENDMETHOD.


  METHOD search_message_not_found.

    TRY.

        mo_log->log_message_add( symsg = VALUE #( msgty = 'W'
                                                msgid = 'CL'
                                                msgno = '000'
                                                msgv1 = 'Test Message 1'
                                                msgv2 = ''
                                                msgv3 = ''
                                                msgv4 = '' ) ).

        DATA(result) = mo_log->search_message( search = VALUE #( msgno = '003' ) ).

        cl_abap_unit_assert=>assert_false( result ).
        mo_log->reset_appl_log( ).

      CATCH zcx_cloud_logger_error INTO DATA(lo_exception).
        DATA(lv_exception_text) = lo_exception->get_text( ).
        cl_abap_unit_assert=>fail( ).
    ENDTRY.

  ENDMETHOD.


  METHOD search_message_with_type.

    TRY.

        mo_log->log_message_add( symsg = VALUE #( msgty = 'W'
                                                msgid = 'CL'
                                                msgno = '000'
                                                msgv1 = 'Test Message 1'
                                                msgv2 = ''
                                                msgv3 = ''
                                                msgv4 = '' ) ).

        DATA(lv_result) = mo_log->search_message( search = VALUE #( msgid = 'CL' msgno = '000' msgty = 'W' ) ).

        cl_abap_unit_assert=>assert_true( lv_result ).
        mo_log->reset_appl_log( ).

      CATCH zcx_cloud_logger_error INTO DATA(lo_exception).
        DATA(lv_exception_text) = lo_exception->get_text( ).
        cl_abap_unit_assert=>fail( ).
    ENDTRY.

  ENDMETHOD.

  METHOD test_fluent_chaining_1.

    mo_log->log_string_add( 'Message 1' )->log_string_add( 'Message 2' )->log_string_add( 'Message 3' ).

    cl_abap_unit_assert=>assert_equals(
      act = mo_log->get_message_count( )
      exp = 3
      msg = 'Should have logged 2 messages via chaining' ).

  ENDMETHOD.

  METHOD free_and_reset_log.
    mo_log->free( ).
    mo_log->reset_appl_log( ).
  ENDMETHOD.

  METHOD test_log_data_as_json.

    TYPES: BEGIN OF ty_dummy_data,
             id     TYPE i,
             name   TYPE string,
             active TYPE abap_bool,
           END OF ty_dummy_data.

    DATA: lt_data TYPE STANDARD TABLE OF ty_dummy_data WITH EMPTY KEY.

    lt_data = VALUE #( ( id = 100 name = 'Alpha' active = abap_true )
                       ( id = 200 name = 'Beta'  active = abap_false ) ).

    mo_log->log_data_add( lt_data ).

    DATA(lt_msgs) = mo_log->get_messages_flat( ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_msgs )
      exp = 1
      msg = 'Should have logged exactly 1 message' ).

    READ TABLE lt_msgs INTO DATA(lv_json_msg) INDEX 1.

    cl_abap_unit_assert=>assert_char_cp(
      act = lv_json_msg
      exp = '*"id":100*'
      msg = 'JSON should contain the first ID').

    cl_abap_unit_assert=>assert_char_cp(
      act = lv_json_msg
      exp = '*"name":"Alpha"*'
      msg = 'JSON should contain the first Name' ).

    SELECT * FROM i_companycode INTO TABLE @DATA(lt_company_codes) UP TO 10 ROWS.

    mo_log->log_data_add( lt_company_codes )->save_application_log( ).
    COMMIT WORK.

  ENDMETHOD.

  METHOD empty_log.

    TRY.

        IF mo_log->log_is_empty( ) EQ abap_false.
          cl_abap_unit_assert=>fail( ).
        ELSE.
          cl_abap_unit_assert=>assert_true( abap_true ).
        ENDIF.

      CATCH zcx_cloud_logger_error INTO DATA(lo_exception).
        DATA(lv_exception_text) = lo_exception->get_text( ).
        cl_abap_unit_assert=>fail( ).
    ENDTRY.

  ENDMETHOD.

  METHOD log_contain_messages.

    TRY.

        IF mo_log->log_contains_messages( ) EQ abap_false.
          cl_abap_unit_assert=>assert_true( abap_true ).
        ELSE.
          cl_abap_unit_assert=>fail( ).
        ENDIF.

      CATCH zcx_cloud_logger_error INTO DATA(lo_exception).
        DATA(lv_exception_text) = lo_exception->get_text( ).
        cl_abap_unit_assert=>fail( ).
    ENDTRY.

  ENDMETHOD.

  METHOD use_same_instance.

    TRY.

        "ADD MESSAGES TO PREVIOUS INSTANCE
        mo_log->log_bapiret2_table_add( VALUE #( id     = 'Z_CLOUD_LOGGER'
                                            type   = 'W'
                                            number = '002'
                                            ( message_v1 = 'BAPIS' )
                                            ( message_v1 = 'More' ) ) ).

        mo_log->log_exception_add( exception = NEW cx_sy_itab_line_not_found( ) ).

        "GET SAME INSTANCE BACK
        DATA(lr_same_instance) = zcl_cloud_logger=>get_instance( object    = 'Z_CLOUD_LOG_SAMPLE'
                                                                 subobject = 'SETUP' ).

        cl_abap_unit_assert=>assert_equals( exp = 3
                                            act = lr_same_instance->get_message_count( ) ).

        cl_abap_unit_assert=>assert_equals( exp = 3
                                            act = lines( lr_same_instance->get_messages_rap( ) ) ).


      CATCH zcx_cloud_logger_error INTO DATA(lo_exception).
        DATA(lv_exception_text) = lo_exception->get_text( ).
        cl_abap_unit_assert=>fail( ).
    ENDTRY.

  ENDMETHOD.

  METHOD handle_not_initial.

    TRY.

        cl_abap_unit_assert=>assert_not_initial( mo_log->get_handle( ) ).

      CATCH zcx_cloud_logger_error INTO DATA(lo_exception).
        DATA(lv_exception_text) = lo_exception->get_text( ).
        cl_abap_unit_assert=>fail( ).
    ENDTRY.

  ENDMETHOD.

  METHOD bapiret2_smart_filtering.

    TRY.

        " 1. Prepare Data: Success, Warning, Error
        DATA: lt_bapi TYPE zif_cloud_logger=>bapiret2_messages.

        lt_bapi = VALUE #(
            ( type = 'S' message = 'Success Msg' id = 'Z_CLOUD_LOGGER' number = '002' )
            ( type = 'W' message = 'Warning Msg' id = 'Z_CLOUD_LOGGER' number = '002' )
            ( type = 'E' message = 'Error Msg'   id = 'Z_CLOUD_LOGGER' number = '002' )
            ( type = 'A' message = 'Abort Msg'   id = 'Z_CLOUD_LOGGER' number = '002' )
        ).

        " 2. Act: Import ONLY Errors and above (Level 3+)
        mo_log->log_bapiret2_table_add(
            bapiret2_t   = lt_bapi
            min_severity = 'E'
        ).

        " 3. Assert: We expect only 'E' and 'A' (2 messages)
        DATA(lt_msgs) = mo_log->get_messages_flat( ).

        cl_abap_unit_assert=>assert_equals(
          act = lines( lt_msgs )
          exp = 2
          msg = 'Filtering failed. Should only keep Error and Abort.'
        ).

      CATCH zcx_cloud_logger_error INTO DATA(lo_exception).
        DATA(lv_exception_text) = lo_exception->get_text( ).
        cl_abap_unit_assert=>fail( ).
    ENDTRY.

  ENDMETHOD.

  METHOD test_timer.

    mo_log->start_timer( ).

    WAIT UP TO 1 SECONDS.

    mo_log->stop_timer( 'Test Operation' ).

    DATA(lt_msgs) = mo_log->get_messages_flat( ).

    READ TABLE lt_msgs INTO DATA(lv_msg) INDEX 1.

    IF lv_msg CS 'Test Operation' AND lt_msgs IS NOT INITIAL.
      cl_abap_unit_assert=>assert_true( abap_true ).
    ELSE.
      cl_abap_unit_assert=>fail( ).
    ENDIF.

  ENDMETHOD.

  METHOD test_sticky_context.

    mo_log->set_context( 'Order 100' ).

    mo_log->log_string_add( 'Validation started' ).
    mo_log->log_string_add( 'Price checked' ).

    mo_log->set_context( 'Order 200' ).
    mo_log->log_string_add( 'Stock error' ).

    mo_log->clear_context( ).
    mo_log->log_string_add( 'Process finished' ).

    DATA(lt_msgs) = mo_log->get_messages_flat( ).

    READ TABLE lt_msgs INTO DATA(lv_msg1) INDEX 1.
    cl_abap_unit_assert=>assert_char_cp( act = lv_msg1 exp = '*[Order 100] Validation started*' ).

    READ TABLE lt_msgs INTO DATA(lv_msg3) INDEX 3.
    cl_abap_unit_assert=>assert_char_cp( act = lv_msg3 exp = '*[Order 200] Stock error*' ).

    READ TABLE lt_msgs INTO DATA(lv_msg4) INDEX 4.
    IF lv_msg4 CS '['.
      cl_abap_unit_assert=>fail( 'Context was not cleared properly' ).
    ENDIF.

  ENDMETHOD.

  METHOD get_instance_same_params.
    " Re-requesting with identical parameters should return the same instance silently
    TRY.
        DATA(second) = zcl_cloud_logger=>get_instance(
          object    = 'Z_CLOUD_LOG_SAMPLE'
          subobject = 'SETUP'
          db_save   = abap_true ).

        cl_abap_unit_assert=>assert_equals( act = second exp = mo_log ).

      CATCH zcx_cloud_logger_error.
        cl_abap_unit_assert=>fail( 'Same parameters should not raise' ).
    ENDTRY.
  ENDMETHOD.

  METHOD get_instance_omitted_params.
    " Omitting optional parameters should not raise
    TRY.
        DATA(second) = zcl_cloud_logger=>get_instance(
          object    = 'Z_CLOUD_LOG_SAMPLE'
          subobject = 'SETUP' ).

        cl_abap_unit_assert=>assert_equals( act = second exp = mo_log ).

      CATCH zcx_cloud_logger_error.
        cl_abap_unit_assert=>fail( 'Omitted parameters should not raise' ).
    ENDTRY.
  ENDMETHOD.

  METHOD get_instance_conflict_db_save.
    TRY.
        zcl_cloud_logger=>get_instance(
          object    = 'Z_CLOUD_LOG_SAMPLE'
          subobject = 'SETUP'
          db_save   = abap_false ).

        cl_abap_unit_assert=>fail( 'Conflicting db_save should raise' ).

      CATCH zcx_cloud_logger_error.
        " expected
    ENDTRY.
  ENDMETHOD.

  METHOD get_instance_conflict_expiry.
    TRY.
        zcl_cloud_logger=>get_instance( object      = 'Z_CLOUD_LOG_SAMPLE'
                                        subobject   = 'SETUP'
                                        expiry_date = '20991231' ).

        cl_abap_unit_assert=>fail( 'Conflicting expiry_date should raise' ).

      CATCH zcx_cloud_logger_error.
        " expected
    ENDTRY.
  ENDMETHOD.

  METHOD long_string_not_truncated.

    DATA(long_text) = repeat( val = `x` occ = 500 ).

    mo_log->log_string_add( long_text ).

    " 1. Internal log πρέπει να έχει ολόκληρο το text
    DATA(messages) = mo_log->get_messages( ).
    READ TABLE messages INTO DATA(msg) INDEX 1.

    cl_abap_unit_assert=>assert_equals(
      act = strlen( msg-message )
      exp = 500
      msg = 'Full text should be preserved in internal log' ).

    " 2. BAPIRET2 export πρέπει να έχει ολόκληρο το text
    DATA(bapiret2) = mo_log->get_messages_as_bapiret2( ).
    READ TABLE bapiret2 INTO DATA(line) INDEX 1.

    cl_abap_unit_assert=>assert_equals(
      act = strlen( line-message )
      exp = 220   " το bapiret2-message είναι bapi_msg = 220 chars max
      msg = 'BAPIRET2 message should hold up to 220 chars (its native limit)' ).

    " 3. Flat export πρέπει να εμφανίζει το πλήρες text
    DATA(flat) = mo_log->get_messages_flat( ).
    READ TABLE flat INTO DATA(flat_line) INDEX 1.

    cl_abap_unit_assert=>assert_char_cp(
      act = flat_line
      exp = |*{ repeat( val = `x` occ = 100 ) }*|
      msg = 'Flat message should contain at least 100 of the x characters' ).

  ENDMETHOD.

  METHOD long_exception_not_trunc.
    TRY.
        RAISE EXCEPTION NEW cx_sy_zerodivide( ).
      CATCH cx_root INTO DATA(caught).
        mo_log->log_exception_add( exception = caught
                                   severity  = 'E' ).
    ENDTRY.

    DATA(messages) = mo_log->get_messages( ).
    READ TABLE messages INTO DATA(msg) INDEX 1.

    cl_abap_unit_assert=>assert_not_initial( act = msg-message
                                             msg = 'Exception text should be stored in internal log' ).

    cl_abap_unit_assert=>assert_char_cp( exp = '*divi*'
                                         act = msg-message
                                         msg = 'Exception text should mention division (full text not truncated)' ).
  ENDMETHOD.

  METHOD context_applies_to_all_methods.

    mo_log->set_context( 'Order 100' ).

    " Free text path
    mo_log->log_string_add( 'Free text msg' ).

    " Symsg path
    mo_log->log_message_add( symsg = VALUE #( msgty = 'W'
                                              msgid = 'CL'
                                              msgno = '000'
                                              msgv1 = 'Sym msg' ) ).

    " Exception path
    TRY.
        RAISE EXCEPTION NEW cx_sy_zerodivide( ).
      CATCH cx_root INTO DATA(caught).
        mo_log->log_exception_add( exception = caught
                                   severity  = 'E' ).
    ENDTRY.

    " BAPIRET2 path
    mo_log->log_bapiret2_structure_add( VALUE #( id     = 'Z_CLOUD_LOGGER'
                                                 type   = 'I'
                                                 number = '002'
                                                 message_v1 = 'BAPI msg' ) ).

    DATA(flat) = mo_log->get_messages_flat( ).

    cl_abap_unit_assert=>assert_equals( exp = 4
                                        act = lines( flat )
                                        msg = 'Should have 4 messages' ).

    LOOP AT flat INTO DATA(line).
      cl_abap_unit_assert=>assert_char_cp(
        act = line
        exp = '*[Order 100]*'
        msg = |Message #{ sy-tabix } should carry the context prefix| ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
