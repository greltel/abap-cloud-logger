"! <p class="shorttext synchronized" lang="en">Cloud Logger Viewer for the ADT console</p>
"! Writes a logger's entries and internal error trail to an
"! {@link if_oo_adt_classrun_out} console, e.g. from a class run with F9 in ADT.
"! Any other output channel is a further implementation of
"! {@link zif_cloud_logger_viewer}.
CLASS zcl_cloud_logger_view_console DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_cloud_logger_viewer.

    "! @parameter out | Console to write to, usually the <em>out</em> parameter of if_oo_adt_classrun~main
    METHODS constructor
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

  PRIVATE SECTION.
    DATA out TYPE REF TO if_oo_adt_classrun_out.

    METHODS write_header
      IMPORTING logger        TYPE REF TO zif_cloud_logger
                message_count TYPE i.

ENDCLASS.


CLASS zcl_cloud_logger_view_console IMPLEMENTATION.

  METHOD constructor.
    me->out = out.
  ENDMETHOD.

  METHOD zif_cloud_logger_viewer~view.
    IF logger IS NOT BOUND OR out IS NOT BOUND.
      RETURN.
    ENDIF.

    DATA(messages) = logger->get_messages_flat( ).

    write_header( logger        = logger
                  message_count = lines( messages ) ).

    IF messages IS NOT INITIAL.
      out->write( messages ).
    ENDIF.

    DATA(internal_errors) = logger->get_internal_errors( ).

    IF internal_errors IS NOT INITIAL.
      out->write( |Internal error trail - { lines( internal_errors ) } entries| ).
      out->write( internal_errors ).
    ENDIF.
  ENDMETHOD.

  METHOD write_header.
    DATA(abandoned)  = logger->get_message_count( zif_cloud_logger=>c_message_type-abandon ).
    DATA(terminated) = logger->get_message_count( zif_cloud_logger=>c_message_type-terminate ).

    " A and X are rare: they are named only when they occur, so the usual header
    " keeps its form and the counts still add up to the entries
    DATA(fatal_counts) = COND string( WHEN abandoned > 0
                                      THEN | A:{ abandoned }| ) &&
                         COND string( WHEN terminated > 0
                                      THEN | X:{ terminated }| ).

    out->write( |ABAP Cloud Logger { zif_cloud_logger=>c_version } - { message_count } entries | &&
                |(E:{ logger->get_message_count( zif_cloud_logger=>c_message_type-error ) } | &&
                |W:{ logger->get_message_count( zif_cloud_logger=>c_message_type-warning ) } | &&
                |I:{ logger->get_message_count( zif_cloud_logger=>c_message_type-information ) } | &&
                |S:{ logger->get_message_count( zif_cloud_logger=>c_message_type-success ) }{ fatal_counts })| ).
  ENDMETHOD.

ENDCLASS.


