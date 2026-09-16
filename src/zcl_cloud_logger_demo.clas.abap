"! <p class="shorttext synchronized" lang="en">Cloud Logger demo - run with F9 in ADT</p>
"! Shows the typical flow: get an instance, log different kinds of entries,
"! query the log and show it on the ADT console. Nothing is persisted
"! (<em>db_save = abap_false</em>); set it to abap_true and call
"! <em>save_application_log( )</em> to write to the Application Log.
CLASS zcl_cloud_logger_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    CONSTANTS demo_object    TYPE cl_bali_header_setter=>ty_object      VALUE 'Z_CLOUD_LOG_SAMPLE'.
    CONSTANTS demo_subobject TYPE cl_bali_header_setter=>ty_subobject   VALUE 'SETUP'.
    CONSTANTS demo_ext_number TYPE cl_bali_header_setter=>ty_external_id VALUE 'DEMO'.

    METHODS log_a_typical_process
      IMPORTING logger TYPE REF TO zif_cloud_logger
      RAISING   zcx_cloud_logger_error.

ENDCLASS.


CLASS zcl_cloud_logger_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        DATA(logger) = zcl_cloud_logger=>get_instance( object     = demo_object
                                                       subobject  = demo_subobject
                                                       ext_number = demo_ext_number
                                                       db_save    = abap_false ).

        log_a_typical_process( logger ).

        out->write( |Contains errors: { logger->log_contains_error( ) }| ).
        logger->display( NEW zcl_cloud_logger_view_console( out ) ).

        logger->free( ).

      CATCH zcx_cloud_logger_error INTO DATA(error).
        out->write( |Logger error: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD log_a_typical_process.
    logger->start_timer( ).

    logger->set_context( `Order 4711`
      )->log_string_add( `Validation started`
      )->log_message_add( VALUE #( msgty = zif_cloud_logger=>c_message_type-warning
                                   msgid = 'Z_CLOUD_LOGGER'
                                   msgno = '000' )
      )->log_bapiret2_table_add( bapiret2_t   = VALUE #( id     = 'Z_CLOUD_LOGGER'
                                                         number = '000'
                                                         ( type = 'S' message_v1 = 'kept out by the filter' )
                                                         ( type = 'E' message_v1 = 'kept' ) )
                                 min_severity = zif_cloud_logger=>c_message_type-error
      )->clear_context( ).

    TRY.
        RAISE EXCEPTION NEW cx_sy_zerodivide( ).
      CATCH cx_sy_zerodivide INTO DATA(division_error).
        logger->log_exception_add( division_error ).
    ENDTRY.

    logger->log_data_add( VALUE bapiret2( type = 'I' message = 'any structure or table becomes JSON' ) ).

    logger->stop_timer( `Demo block` ).
  ENDMETHOD.

ENDCLASS.

