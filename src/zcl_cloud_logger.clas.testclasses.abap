CLASS ltc_cloud_logger DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    CONSTANTS test_object    TYPE cl_bali_header_setter=>ty_object    VALUE 'Z_CLOUD_LOG_SAMPLE'.
    CONSTANTS test_subobject TYPE cl_bali_header_setter=>ty_subobject VALUE 'SETUP'.

    DATA cut TYPE REF TO zif_cloud_logger.

    METHODS setup    RAISING cx_static_check.
    METHODS teardown.

    " helpers
    METHODS add_warning
      IMPORTING !text TYPE symsgv
      RAISING   zcx_cloud_logger_error.
    METHODS add_error
      IMPORTING !text TYPE symsgv
      RAISING   zcx_cloud_logger_error.
    METHODS secondary_logger
      IMPORTING ext_number    TYPE cl_bali_header_setter=>ty_external_id
                trim_limit    TYPE i DEFAULT zif_cloud_logger=>c_default_trim_limit
      RETURNING VALUE(result) TYPE REF TO zif_cloud_logger
      RAISING   zcx_cloud_logger_error.

    " instantiation & configuration
    METHODS when_get_instance_then_bound    FOR TESTING RAISING cx_static_check.
    METHODS given_unknown_object_raises     FOR TESTING RAISING cx_static_check.
    METHODS given_no_object_db_save_raises  FOR TESTING RAISING cx_static_check.
    METHODS given_neg_trim_limit_raises     FOR TESTING RAISING cx_static_check.
    METHODS given_same_params_then_same     FOR TESTING RAISING cx_static_check.
    METHODS given_omitted_params_no_raise   FOR TESTING RAISING cx_static_check.
    METHODS given_db_save_diff_then_raises  FOR TESTING RAISING cx_static_check.
    METHODS given_expiry_diff_then_raises   FOR TESTING RAISING cx_static_check.
    METHODS given_trim_diff_then_raises     FOR TESTING RAISING cx_static_check.
    METHODS when_same_key_then_same_state   FOR TESTING RAISING cx_static_check.

    " adding entries
    METHODS when_all_paths_then_count_7     FOR TESTING RAISING cx_static_check.
    METHODS given_initial_symsg_ignored     FOR TESTING RAISING cx_static_check.
    METHODS given_bad_msgid_then_no_dump    FOR TESTING RAISING cx_static_check.
    METHODS when_chained_then_3_messages    FOR TESTING RAISING cx_static_check.
    METHODS given_empty_bapiret2_chain_ok   FOR TESTING RAISING cx_static_check.
    METHODS given_freed_then_log_raises     FOR TESTING RAISING cx_static_check.
    METHODS given_freed_then_save_raises    FOR TESTING RAISING cx_static_check.
    METHODS given_freed_then_reset_raises   FOR TESTING RAISING cx_static_check.
    METHODS given_freed_then_queries_empty  FOR TESTING RAISING cx_static_check.
    METHODS given_freed_twice_then_ok       FOR TESTING RAISING cx_static_check.
    METHODS given_freed_then_new_instance FOR TESTING RAISING cx_static_check.
    METHODS given_stale_free_then_new_kept  FOR TESTING RAISING cx_static_check.
    METHODS when_self_merge_then_unchanged  FOR TESTING RAISING cx_static_check.
    METHODS given_blank_msgty_then_warning  FOR TESTING RAISING cx_static_check.
    METHODS given_min_sev_e_then_keeps_2    FOR TESTING RAISING cx_static_check.
    METHODS when_log_data_then_json_entry   FOR TESTING RAISING cx_static_check.
    METHODS given_500_chars_then_kept       FOR TESTING RAISING cx_static_check.
    METHODS given_exception_text_kept       FOR TESTING RAISING cx_static_check.

    " querying
    METHODS given_new_then_is_empty         FOR TESTING RAISING cx_static_check.
    METHODS given_new_then_no_messages      FOR TESTING RAISING cx_static_check.
    METHODS given_error_then_contains_err   FOR TESTING RAISING cx_static_check.
    METHODS given_warn_then_contains_warn   FOR TESTING RAISING cx_static_check.
    METHODS given_msgid_when_search_found   FOR TESTING RAISING cx_static_check.
    METHODS given_other_msgno_search_false  FOR TESTING RAISING cx_static_check.
    METHODS given_full_key_when_found       FOR TESTING RAISING cx_static_check.
    METHODS when_count_by_type_then_exact   FOR TESTING RAISING cx_static_check.
    METHODS when_get_handle_then_filled     FOR TESTING RAISING cx_static_check.

    " context, timer, merge
    METHODS given_context_then_prefixed     FOR TESTING RAISING cx_static_check.
    METHODS given_context_all_paths_prefix  FOR TESTING RAISING cx_static_check.
    METHODS when_timer_stopped_then_logged  FOR TESTING RAISING cx_static_check.
    METHODS when_timer_twice_then_warns     FOR TESTING RAISING cx_static_check.
    METHODS when_merge_then_count_added     FOR TESTING RAISING cx_static_check.
    METHODS when_merge_then_returns_self    FOR TESTING RAISING cx_static_check.

    " saving, reset, trail
    METHODS when_save_then_returns_self     FOR TESTING RAISING cx_static_check.
    METHODS given_no_db_save_then_trail     FOR TESTING RAISING cx_static_check.
    METHODS given_50_saves_then_log_clean   FOR TESTING RAISING cx_static_check.
    METHODS given_trim_5_then_trail_5       FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_cloud_logger IMPLEMENTATION.

  METHOD setup.
    cut = zcl_cloud_logger=>get_instance( object    = test_object
                                          subobject = test_subobject
                                          db_save   = abap_true ).
    cut->reset_appl_log( ).
  ENDMETHOD.

  METHOD teardown.
    cut->free( ).
    CLEAR cut.
  ENDMETHOD.

  METHOD add_warning.
    cut->log_message_add( VALUE #( msgty = 'W'
                                   msgid = 'CL'
                                   msgno = '000'
                                   msgv1 = text ) ).
  ENDMETHOD.

  METHOD add_error.
    cut->log_message_add( VALUE #( msgty = 'E'
                                   msgid = 'CL'
                                   msgno = '000'
                                   msgv1 = text ) ).
  ENDMETHOD.

  METHOD secondary_logger.
    result = zcl_cloud_logger=>get_instance( object     = test_object
                                             subobject  = test_subobject
                                             ext_number = ext_number
                                             trim_limit = trim_limit
                                             db_save    = abap_false ).
  ENDMETHOD.

  METHOD when_get_instance_then_bound.
    cl_abap_unit_assert=>assert_bound( act = cut
                                       msg = `get_instance must return a logger` ).
  ENDMETHOD.

  METHOD given_unknown_object_raises.
    " Needs a real Application Log runtime that validates the object name
    TRY.
        zcl_cloud_logger=>get_instance( object    = 'Z_DUMMY_WRONG'
                                        subobject = 'Z_DUMMY_WRONG'
                                        db_save   = abap_true ).
        cl_abap_unit_assert=>fail( `Unknown Application Log object must raise` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>error_in_creation
                                            msg = `Unknown object must be reported as creation error` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_no_object_db_save_raises.
    TRY.
        zcl_cloud_logger=>get_instance( ext_number = 'NO_OBJECT'
                                        db_save    = abap_true ).
        cl_abap_unit_assert=>fail( `db_save without object must raise` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>object_required
                                            msg = `Missing object must be reported as object_required` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_neg_trim_limit_raises.
    TRY.
        secondary_logger( ext_number = 'INVALID'
                          trim_limit = -5 ).
        cl_abap_unit_assert=>fail( `Negative trim_limit must raise` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>invalid_trim_limit
                                            msg = `Negative trim_limit must be reported as invalid_trim_limit` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_same_params_then_same.
    DATA(second) = zcl_cloud_logger=>get_instance( object    = test_object
                                                   subobject = test_subobject
                                                   db_save   = abap_true ).

    cl_abap_unit_assert=>assert_equals( act = second
                                        exp = cut
                                        msg = `Identical parameters must return the registered instance` ).
  ENDMETHOD.

  METHOD given_omitted_params_no_raise.
    DATA(second) = zcl_cloud_logger=>get_instance( object    = test_object
                                                   subobject = test_subobject ).

    cl_abap_unit_assert=>assert_equals( act = second
                                        exp = cut
                                        msg = `Omitted parameters mean "no preference" and must not conflict` ).
  ENDMETHOD.

  METHOD given_db_save_diff_then_raises.
    TRY.
        zcl_cloud_logger=>get_instance( object    = test_object
                                        subobject = test_subobject
                                        db_save   = abap_false ).
        cl_abap_unit_assert=>fail( `Conflicting db_save must raise` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>config_mismatch
                                            msg = `Conflict must be reported as config_mismatch` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_expiry_diff_then_raises.
    TRY.
        zcl_cloud_logger=>get_instance( object      = test_object
                                        subobject   = test_subobject
                                        expiry_date = '20991231' ).
        cl_abap_unit_assert=>fail( `Conflicting expiry_date must raise` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>config_mismatch
                                            msg = `Conflict must be reported as config_mismatch` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_trim_diff_then_raises.
    TRY.
        zcl_cloud_logger=>get_instance( object     = test_object
                                        subobject  = test_subobject
                                        trim_limit = 50 ).
        cl_abap_unit_assert=>fail( `Conflicting trim_limit must raise` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>config_mismatch
                                            msg = `Conflict must be reported as config_mismatch` ).
    ENDTRY.
  ENDMETHOD.

  METHOD when_same_key_then_same_state.
    cut->log_bapiret2_table_add( VALUE #( id     = 'Z_CLOUD_LOGGER'
                                          type   = 'W'
                                          number = '002'
                                          ( message_v1 = 'BAPIS' )
                                          ( message_v1 = 'More' ) ) ).
    cut->log_exception_add( NEW cx_sy_itab_line_not_found( ) ).

    DATA(same_instance) = zcl_cloud_logger=>get_instance( object    = test_object
                                                          subobject = test_subobject ).

    cl_abap_unit_assert=>assert_equals( act = same_instance->get_message_count( )
                                        exp = 3
                                        msg = `The shared instance must see the entries added earlier` ).
    cl_abap_unit_assert=>assert_equals( act = lines( same_instance->get_messages_rap( ) )
                                        exp = 3
                                        msg = `RAP conversion must return one message per entry` ).
  ENDMETHOD.

  METHOD when_all_paths_then_count_7.
    add_warning( 'Test Message' ).
    cut->log_bapiret2_structure_add( VALUE #( id         = 'Z_CLOUD_LOGGER'
                                              type       = 'W'
                                              number     = '002'
                                              message_v1 = 'TEST' ) ).
    cut->log_bapiret2_table_add( VALUE #( id     = 'Z_CLOUD_LOGGER'
                                          type   = 'W'
                                          number = '002'
                                          ( message_v1 = 'BAPIS' )
                                          ( message_v1 = 'More' ) ) ).
    cut->log_exception_add( NEW cx_sy_itab_line_not_found( ) ).
    MESSAGE s003(z_cloud_logger) INTO DATA(dummy) ##NEEDED.
    cut->log_syst_add( ).
    cut->log_string_add( `Some freestyle text` ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 7
                                        msg = `Every entry path must produce exactly one internal entry` ).
    cl_abap_unit_assert=>assert_equals( act = lines( cut->get_messages_as_bapiret2( ) )
                                        exp = 7
                                        msg = `BAPIRET2 conversion must return one line per entry` ).
  ENDMETHOD.

  METHOD given_initial_symsg_ignored.
    DATA(chained) = cut->log_message_add( VALUE #( ) ).

    cl_abap_unit_assert=>assert_bound( act = chained
                                       msg = `Ignored call must still return the logger` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 0
                                        msg = `An initial symsg must not create an empty entry` ).
  ENDMETHOD.

  METHOD given_bad_msgid_then_no_dump.
    " Audit #19: text resolution for a message class that does not exist must
    " fall back instead of dumping. Verify in ADT that the BAL setter accepts
    " the key; if it raises cx_bali_runtime the entry is rejected before resolution.
    cut->log_message_add( VALUE #( msgty = 'E'
                                   msgid = 'ZZ_NO_SUCH_CLASS'
                                   msgno = '999'
                                   msgv1 = 'poison' ) ).

    DATA(flat) = cut->get_messages_flat( ).

    cl_abap_unit_assert=>assert_equals( act = lines( flat )
                                        exp = 1
                                        msg = `The entry must be kept even when its text cannot be resolved` ).
    cl_abap_unit_assert=>assert_not_initial( act = flat[ 1 ]
                                             msg = `Fallback rendering must not be empty` ).
    cl_abap_unit_assert=>assert_equals( act = lines( cut->get_messages_rap( ) )
                                        exp = 1
                                        msg = `RAP conversion must survive an unresolvable message class` ).
  ENDMETHOD.

  METHOD when_chained_then_3_messages.
    cut->log_string_add( `Message 1`
       )->log_string_add( `Message 2`
       )->log_string_add( `Message 3` ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 3
                                        msg = `Each link of the chain must add one entry` ).
  ENDMETHOD.

  METHOD given_empty_bapiret2_chain_ok.
    DATA(chained) = cut->log_bapiret2_structure_add( VALUE #( )
                       )->log_string_add( `after no-op` ).

    cl_abap_unit_assert=>assert_bound( act = chained
                                       msg = `Logger reference must stay bound after a no-op bapiret2 call` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 1
                                        msg = `Only the chained log_string_add must produce an entry` ).
  ENDMETHOD.

  METHOD given_freed_then_log_raises.
    cut->free( ).

    TRY.
        cut->log_string_add( `after free` ).
        cl_abap_unit_assert=>fail( `Logging on a released instance must raise` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>instance_released
                                            msg = `Use after free( ) must be reported as instance_released` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_freed_then_save_raises.
    cut->free( ).

    TRY.
        cut->save_application_log( ).
        cl_abap_unit_assert=>fail( `Saving a released instance must raise` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>instance_released
                                            msg = `Use after free( ) must be reported as instance_released` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_freed_then_reset_raises.
    cut->free( ).

    TRY.
        cut->reset_appl_log( ).
        cl_abap_unit_assert=>fail( `A released instance cannot be revived by reset_appl_log` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>instance_released
                                            msg = `Use after free( ) must be reported as instance_released` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_freed_then_queries_empty.
    cut->log_string_add( `before free` ).

    cut->free( ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 0
                                        msg = `Queries on a released instance must return empty results` ).
    cl_abap_unit_assert=>assert_equals( act = cut->log_is_empty( )
                                        exp = abap_true
                                        msg = `A released instance must report itself empty` ).
    cl_abap_unit_assert=>assert_initial( act = cut->get_handle( )
                                         msg = `The BAL handle must be gone after free( )` ).
    cl_abap_unit_assert=>assert_equals( act = cut->search_message( VALUE #( msgid = 'CL' ) )
                                        exp = abap_false
                                        msg = `Searching a released instance must not find anything` ).
  ENDMETHOD.

  METHOD given_freed_twice_then_ok.
    cut->free( ).

    cut->free( ).

    cl_abap_unit_assert=>assert_initial( act = cut->get_log_handle( )
                                         msg = `A second free( ) must be a harmless no-op` ).
  ENDMETHOD.

  METHOD given_freed_then_new_instance.
    DATA(released) = cut.
    released->free( ).

    cut = zcl_cloud_logger=>get_instance( object    = test_object
                                          subobject = test_subobject
                                          db_save   = abap_true ).
    cut->log_string_add( `on the fresh instance` ).

    cl_abap_unit_assert=>assert_equals( act = xsdbool( cut = released )
                                        exp = abap_false
                                        msg = `get_instance after free( ) must create a new instance` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 1
                                        msg = `The fresh instance must be fully usable` ).
  ENDMETHOD.

  METHOD given_stale_free_then_new_kept.
    DATA(stale) = cut.
    stale->free( ).
    cut = zcl_cloud_logger=>get_instance( object    = test_object
                                          subobject = test_subobject
                                          db_save   = abap_true ).

    stale->free( ).

    DATA(again) = zcl_cloud_logger=>get_instance( object    = test_object
                                                  subobject = test_subobject
                                                  db_save   = abap_true ).

    cl_abap_unit_assert=>assert_equals( act = again
                                        exp = cut
                                        msg = `free( ) on a stale reference must not drop the registered instance` ).
  ENDMETHOD.

  METHOD when_self_merge_then_unchanged.
    cut->log_string_add( `only one` ).

    DATA(chained) = cut->merge_logs( cut ).

    cl_abap_unit_assert=>assert_bound( act = chained
                                       msg = `Self-merge must still return the logger` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 1
                                        msg = `Merging a logger into itself must not duplicate entries` ).
  ENDMETHOD.

  METHOD given_blank_msgty_then_warning.
    cut->log_message_add( VALUE #( msgid = 'CL'
                                   msgno = '000'
                                   msgv1 = 'no severity given' ) ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( zif_cloud_logger=>c_message_type-warning )
                                        exp = 1
                                        msg = `A message without severity must default to warning` ).
    cl_abap_unit_assert=>assert_equals( act = cut->log_contains_warning( )
                                        exp = abap_true
                                        msg = `The defaulted entry must be visible to the severity queries` ).
  ENDMETHOD.

  METHOD given_min_sev_e_then_keeps_2.
    DATA(bapiret2) = VALUE zif_cloud_logger=>bapiret2_messages(
        id     = 'Z_CLOUD_LOGGER'
        number = '002'
        ( type = 'S' message_v1 = 'Success Msg' )
        ( type = 'W' message_v1 = 'Warning Msg' )
        ( type = 'E' message_v1 = 'Error Msg' )
        ( type = 'A' message_v1 = 'Abort Msg' ) ).

    cut->log_bapiret2_table_add( bapiret2_t   = bapiret2
                                 min_severity = 'E' ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 2
                                        msg = `min_severity E must keep only E and A` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( 'S' ) + cut->get_message_count( 'W' )
                                        exp = 0
                                        msg = `S and W entries must be filtered out` ).
  ENDMETHOD.

  METHOD when_log_data_then_json_entry.
    TYPES: BEGIN OF dummy_line,
             id     TYPE i,
             name   TYPE string,
             active TYPE abap_bool,
           END OF dummy_line.
    DATA dummy_data TYPE STANDARD TABLE OF dummy_line WITH EMPTY KEY.

    dummy_data = VALUE #( ( id = 100 name = 'Alpha' active = abap_true )
                          ( id = 200 name = 'Beta'  active = abap_false ) ).

    cut->log_data_add( dummy_data ).

    DATA(flat) = cut->get_messages_flat( ).

    cl_abap_unit_assert=>assert_equals( act = lines( flat )
                                        exp = 1
                                        msg = `The whole table must be logged as one entry` ).
    cl_abap_unit_assert=>assert_char_cp( act = flat[ 1 ]
                                         exp = '*"id":100*'
                                         msg = `JSON must contain the first id` ).
    cl_abap_unit_assert=>assert_char_cp( act = flat[ 1 ]
                                         exp = '*"name":"Alpha"*'
                                         msg = `JSON must contain the first name` ).
  ENDMETHOD.

  METHOD given_500_chars_then_kept.
    DATA(long_text) = repeat( val = `x`
                              occ = 500 ).

    cut->log_string_add( long_text ).

    DATA(messages) = cut->get_messages( ).
    DATA(bapiret2) = cut->get_messages_as_bapiret2( ).
    DATA(flat)     = cut->get_messages_flat( ).

    cl_abap_unit_assert=>assert_equals( act = strlen( messages[ 1 ]-message )
                                        exp = 500
                                        msg = `Internal log must keep the full text` ).
    cl_abap_unit_assert=>assert_equals( act = strlen( bapiret2[ 1 ]-message )
                                        exp = 220
                                        msg = `BAPIRET2 message is limited to its native 220 characters` ).
    cl_abap_unit_assert=>assert_equals( act = strlen( flat[ 1 ] )
                                        exp = 500
                                        msg = `Flat rendering of free text must keep the full text` ).
  ENDMETHOD.

  METHOD given_exception_text_kept.
    TRY.
        RAISE EXCEPTION NEW cx_sy_zerodivide( ).
      CATCH cx_sy_zerodivide INTO DATA(caught).
        cut->log_exception_add( exception = caught
                                severity  = 'E' ).
    ENDTRY.

    DATA(messages) = cut->get_messages( ).

    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-message
                                        exp = caught->get_text( )
                                        msg = `Internal log must hold the full exception text` ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-type
                                        exp = 'E'
                                        msg = `Severity passed for the exception must be kept` ).
  ENDMETHOD.

  METHOD given_new_then_is_empty.
    cl_abap_unit_assert=>assert_equals( act = cut->log_is_empty( )
                                        exp = abap_true
                                        msg = `A freshly reset logger must be empty` ).
  ENDMETHOD.

  METHOD given_new_then_no_messages.
    cl_abap_unit_assert=>assert_equals( act = cut->log_contains_messages( )
                                        exp = abap_false
                                        msg = `A freshly reset logger must not contain messages` ).
  ENDMETHOD.

  METHOD given_error_then_contains_err.
    add_warning( 'Test Message 1' ).
    add_error( 'Test Message 2' ).

    cl_abap_unit_assert=>assert_equals( act = cut->log_contains_error( )
                                        exp = abap_true
                                        msg = `An E entry must be reported as error` ).
  ENDMETHOD.

  METHOD given_warn_then_contains_warn.
    add_warning( 'Test Message 1' ).

    cl_abap_unit_assert=>assert_equals( act = cut->log_contains_warning( )
                                        exp = abap_true
                                        msg = `A W entry must be reported as warning` ).
    cl_abap_unit_assert=>assert_equals( act = cut->log_contains_error( )
                                        exp = abap_false
                                        msg = `A W entry alone must not be reported as error` ).
  ENDMETHOD.

  METHOD given_msgid_when_search_found.
    add_warning( 'Test Message 1' ).

    cl_abap_unit_assert=>assert_equals( act = cut->search_message( VALUE #( msgid = 'CL' ) )
                                        exp = abap_true
                                        msg = `Search by message class alone must find the entry` ).
  ENDMETHOD.

  METHOD given_other_msgno_search_false.
    add_warning( 'Test Message 1' ).

    cl_abap_unit_assert=>assert_equals( act = cut->search_message( VALUE #( msgno = '003' ) )
                                        exp = abap_false
                                        msg = `A different message number must not match` ).
  ENDMETHOD.

  METHOD given_full_key_when_found.
    add_warning( 'Test Message 1' ).

    cl_abap_unit_assert=>assert_equals( act = cut->search_message( VALUE #( msgid = 'CL'
                                                                            msgno = '000'
                                                                            msgty = 'W' ) )
                                        exp = abap_true
                                        msg = `Search by class, number and type must find the entry` ).
  ENDMETHOD.

  METHOD when_count_by_type_then_exact.
    cut->log_string_add( string = `warning one`
                         msgty  = 'W' ).
    cut->log_string_add( string = `error one`
                         msgty  = 'E' ).
    cut->log_string_add( string = `error two`
                         msgty  = 'E' ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 3
                                        msg = `Unfiltered count must return all entries` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( 'E' )
                                        exp = 2
                                        msg = `Filtered count must return only errors` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( 'A' )
                                        exp = 0
                                        msg = `Filtered count for an absent type must be zero` ).
  ENDMETHOD.

  METHOD when_get_handle_then_filled.
    cl_abap_unit_assert=>assert_not_initial( act = cut->get_handle( )
                                             msg = `A live logger must expose its BAL handle` ).
    cl_abap_unit_assert=>assert_bound( act = cut->get_log_handle( )
                                       msg = `A live logger must expose its if_bali_log object` ).
  ENDMETHOD.

  METHOD given_context_then_prefixed.
    cut->set_context( `Order 100` ).
    cut->log_string_add( `Validation started` ).
    cut->log_string_add( `Price checked` ).
    cut->set_context( `Order 200` ).
    cut->log_string_add( `Stock error` ).
    cut->clear_context( ).
    cut->log_string_add( `Process finished` ).

    DATA(flat) = cut->get_messages_flat( ).

    cl_abap_unit_assert=>assert_equals( act = flat[ 1 ]
                                        exp = `[Order 100] Validation started`
                                        msg = `First context must prefix the first entry` ).
    cl_abap_unit_assert=>assert_equals( act = flat[ 3 ]
                                        exp = `[Order 200] Stock error`
                                        msg = `Changed context must prefix later entries` ).
    cl_abap_unit_assert=>assert_equals( act = flat[ 4 ]
                                        exp = `Process finished`
                                        msg = `Cleared context must leave the entry unprefixed` ).
  ENDMETHOD.

  METHOD given_context_all_paths_prefix.
    cut->set_context( `Order 100` ).

    cut->log_string_add( `Free text msg` ).
    add_warning( 'Sym msg' ).
    cut->log_exception_add( NEW cx_sy_zerodivide( ) ).
    cut->log_bapiret2_structure_add( VALUE #( id         = 'Z_CLOUD_LOGGER'
                                              type       = 'I'
                                              number     = '002'
                                              message_v1 = 'BAPI msg' ) ).

    DATA(flat) = cut->get_messages_flat( ).

    cl_abap_unit_assert=>assert_equals( act = lines( flat )
                                        exp = 4
                                        msg = `All four entry paths must produce an entry` ).
    LOOP AT flat INTO DATA(line).
      cl_abap_unit_assert=>assert_char_cp( act = line
                                           exp = '[Order 100]*'
                                           msg = |Entry { sy-tabix } must carry the context prefix| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD when_timer_stopped_then_logged.
    cut->start_timer( ).
    cut->stop_timer( `Test Operation` ).

    DATA(flat) = cut->get_messages_flat( ).

    cl_abap_unit_assert=>assert_equals( act = lines( flat )
                                        exp = 1
                                        msg = `stop_timer must log exactly one entry` ).
    cl_abap_unit_assert=>assert_char_cp( act = flat[ 1 ]
                                         exp = '*Test Operation*'
                                         msg = `Timer entry must carry the label` ).
  ENDMETHOD.

  METHOD when_timer_twice_then_warns.
    cut->start_timer( ).
    cut->start_timer( ).

    DATA(flat) = cut->get_messages_flat( ).

    cl_abap_unit_assert=>assert_equals( act = lines( flat )
                                        exp = 1
                                        msg = `Second start_timer must log a warning` ).
    cl_abap_unit_assert=>assert_char_cp( act = flat[ 1 ]
                                         exp = '*previous timer reset*'
                                         msg = `Warning text must explain the reset` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( 'W' )
                                        exp = 1
                                        msg = `The double-start entry must be a warning` ).
  ENDMETHOD.

  METHOD when_merge_then_count_added.
    DATA(second) = secondary_logger( '1234' ).

    TRY.
        MESSAGE e005(z_cloud_logger) INTO DATA(dummy) ##NEEDED.
        second->log_syst_add( ).

        cut->merge_logs( second ).

        cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                            exp = 1
                                            msg = `Merged entry must appear in the target logger` ).
        cl_abap_unit_assert=>assert_equals( act = second->get_message_count( )
                                            exp = 1
                                            msg = `Source logger must be left unchanged` ).

      CLEANUP.
        second->free( ).
    ENDTRY.
    second->free( ).
  ENDMETHOD.

  METHOD when_merge_then_returns_self.
    DATA(chained) = cut->merge_logs( VALUE #( ) )->log_string_add( `after merge` ).

    cl_abap_unit_assert=>assert_bound( act = chained
                                       msg = `merge_logs must return the logger for chaining` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 1
                                        msg = `Unbound merge input must be ignored, the chain must continue` ).
  ENDMETHOD.

  METHOD when_save_then_returns_self.
    " Writes through the real Application Log until the persistence seam of
    " phase 2 makes this DB-free.
    DATA(chained) = cut->log_string_add( `Message to save`
                       )->save_application_log( ).

    cl_abap_unit_assert=>assert_bound( act = chained
                                       msg = `save_application_log must return the logger for chaining` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 1
                                        msg = `Saving must not alter the internal log` ).
  ENDMETHOD.

  METHOD given_no_db_save_then_trail.
    DATA(no_save_logger) = secondary_logger( 'NO_SAVE' ).

    TRY.
        no_save_logger->save_application_log( ).

        cl_abap_unit_assert=>assert_equals( act = no_save_logger->get_message_count( )
                                            exp = 0
                                            msg = `The no-op save must not pollute the user-facing log` ).
        cl_abap_unit_assert=>assert_equals( act = lines( no_save_logger->get_internal_errors( ) )
                                            exp = 1
                                            msg = `The no-op save must be visible in the internal trail` ).

      CLEANUP.
        no_save_logger->free( ).
    ENDTRY.
    no_save_logger->free( ).
  ENDMETHOD.

  METHOD given_50_saves_then_log_clean.
    DATA(no_save_logger) = secondary_logger( 'LOOP_TEST' ).

    TRY.
        DO 50 TIMES.
          no_save_logger->save_application_log( ).
        ENDDO.

        cl_abap_unit_assert=>assert_equals( act = no_save_logger->get_message_count( )
                                            exp = 0
                                            msg = `50 no-op saves must produce 0 user-facing entries` ).
        cl_abap_unit_assert=>assert_equals( act = lines( no_save_logger->get_internal_errors( ) )
                                            exp = 50
                                            msg = `Every no-op save must be trailed while below the cap` ).

      CLEANUP.
        no_save_logger->free( ).
    ENDTRY.
    no_save_logger->free( ).
  ENDMETHOD.

  METHOD given_trim_5_then_trail_5.
    DATA(small_logger) = secondary_logger( ext_number = 'TRIM_5'
                                           trim_limit = 5 ).

    TRY.
        DO 10 TIMES.
          small_logger->save_application_log( ).
        ENDDO.

        cl_abap_unit_assert=>assert_equals( act = lines( small_logger->get_internal_errors( ) )
                                            exp = 5
                                            msg = `trim_limit 5 must cap the trail at 5 entries` ).

      CLEANUP.
        small_logger->free( ).
    ENDTRY.
    small_logger->free( ).
  ENDMETHOD.

ENDCLASS.


"! Fixed environment: date, time, user and message are constants, now( ) hands
"! out the queued time stamps in order and repeats the last one when the queue
"! is empty. Hand-written because the off-stack runtime has no cl_abap_testdouble
"! and because a scripted sequence of time stamps is clearer this way.
CLASS ltd_fixed_system DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_cloud_logger_system.

    CONSTANTS fixed_date TYPE d       VALUE '20260916'.
    CONSTANTS fixed_time TYPE t       VALUE '101500'.
    CONSTANTS fixed_user TYPE syuname VALUE 'TESTUSER'.
    CONSTANTS first_now  TYPE timestampl VALUE '20260916101500.0000000'.
    CONSTANTS second_now TYPE timestampl VALUE '20260916101502.0000000'.
    "! Half a second before midnight and one second after, for the day-boundary test
    CONSTANTS before_midnight TYPE timestampl VALUE '20260916235959.5000000'.
    CONSTANTS after_midnight  TYPE timestampl VALUE '20260917000001.0000000'.

    TYPES time_stamps TYPE STANDARD TABLE OF timestampl WITH EMPTY KEY.

    "! Time stamps not yet handed out by now( )
    DATA queued_stamps TYPE time_stamps READ-ONLY.

    METHODS queue_stamps
      IMPORTING stamps TYPE time_stamps.
    METHODS set_message
      IMPORTING !message TYPE symsg.

  PRIVATE SECTION.
    DATA last_stamp TYPE timestampl VALUE first_now.
    DATA message    TYPE symsg.
ENDCLASS.


CLASS ltd_fixed_system IMPLEMENTATION.

  METHOD queue_stamps.
    queued_stamps = stamps.
  ENDMETHOD.

  METHOD set_message.
    me->message = message.
  ENDMETHOD.

  METHOD zif_cloud_logger_system~system_date.
    result = fixed_date.
  ENDMETHOD.

  METHOD zif_cloud_logger_system~system_time.
    result = fixed_time.
  ENDMETHOD.

  METHOD zif_cloud_logger_system~now.
    IF queued_stamps IS NOT INITIAL.
      last_stamp = queued_stamps[ 1 ].
      DELETE queued_stamps INDEX 1.
    ENDIF.
    result = last_stamp.
  ENDMETHOD.

  METHOD zif_cloud_logger_system~user_name.
    result = fixed_user.
  ENDMETHOD.

  METHOD zif_cloud_logger_system~current_message.
    result = message.
  ENDMETHOD.

ENDCLASS.


"! Records every persistence call and can be told to fail the next one.
CLASS ltd_persistence_spy DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_cloud_logger_persistence.

    DATA save_calls           TYPE i                   READ-ONLY.
    DATA delete_calls         TYPE i                   READ-ONLY.
    DATA saved_log            TYPE REF TO if_bali_log  READ-ONLY.
    DATA saved_on_2nd_db_conn TYPE abap_boolean        READ-ONLY.
    DATA saved_to_appl_job    TYPE abap_boolean        READ-ONLY.

    METHODS fail_next_save.
    METHODS fail_next_delete.

  PRIVATE SECTION.
    DATA fail_save   TYPE abap_boolean.
    DATA fail_delete TYPE abap_boolean.
ENDCLASS.


"! cx_bali_runtime is abstract, so the spy raises this concrete stand-in.
CLASS ltd_bali_failure DEFINITION FINAL FOR TESTING
  INHERITING FROM cx_bali_runtime.
ENDCLASS.


CLASS ltd_bali_failure IMPLEMENTATION.
ENDCLASS.


CLASS ltd_persistence_spy IMPLEMENTATION.

  METHOD fail_next_save.
    fail_save = abap_true.
  ENDMETHOD.

  METHOD fail_next_delete.
    fail_delete = abap_true.
  ENDMETHOD.

  METHOD zif_cloud_logger_persistence~save_log.
    save_calls += 1.
    saved_log            = log.
    saved_on_2nd_db_conn = use_2nd_db_connection.
    saved_to_appl_job    = assign_to_current_appl_job.
    IF fail_save = abap_true.
      RAISE EXCEPTION NEW ltd_bali_failure( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_cloud_logger_persistence~delete_log.
    delete_calls += 1.
    IF fail_delete = abap_true.
      RAISE EXCEPTION NEW ltd_bali_failure( ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


"! Pure unit tests: the logger is built directly with doubles (local friend of
"! the CREATE PRIVATE class), so nothing here touches the clock, the user
"! context or the database.
CLASS ltc_cloud_logger_isolated DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    CONSTANTS test_object    TYPE cl_bali_header_setter=>ty_object    VALUE 'Z_CLOUD_LOG_SAMPLE'.
    CONSTANTS test_subobject TYPE cl_bali_header_setter=>ty_subobject VALUE 'SETUP'.

    DATA cut         TYPE REF TO zif_cloud_logger.
    DATA system      TYPE REF TO ltd_fixed_system.
    DATA persistence TYPE REF TO ltd_persistence_spy.

    METHODS setup    RAISING cx_static_check.
    METHODS teardown.

    METHODS create_logger
      IMPORTING db_save       TYPE abap_boolean DEFAULT abap_true
      RETURNING VALUE(result) TYPE REF TO zif_cloud_logger
      RAISING   zcx_cloud_logger_error.

    METHODS given_fixed_env_then_stamped    FOR TESTING RAISING cx_static_check.
    METHODS given_2s_clock_then_timer_text    FOR TESTING RAISING cx_static_check.
    METHODS given_midnight_clock_then_1_5   FOR TESTING RAISING cx_static_check.
    METHODS given_trail_then_fixed_stamp    FOR TESTING RAISING cx_static_check.
    METHODS given_sy_message_then_logged    FOR TESTING RAISING cx_static_check.
    METHODS given_no_sy_message_ignored     FOR TESTING RAISING cx_static_check.
    METHODS when_save_then_persisted_once   FOR TESTING RAISING cx_static_check.
    METHODS when_save_then_flags_passed     FOR TESTING RAISING cx_static_check.
    METHODS given_no_db_save_no_persist     FOR TESTING RAISING cx_static_check.
    METHODS given_save_fails_then_raises    FOR TESTING RAISING cx_static_check.
    METHODS given_reset_db_then_deleted     FOR TESTING RAISING cx_static_check.
    METHODS given_reset_no_db_no_delete     FOR TESTING RAISING cx_static_check.
    METHODS given_delete_fails_then_trail   FOR TESTING RAISING cx_static_check.
    METHODS when_merge_then_trail_ordered   FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS zcl_cloud_logger DEFINITION LOCAL FRIENDS ltc_cloud_logger_isolated.


CLASS ltc_cloud_logger_isolated IMPLEMENTATION.

  METHOD setup.
    system      = NEW #( ).
    persistence = NEW #( ).
    cut         = create_logger( ).
  ENDMETHOD.

  METHOD teardown.
    cut->free( ).
    CLEAR cut.
    CLEAR system.
    CLEAR persistence.
  ENDMETHOD.

  METHOD create_logger.
    " Built directly, so the instance is not registered in the multiton and
    " cannot collide with the integration tests above.
    result = NEW zcl_cloud_logger( object      = test_object
                                   subobject   = test_subobject
                                   ext_number  = 'ISOLATED'
                                   db_save     = db_save
                                   system      = system
                                   persistence = persistence ).
  ENDMETHOD.

  METHOD given_fixed_env_then_stamped.
    cut->log_string_add( `stamped` ).

    DATA(messages) = cut->get_messages( ).
    DATA(entry)    = messages[ 1 ].

    cl_abap_unit_assert=>assert_equals( act = entry-date
                                        exp = ltd_fixed_system=>fixed_date
                                        msg = `Entry date must come from the injected system` ).
    cl_abap_unit_assert=>assert_equals( act = entry-time
                                        exp = ltd_fixed_system=>fixed_time
                                        msg = `Entry time must come from the injected system` ).
    cl_abap_unit_assert=>assert_equals( act = entry-user_name
                                        exp = ltd_fixed_system=>fixed_user
                                        msg = `Entry user must come from the injected system` ).
  ENDMETHOD.

  METHOD given_2s_clock_then_timer_text.
    system->queue_stamps( VALUE #( ( ltd_fixed_system=>first_now )
                                   ( ltd_fixed_system=>second_now ) ) ).

    cut->start_timer( )->stop_timer( `Block A` ).

    DATA(flat) = cut->get_messages_flat( ).

    cl_abap_unit_assert=>assert_equals( act = lines( flat )
                                        exp = 1
                                        msg = `stop_timer must log exactly one entry` ).
    " '+' matches the decimal separator of the executing user's format settings
    cl_abap_unit_assert=>assert_char_cp( act = flat[ 1 ]
                                         exp = '*Block A took 2+000 seconds*'
                                         msg = `Elapsed time must be computed from the injected time stamps` ).
    cl_abap_unit_assert=>assert_initial( act = system->queued_stamps
                                         msg = `start_timer and stop_timer must each read the injected clock once` ).
  ENDMETHOD.

  METHOD given_midnight_clock_then_1_5.
    system->queue_stamps( VALUE #( ( ltd_fixed_system=>before_midnight )
                                   ( ltd_fixed_system=>after_midnight ) ) ).

    cut->start_timer( )->stop_timer( `Night run` ).

    DATA(flat) = cut->get_messages_flat( ).

    cl_abap_unit_assert=>assert_char_cp( act = flat[ 1 ]
                                         exp = '*Night run took 1+500 seconds*'
                                         msg = `Elapsed time must be correct across a day boundary` ).
  ENDMETHOD.

  METHOD given_trail_then_fixed_stamp.
    DATA(no_save_logger) = create_logger( abap_false ).

    no_save_logger->save_application_log( ).

    DATA(trail) = no_save_logger->get_internal_errors( ).

    cl_abap_unit_assert=>assert_equals( act = lines( trail )
                                        exp = 1
                                        msg = `The no-op save must leave one trail entry` ).
    cl_abap_unit_assert=>assert_equals( act = trail[ 1 ]-timestamp
                                        exp = ltd_fixed_system=>first_now
                                        msg = `Trail time stamp must come from the injected system` ).
  ENDMETHOD.

  METHOD given_sy_message_then_logged.
    DATA(sy_message) = VALUE symsg( msgty = 'E'
                                    msgid = 'CL'
                                    msgno = '000'
                                    msgv1 = 'from sy' ).
    system->set_message( sy_message ).

    cut->log_syst_add( ).

    DATA(messages) = cut->get_messages( ).
    DATA(entry)    = messages[ 1 ].

    cl_abap_unit_assert=>assert_equals( act = entry-symsg
                                        exp = sy_message
                                        msg = `log_syst_add must log the message provided by the system` ).
    cl_abap_unit_assert=>assert_equals( act = entry-type
                                        exp = 'E'
                                        msg = `Severity must be taken from the SY message type` ).
  ENDMETHOD.

  METHOD given_no_sy_message_ignored.
    system->set_message( VALUE #( ) ).

    DATA(chained) = cut->log_syst_add( ).

    cl_abap_unit_assert=>assert_bound( act = chained
                                       msg = `log_syst_add must stay chainable when SY is empty` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 0
                                        msg = `An empty SY message must not produce a blank entry` ).
  ENDMETHOD.

  METHOD when_save_then_persisted_once.
    cut->log_string_add( `to be saved` ).

    cut->save_application_log( ).

    cl_abap_unit_assert=>assert_equals( act = persistence->save_calls
                                        exp = 1
                                        msg = `save_application_log must call the persistence exactly once` ).
    cl_abap_unit_assert=>assert_equals( act = persistence->saved_log
                                        exp = cut->get_log_handle( )
                                        msg = `The logger's own Application Log must be handed to the persistence` ).
  ENDMETHOD.

  METHOD when_save_then_flags_passed.
    cut->save_application_log( use_2nd_db_connection      = abap_true
                               assign_to_current_appl_job = abap_true ).

    cl_abap_unit_assert=>assert_equals( act = persistence->saved_on_2nd_db_conn
                                        exp = abap_true
                                        msg = `use_2nd_db_connection must be forwarded` ).
    cl_abap_unit_assert=>assert_equals( act = persistence->saved_to_appl_job
                                        exp = abap_true
                                        msg = `assign_to_current_appl_job must be forwarded` ).
  ENDMETHOD.

  METHOD given_no_db_save_no_persist.
    DATA(no_save_logger) = create_logger( abap_false ).

    no_save_logger->save_application_log( ).

    cl_abap_unit_assert=>assert_equals( act = persistence->save_calls
                                        exp = 0
                                        msg = `db_save = abap_false must never reach the persistence` ).
  ENDMETHOD.

  METHOD given_save_fails_then_raises.
    persistence->fail_next_save( ).

    TRY.
        cut->save_application_log( ).
        cl_abap_unit_assert=>fail( `A failing persistence must surface as zcx_cloud_logger_error` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>error_release
                                            msg = `Save failures must be reported as error_release` ).
        cl_abap_unit_assert=>assert_bound( act = error->previous
                                           msg = `The original cx_bali_runtime must be chained as previous` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_reset_db_then_deleted.
    cut->log_string_add( `before reset` ).

    cut->reset_appl_log( abap_true ).

    cl_abap_unit_assert=>assert_equals( act = persistence->delete_calls
                                        exp = 1
                                        msg = `delete_from_db = abap_true must delete the persisted log once` ).
    cl_abap_unit_assert=>assert_equals( act = cut->log_is_empty( )
                                        exp = abap_true
                                        msg = `The reset logger must start empty` ).
  ENDMETHOD.

  METHOD given_reset_no_db_no_delete.
    cut->reset_appl_log( ).

    cl_abap_unit_assert=>assert_equals( act = persistence->delete_calls
                                        exp = 0
                                        msg = `A plain reset must not touch the database` ).
  ENDMETHOD.

  METHOD when_merge_then_trail_ordered.
    " The other logger's no-op is stamped earlier than ours, so after the merge
    " it must come first even though it was appended last.
    system->queue_stamps( VALUE #( ( ltd_fixed_system=>second_now )
                                   ( ltd_fixed_system=>first_now ) ) ).
    DATA(target) = create_logger( abap_false ).
    DATA(other)  = create_logger( abap_false ).
    target->save_application_log( ).
    other->save_application_log( ).

    target->merge_logs( other ).

    DATA(trail) = target->get_internal_errors( ).

    cl_abap_unit_assert=>assert_equals( act = lines( trail )
                                        exp = 2
                                        msg = `Both trails must be merged` ).
    cl_abap_unit_assert=>assert_equals( act = trail[ 1 ]-timestamp
                                        exp = ltd_fixed_system=>first_now
                                        msg = `The merged trail must be chronological` ).
  ENDMETHOD.

  METHOD given_delete_fails_then_trail.
    persistence->fail_next_delete( ).

    cut->reset_appl_log( abap_true ).

    cl_abap_unit_assert=>assert_bound( act = cut->get_log_handle( )
                                       msg = `A failed delete must not prevent the reset itself` ).
    cl_abap_unit_assert=>assert_equals( act = lines( cut->get_internal_errors( ) )
                                        exp = 1
                                        msg = `The failed delete must be recorded in the internal trail` ).
  ENDMETHOD.

ENDCLASS.
