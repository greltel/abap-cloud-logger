"! <p class="shorttext synchronized" lang="en">Cloud Logger benchmark - run with F9 in ADT</p>
"! Measures the logger on the current system: time to add <em>entries</em>
"! entries, to render and count them, to persist and to delete the log, and
"! whether the emergency log mirror works. Prints the numbers on the console.
"! Nothing is kept unless <em>keep_persisted_log</em> is switched on. Memory is
"! observed from outside (SM04 / SM50 during the run): the memory utilities
"! are not released for ABAP Cloud.
CLASS zcl_cloud_logger_benchmark DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    "! Number of entries for the volume run; raise it to find the limit of your system
    CONSTANTS entries            TYPE i VALUE 20000.
    "! abap_true leaves the persisted log in place for inspection in the Application Logs app
    CONSTANTS keep_persisted_log TYPE abap_boolean VALUE abap_false.
    CONSTANTS every_nth_is_error TYPE i VALUE 10.
    CONSTANTS milliseconds       TYPE i VALUE 1000.

    CONSTANTS bench_object        TYPE cl_bali_header_setter=>ty_object      VALUE 'Z_CLOUD_LOG_SAMPLE'.
    CONSTANTS bench_subobject     TYPE cl_bali_header_setter=>ty_subobject   VALUE 'SETUP'.
    CONSTANTS bench_ext_number    TYPE cl_bali_header_setter=>ty_external_id VALUE 'BENCHMARK'.
    CONSTANTS emergency_ext_number TYPE cl_bali_header_setter=>ty_external_id VALUE 'BENCHMARK_EMERGENCY'.

    DATA console TYPE REF TO if_oo_adt_classrun_out.

    METHODS measure_volume
      RAISING zcx_cloud_logger_error.

    METHODS measure_emergency_log
      RAISING zcx_cloud_logger_error.

    METHODS report
      IMPORTING label TYPE string
                since TYPE utclong.

ENDCLASS.


CLASS zcl_cloud_logger_benchmark IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    console = out.

    TRY.
        measure_volume( ).
        measure_emergency_log( ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        console->write( |Benchmark aborted: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD measure_volume.
    DATA(logger) = zcl_cloud_logger=>get_instance( object     = bench_object
                                                   subobject  = bench_subobject
                                                   ext_number = bench_ext_number ).

    console->write( |Volume run: { entries } entries, every { every_nth_is_error }th an error| ).

    DATA(started) = utclong_current( ).
    DO entries TIMES.
      logger->log_string_add( string = |entry { sy-index }|
                              msgty  = COND #( WHEN sy-index MOD every_nth_is_error = 0
                                               THEN zif_cloud_logger=>c_message_type-error
                                               ELSE zif_cloud_logger=>c_message_type-information ) ).
    ENDDO.
    report( label = `log_string_add x entries`
            since = started ).

    started = utclong_current( ).
    DATA(flat) = logger->get_messages_flat( ).
    report( label = |get_messages_flat ({ lines( flat ) } lines)|
            since = started ).

    started = utclong_current( ).
    DATA(errors) = logger->get_message_count( zif_cloud_logger=>c_message_type-error ).
    report( label = |get_message_count( 'E' ) = { errors }|
            since = started ).

    started = utclong_current( ).
    logger->save_application_log( ).
    COMMIT WORK.
    report( label = `save_application_log + COMMIT WORK`
            since = started ).
    console->write( |Handle: { logger->get_handle( ) }| ).

    IF keep_persisted_log = abap_false.
      started = utclong_current( ).
      logger->reset_appl_log( abap_true ).
      COMMIT WORK.
      report( label = `reset_appl_log( delete_from_db ) + COMMIT WORK`
              since = started ).
    ENDIF.

    logger->free( ).
  ENDMETHOD.

  METHOD measure_emergency_log.
    DATA(logger) = zcl_cloud_logger=>get_instance( object               = bench_object
                                                   subobject            = bench_subobject
                                                   ext_number           = emergency_ext_number
                                                   enable_emergency_log = abap_true
                                                   db_save              = abap_false ).

    logger->log_string_add( `mirrored free text`
      )->log_message_add( VALUE #( msgty = zif_cloud_logger=>c_message_type-warning
                                   msgid = 'Z_CLOUD_LOGGER'
                                   msgno = '000' )
      )->log_exception_add( NEW cx_sy_zerodivide( ) ).

    DATA(trail) = logger->get_internal_errors( ).

    console->write( |Emergency log: 3 entries mirrored, { lines( trail ) } internal errors| ).

    IF trail IS NOT INITIAL.
      console->write( trail ).
    ENDIF.

    console->write( |Look for object { bench_object }, external id { emergency_ext_number } | &&
                    |in the Application Logs app / SLG1 to see what the XCO mirror wrote| ).

    logger->free( ).
  ENDMETHOD.

  METHOD report.
    DATA(elapsed) = utclong_diff( high = utclong_current( )
                                  low  = since ).

    console->write( |{ label }: { elapsed DECIMALS = 3 } s | &&
                    |({ elapsed / entries * milliseconds DECIMALS = 3 } ms per entry)| ).
  ENDMETHOD.

ENDCLASS.

