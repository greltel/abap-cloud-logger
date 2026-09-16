"! Records what the viewer writes: strings verbatim, tables as their line count.
CLASS ltd_console_spy DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun_out PARTIALLY IMPLEMENTED.

    TYPES:
      BEGIN OF write_call,
        "! Text of an elementary write, empty for tables
        text       TYPE string,
        "! Number of lines of a table write, 0 for elementary data
        line_count TYPE i,
      END OF write_call.
    TYPES write_calls TYPE STANDARD TABLE OF write_call WITH EMPTY KEY.

    DATA calls TYPE write_calls READ-ONLY.
ENDCLASS.


CLASS ltd_console_spy IMPLEMENTATION.

  METHOD if_oo_adt_classrun_out~write.
    FIELD-SYMBOLS <table> TYPE ANY TABLE.

    output = me.

    IF cl_abap_typedescr=>describe_by_data( data )->kind = cl_abap_typedescr=>kind_table.
      ASSIGN data TO <table>.
      INSERT VALUE #( line_count = lines( <table> ) ) INTO TABLE calls.
    ELSE.
      INSERT VALUE #( text = data ) INTO TABLE calls.
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_console_viewer DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    DATA console TYPE REF TO ltd_console_spy.
    DATA cut     TYPE REF TO zif_cloud_logger_viewer.
    DATA logger  TYPE REF TO zif_cloud_logger.

    METHODS setup    RAISING cx_static_check.
    METHODS teardown.

    METHODS given_2_entries_then_header_2   FOR TESTING RAISING cx_static_check.
    METHODS given_2_entries_then_table_2    FOR TESTING RAISING cx_static_check.
    METHODS given_empty_log_then_header FOR TESTING RAISING cx_static_check.
    METHODS given_trail_then_trail_written  FOR TESTING RAISING cx_static_check.
    METHODS given_unbound_logger_no_write   FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_console_viewer IMPLEMENTATION.

  METHOD setup.
    console = NEW #( ).
    cut     = NEW zcl_cloud_logger_view_console( console ).
    logger  = zcl_cloud_logger=>get_instance( object     = 'Z_CLOUD_LOG_SAMPLE'
                                              subobject  = 'SETUP'
                                              ext_number = 'CONSOLE_VIEWER'
                                              db_save    = abap_false ).
  ENDMETHOD.

  METHOD teardown.
    logger->free( ).
    CLEAR logger.
    CLEAR cut.
    CLEAR console.
  ENDMETHOD.

  METHOD given_2_entries_then_header_2.
    logger->log_string_add( string = `first`
                            msgty  = 'E'
       )->log_string_add( `second` ).

    cut->view( logger ).

    DATA(header) = console->calls[ 1 ].

    cl_abap_unit_assert=>assert_char_cp( act = header-text
                                         exp = '*2 entries*'
                                         msg = `Header must state the number of entries` ).
    cl_abap_unit_assert=>assert_char_cp( act = header-text
                                         exp = '*E:1*'
                                         msg = `Header must count the errors` ).
  ENDMETHOD.

  METHOD given_2_entries_then_table_2.
    logger->log_string_add( `first`
       )->log_string_add( `second` ).

    cut->view( logger ).

    cl_abap_unit_assert=>assert_equals( act = lines( console->calls )
                                        exp = 2
                                        msg = `Header and message table must be the only writes` ).
    cl_abap_unit_assert=>assert_equals( act = console->calls[ 2 ]-line_count
                                        exp = 2
                                        msg = `The message table must contain one line per entry` ).
  ENDMETHOD.

  METHOD given_empty_log_then_header.
    cut->view( logger ).

    cl_abap_unit_assert=>assert_equals( act = lines( console->calls )
                                        exp = 1
                                        msg = `An empty log must produce the header and nothing else` ).
    cl_abap_unit_assert=>assert_char_cp( act = console->calls[ 1 ]-text
                                         exp = '*0 entries*'
                                         msg = `Header must state zero entries` ).
  ENDMETHOD.

  METHOD given_trail_then_trail_written.
    " db_save = abap_false turns save_application_log into a trailed no-op
    logger->save_application_log( ).

    cut->view( logger ).

    cl_abap_unit_assert=>assert_equals( act = lines( console->calls )
                                        exp = 3
                                        msg = `Header, trail title and trail table are expected` ).
    cl_abap_unit_assert=>assert_char_cp( act = console->calls[ 2 ]-text
                                         exp = 'Internal error trail*'
                                         msg = `The trail section must be titled` ).
    cl_abap_unit_assert=>assert_equals( act = console->calls[ 3 ]-line_count
                                        exp = 1
                                        msg = `The trail table must contain the recorded no-op` ).
  ENDMETHOD.

  METHOD given_unbound_logger_no_write.
    cut->view( VALUE #( ) ).

    cl_abap_unit_assert=>assert_initial( act = console->calls
                                         msg = `An unbound logger must not write anything` ).
  ENDMETHOD.

ENDCLASS.
