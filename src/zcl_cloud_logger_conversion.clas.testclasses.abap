"! T100 exception whose key names a numeric and a table attribute
CLASS lth_typed_failure DEFINITION FINAL FOR TESTING
  INHERITING FROM cx_static_check.

  PUBLIC SECTION.
    INTERFACES if_t100_message.

    DATA item_count TYPE i READ-ONLY.
    DATA item_names TYPE string_table READ-ONLY.

    METHODS constructor
      IMPORTING item_count TYPE i.

ENDCLASS.


CLASS lth_typed_failure IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    me->item_count = item_count.
    item_names = VALUE #( ( `first` ) ).
    if_t100_message~t100key = VALUE #( msgid = 'Z_CLOUD_LOGGER'
                                       msgno = '003'
                                       attr1 = 'ITEM_COUNT'
                                       attr2 = 'ITEM_NAMES'
                                       attr3 = 'NO_SUCH_ATTRIBUTE' ).
  ENDMETHOD.

ENDCLASS.


"! Exception without if_t100_message
CLASS lth_keyless_failure DEFINITION FINAL FOR TESTING
  INHERITING FROM cx_static_check.
ENDCLASS.


CLASS lth_keyless_failure IMPLEMENTATION.
ENDCLASS.


CLASS ltc_severity DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS given_lower_case_then_upper     FOR TESTING.
    METHODS given_blank_then_fallback       FOR TESTING.
    METHODS given_unknown_then_fallback     FOR TESTING.
    METHODS given_min_w_then_w_and_above    FOR TESTING.
    METHODS given_min_e_then_e_and_above    FOR TESTING.
    METHODS given_min_a_or_x_then_both      FOR TESTING.
    METHODS given_min_i_then_all_kept       FOR TESTING.
    METHODS given_lower_case_min_filters    FOR TESTING.
    METHODS given_lower_case_row_then_kept  FOR TESTING.

ENDCLASS.


CLASS ltc_severity IMPLEMENTATION.

  METHOD given_lower_case_then_upper.
    DATA(severity) = zcl_cloud_logger_conversion=>normalized_severity( msgty    = 'e'
                                                                       fallback = 'W' ).

    cl_abap_unit_assert=>assert_equals( act = severity
                                        exp = 'E'
                                        msg = `A lower-case severity must be turned into upper case` ).
  ENDMETHOD.

  METHOD given_blank_then_fallback.
    DATA(severity) = zcl_cloud_logger_conversion=>normalized_severity( msgty    = space
                                                                       fallback = 'S' ).

    cl_abap_unit_assert=>assert_equals( act = severity
                                        exp = 'S'
                                        msg = `A blank severity must become the fallback` ).
  ENDMETHOD.

  METHOD given_unknown_then_fallback.
    DATA(severity) = zcl_cloud_logger_conversion=>normalized_severity( msgty    = 'Z'
                                                                       fallback = 'W' ).

    cl_abap_unit_assert=>assert_equals( act = severity
                                        exp = 'W'
                                        msg = `A severity outside I, S, W, E, A, X must become the fallback` ).
  ENDMETHOD.

  METHOD given_min_w_then_w_and_above.
    DATA(kept) = ``.

    DO strlen( `SIWEAX` ) TIMES.
      DATA(severity) = CONV symsgty( substring( val = `SIWEAX`
                                                off = sy-index - 1
                                                len = 1 ) ).
      IF zcl_cloud_logger_conversion=>reaches_severity( severity = severity
                                                        minimum  = 'W' ) = abap_true.
        kept = kept && severity.
      ENDIF.
    ENDDO.

    cl_abap_unit_assert=>assert_equals( act = kept
                                        exp = `WEAX`
                                        msg = `Minimum W must keep W, E, A and X` ).
  ENDMETHOD.

  METHOD given_min_e_then_e_and_above.
    DATA(kept)       = zcl_cloud_logger_conversion=>reaches_severity( severity = 'W'
                                                                      minimum  = 'E' ).
    DATA(other_kept) = zcl_cloud_logger_conversion=>reaches_severity( severity = 'A'
                                                                      minimum  = 'E' ).

    cl_abap_unit_assert=>assert_equals( act = kept
                                        exp = abap_false
                                        msg = `Minimum E must drop a warning` ).
    cl_abap_unit_assert=>assert_equals( act = other_kept
                                        exp = abap_true
                                        msg = `Minimum E must keep an abort` ).
  ENDMETHOD.

  METHOD given_min_a_or_x_then_both.
    DATA(kept)       = zcl_cloud_logger_conversion=>reaches_severity( severity = 'A'
                                                                      minimum  = 'X' ).
    DATA(other_kept) = zcl_cloud_logger_conversion=>reaches_severity( severity = 'E'
                                                                      minimum  = 'A' ).

    cl_abap_unit_assert=>assert_equals( act = kept
                                        exp = abap_true
                                        msg = `A and X rank the same: minimum X must keep A` ).
    cl_abap_unit_assert=>assert_equals( act = other_kept
                                        exp = abap_false
                                        msg = `Minimum A must drop an error` ).
  ENDMETHOD.

  METHOD given_min_i_then_all_kept.
    DATA(kept)       = zcl_cloud_logger_conversion=>reaches_severity( severity = 'S'
                                                                      minimum  = 'I' ).
    DATA(other_kept) = zcl_cloud_logger_conversion=>reaches_severity( severity = 'S'
                                                                      minimum  = space ).

    cl_abap_unit_assert=>assert_equals( act = kept
                                        exp = abap_true
                                        msg = `Minimum I is no filter` ).
    cl_abap_unit_assert=>assert_equals( act = other_kept
                                        exp = abap_true
                                        msg = `No minimum is no filter` ).
  ENDMETHOD.

  METHOD given_lower_case_min_filters.
    DATA(kept) = zcl_cloud_logger_conversion=>reaches_severity( severity = 'W'
                                                                minimum  = 'e' ).

    cl_abap_unit_assert=>assert_equals( act = kept
                                        exp = abap_false
                                        msg = `A lower-case minimum must filter like its upper-case form` ).
  ENDMETHOD.

  METHOD given_lower_case_row_then_kept.
    DATA(kept) = zcl_cloud_logger_conversion=>reaches_severity( severity = 'e'
                                                                minimum  = 'E' ).

    cl_abap_unit_assert=>assert_equals( act = kept
                                        exp = abap_true
                                        msg = `A lower-case severity must be ranked like its upper-case form` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_text_to_symsg DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    " The text the message runtime builds from the carrier message
    METHODS resolved
      IMPORTING !text         TYPE string
      RETURNING VALUE(result) TYPE string.

    METHODS given_blank_at_50_then_kept     FOR TESTING.
    METHODS given_blank_at_100_150_kept     FOR TESTING.
    METHODS given_blanks_across_50_kept     FOR TESTING.
    METHODS given_blank_slice_then_ends     FOR TESTING.
    METHODS given_word_over_50_then_cut     FOR TESTING.
    METHODS given_exact_lengths_then_full   FOR TESTING.
    METHODS given_over_200_then_cut_off     FOR TESTING.
    METHODS given_empty_then_no_variables   FOR TESTING.
    METHODS given_short_text_then_msgv1     FOR TESTING.
    METHODS given_blank_msgty_then_info     FOR TESTING.
    METHODS when_packed_then_carrier_key    FOR TESTING.

ENDCLASS.


CLASS ltc_text_to_symsg IMPLEMENTATION.

  METHOD resolved.
    DATA(symsg) = zcl_cloud_logger_conversion=>text_to_symsg( text  = text
                                                              msgty = 'I' ).

    MESSAGE ID symsg-msgid TYPE symsg-msgty NUMBER symsg-msgno
            WITH symsg-msgv1 symsg-msgv2 symsg-msgv3 symsg-msgv4
            INTO result.
  ENDMETHOD.

  METHOD given_blank_at_50_then_kept.
    DATA(text) = |{ repeat( val = `a`
                            occ = 49 ) } bbbbb|.

    cl_abap_unit_assert=>assert_equals( act = resolved( text )
                                        exp = text
                                        msg = `A blank at position 50 must survive the split` ).
  ENDMETHOD.

  METHOD given_blank_at_100_150_kept.
    DATA(word) = repeat( val = `b`
                         occ = 49 ).
    DATA(text) = |{ word } { word } { word } end|.

    cl_abap_unit_assert=>assert_equals( act = resolved( text )
                                        exp = text
                                        msg = `Blanks at positions 50, 100 and 150 must survive the split` ).
  ENDMETHOD.

  METHOD given_blanks_across_50_kept.
    DATA(text) = |{ repeat( val = `a`
                            occ = 48 ) }    bbb|.

    cl_abap_unit_assert=>assert_equals( act = resolved( text )
                                        exp = text
                                        msg = `Several blanks across the boundary must all open the next slice` ).
  ENDMETHOD.

  METHOD given_blank_slice_then_ends.
    DATA(text) = |{ repeat( val = ` `
                            occ = 60 ) }x|.

    DATA(symsg) = zcl_cloud_logger_conversion=>text_to_symsg( text  = text
                                                              msgty = 'I' ).

    cl_abap_unit_assert=>assert_initial( act = symsg-msgv1
                                         msg = `A slice of blanks only is taken as it is` ).
    cl_abap_unit_assert=>assert_equals( act = symsg-msgv2
                                        exp = '          x'
                                        msg = `The text after a blank slice must follow in the next variable` ).
  ENDMETHOD.

  METHOD given_word_over_50_then_cut.
    DATA(symsg) = zcl_cloud_logger_conversion=>text_to_symsg( text  = repeat( val = `a`
                                                                              occ = 60 )
                                                              msgty = 'I' ).

    cl_abap_unit_assert=>assert_equals( act = strlen( symsg-msgv1 )
                                        exp = 50
                                        msg = `A word longer than a variable must fill the first variable` ).
    cl_abap_unit_assert=>assert_equals( act = strlen( symsg-msgv2 )
                                        exp = 10
                                        msg = `The rest of the word must follow in the second variable` ).
  ENDMETHOD.

  METHOD given_exact_lengths_then_full.
    DO 4 TIMES.
      DATA(length) = sy-index * 50.
      DATA(text)   = repeat( val = `x`
                             occ = length ).

      cl_abap_unit_assert=>assert_equals( act = resolved( text )
                                          exp = text
                                          msg = |A text of exactly { length } characters must be kept| ).
    ENDDO.
  ENDMETHOD.

  METHOD given_over_200_then_cut_off.
    DATA(text) = repeat( val = `0123456789`
                         occ = 25 ).

    cl_abap_unit_assert=>assert_equals( act = resolved( text )
                                        exp = substring( val = text
                                                         len = 200 )
                                        msg = `Text beyond four variables must be cut off, not raise` ).
  ENDMETHOD.

  METHOD given_empty_then_no_variables.
    DATA(symsg) = zcl_cloud_logger_conversion=>text_to_symsg( text  = ``
                                                              msgty = 'I' ).

    cl_abap_unit_assert=>assert_initial( act = symsg-msgv1
                                         msg = `An empty text must leave the variables empty` ).
  ENDMETHOD.

  METHOD given_short_text_then_msgv1.
    DATA(symsg) = zcl_cloud_logger_conversion=>text_to_symsg( text  = `short text`
                                                              msgty = 'W' ).

    cl_abap_unit_assert=>assert_equals( act = symsg-msgv1
                                        exp = 'short text'
                                        msg = `A short text must go into the first variable` ).
    cl_abap_unit_assert=>assert_initial( act = symsg-msgv2
                                         msg = `Unused variables must stay empty` ).
  ENDMETHOD.

  METHOD given_blank_msgty_then_info.
    DATA(symsg) = zcl_cloud_logger_conversion=>text_to_symsg( text  = `text`
                                                              msgty = space ).

    cl_abap_unit_assert=>assert_equals( act = symsg-msgty
                                        exp = 'I'
                                        msg = `A carrier message without severity must be an information` ).
  ENDMETHOD.

  METHOD when_packed_then_carrier_key.
    DATA(symsg) = zcl_cloud_logger_conversion=>text_to_symsg( text  = `text`
                                                              msgty = 'e' ).

    cl_abap_unit_assert=>assert_equals( act = symsg-msgid
                                        exp = zif_cloud_logger=>c_free_text_message-msgid
                                        msg = `Free text must be carried by the logger's message class` ).
    cl_abap_unit_assert=>assert_equals( act = symsg-msgno
                                        exp = zif_cloud_logger=>c_free_text_message-msgno
                                        msg = `Free text must be carried by the placeholder message` ).
    cl_abap_unit_assert=>assert_equals( act = symsg-msgty
                                        exp = 'E'
                                        msg = `The severity of the carrier message must be normalised` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_exception_key DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS given_t100_exception_then_key   FOR TESTING.
    METHODS given_int_attr_then_unpadded    FOR TESTING.
    METHODS given_table_attr_then_empty     FOR TESTING.
    METHODS given_unknown_attr_then_empty   FOR TESTING.
    METHODS given_dyn_message_then_vars     FOR TESTING.
    METHODS given_no_key_then_severity      FOR TESTING.

ENDCLASS.


CLASS ltc_exception_key IMPLEMENTATION.

  METHOD given_t100_exception_then_key.
    DATA(failure) = NEW zcx_cloud_logger_error( textid     = zcx_cloud_logger_error=>config_mismatch
                                                log_object = 'ZTEST_OBJECT' ).

    DATA(symsg) = zcl_cloud_logger_conversion=>symsg_from_exception( exception = failure
                                                                     severity  = 'E' ).

    cl_abap_unit_assert=>assert_equals( act = symsg
                                        exp = VALUE symsg( msgty = 'E'
                                                           msgid = 'Z_CLOUD_LOGGER'
                                                           msgno = '007'
                                                           msgv1 = 'ZTEST_OBJECT' )
                                        msg = `Key and attribute of a T100 exception must become the message` ).
  ENDMETHOD.

  METHOD given_int_attr_then_unpadded.
    DATA(symsg) = zcl_cloud_logger_conversion=>symsg_from_exception( exception = NEW lth_typed_failure( 42 )
                                                                     severity  = 'E' ).

    cl_abap_unit_assert=>assert_equals( act = symsg-msgv1
                                        exp = '42'
                                        msg = `A numeric attribute must not be right-aligned in the variable` ).
  ENDMETHOD.

  METHOD given_table_attr_then_empty.
    DATA(symsg) = zcl_cloud_logger_conversion=>symsg_from_exception( exception = NEW lth_typed_failure( 1 )
                                                                     severity  = 'E' ).

    cl_abap_unit_assert=>assert_initial( act = symsg-msgv2
                                         msg = `An attribute that is not elementary must yield an empty variable` ).
  ENDMETHOD.

  METHOD given_unknown_attr_then_empty.
    DATA(symsg) = zcl_cloud_logger_conversion=>symsg_from_exception( exception = NEW lth_typed_failure( 1 )
                                                                     severity  = 'E' ).

    cl_abap_unit_assert=>assert_initial( act = symsg-msgv3
                                         msg = `An attribute name that does not exist must yield an empty variable` ).
  ENDMETHOD.

  METHOD given_dyn_message_then_vars.
    DATA(message) = zcx_cloud_logger_message=>new_message( class    = 'CL'
                                                           number   = '000'
                                                           severity = if_abap_behv_message=>severity-error
                                                           v1       = 'first'
                                                           v2       = 'second' ).

    DATA(symsg) = zcl_cloud_logger_conversion=>symsg_from_exception( exception = CAST #( message )
                                                                     severity  = 'W' ).

    cl_abap_unit_assert=>assert_equals( act = symsg
                                        exp = VALUE symsg( msgty = 'W'
                                                           msgid = 'CL'
                                                           msgno = '000'
                                                           msgv1 = 'first'
                                                           msgv2 = 'second' )
                                        msg = `Dynamic message variables must be read through if_t100_dyn_msg` ).
  ENDMETHOD.

  METHOD given_no_key_then_severity.
    DATA(symsg) = zcl_cloud_logger_conversion=>symsg_from_exception( exception = NEW lth_keyless_failure( )
                                                                     severity  = 'E' ).

    cl_abap_unit_assert=>assert_equals( act = symsg
                                        exp = VALUE symsg( msgty = 'E' )
                                        msg = `An exception without T100 key must carry the severity only` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_search DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    DATA entry TYPE symsg.

    METHODS setup.

    METHODS given_same_variable_then_match  FOR TESTING.
    METHODS given_other_variable_no_match   FOR TESTING.
    METHODS given_key_only_then_match       FOR TESTING.
    METHODS given_other_number_no_match     FOR TESTING.
    METHODS given_empty_search_then_match   FOR TESTING.

ENDCLASS.


CLASS ltc_search IMPLEMENTATION.

  METHOD setup.
    entry = VALUE #( msgty = 'W'
                     msgid = 'CL'
                     msgno = '005'
                     msgv1 = 'abc'
                     msgv4 = 'last' ).
  ENDMETHOD.

  METHOD given_same_variable_then_match.
    cl_abap_unit_assert=>assert_equals(
        act = zcl_cloud_logger_conversion=>matches_search( symsg  = entry
                                                           search = VALUE #( msgv1 = 'abc'
                                                                             msgv4 = 'last' ) )
        exp = abap_true
        msg = `Filled variables of the search must be compared` ).
  ENDMETHOD.

  METHOD given_other_variable_no_match.
    cl_abap_unit_assert=>assert_equals(
        act = zcl_cloud_logger_conversion=>matches_search( symsg  = entry
                                                           search = VALUE #( msgid = 'CL'
                                                                             msgv1 = 'zzz' ) )
        exp = abap_false
        msg = `A different variable must not match` ).
  ENDMETHOD.

  METHOD given_key_only_then_match.
    cl_abap_unit_assert=>assert_equals(
        act = zcl_cloud_logger_conversion=>matches_search( symsg  = entry
                                                           search = VALUE #( msgid = 'CL'
                                                                             msgno = '005'
                                                                             msgty = 'W' ) )
        exp = abap_true
        msg = `Initial variables of the search must not be compared` ).
  ENDMETHOD.

  METHOD given_other_number_no_match.
    cl_abap_unit_assert=>assert_equals(
        act = zcl_cloud_logger_conversion=>matches_search( symsg  = entry
                                                           search = VALUE #( msgno = '003' ) )
        exp = abap_false
        msg = `A different message number must not match` ).
  ENDMETHOD.

  METHOD given_empty_search_then_match.
    cl_abap_unit_assert=>assert_equals(
        act = zcl_cloud_logger_conversion=>matches_search( symsg  = entry
                                                           search = VALUE #( ) )
        exp = abap_true
        msg = `An initial search matches every message` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_message_text DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    DATA message TYPE symsg.

    METHODS setup.

    METHODS given_resolved_then_kept        FOR TESTING.
    METHODS given_not_found_then_fallback   FOR TESTING.
    METHODS given_not_found_no_fallback     FOR TESTING.
    METHODS given_empty_then_fallback       FOR TESTING.
    METHODS given_empty_then_raw_parts      FOR TESTING.

ENDCLASS.


CLASS ltc_message_text IMPLEMENTATION.

  METHOD setup.
    message = VALUE #( msgty = 'E'
                       msgid = 'ZZ_NO_SUCH_CLASS'
                       msgno = '999'
                       msgv1 = 'poison' ).
  ENDMETHOD.

  METHOD given_resolved_then_kept.
    DATA(text) = zcl_cloud_logger_conversion=>text_or_fallback( symsg    = message
                                                                resolved = `Order 1 is locked`
                                                                fallback = `Text of the caller` ).

    cl_abap_unit_assert=>assert_equals( act = text
                                        exp = `Order 1 is locked`
                                        msg = `A resolved text must win over the fallback` ).
  ENDMETHOD.

  METHOD given_not_found_then_fallback.
    DATA(text) = zcl_cloud_logger_conversion=>text_or_fallback( symsg    = message
                                                                resolved = `E:ZZ_NO_SUCH_CLASS:999 poison`
                                                                fallback = `Text of the caller` ).

    cl_abap_unit_assert=>assert_equals( act = text
                                        exp = `Text of the caller`
                                        msg = `The rendering of a missing message must give way to the fallback` ).
  ENDMETHOD.

  METHOD given_not_found_no_fallback.
    DATA(text) = zcl_cloud_logger_conversion=>text_or_fallback( symsg    = message
                                                                resolved = `E:ZZ_NO_SUCH_CLASS:999 poison` ).

    cl_abap_unit_assert=>assert_equals( act = text
                                        exp = `E:ZZ_NO_SUCH_CLASS:999 poison`
                                        msg = `Without fallback the text of the message runtime is kept` ).
  ENDMETHOD.

  METHOD given_empty_then_fallback.
    DATA(text) = zcl_cloud_logger_conversion=>text_or_fallback( symsg    = message
                                                                resolved = ``
                                                                fallback = `Text of the caller` ).

    cl_abap_unit_assert=>assert_equals( act = text
                                        exp = `Text of the caller`
                                        msg = `An empty text must give way to the fallback` ).
  ENDMETHOD.

  METHOD given_empty_then_raw_parts.
    DATA(text) = zcl_cloud_logger_conversion=>text_or_fallback( symsg    = message
                                                                resolved = `` ).

    cl_abap_unit_assert=>assert_equals( act = text
                                        exp = `ZZ_NO_SUCH_CLASS 999 poison`
                                        msg = `Without text and fallback the raw message parts must be shown` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_entries_reaching DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    DATA entries TYPE zif_cloud_logger=>log_messages.

    METHODS setup.

    METHODS given_no_minimum_then_all       FOR TESTING.
    METHODS given_min_i_then_all            FOR TESTING.
    METHODS given_min_w_then_four           FOR TESTING.
    METHODS given_min_e_then_order_kept     FOR TESTING.
    METHODS given_min_a_then_a_and_x        FOR TESTING.
    METHODS given_lower_min_then_filtered   FOR TESTING.
    METHODS given_blank_type_then_dropped   FOR TESTING.

    "! The severities of the entries, one character each, in their order
    METHODS severities_of
      IMPORTING !entries      TYPE zif_cloud_logger=>log_messages
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS ltc_entries_reaching IMPLEMENTATION.

  METHOD setup.
    entries = VALUE #( ( type = 'S' message = `success` )
                       ( type = 'E' message = `first error` )
                       ( type = 'I' message = `information` )
                       ( type = 'W' message = `warning` )
                       ( type = 'X' message = `terminate` )
                       ( type = 'E' message = `second error` )
                       ( type = 'A' message = `abandon` ) ).
  ENDMETHOD.

  METHOD severities_of.
    LOOP AT entries REFERENCE INTO DATA(entry).
      result = result && entry->type.
    ENDLOOP.
  ENDMETHOD.

  METHOD given_no_minimum_then_all.
    DATA(kept) = zcl_cloud_logger_conversion=>entries_reaching( entries = entries
                                                                minimum = space ).

    cl_abap_unit_assert=>assert_equals( act = kept
                                        exp = entries
                                        msg = `Without a minimum every entry must be returned` ).
  ENDMETHOD.

  METHOD given_min_i_then_all.
    DATA(kept) = zcl_cloud_logger_conversion=>entries_reaching( entries = entries
                                                                minimum = 'I' ).

    cl_abap_unit_assert=>assert_equals( act = lines( kept )
                                        exp = 7
                                        msg = `Minimum I is no filter` ).
  ENDMETHOD.

  METHOD given_min_w_then_four.
    DATA(kept) = zcl_cloud_logger_conversion=>entries_reaching( entries = entries
                                                                minimum = 'W' ).

    cl_abap_unit_assert=>assert_equals( act = severities_of( kept )
                                        exp = `EWXEA`
                                        msg = `Minimum W must keep W, E, A and X` ).
  ENDMETHOD.

  METHOD given_min_e_then_order_kept.
    DATA(kept) = zcl_cloud_logger_conversion=>entries_reaching( entries = entries
                                                                minimum = 'E' ).

    cl_abap_unit_assert=>assert_equals( act = severities_of( kept )
                                        exp = `EXEA`
                                        msg = `Minimum E must keep E, A and X` ).
    cl_abap_unit_assert=>assert_equals( act = kept[ 3 ]-message
                                        exp = `second error`
                                        msg = `The entries must keep their order and content` ).
  ENDMETHOD.

  METHOD given_min_a_then_a_and_x.
    DATA(from_a) = zcl_cloud_logger_conversion=>entries_reaching( entries = entries
                                                                  minimum = 'A' ).
    DATA(from_x) = zcl_cloud_logger_conversion=>entries_reaching( entries = entries
                                                                  minimum = 'X' ).

    cl_abap_unit_assert=>assert_equals( act = severities_of( from_a )
                                        exp = `XA`
                                        msg = `Minimum A must keep A and X` ).
    cl_abap_unit_assert=>assert_equals( act = from_x
                                        exp = from_a
                                        msg = `Minimum X must filter like A` ).
  ENDMETHOD.

  METHOD given_lower_min_then_filtered.
    DATA(kept) = zcl_cloud_logger_conversion=>entries_reaching( entries = entries
                                                                minimum = 'e' ).

    cl_abap_unit_assert=>assert_equals( act = severities_of( kept )
                                        exp = `EXEA`
                                        msg = `A lower-case minimum must filter like E` ).
  ENDMETHOD.

  METHOD given_blank_type_then_dropped.
    INSERT VALUE #( message = `entry without severity` ) INTO TABLE entries.

    DATA(kept) = zcl_cloud_logger_conversion=>entries_reaching( entries = entries
                                                                minimum = 'W' ).

    cl_abap_unit_assert=>assert_equals( act = lines( kept )
                                        exp = 5
                                        msg = `An entry without severity reaches no minimum` ).
  ENDMETHOD.

ENDCLASS.
