interface ZIF_CLOUD_LOGGER
  public .


  types:
    bapiret2_messages TYPE STANDARD TABLE OF bapiret2 WITH EMPTY KEY .
  types:
    rap_messages  TYPE STANDARD TABLE OF REF TO if_abap_behv_message WITH EMPTY KEY .
  types FLAT_MESSAGE type STRING .
  types:
    flat_messages TYPE STANDARD TABLE OF flat_message WITH EMPTY KEY .
  types:
    BEGIN OF t_log_messages,
      symsg     TYPE symsg,
      message   TYPE bapi_msg,
      type      TYPE symsgty,
      user_name TYPE syuname,
      date      TYPE xsddate_d,
      time      TYPE xsdtime_t,
      item      TYPE REF TO if_bali_item_setter,
    END OF t_log_messages .
  types:
    log_messages TYPE STANDARD TABLE OF t_log_messages WITH EMPTY KEY
                    WITH NON-UNIQUE SORTED KEY key_search
                    COMPONENTS symsg-msgid symsg-msgno symsg-msgty .
  types:
    BEGIN OF t_logger_instance,
      log_object    TYPE        cl_bali_header_setter=>ty_object,
      log_subobject TYPE        cl_bali_header_setter=>ty_subobject,
      extnumber     TYPE        cl_bali_header_setter=>ty_external_id,
      logger        TYPE REF TO zif_cloud_logger,
    END OF t_logger_instance .
  types:
    logger_instances TYPE HASHED TABLE OF t_logger_instance
                        WITH UNIQUE KEY log_object log_subobject extnumber .

  constants:
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
  constants:
    BEGIN OF c_default_message_attributes,
      type TYPE symsgty VALUE c_message_type-warning,
      id   TYPE symsgid VALUE 'CL',
      no   TYPE symsgno VALUE '000',
    END OF c_default_message_attributes .
  constants:
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

  methods MERGE_LOGS
    importing
      !EXTERNAL_LOG type ref to ZIF_CLOUD_LOGGER .
  methods LOG_STRING_ADD
    importing
      !STRING type STRING
      !MSGTY type SYMSGTY default C_DEFAULT_MESSAGE_ATTRIBUTES-TYPE
    returning
      value(LOGGER) type ref to ZIF_CLOUD_LOGGER .
  methods LOG_MESSAGE_ADD
    importing
      !SYMSG type SYMSG optional
    returning
      value(LOGGER) type ref to ZIF_CLOUD_LOGGER .
  methods LOG_SYST_ADD
    returning
      value(LOGGER) type ref to ZIF_CLOUD_LOGGER .
  methods LOG_EXCEPTION_ADD
    importing
      !SEVERITY type SYMSGTY default C_DEFAULT_MESSAGE_ATTRIBUTES-TYPE
      !EXCEPTION type ref to CX_ROOT
    returning
      value(LOGGER) type ref to ZIF_CLOUD_LOGGER .
  methods LOG_BAPIRET2_TABLE_ADD
    importing
      !BAPIRET2_T type BAPIRET2_MESSAGES
      !MIN_SEVERITY type SYMSGTY optional
    returning
      value(LOGGER) type ref to ZIF_CLOUD_LOGGER .
  methods LOG_BAPIRET2_STRUCTURE_ADD
    importing
      !BAPIRET2 type BAPIRET2
    returning
      value(LOGGER) type ref to ZIF_CLOUD_LOGGER .
  methods LOG_DATA_ADD
    importing
      !DATA type DATA
      !MSGTY type SYMSGTY default C_DEFAULT_MESSAGE_ATTRIBUTES-TYPE
    returning
      value(LOGGER) type ref to ZIF_CLOUD_LOGGER .
  methods SAVE_APPLICATION_LOG
    importing
      !IM_USE_2ND_DB_CONNECTION type ABAP_BOOLEAN default ABAP_FALSE
      !IM_ASSIGN_TO_CURRENT_APPL_JOB type ABAP_BOOLEAN default ABAP_FALSE .
  methods GET_MESSAGES
    returning
      value(RESULT) type LOG_MESSAGES .
  methods GET_MESSAGES_FLAT
    returning
      value(RESULT) type FLAT_MESSAGES .
  methods GET_MESSAGES_AS_BAPIRET2
    returning
      value(BAPIRET2) type BAPIRET2_MESSAGES .
  methods GET_MESSAGES_RAP
    returning
      value(RESULT) type RAP_MESSAGES .
  methods GET_HANDLE
    returning
      value(HANDLE) type BALLOGHNDL .
  methods GET_LOG_HANDLE
    returning
      value(RESULT) type ref to IF_BALI_LOG .
  methods GET_MESSAGE_COUNT
    returning
      value(COUNT) type INT4 .
  methods RESET_APPL_LOG
    importing
      !DELETE_FROM_DB type ABAP_BOOL default ABAP_TRUE .
  methods LOG_IS_EMPTY
    returning
      value(RESULT) type ABAP_BOOLEAN .
  methods LOG_CONTAINS_MESSAGES
    returning
      value(RESULT) type ABAP_BOOLEAN .
  methods LOG_CONTAINS_ERROR
    returning
      value(RESULT) type ABAP_BOOLEAN .
  methods LOG_CONTAINS_WARNING
    returning
      value(RESULT) type ABAP_BOOLEAN .
  methods SEARCH_MESSAGE
    importing
      !SEARCH type SYMSG
    returning
      value(RESULT) type ABAP_BOOLEAN .
  methods FREE .
  methods START_TIMER
    returning
      value(LOGGER) type ref to ZIF_CLOUD_LOGGER .
  methods STOP_TIMER
    importing
      !TEXT type STRING optional
    returning
      value(LOGGER) type ref to ZIF_CLOUD_LOGGER .
  methods DISPLAY
    importing
      !VIEWER type ref to ZIF_CLOUD_LOGGER_VIEWER .
  methods SET_CONTEXT
    importing
      !CONTEXT type STRING
    returning
      value(LOGGER) type ref to ZIF_CLOUD_LOGGER .
  methods CLEAR_CONTEXT
    returning
      value(LOGGER) type ref to ZIF_CLOUD_LOGGER .
endinterface.
