INTERFACE zif_cloud_logger
  PUBLIC .


  TYPES:
    bapiret2_messages TYPE STANDARD TABLE OF bapiret2 WITH EMPTY KEY .
  TYPES:
    rap_messages  TYPE STANDARD TABLE OF REF TO if_abap_behv_message WITH EMPTY KEY .
  TYPES flat_message TYPE string .
  TYPES:
    flat_messages TYPE STANDARD TABLE OF flat_message WITH EMPTY KEY .
  TYPES:
    BEGIN OF t_log_messages,
      symsg     TYPE symsg,
      message   TYPE string,
      type      TYPE symsgty,
      context   TYPE string,
      user_name TYPE syuname,
      date      TYPE xsddate_d,
      time      TYPE xsdtime_t,
      item      TYPE REF TO if_bali_item_setter,
    END OF t_log_messages .
  TYPES:
    log_messages TYPE STANDARD TABLE OF t_log_messages WITH EMPTY KEY.
  TYPES:
    BEGIN OF t_logger_instance,
      log_object           TYPE        cl_bali_header_setter=>ty_object,
      log_subobject        TYPE        cl_bali_header_setter=>ty_subobject,
      extnumber            TYPE        cl_bali_header_setter=>ty_external_id,
      db_save              TYPE        abap_boolean,
      enable_emergency_log TYPE        abap_boolean,
      expiry_date          TYPE        xsddate_d,
      logger               TYPE REF TO zif_cloud_logger,
    END OF t_logger_instance .
  TYPES:
    logger_instances TYPE HASHED TABLE OF t_logger_instance
                        WITH UNIQUE KEY log_object log_subobject extnumber .

  CONSTANTS:
    BEGIN OF c_message_type,
      information     TYPE symsgty VALUE 'I',
      error           TYPE symsgty VALUE 'E',
      success         TYPE symsgty VALUE 'S',
      warning         TYPE symsgty VALUE 'W',
      abandon         TYPE symsgty VALUE 'A',
      terminate       TYPE symsgty VALUE 'X',
      error_pattern   TYPE c       LENGTH 3 VALUE 'AEX',
      warning_pattern TYPE c       LENGTH 4 VALUE 'AEXW',
    END OF c_message_type .
  CONSTANTS:
    BEGIN OF c_default_message_attributes,
      type TYPE symsgty VALUE c_message_type-warning,
      id   TYPE symsgid VALUE 'CL',
      no   TYPE symsgno VALUE '000',
    END OF c_default_message_attributes .
  CONSTANTS:
    BEGIN OF c_select_options,
      option_between              TYPE ddoption VALUE 'BT',
      option_contains_pattern     TYPE ddoption VALUE 'CP',
      option_equal                TYPE ddoption VALUE 'EQ',
      option_greater              TYPE ddoption VALUE 'GT',
      option_greater_equal        TYPE ddoption VALUE 'GE',
      option_less                 TYPE ddoption VALUE 'LT',
      option_less_equal           TYPE ddoption VALUE 'LE',
      option_not_between          TYPE ddoption VALUE 'NB',
      option_not_contains_pattern TYPE ddoption VALUE 'NP',
      option_not_equal            TYPE ddoption VALUE 'NE',
      sign_exclude                TYPE ddsign   VALUE 'E',
      sign_include                TYPE ddsign   VALUE 'I',
    END OF c_select_options .

  METHODS merge_logs
    IMPORTING
      !external_log TYPE REF TO zif_cloud_logger .
  METHODS log_string_add
    IMPORTING
      !string       TYPE string
      !msgty        TYPE symsgty DEFAULT c_default_message_attributes-type
    RETURNING
      VALUE(logger) TYPE REF TO zif_cloud_logger .
  METHODS log_message_add
    IMPORTING
      !symsg        TYPE symsg OPTIONAL
    RETURNING
      VALUE(logger) TYPE REF TO zif_cloud_logger .
  METHODS log_syst_add
    RETURNING
      VALUE(logger) TYPE REF TO zif_cloud_logger .
  METHODS log_exception_add
    IMPORTING
      !severity     TYPE symsgty DEFAULT c_default_message_attributes-type
      !exception    TYPE REF TO cx_root
    RETURNING
      VALUE(logger) TYPE REF TO zif_cloud_logger .
  METHODS log_bapiret2_table_add
    IMPORTING
      !bapiret2_t   TYPE bapiret2_messages
      !min_severity TYPE symsgty OPTIONAL
    RETURNING
      VALUE(logger) TYPE REF TO zif_cloud_logger .
  METHODS log_bapiret2_structure_add
    IMPORTING
      !bapiret2     TYPE bapiret2
    RETURNING
      VALUE(logger) TYPE REF TO zif_cloud_logger .
  METHODS log_data_add
    IMPORTING
      !data         TYPE data
      !msgty        TYPE symsgty DEFAULT c_default_message_attributes-type
    RETURNING
      VALUE(logger) TYPE REF TO zif_cloud_logger .
  METHODS save_application_log
    IMPORTING
      !use_2nd_db_connection      TYPE abap_boolean DEFAULT abap_false
      !assign_to_current_appl_job TYPE abap_boolean DEFAULT abap_false.
*      !ASYNC type ABAP_BOOLEAN default ABAP_FALSE
*      !ASYNC_NAME type IF_BGMC_PROCESS=>TY_NAME default 'Background Logger Save'
  METHODS get_messages
    RETURNING
      VALUE(result) TYPE log_messages .
  METHODS get_messages_flat
    RETURNING
      VALUE(result) TYPE flat_messages .
  METHODS get_messages_as_bapiret2
    RETURNING
      VALUE(bapiret2) TYPE bapiret2_messages .
  METHODS get_messages_rap
    RETURNING
      VALUE(result) TYPE rap_messages .
  METHODS get_handle
    RETURNING
      VALUE(handle) TYPE balloghndl .
  METHODS get_log_handle
    RETURNING
      VALUE(result) TYPE REF TO if_bali_log .
  METHODS get_message_count
    RETURNING
      VALUE(count) TYPE int4 .
  METHODS reset_appl_log
    IMPORTING
      !delete_from_db TYPE abap_bool DEFAULT abap_true .
  METHODS log_is_empty
    RETURNING
      VALUE(result) TYPE abap_boolean .
  METHODS log_contains_messages
    RETURNING
      VALUE(result) TYPE abap_boolean .
  METHODS log_contains_error
    RETURNING
      VALUE(result) TYPE abap_boolean .
  METHODS log_contains_warning
    RETURNING
      VALUE(result) TYPE abap_boolean .
  METHODS search_message
    IMPORTING
      !search       TYPE symsg
    RETURNING
      VALUE(result) TYPE abap_boolean .
  METHODS free .
  METHODS start_timer
    RETURNING
      VALUE(logger) TYPE REF TO zif_cloud_logger .
  METHODS stop_timer
    IMPORTING
      !text         TYPE string OPTIONAL
    RETURNING
      VALUE(logger) TYPE REF TO zif_cloud_logger .
  METHODS display
    IMPORTING
      !viewer TYPE REF TO zif_cloud_logger_viewer .
  METHODS set_context
    IMPORTING
      !context      TYPE string
    RETURNING
      VALUE(logger) TYPE REF TO zif_cloud_logger .
  METHODS clear_context
    RETURNING
      VALUE(logger) TYPE REF TO zif_cloud_logger .
ENDINTERFACE.
