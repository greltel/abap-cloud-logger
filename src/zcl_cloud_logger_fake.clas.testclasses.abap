CLASS ltc_cloud_logger_fake DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zif_cloud_logger.

    METHODS setup.

    METHODS when_string_logged_then_kept    FOR TESTING RAISING cx_static_check.
    METHODS when_chained_then_all_kept      FOR TESTING RAISING cx_static_check.
    METHODS given_context_then_flat_prefix  FOR TESTING RAISING cx_static_check.
    METHODS given_min_sev_e_then_filtered   FOR TESTING RAISING cx_static_check.
    METHODS when_saved_then_counted         FOR TESTING RAISING cx_static_check.
    METHODS when_reset_then_empty_counted   FOR TESTING RAISING cx_static_check.
    METHODS given_freed_then_log_raises     FOR TESTING RAISING cx_static_check.
    METHODS given_message_then_searchable   FOR TESTING RAISING cx_static_check.
    METHODS given_error_then_queries_agree  FOR TESTING RAISING cx_static_check.
    METHODS when_rap_then_one_per_entry     FOR TESTING RAISING cx_static_check.
    METHODS given_no_bal_then_handle_empty  FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_cloud_logger_fake IMPLEMENTATION.

  METHOD setup.
    cut = NEW zcl_cloud_logger_fake( ).
  ENDMETHOD.

  METHOD when_string_logged_then_kept.
    cut->log_string_add( string = `hello`
                         msgty  = 'E' ).

    DATA(messages) = cut->get_messages( ).

    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-message
                                        exp = `hello`
                                        msg = `The fake must keep the logged text` ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-type
                                        exp = 'E'
                                        msg = `The fake must keep the severity` ).
  ENDMETHOD.

  METHOD when_chained_then_all_kept.
    DATA(chained) = cut->log_string_add( `one`
                       )->log_message_add( VALUE #( msgty = 'W' msgid = 'CL' msgno = '000' )
                       )->log_exception_add( NEW cx_sy_zerodivide( )
                       )->log_bapiret2_structure_add( VALUE #( type = 'S' id = 'CL' number = '000' )
                       )->log_data_add( VALUE bapiret2( type = 'I' ) ).

    cl_abap_unit_assert=>assert_equals( act = chained
                                        exp = cut
                                        msg = `Every fluent method must return the fake itself` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 5
                                        msg = `Every entry path must be recorded` ).
  ENDMETHOD.

  METHOD given_context_then_flat_prefix.
    cut->set_context( `Order 1` )->log_string_add( `checked` )->clear_context( )->log_string_add( `done` ).

    DATA(flat) = cut->get_messages_flat( ).

    cl_abap_unit_assert=>assert_equals( act = flat[ 1 ]
                                        exp = `[Order 1] checked`
                                        msg = `Context must prefix the flat rendering` ).
    cl_abap_unit_assert=>assert_equals( act = flat[ 2 ]
                                        exp = `done`
                                        msg = `Cleared context must leave the entry unprefixed` ).
  ENDMETHOD.

  METHOD given_min_sev_e_then_filtered.
    cut->log_bapiret2_table_add( bapiret2_t   = VALUE #( id = 'CL' number = '000'
                                                         ( type = 'S' ) ( type = 'W' ) ( type = 'E' ) ( type = 'A' ) )
                                 min_severity = 'E' ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 2
                                        msg = `The fake must apply the same severity filter as the logger` ).
  ENDMETHOD.

  METHOD when_saved_then_counted.
    cut->log_string_add( `x` )->save_application_log( )->save_application_log( ).

    cl_abap_unit_assert=>assert_equals( act = CAST zcl_cloud_logger_fake( cut )->save_calls
                                        exp = 2
                                        msg = `Every save must be counted` ).
  ENDMETHOD.

  METHOD when_reset_then_empty_counted.
    cut->log_string_add( `x` ).

    cut->reset_appl_log( ).

    cl_abap_unit_assert=>assert_equals( act = cut->log_is_empty( )
                                        exp = abap_true
                                        msg = `Reset must discard the entries` ).
    cl_abap_unit_assert=>assert_equals( act = CAST zcl_cloud_logger_fake( cut )->reset_calls
                                        exp = 1
                                        msg = `Every reset must be counted` ).
  ENDMETHOD.

  METHOD given_freed_then_log_raises.
    cut->free( ).

    TRY.
        cut->log_string_add( `after free` ).
        cl_abap_unit_assert=>fail( `The fake must mimic the released-instance contract` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>instance_released
                                            msg = `Use after free( ) must be reported as instance_released` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_message_then_searchable.
    cut->log_message_add( VALUE #( msgty = 'E' msgid = 'ZMY' msgno = '042' ) ).

    cl_abap_unit_assert=>assert_equals( act = cut->search_message( VALUE #( msgid = 'ZMY' msgno = '042' ) )
                                        exp = abap_true
                                        msg = `The logged message must be found by class and number` ).
    cl_abap_unit_assert=>assert_equals( act = cut->search_message( VALUE #( msgno = '043' ) )
                                        exp = abap_false
                                        msg = `A different number must not match` ).
  ENDMETHOD.

  METHOD given_error_then_queries_agree.
    cut->log_string_add( string = `bad`
                         msgty  = 'E' ).

    cl_abap_unit_assert=>assert_equals( act = cut->log_contains_error( )
                                        exp = abap_true
                                        msg = `An E entry must be reported as error` ).
    cl_abap_unit_assert=>assert_equals( act = cut->log_contains_warning( )
                                        exp = abap_true
                                        msg = `An E entry must also count as warning` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( 'E' )
                                        exp = 1
                                        msg = `The severity count must see the entry` ).
  ENDMETHOD.

  METHOD when_rap_then_one_per_entry.
    cut->log_string_add( `free text` )->log_message_add( VALUE #( msgty = 'E' msgid = 'CL' msgno = '000' ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( cut->get_messages_rap( ) )
                                        exp = 2
                                        msg = `RAP conversion must return one message per entry` ).
    cl_abap_unit_assert=>assert_equals( act = lines( cut->get_messages_as_bapiret2( ) )
                                        exp = 2
                                        msg = `BAPIRET2 conversion must return one line per entry` ).
  ENDMETHOD.

  METHOD given_no_bal_then_handle_empty.
    cl_abap_unit_assert=>assert_initial( act = cut->get_handle( )
                                         msg = `There is no Application Log behind the fake` ).
    cl_abap_unit_assert=>assert_not_bound( act = cut->get_log_handle( )
                                           msg = `There is no Application Log object behind the fake` ).
  ENDMETHOD.

ENDCLASS.
