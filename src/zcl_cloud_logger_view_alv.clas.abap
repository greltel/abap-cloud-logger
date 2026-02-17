class ZCL_CLOUD_LOGGER_VIEW_ALV definition
  public
  final
  create public .

public section.

  interfaces ZIF_CLOUD_LOGGER_VIEWER .
protected section.
private section.
ENDCLASS.



CLASS ZCL_CLOUD_LOGGER_VIEW_ALV IMPLEMENTATION.


  METHOD zif_cloud_logger_viewer~view.

    DATA(bapiret2) = logger->get_messages_as_bapiret2( ).
    CHECK bapiret2 IS NOT INITIAL.

    TRY.

        cl_salv_table=>factory( IMPORTING r_salv_table = DATA(alv)
                                CHANGING  t_table      = bapiret2 ).

        alv->set_screen_popup(
          start_column = 10
          end_column   = 120
          start_line   = 5
          end_line     = 25 ).

        alv->get_columns( )->set_optimize( abap_true ).
        alv->display( ).

      CATCH cx_salv_msg.
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
