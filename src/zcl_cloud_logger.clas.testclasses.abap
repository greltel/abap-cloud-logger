"! Exception without if_t100_message, to exercise the free-text path
CLASS lth_plain_failure DEFINITION FINAL FOR TESTING
  INHERITING FROM cx_static_check.
ENDCLASS.


CLASS lth_plain_failure IMPLEMENTATION.
ENDCLASS.


"! T100 exception whose key names a numeric attribute
CLASS lth_counted_failure DEFINITION FINAL FOR TESTING
  INHERITING FROM cx_static_check.

  PUBLIC SECTION.
    INTERFACES if_t100_message.

    DATA item_count TYPE i READ-ONLY.

    METHODS constructor
      IMPORTING item_count TYPE i.

ENDCLASS.


CLASS lth_counted_failure IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    me->item_count = item_count.
    if_t100_message~t100key = VALUE #( msgid = 'Z_CLOUD_LOGGER'
                                       msgno = '003'
                                       attr1 = 'ITEM_COUNT' ).
  ENDMETHOD.

ENDCLASS.


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
    METHODS given_no_object_then_raises     FOR TESTING RAISING cx_static_check.
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
    METHODS given_t100_exception_then_key   FOR TESTING RAISING cx_static_check.
    METHODS given_dyn_exception_then_vars   FOR TESTING RAISING cx_static_check.
    METHODS given_plain_exception_no_key    FOR TESTING RAISING cx_static_check.
    METHODS given_free_text_then_rap_wrap   FOR TESTING RAISING cx_static_check.
    METHODS given_abort_then_contains_err   FOR TESTING RAISING cx_static_check.
    METHODS when_display_unbound_no_dump    FOR TESTING RAISING cx_static_check.
    METHODS given_error_then_object_known   FOR TESTING RAISING cx_static_check.
    METHODS given_msgno_000_then_t100_kept   FOR TESTING RAISING cx_static_check.
    METHODS given_saved_then_load_same  FOR TESTING RAISING cx_static_check.
    METHODS given_active_when_load_raises    FOR TESTING RAISING cx_static_check.
    METHODS given_bad_handle_load_raises FOR TESTING RAISING cx_static_check.
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
    METHODS given_other_freed_then_kept     FOR TESTING RAISING cx_static_check.

    " severities
    METHODS given_blank_str_sev_then_w      FOR TESTING RAISING cx_static_check.
    METHODS given_blank_exc_sev_then_e      FOR TESTING RAISING cx_static_check.
    METHODS given_lower_sev_then_upper      FOR TESTING RAISING cx_static_check.
    METHODS given_lower_min_sev_filters     FOR TESTING RAISING cx_static_check.
    METHODS given_lower_row_type_kept       FOR TESTING RAISING cx_static_check.
    METHODS given_min_sev_w_then_keeps_3    FOR TESTING RAISING cx_static_check.
    METHODS given_min_sev_a_then_keeps_a_x  FOR TESTING RAISING cx_static_check.
    METHODS given_min_sev_x_then_keeps_a_x  FOR TESTING RAISING cx_static_check.
    METHODS given_min_sev_i_then_keeps_all  FOR TESTING RAISING cx_static_check.

    " BAPI return rows
    METHODS given_text_only_ret2_then_kept  FOR TESTING RAISING cx_static_check.
    METHODS given_type_only_ret2_ignored    FOR TESTING RAISING cx_static_check.
    METHODS given_blank_ret2_type_then_s    FOR TESTING RAISING cx_static_check.
    METHODS given_unknown_ret2_then_text    FOR TESTING RAISING cx_static_check.

    " conversions and queries
    METHODS given_blank_at_50_then_kept     FOR TESTING RAISING cx_static_check.
    METHODS given_int_attr_then_unpadded    FOR TESTING RAISING cx_static_check.
    METHODS given_unbound_exc_ignored       FOR TESTING RAISING cx_static_check.
    METHODS given_msgv_search_then_matched  FOR TESTING RAISING cx_static_check.
    METHODS given_other_msgv_search_false   FOR TESTING RAISING cx_static_check.
    METHODS given_merge_then_counts_added   FOR TESTING RAISING cx_static_check.
    METHODS given_reset_then_counts_zero    FOR TESTING RAISING cx_static_check.

    " getters with a minimum severity
    METHODS given_min_sev_then_msgs_filter  FOR TESTING RAISING cx_static_check.
    METHODS given_min_sev_then_flat_filter  FOR TESTING RAISING cx_static_check.
    METHODS given_min_sev_then_ret2_filter  FOR TESTING RAISING cx_static_check.
    METHODS given_min_sev_then_rap_filter   FOR TESTING RAISING cx_static_check.
    METHODS given_lower_min_sev_getter      FOR TESTING RAISING cx_static_check.

    "! One success, one warning, one error and one abandon entry
    METHODS add_one_of_each
      RAISING zcx_cloud_logger_error.

    " Application Log memory
    METHODS when_free_then_log_released     FOR TESTING RAISING cx_static_check.
    METHODS when_reset_then_old_released    FOR TESTING RAISING cx_static_check.
    METHODS given_merged_source_freed_kept  FOR TESTING RAISING cx_static_check.

    " configuration checks
    METHODS given_used_key_neg_trim_raises  FOR TESTING RAISING cx_static_check.
    METHODS given_emergency_diff_raises     FOR TESTING RAISING cx_static_check.
    METHODS given_emergency_no_obj_raises   FOR TESTING RAISING cx_static_check.

    " Application Log items
    METHODS given_context_then_item_prefix  FOR TESTING RAISING cx_static_check.
    METHODS given_long_text_then_item_200   FOR TESTING RAISING cx_static_check.
    METHODS when_merge_then_items_copied    FOR TESTING RAISING cx_static_check.
    METHODS given_empty_saved_then_load_ok  FOR TESTING RAISING cx_static_check.

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

  METHOD given_no_object_then_raises.
    " The Application Log refuses a header without object, with or without db_save
    TRY.
        DATA(logger) = zcl_cloud_logger=>get_instance( ext_number = 'NO_OBJECT_IN_MEMORY'
                                                       db_save    = abap_false ).
        logger->free( ).
        cl_abap_unit_assert=>fail( `A logger without object must raise` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>object_required
                                            msg = `Missing object must be reported as object_required` ).
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
    MESSAGE s003(z_cloud_logger) WITH 'Z_CLOUD_LOG_SAMPLE' INTO DATA(dummy) ##NEEDED.
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

  METHOD given_other_freed_then_kept.
    DATA(other) = secondary_logger( 'OTHER' ).

    other->free( ).

    DATA(again) = zcl_cloud_logger=>get_instance( object    = test_object
                                                  subobject = test_subobject
                                                  db_save   = abap_true ).

    cl_abap_unit_assert=>assert_equals( act = again
                                        exp = cut
                                        msg = `free( ) must drop only its own registry entry` ).
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

  METHOD given_t100_exception_then_key.
    DATA(failure) = NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>config_mismatch
                                                log_object = 'ZTEST_OBJECT' ).

    cut->log_exception_add( failure ).

    DATA(messages)    = cut->get_messages( ).
    DATA(rap)         = cut->get_messages_rap( ).
    DATA(rap_message) = CAST if_t100_message( rap[ 1 ] ).

    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-symsg-msgid
                                        exp = 'Z_CLOUD_LOGGER'
                                        msg = `The exception's message class must be kept` ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-symsg-msgno
                                        exp = '007'
                                        msg = `The exception's message number must be kept` ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-symsg-msgv1
                                        exp = 'ZTEST_OBJECT'
                                        msg = `The attribute named in the T100 key becomes the variable` ).
    cl_abap_unit_assert=>assert_equals( act = cut->search_message( VALUE #( msgid = 'Z_CLOUD_LOGGER'
                                                                            msgno = '007' ) )
                                        exp = abap_true
                                        msg = `The logged exception must be searchable by its T100 key` ).
    cl_abap_unit_assert=>assert_equals( act = rap_message->t100key-msgno
                                        exp = '007'
                                        msg = `RAP conversion must carry the real T100 key` ).
  ENDMETHOD.

  METHOD given_dyn_exception_then_vars.
    DATA(message) = zcx_cloud_logger_message=>new_message( class    = 'CL'
                                                           number   = '000'
                                                           severity = if_abap_behv_message=>severity-error
                                                           v1       = 'first'
                                                           v2       = 'second' ).
    DATA(failure) = CAST cx_root( message ).

    cut->log_exception_add( failure ).

    DATA(messages) = cut->get_messages( ).

    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-symsg-msgv1
                                        exp = 'first'
                                        msg = `Variables must be read through the T100 attribute names` ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-symsg-msgv2
                                        exp = 'second'
                                        msg = `Every filled variable must be kept` ).
    cl_abap_unit_assert=>assert_initial( act = messages[ 1 ]-symsg-msgv3
                                         msg = `Unused variables must stay empty` ).
  ENDMETHOD.

  METHOD given_plain_exception_no_key.
    DATA(failure) = NEW lth_plain_failure( ).

    cut->log_exception_add( failure ).

    DATA(messages) = cut->get_messages( ).

    cl_abap_unit_assert=>assert_initial( act = messages[ 1 ]-symsg-msgid
                                         msg = `An exception without T100 key must be logged as free text` ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-message
                                        exp = failure->get_text( )
                                        msg = `The exception text must be kept` ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-type
                                        exp = 'E'
                                        msg = `The default severity for exceptions is error` ).
  ENDMETHOD.

  METHOD given_free_text_then_rap_wrap.
    DATA(long_text) = repeat( val = `a`
                              occ = 60 ).

    cut->log_string_add( long_text ).

    DATA(rap)       = cut->get_messages_rap( ).
    DATA(rap_t100)  = CAST if_t100_message( rap[ 1 ] ).
    DATA(rap_vars)  = CAST if_t100_dyn_msg( rap[ 1 ] ).
    DATA(key)       = rap_t100->t100key.

    cl_abap_unit_assert=>assert_equals( act = key-msgid
                                        exp = zif_cloud_logger=>c_free_text_message-msgid
                                        msg = `Free text must be wrapped in the carrier message class` ).
    cl_abap_unit_assert=>assert_equals( act = key-msgno
                                        exp = zif_cloud_logger=>c_free_text_message-msgno
                                        msg = `Free text must be wrapped in the carrier message number` ).
    cl_abap_unit_assert=>assert_equals( act = strlen( rap_vars->msgv1 )
                                        exp = 50
                                        msg = `The first placeholder must carry the first 50 characters` ).
    cl_abap_unit_assert=>assert_equals( act = strlen( rap_vars->msgv2 )
                                        exp = 10
                                        msg = `The second placeholder must carry the remainder` ).
  ENDMETHOD.

  METHOD given_abort_then_contains_err.
    cut->log_string_add( string = `abort`
                         msgty  = zif_cloud_logger=>c_message_type-abandon ).

    cl_abap_unit_assert=>assert_equals( act = cut->log_contains_error( )
                                        exp = abap_true
                                        msg = `Severity A must count as error` ).

    cut->reset_appl_log( ).
    cut->log_string_add( string = `terminate`
                         msgty  = zif_cloud_logger=>c_message_type-terminate ).

    cl_abap_unit_assert=>assert_equals( act = cut->log_contains_error( )
                                        exp = abap_true
                                        msg = `Severity X must count as error` ).
  ENDMETHOD.

  METHOD when_display_unbound_no_dump.
    cut->log_string_add( `something to show` ).

    cut->display( VALUE #( ) ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 1
                                        msg = `display( ) without viewer must be a harmless no-op` ).
  ENDMETHOD.

  METHOD given_error_then_object_known.
    TRY.
        zcl_cloud_logger=>get_instance( object    = test_object
                                        subobject = test_subobject
                                        db_save   = abap_false ).
        cl_abap_unit_assert=>fail( `Conflicting db_save must raise` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->log_object
                                            exp = test_object
                                            msg = `The exception must name the Application Log object concerned` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_msgno_000_then_t100_kept.
    " Message number 000 is a valid number; as NUMC it is also IS INITIAL
    cut->log_message_add( VALUE #( msgty = 'W'
                                   msgid = 'CL'
                                   msgno = '000'
                                   msgv1 = 'zero' ) ).

    DATA(flat)     = cut->get_messages_flat( ).
    DATA(rap)      = cut->get_messages_rap( ).
    DATA(rap_t100) = CAST if_t100_message( rap[ 1 ] ).

    cl_abap_unit_assert=>assert_char_cp( act = flat[ 1 ]
                                         exp = 'W000(CL) - *'
                                         msg = `Message 000 must render as a T100 message, not as free text` ).
    cl_abap_unit_assert=>assert_equals( act = rap_t100->t100key-msgid
                                        exp = 'CL'
                                        msg = `Message 000 must keep its class in the RAP conversion` ).
  ENDMETHOD.

  METHOD given_saved_then_load_same.
    " Needs the real Application Log runtime (get_header, item getters)
    cut->log_string_add( string = `persisted before load`
                         msgty  = 'E' ).
    cut->save_application_log( ).
    DATA(handle) = cut->get_handle( ).
    cut->free( ).

    cut = zcl_cloud_logger=>load( handle ).
    cut->log_string_add( `appended after load` ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_handle( )
                                        exp = handle
                                        msg = `The loaded logger must write to the same Application Log` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 2
                                        msg = `Persisted items plus new entries must both be visible` ).
    cl_abap_unit_assert=>assert_equals( act = cut->log_contains_error( )
                                        exp = abap_true
                                        msg = `Queries must see the persisted history` ).
    cl_abap_unit_assert=>assert_equals( act = zcl_cloud_logger=>get_instance( object    = test_object
                                                                              subobject = test_subobject )
                                        exp = cut
                                        msg = `The loaded instance must be registered under the log's key` ).
  ENDMETHOD.

  METHOD given_active_when_load_raises.
    " Needs the real Application Log runtime
    cut->save_application_log( ).

    TRY.
        zcl_cloud_logger=>load( cut->get_handle( ) ).
        cl_abap_unit_assert=>fail( `Loading a log whose key is active must raise` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>already_active
                                            msg = `The conflict must be reported as already_active` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_bad_handle_load_raises.
    " Needs the real Application Log runtime
    TRY.
        zcl_cloud_logger=>load( 'NO_SUCH_HANDLE' ).
        cl_abap_unit_assert=>fail( `An unknown handle must raise` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>error_in_loading
                                            msg = `The failure must be reported as error_in_loading` ).
        cl_abap_unit_assert=>assert_equals( act = error->log_handle
                                            exp = 'NO_SUCH_HANDLE'
                                            msg = `The exception must carry the handle` ).
    ENDTRY.
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
        MESSAGE e005(z_cloud_logger) WITH 'Z_CLOUD_LOG_SAMPLE' INTO DATA(dummy) ##NEEDED.
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

  METHOD given_blank_str_sev_then_w.
    cut->log_string_add( string = `no severity`
                         msgty  = space ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( zif_cloud_logger=>c_message_type-warning )
                                        exp = 1
                                        msg = `Free text without severity must count as warning` ).
  ENDMETHOD.

  METHOD given_blank_exc_sev_then_e.
    cut->log_exception_add( exception = NEW cx_sy_zerodivide( )
                            severity  = space ).

    cl_abap_unit_assert=>assert_equals( act = cut->log_contains_error( )
                                        exp = abap_true
                                        msg = `An exception without severity must count as error` ).
  ENDMETHOD.

  METHOD given_lower_sev_then_upper.
    cut->log_string_add( string = `lower case`
                         msgty  = 'e' ).

    DATA(messages) = cut->get_messages( ).

    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-type
                                        exp = 'E'
                                        msg = `A lower-case severity must be stored in upper case` ).
    cl_abap_unit_assert=>assert_equals( act = cut->log_contains_error( )
                                        exp = abap_true
                                        msg = `The entry must be visible to the severity queries` ).
  ENDMETHOD.

  METHOD given_lower_min_sev_filters.
    cut->log_bapiret2_table_add( bapiret2_t   = VALUE #( id     = 'Z_CLOUD_LOGGER'
                                                         number = '002'
                                                         ( type = 'S' )
                                                         ( type = 'W' )
                                                         ( type = 'E' ) )
                                 min_severity = 'e' ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 1
                                        msg = `A lower-case min_severity must filter like E` ).
  ENDMETHOD.

  METHOD given_lower_row_type_kept.
    cut->log_bapiret2_table_add( bapiret2_t   = VALUE #( id     = 'Z_CLOUD_LOGGER'
                                                         number = '002'
                                                         ( type = 'e' ) )
                                 min_severity = 'E' ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( zif_cloud_logger=>c_message_type-error )
                                        exp = 1
                                        msg = `A row with a lower-case type must pass the filter as error` ).
  ENDMETHOD.

  METHOD given_min_sev_w_then_keeps_3.
    cut->log_bapiret2_table_add( bapiret2_t   = VALUE #( id     = 'Z_CLOUD_LOGGER'
                                                         number = '002'
                                                         ( type = 'S' )
                                                         ( type = 'I' )
                                                         ( type = 'W' )
                                                         ( type = 'E' )
                                                         ( type = 'A' ) )
                                 min_severity = 'W' ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 3
                                        msg = `min_severity W must keep W, E and A` ).
  ENDMETHOD.

  METHOD given_min_sev_a_then_keeps_a_x.
    cut->log_bapiret2_table_add( bapiret2_t   = VALUE #( id     = 'Z_CLOUD_LOGGER'
                                                         number = '002'
                                                         ( type = 'E' )
                                                         ( type = 'A' )
                                                         ( type = 'X' ) )
                                 min_severity = 'A' ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 2
                                        msg = `min_severity A must keep A and X` ).
  ENDMETHOD.

  METHOD given_min_sev_x_then_keeps_a_x.
    cut->log_bapiret2_table_add( bapiret2_t   = VALUE #( id     = 'Z_CLOUD_LOGGER'
                                                         number = '002'
                                                         ( type = 'E' )
                                                         ( type = 'A' )
                                                         ( type = 'X' ) )
                                 min_severity = 'X' ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 2
                                        msg = `min_severity X must keep A and X` ).
  ENDMETHOD.

  METHOD given_min_sev_i_then_keeps_all.
    cut->log_bapiret2_table_add( bapiret2_t   = VALUE #( id     = 'Z_CLOUD_LOGGER'
                                                         number = '002'
                                                         ( type = 'S' )
                                                         ( type = 'I' )
                                                         ( type = 'W' ) )
                                 min_severity = 'I' ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 3
                                        msg = `min_severity I is no filter` ).
  ENDMETHOD.

  METHOD given_text_only_ret2_then_kept.
    cut->log_bapiret2_structure_add( VALUE #( type    = 'E'
                                              message = 'Custom text only' ) ).

    DATA(messages) = cut->get_messages( ).

    cl_abap_unit_assert=>assert_equals( act = lines( messages )
                                        exp = 1
                                        msg = `A row with a text but no message class must be logged` ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-message
                                        exp = `Custom text only`
                                        msg = `The text of the BAPI must be kept` ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-type
                                        exp = 'E'
                                        msg = `The severity of the row must be kept` ).
  ENDMETHOD.

  METHOD given_type_only_ret2_ignored.
    cut->log_bapiret2_structure_add( VALUE #( type = 'S' ) ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 0
                                        msg = `A row without message class and without text says nothing` ).
  ENDMETHOD.

  METHOD given_blank_ret2_type_then_s.
    cut->log_bapiret2_structure_add( VALUE #( id         = 'Z_CLOUD_LOGGER'
                                              number     = '002'
                                              message_v1 = 'no type' ) ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( zif_cloud_logger=>c_message_type-success )
                                        exp = 1
                                        msg = `A BAPI row without type is a success message` ).
  ENDMETHOD.

  METHOD given_unknown_ret2_then_text.
    cut->log_bapiret2_structure_add( VALUE #( type    = 'E'
                                              id      = 'ZZ_NO_SUCH_CLASS'
                                              number  = '999'
                                              message = 'Text supplied by the BAPI' ) ).

    DATA(messages) = cut->get_messages( ).

    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-message
                                        exp = `Text supplied by the BAPI`
                                        msg = `A message that cannot be resolved must fall back to the BAPI text` ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-symsg-msgid
                                        exp = 'ZZ_NO_SUCH_CLASS'
                                        msg = `The message key must be kept all the same` ).
  ENDMETHOD.

  METHOD given_blank_at_50_then_kept.
    DATA(text) = |{ repeat( val = `a`
                            occ = 49 ) } bbbbb|.

    cut->log_string_add( text ).

    DATA(rap)       = cut->get_messages_rap( ).
    DATA(variables) = CAST if_t100_dyn_msg( rap[ 1 ] ).
    MESSAGE ID zif_cloud_logger=>c_free_text_message-msgid TYPE 'S'
            NUMBER zif_cloud_logger=>c_free_text_message-msgno
            WITH variables->msgv1 variables->msgv2 variables->msgv3 variables->msgv4
            INTO DATA(resolved).

    cl_abap_unit_assert=>assert_equals( act = resolved
                                        exp = text
                                        msg = `A blank at position 50 must survive the RAP conversion` ).
  ENDMETHOD.

  METHOD given_int_attr_then_unpadded.
    cut->log_exception_add( NEW lth_counted_failure( 42 ) ).

    DATA(messages) = cut->get_messages( ).

    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-symsg-msgv1
                                        exp = '42'
                                        msg = `A numeric T100 attribute must not be padded in the variable` ).
  ENDMETHOD.

  METHOD given_unbound_exc_ignored.
    DATA(chained) = cut->log_exception_add( VALUE #( ) ).

    cl_abap_unit_assert=>assert_bound( act = chained
                                       msg = `Ignored call must still return the logger` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 0
                                        msg = `An unbound exception must not create an entry` ).
  ENDMETHOD.

  METHOD given_msgv_search_then_matched.
    add_warning( 'abc' ).

    cl_abap_unit_assert=>assert_equals( act = cut->search_message( VALUE #( msgid = 'CL'
                                                                            msgv1 = 'abc' ) )
                                        exp = abap_true
                                        msg = `Search by class and variable must find the entry` ).
  ENDMETHOD.

  METHOD given_other_msgv_search_false.
    add_warning( 'abc' ).

    cl_abap_unit_assert=>assert_equals( act = cut->search_message( VALUE #( msgv1 = 'zzz' ) )
                                        exp = abap_false
                                        msg = `A different variable must not match` ).
  ENDMETHOD.

  METHOD given_merge_then_counts_added.
    DATA(second) = secondary_logger( 'COUNTS' ).

    TRY.
        second->log_string_add( string = `merged error`
                                msgty  = 'E' ).
        cut->log_string_add( string = `own warning`
                             msgty  = 'W' ).

        cut->merge_logs( second ).

        cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( 'E' )
                                            exp = 1
                                            msg = `Merged entries must be counted by severity` ).
        cl_abap_unit_assert=>assert_equals( act = cut->log_contains_error( )
                                            exp = abap_true
                                            msg = `A merged error must be visible to the severity queries` ).

      CLEANUP.
        second->free( ).
    ENDTRY.
    second->free( ).
  ENDMETHOD.

  METHOD given_reset_then_counts_zero.
    cut->log_string_add( string = `error before reset`
                         msgty  = 'E' ).

    cut->reset_appl_log( ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( 'E' )
                                        exp = 0
                                        msg = `A reset must clear the counts by severity` ).
    cl_abap_unit_assert=>assert_equals( act = cut->log_contains_error( )
                                        exp = abap_false
                                        msg = `A reset logger must not report old errors` ).
  ENDMETHOD.

  METHOD add_one_of_each.
    cut->log_string_add( string = `saved`
                         msgty  = 'S' ).
    cut->log_string_add( string = `check the price`
                         msgty  = 'W' ).
    cut->log_message_add( VALUE #( msgty = 'E'
                                   msgid = 'Z_CLOUD_LOGGER'
                                   msgno = '008' ) ).
    cut->log_string_add( string = `run abandoned`
                         msgty  = 'A' ).
  ENDMETHOD.

  METHOD given_min_sev_then_msgs_filter.
    add_one_of_each( ).

    DATA(messages) = cut->get_messages( 'E' ).

    cl_abap_unit_assert=>assert_equals( act = lines( messages )
                                        exp = 2
                                        msg = `Minimum E must return the error and the abandon entry` ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-symsg-msgno
                                        exp = '008'
                                        msg = `The returned entries must keep their details` ).
    cl_abap_unit_assert=>assert_equals( act = lines( cut->get_messages( ) )
                                        exp = 4
                                        msg = `Filtering must not remove anything from the log` ).
  ENDMETHOD.

  METHOD given_min_sev_then_flat_filter.
    add_one_of_each( ).

    DATA(lines) = cut->get_messages_flat( 'A' ).

    cl_abap_unit_assert=>assert_equals( act = lines
                                        exp = VALUE zif_cloud_logger=>flat_messages( ( `run abandoned` ) )
                                        msg = `Minimum A must render the abandon entry only` ).
  ENDMETHOD.

  METHOD given_min_sev_then_ret2_filter.
    add_one_of_each( ).

    DATA(return) = cut->get_messages_as_bapiret2( 'W' ).

    cl_abap_unit_assert=>assert_equals( act = lines( return )
                                        exp = 3
                                        msg = `Minimum W must return warning, error and abandon` ).
    cl_abap_unit_assert=>assert_equals( act = return[ 1 ]-type
                                        exp = 'W'
                                        msg = `The success row must be left out` ).
  ENDMETHOD.

  METHOD given_min_sev_then_rap_filter.
    add_one_of_each( ).

    DATA(reported) = cut->get_messages_rap( 'E' ).

    cl_abap_unit_assert=>assert_equals( act = lines( reported )
                                        exp = 2
                                        msg = `Minimum E must create two RAP messages, not four` ).
    cl_abap_unit_assert=>assert_equals( act = reported[ 1 ]->m_severity
                                        exp = if_abap_behv_message=>severity-error
                                        msg = `The first RAP message must be the error` ).
  ENDMETHOD.

  METHOD given_lower_min_sev_getter.
    add_one_of_each( ).

    cl_abap_unit_assert=>assert_equals( act = lines( cut->get_messages_as_bapiret2( 'e' ) )
                                        exp = 2
                                        msg = `A lower-case minimum must filter like E` ).
    cl_abap_unit_assert=>assert_equals( act = lines( cut->get_messages_rap( 'i' ) )
                                        exp = 4
                                        msg = `Minimum I is no filter` ).
  ENDMETHOD.

  METHOD when_free_then_log_released.
    DATA(log) = cut->get_log_handle( ).

    cut->free( ).

    cl_abap_unit_assert=>assert_equals( act = log->is_invalidated( )
                                        exp = abap_true
                                        msg = `free( ) must release the log from Application Log memory` ).
  ENDMETHOD.

  METHOD when_reset_then_old_released.
    DATA(old_log) = cut->get_log_handle( ).

    cut->reset_appl_log( ).

    cl_abap_unit_assert=>assert_equals( act = old_log->is_invalidated( )
                                        exp = abap_true
                                        msg = `A reset must release the replaced log from Application Log memory` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_log_handle( )->is_invalidated( )
                                        exp = abap_false
                                        msg = `The fresh log must be usable` ).
  ENDMETHOD.

  METHOD given_merged_source_freed_kept.
    DATA(second) = secondary_logger( 'RELEASED' ).
    second->log_string_add( string = `merged, then its logger was freed`
                            msgty  = 'E' ).
    cut->merge_logs( second ).

    second->free( ).
    cut->log_string_add( `still writable` ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 2
                                        msg = `Releasing a merged logger must not touch the target` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_log_handle( )->is_invalidated( )
                                        exp = abap_false
                                        msg = `The target log must stay in memory` ).
  ENDMETHOD.

  METHOD given_used_key_neg_trim_raises.
    TRY.
        zcl_cloud_logger=>get_instance( object     = test_object
                                        subobject  = test_subobject
                                        trim_limit = -1 ).
        cl_abap_unit_assert=>fail( `Negative trim_limit must raise, also for a registered key` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>invalid_trim_limit
                                            msg = `An invalid value must not be reported as configuration conflict` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_emergency_diff_raises.
    TRY.
        zcl_cloud_logger=>get_instance( object               = test_object
                                        subobject            = test_subobject
                                        enable_emergency_log = abap_true ).
        cl_abap_unit_assert=>fail( `Conflicting enable_emergency_log must raise` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>config_mismatch
                                            msg = `Conflict must be reported as config_mismatch` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_emergency_no_obj_raises.
    TRY.
        zcl_cloud_logger=>get_instance( ext_number           = 'NO_OBJECT_EMERGENCY'
                                        enable_emergency_log = abap_true
                                        db_save              = abap_false ).
        cl_abap_unit_assert=>fail( `An emergency log without object must raise` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>object_required
                                            msg = `Missing object must be reported as object_required` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_context_then_item_prefix.
    cut->set_context( `Order 1` ).

    cut->log_string_add( `checked` ).

    DATA(items) = cut->get_log_handle( )->get_all_items( ).

    cl_abap_unit_assert=>assert_equals( act = items[ 1 ]-item->get_message_text( )
                                        exp = `[Order 1] checked`
                                        msg = `The persisted free text must carry the context prefix` ).
  ENDMETHOD.

  METHOD given_long_text_then_item_200.
    cut->set_context( repeat( val = `c`
                              occ = 150 ) ).

    cut->log_string_add( repeat( val = `x`
                                 occ = 100 ) ).

    DATA(items) = cut->get_log_handle( )->get_all_items( ).

    cl_abap_unit_assert=>assert_equals( act = strlen( items[ 1 ]-item->get_message_text( ) )
                                        exp = 200
                                        msg = `The Application Log keeps 200 characters, prefix included` ).
  ENDMETHOD.

  METHOD when_merge_then_items_copied.
    " Needs the real Application Log runtime: the off-stack stub does not copy items.
    " The source is freed before the check: the copied item must survive the
    " release of the log it came from.
    DATA(second) = secondary_logger( 'ITEMS' ).
    second->log_string_add( `one item` ).

    cut->merge_logs( second ).
    second->free( ).

    cl_abap_unit_assert=>assert_equals( act = lines( cut->get_log_handle( )->get_all_items( ) )
                                        exp = 1
                                        msg = `merge_logs must copy the Application Log items` ).
  ENDMETHOD.

  METHOD given_empty_saved_then_load_ok.
    " Needs the real Application Log runtime: there, a log without items has no item table
    cut->save_application_log( ).
    DATA(handle) = cut->get_handle( ).
    cut->free( ).

    cut = zcl_cloud_logger=>load( handle ).

    cl_abap_unit_assert=>assert_equals( act = cut->get_message_count( )
                                        exp = 0
                                        msg = `A log saved without entries must load empty` ).
    cl_abap_unit_assert=>assert_equals( act = cut->get_handle( )
                                        exp = handle
                                        msg = `The loaded logger must be attached to the saved log` ).
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
    "! How often date and time were read as one moment
    DATA moment_reads  TYPE i           READ-ONLY.

    METHODS queue_stamps
      IMPORTING stamps TYPE time_stamps.
    METHODS set_message
      IMPORTING !message TYPE symsg.
    "! Moves the system date, e.g. to the next day
    METHODS set_date
      IMPORTING !date TYPE d.

  PRIVATE SECTION.
    DATA last_stamp TYPE timestampl VALUE first_now.
    DATA today      TYPE d          VALUE fixed_date.
    DATA message    TYPE symsg.
ENDCLASS.


CLASS ltd_fixed_system IMPLEMENTATION.

  METHOD queue_stamps.
    queued_stamps = stamps.
  ENDMETHOD.

  METHOD set_message.
    me->message = message.
  ENDMETHOD.

  METHOD set_date.
    today = date.
  ENDMETHOD.

  METHOD zif_cloud_logger_system~system_date.
    result = today.
  ENDMETHOD.

  METHOD zif_cloud_logger_system~system_moment.
    moment_reads += 1.
    result = VALUE #( date = today
                      time = fixed_time ).
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
    "! abap_true when delete_log( ) received a log whose memory was released already
    DATA deleted_released_log TYPE abap_boolean        READ-ONLY.
    DATA saved_log            TYPE REF TO if_bali_log  READ-ONLY.
    DATA saved_on_2nd_db_conn TYPE abap_boolean        READ-ONLY.
    DATA saved_to_appl_job    TYPE abap_boolean        READ-ONLY.
    DATA load_calls           TYPE i                   READ-ONLY.
    DATA loaded_handle        TYPE balloghndl          READ-ONLY.

    TYPES messages TYPE STANDARD TABLE OF symsg WITH EMPTY KEY.

    DATA emergency_opens      TYPE i                                      READ-ONLY.
    DATA emergency_object     TYPE cl_bali_header_setter=>ty_object       READ-ONLY.
    DATA emergency_ext_id     TYPE cl_bali_header_setter=>ty_external_id  READ-ONLY.
    DATA mirrored_messages    TYPE messages                               READ-ONLY.
    DATA mirrored_exceptions  TYPE i                                      READ-ONLY.
    DATA mirrored_severity    TYPE symsgty                                READ-ONLY.

    METHODS fail_next_save.
    METHODS fail_next_delete.
    METHODS fail_next_load.
    METHODS fail_next_open.
    METHODS fail_next_mirror.
    "! What the next load_log( ) returns
    METHODS answer_load_with
      IMPORTING loaded TYPE zif_cloud_logger_persistence=>loaded_log.

  PRIVATE SECTION.
    DATA fail_save   TYPE abap_boolean.
    DATA fail_delete TYPE abap_boolean.
    DATA fail_load   TYPE abap_boolean.
    DATA fail_open   TYPE abap_boolean.
    DATA fail_mirror TYPE abap_boolean.
    DATA load_answer TYPE zif_cloud_logger_persistence=>loaded_log.
ENDCLASS.


"! cx_bali_runtime is abstract, so the spy raises this concrete stand-in.
CLASS ltd_bali_failure DEFINITION FINAL FOR TESTING
  INHERITING FROM cx_bali_runtime.
ENDCLASS.


CLASS ltd_bali_failure IMPLEMENTATION.
ENDCLASS.


"! XCO reports problems with exceptions of the cx_no_check family; the spy
"! raises this stand-in for a failing emergency log.
CLASS ltd_xco_failure DEFINITION FINAL FOR TESTING
  INHERITING FROM cx_no_check.
ENDCLASS.


CLASS ltd_xco_failure IMPLEMENTATION.
ENDCLASS.


"! Application Log that rejects one item, to reach the error paths of the
"! logger without a database. Only add_item is needed.
CLASS ltd_rejecting_log DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES if_bali_log PARTIALLY IMPLEMENTED.

    DATA added_items TYPE i READ-ONLY.

    "! The item with this serial number is rejected
    METHODS reject_item
      IMPORTING !number TYPE i.

  PRIVATE SECTION.
    DATA rejected_number TYPE i.
ENDCLASS.


CLASS ltd_rejecting_log IMPLEMENTATION.

  METHOD reject_item.
    rejected_number = number.
  ENDMETHOD.

  METHOD if_bali_log~add_item.
    added_items += 1.
    IF added_items = rejected_number.
      RAISE EXCEPTION NEW ltd_bali_failure( ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS ltd_persistence_spy IMPLEMENTATION.

  METHOD fail_next_save.
    fail_save = abap_true.
  ENDMETHOD.

  METHOD fail_next_delete.
    fail_delete = abap_true.
  ENDMETHOD.

  METHOD answer_load_with.
    load_answer = loaded.
  ENDMETHOD.

  METHOD fail_next_load.
    fail_load = abap_true.
  ENDMETHOD.

  METHOD fail_next_open.
    fail_open = abap_true.
  ENDMETHOD.

  METHOD fail_next_mirror.
    fail_mirror = abap_true.
  ENDMETHOD.

  METHOD zif_cloud_logger_persistence~load_log.
    load_calls   += 1.
    loaded_handle = handle.
    IF fail_load = abap_true.
      CLEAR fail_load.
      RAISE EXCEPTION NEW ltd_bali_failure( ).
    ENDIF.
    result = load_answer.
  ENDMETHOD.

  METHOD zif_cloud_logger_persistence~open_emergency_log.
    IF fail_open = abap_true.
      CLEAR fail_open.
      RAISE EXCEPTION NEW ltd_xco_failure( ).
    ENDIF.
    emergency_opens += 1.
    emergency_object = object.
    emergency_ext_id = external_id.
  ENDMETHOD.

  METHOD zif_cloud_logger_persistence~mirror_message.
    IF fail_mirror = abap_true.
      CLEAR fail_mirror.
      RAISE EXCEPTION NEW ltd_xco_failure( ).
    ENDIF.
    INSERT symsg INTO TABLE mirrored_messages.
  ENDMETHOD.

  METHOD zif_cloud_logger_persistence~mirror_exception.
    IF fail_mirror = abap_true.
      CLEAR fail_mirror.
      RAISE EXCEPTION NEW ltd_xco_failure( ).
    ENDIF.
    mirrored_exceptions += 1.
    mirrored_severity = severity.
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
    deleted_released_log = log->is_invalidated( ).
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

    TYPES loggers TYPE STANDARD TABLE OF REF TO zif_cloud_logger WITH EMPTY KEY.

    DATA cut         TYPE REF TO zif_cloud_logger.
    DATA system      TYPE REF TO ltd_fixed_system.
    DATA persistence TYPE REF TO ltd_persistence_spy.
    "! Loggers a test entered into the multiton registry; released in teardown
    DATA registered  TYPE loggers.

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
    METHODS given_loaded_then_history_kept  FOR TESTING RAISING cx_static_check.
    METHODS given_loaded_then_add_appends FOR TESTING RAISING cx_static_check.
    METHODS given_loaded_then_save_same FOR TESTING RAISING cx_static_check.

    METHODS attach_to_prepared_log
      RETURNING VALUE(result) TYPE REF TO zif_cloud_logger
      RAISING   cx_static_check.

    " trail
    METHODS given_trim_0_then_no_trail      FOR TESTING RAISING cx_static_check.
    METHODS given_trim_1_then_newest_kept   FOR TESTING RAISING cx_static_check.
    METHODS given_equal_stamps_order_kept   FOR TESTING RAISING cx_static_check.

    " entries
    METHODS given_entry_then_system_moment  FOR TESTING RAISING cx_static_check.
    METHODS given_loaded_then_counts_right  FOR TESTING RAISING cx_static_check.

    " a rejecting Application Log
    METHODS given_item_rejected_raises      FOR TESTING RAISING cx_static_check.
    METHODS given_row_rejected_rest_kept    FOR TESTING RAISING cx_static_check.
    METHODS given_data_fails_then_error     FOR TESTING RAISING cx_static_check.
    METHODS given_new_log_fails_no_delete   FOR TESTING RAISING cx_static_check.
    METHODS given_reset_fails_log_kept      FOR TESTING RAISING cx_static_check.
    METHODS when_reset_then_delete_first    FOR TESTING RAISING cx_static_check.

    " emergency log
    METHODS given_emergency_then_opened     FOR TESTING RAISING cx_static_check.
    METHODS given_no_ext_then_handle_id     FOR TESTING RAISING cx_static_check.
    METHODS when_string_then_carrier_sent   FOR TESTING RAISING cx_static_check.
    METHODS when_message_then_mirrored      FOR TESTING RAISING cx_static_check.
    METHODS when_exception_then_sev_sent    FOR TESTING RAISING cx_static_check.
    METHODS given_mirror_fails_then_trail   FOR TESTING RAISING cx_static_check.
    METHODS when_reset_then_reopened        FOR TESTING RAISING cx_static_check.
    METHODS given_open_fails_then_raises    FOR TESTING RAISING cx_static_check.
    METHODS given_reopen_fails_then_trail   FOR TESTING RAISING cx_static_check.
    METHODS given_no_emergency_no_mirror    FOR TESTING RAISING cx_static_check.

    METHODS emergency_logger
      IMPORTING ext_number    TYPE cl_bali_header_setter=>ty_external_id DEFAULT 'EMERGENCY'
      RETURNING VALUE(result) TYPE REF TO zif_cloud_logger
      RAISING   zcx_cloud_logger_error.

    METHODS logger_on
      IMPORTING !log          TYPE REF TO if_bali_log
                !object       TYPE cl_bali_header_setter=>ty_object DEFAULT test_object
      RETURNING VALUE(result) TYPE REF TO zif_cloud_logger
      RAISING   zcx_cloud_logger_error.

    " loading through the injected persistence
    METHODS when_load_then_attached         FOR TESTING RAISING cx_static_check.
    METHODS when_load_then_registered       FOR TESTING RAISING cx_static_check.
    METHODS given_empty_log_then_loads      FOR TESTING RAISING cx_static_check.
    METHODS given_unknown_handle_raises     FOR TESTING RAISING cx_static_check.
    METHODS given_active_handle_raises      FOR TESTING RAISING cx_static_check.
    METHODS given_active_key_raises         FOR TESTING RAISING cx_static_check.
    METHODS given_neg_trim_then_no_read     FOR TESTING RAISING cx_static_check.

    " registry and expiry
    METHODS given_explicit_default_expiry   FOR TESTING RAISING cx_static_check.
    METHODS given_reset_then_expiry_synced  FOR TESTING RAISING cx_static_check.

    "! A log as the persistence adapter returns it: two items, two entries
    METHODS persisted_log
      RETURNING VALUE(result) TYPE zif_cloud_logger_persistence=>loaded_log
      RAISING   cx_static_check.

    "! Loads through the spy and remembers the logger for teardown
    METHODS load_through_spy
      IMPORTING handle        TYPE balloghndl DEFAULT 'HANDLE_OF_SAVED_LOG'
                trim_limit    TYPE i          DEFAULT zif_cloud_logger=>c_default_trim_limit
      RETURNING VALUE(result) TYPE REF TO zif_cloud_logger
      RAISING   zcx_cloud_logger_error.

    "! A logger with the injected doubles that is known to the multiton registry
    METHODS registered_logger
      IMPORTING ext_number    TYPE cl_bali_header_setter=>ty_external_id
      RETURNING VALUE(result) TYPE REF TO zif_cloud_logger
      RAISING   zcx_cloud_logger_error.

ENDCLASS.

"! Contract between {@link zcl_cloud_logger} and the test double
"! {@link zcl_cloud_logger_fake}: every scenario runs against both, and both
"! must show a consumer the same entries, renderings, counts and answers.
"! Not compared, because the fake has neither: Application Log and clock
"! (handle, item, user, date and time of an entry).
CLASS ltc_logger_contract DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    TYPES loggers TYPE STANDARD TABLE OF REF TO zif_cloud_logger WITH EMPTY KEY.

    TYPES:
      BEGIN OF entry_view,
        symsg   TYPE symsg,
        message TYPE string,
        type    TYPE symsgty,
        context TYPE string,
      END OF entry_view.
    TYPES entry_views TYPE STANDARD TABLE OF entry_view WITH EMPTY KEY.

    TYPES:
      BEGIN OF rap_view,
        t100key   TYPE scx_t100key,
        variables TYPE symsg,
        severity  TYPE if_abap_behv_message=>t_severity,
      END OF rap_view.
    TYPES rap_views TYPE STANDARD TABLE OF rap_view WITH EMPTY KEY.

    TYPES:
      "! Everything a consumer can ask a logger about its entries
      BEGIN OF observation,
        entries  TYPE entry_views,
        flat     TYPE zif_cloud_logger=>flat_messages,
        bapiret2 TYPE zif_cloud_logger=>bapiret2_messages,
        rap      TYPE rap_views,
        counts   TYPE string,
        answers  TYPE string,
      END OF observation.

    DATA real TYPE REF TO zif_cloud_logger.
    DATA fake TYPE REF TO zif_cloud_logger.
    "! The real logger and the fake, to run one scenario against both
    DATA both TYPE loggers.

    METHODS setup RAISING cx_static_check.

    METHODS when_free_text_then_same        FOR TESTING RAISING cx_static_check.
    METHODS when_messages_then_same         FOR TESTING RAISING cx_static_check.
    METHODS when_bapiret2_rows_then_same    FOR TESTING RAISING cx_static_check.
    METHODS when_bapiret2_table_then_same   FOR TESTING RAISING cx_static_check.
    METHODS when_exceptions_then_same       FOR TESTING RAISING cx_static_check.
    METHODS when_context_then_same          FOR TESTING RAISING cx_static_check.
    METHODS when_timer_misused_then_same    FOR TESTING RAISING cx_static_check.
    METHODS when_timer_used_then_same       FOR TESTING RAISING cx_static_check.
    METHODS when_data_then_same             FOR TESTING RAISING cx_static_check.
    METHODS when_long_text_then_same        FOR TESTING RAISING cx_static_check.
    METHODS when_searched_then_same         FOR TESTING RAISING cx_static_check.
    METHODS when_reset_then_same            FOR TESTING RAISING cx_static_check.
    METHODS when_merged_then_same           FOR TESTING RAISING cx_static_check.
    METHODS when_freed_then_same            FOR TESTING RAISING cx_static_check.
    METHODS when_filtered_then_same         FOR TESTING RAISING cx_static_check.

    METHODS observed
      IMPORTING logger        TYPE REF TO zif_cloud_logger
                min_severity  TYPE symsgty OPTIONAL
      RETURNING VALUE(result) TYPE observation.

    METHODS rap_view_of
      IMPORTING logger        TYPE REF TO zif_cloud_logger
                min_severity  TYPE symsgty OPTIONAL
      RETURNING VALUE(result) TYPE rap_views.

    "! One character per probe search: X for a hit, a dash for a miss
    METHODS search_answers
      IMPORTING logger        TYPE REF TO zif_cloud_logger
      RETURNING VALUE(result) TYPE string.

    "! Fails unless the fake shows what the real logger shows; the number of
    "! entries is given so that two empty loggers cannot pass as equal. With a
    "! minimum severity the getters of both are asked with that filter.
    METHODS assert_same_with
      IMPORTING entries      TYPE i
                min_severity TYPE symsgty OPTIONAL.

ENDCLASS.


CLASS zcl_cloud_logger DEFINITION LOCAL FRIENDS ltc_cloud_logger_isolated ltc_logger_contract.


CLASS ltc_cloud_logger_isolated IMPLEMENTATION.

  METHOD setup.
    system      = NEW #( ).
    persistence = NEW #( ).
    cut         = create_logger( ).
  ENDMETHOD.

  METHOD teardown.
    cut->free( ).
    LOOP AT registered INTO DATA(logger).
      logger->free( ).
    ENDLOOP.
    CLEAR cut.
    CLEAR system.
    CLEAR persistence.
    CLEAR registered.
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

  METHOD persisted_log.
    " A log "read from the database": a real in-memory BAL object plus the
    " entries the persistence adapter would have mapped from its items
    DATA(persisted) = cl_bali_log=>create( ).
    persisted->add_item( cl_bali_free_text_setter=>create( severity = 'E'
                                                           text     = 'persisted error' ) ).
    persisted->add_item( cl_bali_free_text_setter=>create( severity = 'W'
                                                           text     = 'persisted warning' ) ).

    result = VALUE #( log         = persisted
                      object      = test_object
                      subobject   = test_subobject
                      external_id = 'LOADED'
                      expiry_date = '20301231'
                      entries     = VALUE #( ( symsg   = VALUE #( msgty = 'E' )
                                               type    = 'E'
                                               message = `persisted error` )
                                             ( symsg   = VALUE #( msgty = 'W' )
                                               type    = 'W'
                                               message = `persisted warning` ) ) ).
  ENDMETHOD.

  METHOD attach_to_prepared_log.
    DATA(loaded) = persisted_log( ).

    result = NEW zcl_cloud_logger( object      = loaded-object
                                   subobject   = loaded-subobject
                                   ext_number  = loaded-external_id
                                   expiry_date = loaded-expiry_date
                                   system      = system
                                   persistence = persistence
                                   loaded_log  = loaded ).
  ENDMETHOD.

  METHOD load_through_spy.
    result = zcl_cloud_logger=>load_from( handle      = handle
                                          trim_limit  = trim_limit
                                          persistence = persistence ).
    INSERT result INTO TABLE registered.
  ENDMETHOD.

  METHOD registered_logger.
    DATA(logger) = NEW zcl_cloud_logger( object      = test_object
                                         subobject   = test_subobject
                                         ext_number  = ext_number
                                         db_save     = abap_false
                                         system      = system
                                         persistence = persistence ).

    zcl_cloud_logger=>register( logger ).
    INSERT logger INTO TABLE registered.
    result = logger.
  ENDMETHOD.

  METHOD given_loaded_then_history_kept.
    DATA(loaded_logger) = attach_to_prepared_log( ).

    cl_abap_unit_assert=>assert_equals( act = loaded_logger->get_message_count( )
                                        exp = 2
                                        msg = `Persisted items must become internal log entries` ).
    cl_abap_unit_assert=>assert_equals( act = loaded_logger->log_contains_error( )
                                        exp = abap_true
                                        msg = `Severity queries must see the persisted history` ).
    cl_abap_unit_assert=>assert_equals( act = loaded_logger->get_messages_flat( )
                                        exp = VALUE zif_cloud_logger=>flat_messages( ( `persisted error` )
                                                                                     ( `persisted warning` ) )
                                        msg = `Flat rendering must show the persisted texts` ).
  ENDMETHOD.

  METHOD given_loaded_then_add_appends.
    DATA(loaded_logger) = attach_to_prepared_log( ).

    loaded_logger->log_string_add( `appended` ).

    DATA(messages) = loaded_logger->get_messages( ).

    cl_abap_unit_assert=>assert_equals( act = lines( messages )
                                        exp = 3
                                        msg = `New entries must be appended after the persisted ones` ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 3 ]-message
                                        exp = `appended`
                                        msg = `The new entry must be the last one` ).
    cl_abap_unit_assert=>assert_bound( act = messages[ 3 ]-item
                                       msg = `A new entry must be written to the attached Application Log` ).
  ENDMETHOD.

  METHOD given_loaded_then_save_same.
    DATA(loaded_logger) = attach_to_prepared_log( ).

    loaded_logger->save_application_log( ).

    cl_abap_unit_assert=>assert_equals( act = persistence->save_calls
                                        exp = 1
                                        msg = `Saving a loaded logger must persist once` ).
    cl_abap_unit_assert=>assert_equals( act = persistence->saved_log
                                        exp = loaded_logger->get_log_handle( )
                                        msg = `The attached Application Log itself must be saved, not a new one` ).
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

  METHOD emergency_logger.
    result = NEW zcl_cloud_logger( object               = test_object
                                   subobject            = test_subobject
                                   ext_number           = ext_number
                                   db_save              = abap_false
                                   enable_emergency_log = abap_true
                                   system               = system
                                   persistence          = persistence ).
  ENDMETHOD.

  METHOD logger_on.
    " Attached like a loaded log, so the logger writes to the given Application Log
    result = NEW zcl_cloud_logger( object      = object
                                   subobject   = test_subobject
                                   ext_number  = 'ON_DOUBLE'
                                   system      = system
                                   persistence = persistence
                                   loaded_log  = VALUE #( log = log ) ).
  ENDMETHOD.

  METHOD given_trim_0_then_no_trail.
    DATA(silent) = NEW zcl_cloud_logger( object      = test_object
                                         subobject   = test_subobject
                                         ext_number  = 'TRIM_0'
                                         db_save     = abap_false
                                         trim_limit  = 0
                                         system      = system
                                         persistence = persistence ).

    silent->save_application_log( )->save_application_log( ).

    cl_abap_unit_assert=>assert_initial( act = silent->get_internal_errors( )
                                         msg = `trim_limit 0 must switch the trail off` ).
  ENDMETHOD.

  METHOD given_trim_1_then_newest_kept.
    system->queue_stamps( VALUE #( ( ltd_fixed_system=>first_now )
                                   ( ltd_fixed_system=>second_now ) ) ).
    DATA(short_memory) = NEW zcl_cloud_logger( object      = test_object
                                               subobject   = test_subobject
                                               ext_number  = 'TRIM_1'
                                               db_save     = abap_false
                                               trim_limit  = 1
                                               system      = system
                                               persistence = persistence ).

    short_memory->save_application_log( )->save_application_log( ).

    DATA(trail) = short_memory->get_internal_errors( ).

    cl_abap_unit_assert=>assert_equals( act = lines( trail )
                                        exp = 1
                                        msg = `trim_limit 1 must keep exactly one trail entry` ).
    cl_abap_unit_assert=>assert_equals( act = trail[ 1 ]-timestamp
                                        exp = ltd_fixed_system=>second_now
                                        msg = `The oldest entry must be evicted first` ).
  ENDMETHOD.

  METHOD given_equal_stamps_order_kept.
    " Every trail entry gets the same time stamp: the merge must not shuffle them.
    " The kernel sorts unstably unless told otherwise; the off-stack sort is stable.
    DATA(target) = create_logger( abap_false ).
    DATA(other)  = create_logger( abap_true ).
    target->save_application_log( ).
    persistence->fail_next_delete( ).
    other->reset_appl_log( abap_true ).
    persistence->fail_next_save( ).
    TRY.
        other->save_application_log( ).
      CATCH zcx_cloud_logger_error ##NO_HANDLER.
    ENDTRY.
    DATA(expected) = target->get_internal_errors( ).
    INSERT LINES OF other->get_internal_errors( ) INTO TABLE expected.

    target->merge_logs( other ).

    cl_abap_unit_assert=>assert_equals( act = target->get_internal_errors( )
                                        exp = expected
                                        msg = `Entries with equal time stamps must keep their order` ).
  ENDMETHOD.

  METHOD given_entry_then_system_moment.
    " The UTC clock is on the next day already; the entry shows system date and time
    system->queue_stamps( VALUE #( ( ltd_fixed_system=>after_midnight ) ) ).

    cut->log_string_add( `late in the evening, system time` ).

    DATA(messages) = cut->get_messages( ).

    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-date
                                        exp = ltd_fixed_system=>fixed_date
                                        msg = `The entry date must be the system date` ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-time
                                        exp = ltd_fixed_system=>fixed_time
                                        msg = `The entry time must be the system time` ).
    cl_abap_unit_assert=>assert_equals( act = system->moment_reads
                                        exp = 1
                                        msg = `Date and time must be read together, once per entry` ).
    cl_abap_unit_assert=>assert_equals( act = lines( system->queued_stamps )
                                        exp = 1
                                        msg = `An entry must not consume the UTC clock of the timer` ).
  ENDMETHOD.

  METHOD given_loaded_then_counts_right.
    DATA(loaded_logger) = attach_to_prepared_log( ).

    cl_abap_unit_assert=>assert_equals( act = loaded_logger->get_message_count( 'W' )
                                        exp = 1
                                        msg = `Loaded entries must be counted by severity` ).
    cl_abap_unit_assert=>assert_equals( act = loaded_logger->log_contains_warning( )
                                        exp = abap_true
                                        msg = `Loaded warnings must be visible to the severity queries` ).
  ENDMETHOD.

  METHOD given_item_rejected_raises.
    DATA(log) = NEW ltd_rejecting_log( ).
    log->reject_item( 1 ).
    DATA(logger) = logger_on( log ).

    TRY.
        logger->log_string_add( `rejected` ).
        cl_abap_unit_assert=>fail( `A rejected item must raise` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>error_in_logging
                                            msg = `A rejected item must be reported as error_in_logging` ).
        cl_abap_unit_assert=>assert_bound( act = error->previous
                                           msg = `The original cx_bali_runtime must be chained as previous` ).
        cl_abap_unit_assert=>assert_equals( act = logger->get_message_count( )
                                            exp = 0
                                            msg = `A rejected item must not appear in the internal log` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_row_rejected_rest_kept.
    DATA(log) = NEW ltd_rejecting_log( ).
    log->reject_item( 2 ).
    DATA(logger) = logger_on( log ).

    TRY.
        logger->log_bapiret2_table_add( VALUE #( id     = 'Z_CLOUD_LOGGER'
                                                 number = '002'
                                                 type   = 'E'
                                                 ( message_v1 = 'first' )
                                                 ( message_v1 = 'second' )
                                                 ( message_v1 = 'third' ) ) ).
        cl_abap_unit_assert=>fail( `The rejected row must be reported after the table was processed` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>error_in_logging
                                            msg = `The rejected row must be reported as error_in_logging` ).
        cl_abap_unit_assert=>assert_equals( act = logger->get_message_count( )
                                            exp = 2
                                            msg = `The rows after a rejected one must still be logged` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_data_fails_then_error.
    DATA(log) = NEW ltd_rejecting_log( ).
    log->reject_item( 1 ).
    DATA(logger) = logger_on( log ).

    DATA(chained) = logger->log_data_add( `payload` ).

    DATA(messages) = logger->get_messages( ).

    cl_abap_unit_assert=>assert_bound( act = chained
                                       msg = `log_data_add must not break the chain` ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages )
                                        exp = 1
                                        msg = `The failure must be logged as one entry` ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-type
                                        exp = 'E'
                                        msg = `The failure entry must be an error` ).
  ENDMETHOD.

  METHOD given_new_log_fails_no_delete.
    " The attached logger names an object that does not exist, so a reset cannot
    " create the successor log
    DATA(logger) = logger_on( log    = cl_bali_log=>create( )
                              object = 'Z_DUMMY_WRONG' ).

    TRY.
        logger->reset_appl_log( abap_true ).
        cl_abap_unit_assert=>fail( `A reset that cannot create a new log must raise` ).

      CATCH zcx_cloud_logger_error.
        cl_abap_unit_assert=>assert_equals( act = persistence->delete_calls
                                            exp = 0
                                            msg = `The persisted log must stay when its successor cannot be created` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_reset_fails_log_kept.
    DATA(log)    = cl_bali_log=>create( ).
    DATA(logger) = logger_on( log    = log
                              object = 'Z_DUMMY_WRONG' ).

    TRY.
        logger->reset_appl_log( ).
        cl_abap_unit_assert=>fail( `A reset that cannot create a new log must raise` ).

      CATCH zcx_cloud_logger_error.
        cl_abap_unit_assert=>assert_equals( act = log->is_invalidated( )
                                            exp = abap_false
                                            msg = `The old log must stay in memory when the reset fails` ).
    ENDTRY.
  ENDMETHOD.

  METHOD when_reset_then_delete_first.
    " The Application Log refuses to delete a log whose memory was released
    DATA(logger)  = create_logger( abap_true ).
    DATA(old_log) = logger->get_log_handle( ).

    logger->reset_appl_log( abap_true ).

    cl_abap_unit_assert=>assert_equals( act = persistence->delete_calls
                                        exp = 1
                                        msg = `The persisted log must be deleted` ).
    cl_abap_unit_assert=>assert_equals( act = persistence->deleted_released_log
                                        exp = abap_false
                                        msg = `The log must be deleted before its memory is released` ).
    cl_abap_unit_assert=>assert_equals( act = old_log->is_invalidated( )
                                        exp = abap_true
                                        msg = `After the delete the old log must be released` ).
  ENDMETHOD.

  METHOD given_emergency_then_opened.
    emergency_logger( ).

    cl_abap_unit_assert=>assert_equals( act = persistence->emergency_opens
                                        exp = 1
                                        msg = `The emergency log must be opened once at creation` ).
    cl_abap_unit_assert=>assert_equals( act = persistence->emergency_object
                                        exp = test_object
                                        msg = `The emergency log must use the logger's object` ).
    cl_abap_unit_assert=>assert_equals( act = persistence->emergency_ext_id
                                        exp = 'EMERGENCY'
                                        msg = `The emergency log must use the logger's external id` ).
  ENDMETHOD.

  METHOD given_no_ext_then_handle_id.
    DATA(logger) = emergency_logger( space ).

    cl_abap_unit_assert=>assert_equals( act = persistence->emergency_ext_id
                                        exp = logger->get_handle( )
                                        msg = `Without external id the main log's handle must be used` ).
  ENDMETHOD.

  METHOD when_string_then_carrier_sent.
    DATA(logger) = emergency_logger( ).

    logger->log_string_add( string = `mirrored text`
                            msgty  = 'E' ).

    cl_abap_unit_assert=>assert_equals(
        act = persistence->mirrored_messages
        exp = VALUE ltd_persistence_spy=>messages( ( msgty = 'E'
                                                     msgid = zif_cloud_logger=>c_free_text_message-msgid
                                                     msgno = zif_cloud_logger=>c_free_text_message-msgno
                                                     msgv1 = 'mirrored text' ) )
        msg = `Free text must be mirrored as carrier message with its severity` ).
  ENDMETHOD.

  METHOD when_message_then_mirrored.
    DATA(logger)  = emergency_logger( ).
    DATA(message) = VALUE symsg( msgty = 'W'
                                 msgid = 'CL'
                                 msgno = '000'
                                 msgv1 = 'mirrored' ).

    logger->log_message_add( message ).

    cl_abap_unit_assert=>assert_equals( act = persistence->mirrored_messages
                                        exp = VALUE ltd_persistence_spy=>messages( ( message ) )
                                        msg = `A T100 message must be mirrored unchanged` ).
  ENDMETHOD.

  METHOD when_exception_then_sev_sent.
    DATA(logger) = emergency_logger( ).

    logger->log_exception_add( exception = NEW cx_sy_zerodivide( )
                               severity  = 'W' ).

    cl_abap_unit_assert=>assert_equals( act = persistence->mirrored_exceptions
                                        exp = 1
                                        msg = `An exception must be mirrored once` ).
    cl_abap_unit_assert=>assert_equals( act = persistence->mirrored_severity
                                        exp = 'W'
                                        msg = `The severity of the exception must reach the emergency log` ).
  ENDMETHOD.

  METHOD given_mirror_fails_then_trail.
    DATA(logger) = emergency_logger( ).
    persistence->fail_next_mirror( ).

    logger->log_string_add( `main log survives` ).

    cl_abap_unit_assert=>assert_equals( act = logger->get_message_count( )
                                        exp = 1
                                        msg = `A failing mirror must not cost the main log its entry` ).
    cl_abap_unit_assert=>assert_equals( act = lines( logger->get_internal_errors( ) )
                                        exp = 1
                                        msg = `A failing mirror must be recorded in the internal trail` ).
  ENDMETHOD.

  METHOD when_reset_then_reopened.
    DATA(logger) = emergency_logger( space ).

    logger->reset_appl_log( ).

    cl_abap_unit_assert=>assert_equals( act = persistence->emergency_opens
                                        exp = 2
                                        msg = `A reset must open a new emergency log` ).
    cl_abap_unit_assert=>assert_equals( act = persistence->emergency_ext_id
                                        exp = logger->get_handle( )
                                        msg = `The new emergency log must belong to the new main log` ).
  ENDMETHOD.

  METHOD given_open_fails_then_raises.
    persistence->fail_next_open( ).

    TRY.
        emergency_logger( ).
        cl_abap_unit_assert=>fail( `An emergency log that cannot be opened must raise at creation` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>error_in_emergency_log
                                            msg = `The failure must be reported as error_in_emergency_log` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_reopen_fails_then_trail.
    DATA(logger) = emergency_logger( ).
    persistence->fail_next_open( ).

    logger->reset_appl_log( ).
    logger->log_string_add( `after the reset` ).

    cl_abap_unit_assert=>assert_equals( act = lines( logger->get_internal_errors( ) )
                                        exp = 1
                                        msg = `A failing re-creation must only be trailed` ).
    cl_abap_unit_assert=>assert_initial( act = persistence->mirrored_messages
                                         msg = `Nothing is mirrored while no emergency log is open` ).
  ENDMETHOD.

  METHOD given_no_emergency_no_mirror.
    cut->log_string_add( `not mirrored` ).

    cl_abap_unit_assert=>assert_equals( act = persistence->emergency_opens
                                        exp = 0
                                        msg = `Without enable_emergency_log no emergency log is opened` ).
    cl_abap_unit_assert=>assert_initial( act = persistence->mirrored_messages
                                         msg = `Without enable_emergency_log nothing is mirrored` ).
  ENDMETHOD.

  METHOD when_load_then_attached.
    persistence->answer_load_with( persisted_log( ) ).

    DATA(loaded_logger) = load_through_spy( handle = 'HANDLE_OF_SAVED_LOG' ).

    cl_abap_unit_assert=>assert_equals( act = persistence->load_calls
                                        exp = 1
                                        msg = `The log must be read from the persistence once` ).
    cl_abap_unit_assert=>assert_equals( act = persistence->loaded_handle
                                        exp = 'HANDLE_OF_SAVED_LOG'
                                        msg = `The requested handle must reach the persistence` ).
    cl_abap_unit_assert=>assert_equals( act = loaded_logger->get_message_count( )
                                        exp = 2
                                        msg = `The persisted items must be the history of the logger` ).
  ENDMETHOD.

  METHOD when_load_then_registered.
    persistence->answer_load_with( persisted_log( ) ).

    DATA(loaded_logger) = load_through_spy( ).

    cl_abap_unit_assert=>assert_equals( act = zcl_cloud_logger=>get_instance( object     = test_object
                                                                              subobject  = test_subobject
                                                                              ext_number = 'LOADED' )
                                        exp = loaded_logger
                                        msg = `A loaded logger must be reachable under the key of its log` ).
  ENDMETHOD.

  METHOD given_empty_log_then_loads.
    persistence->answer_load_with( VALUE #( log         = cl_bali_log=>create( )
                                            object      = test_object
                                            subobject   = test_subobject
                                            external_id = 'EMPTY' ) ).

    DATA(loaded_logger) = load_through_spy( ).

    cl_abap_unit_assert=>assert_equals( act = loaded_logger->log_is_empty( )
                                        exp = abap_true
                                        msg = `A log without items must load as an empty logger` ).

    loaded_logger->log_string_add( `first entry after loading` ).

    cl_abap_unit_assert=>assert_equals( act = loaded_logger->get_message_count( )
                                        exp = 1
                                        msg = `An empty loaded logger must accept entries` ).
  ENDMETHOD.

  METHOD given_unknown_handle_raises.
    persistence->fail_next_load( ).

    TRY.
        load_through_spy( ).
        cl_abap_unit_assert=>fail( `A handle the database does not know must raise` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>error_in_loading
                                            msg = `The failure must be reported as error_in_loading` ).
        cl_abap_unit_assert=>assert_bound( act = error->previous
                                           msg = `The original cx_bali_runtime must be chained as previous` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_active_handle_raises.
    DATA(active) = registered_logger( 'ACTIVE_HANDLE' ).

    TRY.
        load_through_spy( handle = active->get_handle( ) ).
        cl_abap_unit_assert=>fail( `A log held by a live logger must not be loaded again` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>already_active
                                            msg = `The conflict must be reported as already_active` ).
        cl_abap_unit_assert=>assert_equals( act = persistence->load_calls
                                            exp = 0
                                            msg = `The session check must come before the database read` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_active_key_raises.
    registered_logger( 'LOADED' ).
    persistence->answer_load_with( persisted_log( ) ).

    TRY.
        load_through_spy( ).
        cl_abap_unit_assert=>fail( `A key that is in use must not be taken over by a loaded log` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>already_active
                                            msg = `The conflict must be reported as already_active` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_neg_trim_then_no_read.
    TRY.
        load_through_spy( trim_limit = -1 ).
        cl_abap_unit_assert=>fail( `A negative trim_limit must raise` ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->if_t100_message~t100key
                                            exp = zcx_cloud_logger_error=>invalid_trim_limit
                                            msg = `The value must be reported as invalid_trim_limit` ).
        cl_abap_unit_assert=>assert_equals( act = persistence->load_calls
                                            exp = 0
                                            msg = `An invalid value must be rejected before the database is read` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_explicit_default_expiry.
    " Spelling out the default expiry explicitly is the same configuration
    DATA(logger)         = registered_logger( 'DEFAULT_EXPIRY' ).
    DATA(default_expiry) = CONV d( ltd_fixed_system=>fixed_date + zif_cloud_logger=>c_default_expiry_days ).

    DATA(same) = zcl_cloud_logger=>get_instance( object      = test_object
                                                 subobject   = test_subobject
                                                 ext_number  = 'DEFAULT_EXPIRY'
                                                 expiry_date = default_expiry ).

    cl_abap_unit_assert=>assert_equals( act = same
                                        exp = logger
                                        msg = `The effective default expiry must not be reported as a conflict` ).
  ENDMETHOD.

  METHOD given_reset_then_expiry_synced.
    " The log created by a reset on the next day expires a day later, and the
    " registry must know: the new default is the configuration from then on
    DATA(logger)     = registered_logger( 'RESET_EXPIRY' ).
    DATA(next_day)   = CONV d( ltd_fixed_system=>fixed_date + 1 ).
    DATA(new_expiry) = CONV d( next_day + zif_cloud_logger=>c_default_expiry_days ).
    system->set_date( next_day ).

    logger->reset_appl_log( ).

    DATA(same) = zcl_cloud_logger=>get_instance( object      = test_object
                                                 subobject   = test_subobject
                                                 ext_number  = 'RESET_EXPIRY'
                                                 expiry_date = new_expiry ).

    cl_abap_unit_assert=>assert_equals( act = same
                                        exp = logger
                                        msg = `After a reset the new default expiry must not be a conflict` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_logger_contract IMPLEMENTATION.

  METHOD setup.
    real = NEW zcl_cloud_logger( object      = 'Z_CLOUD_LOG_SAMPLE'
                                 subobject   = 'SETUP'
                                 ext_number  = 'CONTRACT'
                                 db_save     = abap_false
                                 system      = NEW ltd_fixed_system( )
                                 persistence = NEW ltd_persistence_spy( ) ).
    fake = NEW zcl_cloud_logger_fake( ).
    both = VALUE #( ( real ) ( fake ) ).
  ENDMETHOD.

  METHOD when_free_text_then_same.
    LOOP AT both INTO DATA(logger).
      logger->log_string_add( `default severity` ).
      logger->log_string_add( string = `error`
                              msgty  = 'E' ).
      logger->log_string_add( string = `lower-case error`
                              msgty  = 'e' ).
      logger->log_string_add( string = `no severity`
                              msgty  = space ).
      logger->log_string_add( string = `unknown severity`
                              msgty  = '?' ).
    ENDLOOP.

    assert_same_with( 5 ).
  ENDMETHOD.

  METHOD when_messages_then_same.
    LOOP AT both INTO DATA(logger).
      logger->log_message_add( VALUE #( msgty = 'E'
                                        msgid = 'Z_CLOUD_LOGGER'
                                        msgno = '002'
                                        msgv1 = 'ZORDER' ) ).
      logger->log_message_add( VALUE #( msgid = 'Z_CLOUD_LOGGER'
                                        msgno = '008' ) ).
      logger->log_message_add( VALUE #( msgty = 'w'
                                        msgid = 'ZZ_NO_SUCH_CLASS'
                                        msgno = '999'
                                        msgv1 = 'kept' ) ).
      logger->log_message_add( VALUE #( ) ).
    ENDLOOP.

    assert_same_with( 3 ).
  ENDMETHOD.

  METHOD when_bapiret2_rows_then_same.
    LOOP AT both INTO DATA(logger).
      logger->log_bapiret2_structure_add( VALUE #( type    = 'E'
                                                   message = 'Text without message class' ) ).
      logger->log_bapiret2_structure_add( VALUE #( type = 'S' ) ).
      logger->log_bapiret2_structure_add( VALUE #( id         = 'Z_CLOUD_LOGGER'
                                                   number     = '002'
                                                   message_v1 = 'ZORDER' ) ).
      logger->log_bapiret2_structure_add( VALUE #( type    = 'E'
                                                   id      = 'ZZ_NO_SUCH_CLASS'
                                                   number  = '999'
                                                   message = 'Text supplied by the BAPI' ) ).
      logger->log_bapiret2_structure_add( VALUE #( type    = 'W'
                                                   id      = 'Z_CLOUD_LOGGER'
                                                   number  = '008'
                                                   message = 'Text the BAPI filled in another language' ) ).
    ENDLOOP.

    assert_same_with( 4 ).
  ENDMETHOD.

  METHOD when_bapiret2_table_then_same.
    LOOP AT both INTO DATA(logger).
      logger->log_bapiret2_table_add( bapiret2_t   = VALUE #( id     = 'Z_CLOUD_LOGGER'
                                                              number = '002'
                                                              ( type = 'S' )
                                                              ( type = 'w' )
                                                              ( type = 'E' )
                                                              ( type = space )
                                                              ( type = 'A' ) )
                                      min_severity = 'w' ).
    ENDLOOP.

    assert_same_with( 3 ).
  ENDMETHOD.

  METHOD when_exceptions_then_same.
    DATA(dynamic) = zcx_cloud_logger_message=>new_message( class    = 'CL'
                                                           number   = '000'
                                                           severity = if_abap_behv_message=>severity-error
                                                           v1       = 'first'
                                                           v2       = 'second' ).

    LOOP AT both INTO DATA(logger).
      logger->log_exception_add( NEW lth_counted_failure( 42 ) ).
      logger->log_exception_add( exception = NEW cx_sy_zerodivide( )
                                 severity  = space ).
      logger->log_exception_add( exception = CAST #( dynamic )
                                 severity  = 'w' ).
      logger->log_exception_add( NEW lth_plain_failure( ) ).
      logger->log_exception_add( VALUE #( ) ).
    ENDLOOP.

    assert_same_with( 4 ).
  ENDMETHOD.

  METHOD when_context_then_same.
    LOOP AT both INTO DATA(logger).
      logger->set_context( `Order 1` ).
      logger->log_string_add( `checked` ).
      logger->log_message_add( VALUE #( msgty = 'S'
                                        msgid = 'Z_CLOUD_LOGGER'
                                        msgno = '008' ) ).
      logger->log_exception_add( NEW cx_sy_zerodivide( ) ).
      logger->clear_context( ).
      logger->log_string_add( `done` ).
    ENDLOOP.

    assert_same_with( 4 ).
  ENDMETHOD.

  METHOD when_timer_misused_then_same.
    LOOP AT both INTO DATA(logger).
      logger->stop_timer( `never started` ).
      logger->start_timer( ).
      logger->start_timer( ).
    ENDLOOP.

    assert_same_with( 2 ).
  ENDMETHOD.

  METHOD when_timer_used_then_same.
    " The fixed clock of the real logger does not move, the fake has none: 0.000 seconds
    LOOP AT both INTO DATA(logger).
      logger->start_timer( ).
      logger->stop_timer( `block` ).
      logger->stop_timer( `stopped twice` ).
    ENDLOOP.

    assert_same_with( 2 ).
  ENDMETHOD.

  METHOD when_data_then_same.
    LOOP AT both INTO DATA(logger).
      logger->log_data_add( data  = VALUE bapiret2( type = 'E'
                                                    id   = 'CL' )
                            msgty = 'i' ).
      logger->log_data_add( `plain text` ).
    ENDLOOP.

    assert_same_with( 2 ).
  ENDMETHOD.

  METHOD when_long_text_then_same.
    DATA(long_text) = |{ repeat( val = `a`
                                 occ = 49 ) } { repeat( val = `word `
                                                        occ = 60 ) }|.

    LOOP AT both INTO DATA(logger).
      logger->log_string_add( long_text ).
    ENDLOOP.

    assert_same_with( 1 ).
  ENDMETHOD.

  METHOD when_searched_then_same.
    LOOP AT both INTO DATA(logger).
      logger->log_message_add( VALUE #( msgty = 'E'
                                        msgid = 'Z_CLOUD_LOGGER'
                                        msgno = '002'
                                        msgv1 = 'ZORDER' ) ).
      logger->log_string_add( `free text` ).
    ENDLOOP.

    cl_abap_unit_assert=>assert_equals( act = search_answers( fake )
                                        exp = search_answers( real )
                                        msg = `The fake must answer every search like the real logger` ).
    cl_abap_unit_assert=>assert_equals( act = search_answers( real )
                                        exp = `XXX--X-`
                                        msg = `The probe searches must cover hits and misses` ).
  ENDMETHOD.

  METHOD when_reset_then_same.
    LOOP AT both INTO DATA(logger).
      logger->set_context( `before` ).
      logger->log_string_add( string = `gone after the reset`
                              msgty  = 'E' ).
      logger->start_timer( ).
      logger->reset_appl_log( ).
      logger->stop_timer( `timer was reset as well` ).
    ENDLOOP.

    assert_same_with( 1 ).
  ENDMETHOD.

  METHOD when_merged_then_same.
    DATA(other) = CAST zif_cloud_logger( NEW zcl_cloud_logger_fake( ) ).
    other->set_context( `other log` ).
    other->log_string_add( string = `merged error`
                           msgty  = 'E' ).
    other->log_message_add( VALUE #( msgty = 'S'
                                     msgid = 'Z_CLOUD_LOGGER'
                                     msgno = '008' ) ).

    LOOP AT both INTO DATA(logger).
      logger->log_string_add( `own entry` ).
      logger->merge_logs( other ).
      logger->merge_logs( logger ).
      logger->merge_logs( VALUE #( ) ).
    ENDLOOP.

    assert_same_with( 3 ).
  ENDMETHOD.

  METHOD when_freed_then_same.
    TYPES t100keys TYPE STANDARD TABLE OF scx_t100key WITH EMPTY KEY.

    DATA refusals TYPE t100keys.

    LOOP AT both INTO DATA(logger).
      logger->log_string_add( `released with the logger` ).
      logger->free( ).

      TRY.
          logger->log_string_add( `after free` ).
        CATCH zcx_cloud_logger_error INTO DATA(error).
          INSERT error->if_t100_message~t100key INTO TABLE refusals.
      ENDTRY.
    ENDLOOP.

    cl_abap_unit_assert=>assert_equals(
        act = refusals
        exp = VALUE t100keys( ( zcx_cloud_logger_error=>instance_released )
                              ( zcx_cloud_logger_error=>instance_released ) )
        msg = `Both must refuse to write after free( ) with instance_released` ).
    assert_same_with( 0 ).
  ENDMETHOD.

  METHOD when_filtered_then_same.
    LOOP AT both INTO DATA(logger).
      logger->log_string_add( string = `success`
                              msgty  = 'S' ).
      logger->log_string_add( string = `information`
                              msgty  = 'I' ).
      logger->log_message_add( VALUE #( msgty = 'W'
                                        msgid = 'Z_CLOUD_LOGGER'
                                        msgno = '008' ) ).
      logger->log_exception_add( NEW cx_sy_zerodivide( ) ).
      logger->log_string_add( string = `abandon`
                              msgty  = 'A' ).
      logger->log_string_add( string = `terminate`
                              msgty  = 'X' ).
    ENDLOOP.

    assert_same_with( 6 ).
    assert_same_with( entries      = 6
                      min_severity = 'I' ).
    assert_same_with( entries      = 4
                      min_severity = 'W' ).
    assert_same_with( entries      = 3
                      min_severity = 'e' ).
    assert_same_with( entries      = 2
                      min_severity = 'A' ).
    assert_same_with( entries      = 2
                      min_severity = 'X' ).
    assert_same_with( entries      = 6
                      min_severity = '?' ).
  ENDMETHOD.

  METHOD observed.
    result-entries  = CORRESPONDING #( logger->get_messages( min_severity ) ).
    result-flat     = logger->get_messages_flat( min_severity ).
    result-bapiret2 = logger->get_messages_as_bapiret2( min_severity ).
    result-rap      = rap_view_of( logger       = logger
                                   min_severity = min_severity ).
    result-counts   = |all { logger->get_message_count( ) }| &&
                      | I { logger->get_message_count( 'I' ) }| &&
                      | S { logger->get_message_count( 'S' ) }| &&
                      | W { logger->get_message_count( 'W' ) }| &&
                      | E { logger->get_message_count( 'E' ) }| &&
                      | A { logger->get_message_count( 'A' ) }| &&
                      | X { logger->get_message_count( 'X' ) }| &&
                      | e { logger->get_message_count( 'e' ) }|.
    result-answers  = |empty { logger->log_is_empty( ) }| &&
                      | messages { logger->log_contains_messages( ) }| &&
                      | error { logger->log_contains_error( ) }| &&
                      | warning { logger->log_contains_warning( ) }| &&
                      | search { search_answers( logger ) }|.
  ENDMETHOD.

  METHOD rap_view_of.
    LOOP AT logger->get_messages_rap( min_severity ) INTO DATA(message).
      DATA(variables) = CAST if_t100_dyn_msg( message ).

      INSERT VALUE #( t100key   = CAST if_t100_message( message )->t100key
                      variables = VALUE #( msgty = variables->msgty
                                           msgv1 = variables->msgv1
                                           msgv2 = variables->msgv2
                                           msgv3 = variables->msgv3
                                           msgv4 = variables->msgv4 )
                      severity  = message->m_severity ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD search_answers.
    DATA(probes) = VALUE zif_cloud_logger=>bapiret2_messages( ( )
                                                              ( id = 'Z_CLOUD_LOGGER' )
                                                              ( id = 'Z_CLOUD_LOGGER' number = '002' type = 'E' )
                                                              ( id = 'Z_CLOUD_LOGGER' number = '003' )
                                                              ( type = 'A' )
                                                              ( message_v1 = 'ZORDER' )
                                                              ( id = 'Z_CLOUD_LOGGER' message_v1 = 'OTHER' ) ).

    LOOP AT probes REFERENCE INTO DATA(probe).
      result = result && COND string( WHEN logger->search_message( VALUE #( msgid = probe->id
                                                                            msgno = probe->number
                                                                            msgty = probe->type
                                                                            msgv1 = probe->message_v1 ) ) = abap_true
                                      THEN `X`
                                      ELSE `-` ).
    ENDLOOP.
  ENDMETHOD.

  METHOD assert_same_with.
    DATA(of_real) = observed( logger       = real
                              min_severity = min_severity ).
    DATA(of_fake) = observed( logger       = fake
                              min_severity = min_severity ).

    cl_abap_unit_assert=>assert_equals( act = lines( of_real-entries )
                                        exp = entries
                                        msg = `The real logger must return the expected number of entries` ).
    cl_abap_unit_assert=>assert_equals( act = of_fake-entries
                                        exp = of_real-entries
                                        msg = `The fake must keep the same message key, text, severity and context` ).
    cl_abap_unit_assert=>assert_equals( act = of_fake-flat
                                        exp = of_real-flat
                                        msg = `The fake must render the same flat lines` ).
    cl_abap_unit_assert=>assert_equals( act = of_fake-bapiret2
                                        exp = of_real-bapiret2
                                        msg = `The fake must return the same BAPI return table` ).
    cl_abap_unit_assert=>assert_equals( act = of_fake-rap
                                        exp = of_real-rap
                                        msg = `The fake must return the same RAP messages` ).
    cl_abap_unit_assert=>assert_equals( act = of_fake-counts
                                        exp = of_real-counts
                                        msg = `The fake must count like the real logger` ).
    cl_abap_unit_assert=>assert_equals( act = of_fake-answers
                                        exp = of_real-answers
                                        msg = `The fake must answer the queries like the real logger` ).
  ENDMETHOD.

ENDCLASS.
