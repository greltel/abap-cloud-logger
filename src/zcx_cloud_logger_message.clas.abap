"! <p class="shorttext synchronized" lang="en">Cloud Logger RAP message</p>
"! Adapter that turns a T100 key into an {@link if_abap_behv_message}, so log
"! entries can be handed to a RAP <em>reported</em> response.
CLASS zcx_cloud_logger_message DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_message.
    INTERFACES if_t100_dyn_msg.
    INTERFACES if_abap_behv_message.

    ALIASES msgty FOR if_t100_dyn_msg~msgty.
    ALIASES msgv1 FOR if_t100_dyn_msg~msgv1.
    ALIASES msgv2 FOR if_t100_dyn_msg~msgv2.
    ALIASES msgv3 FOR if_t100_dyn_msg~msgv3.
    ALIASES msgv4 FOR if_t100_dyn_msg~msgv4.

    "! @parameter textid   | T100 key of the message
    "! @parameter previous | Original exception, if any
    "! @parameter msgty    | Message type
    "! @parameter msgv1    | Placeholder 1
    "! @parameter msgv2    | Placeholder 2
    "! @parameter msgv3    | Placeholder 3
    "! @parameter msgv4    | Placeholder 4
    METHODS constructor
      IMPORTING !textid   LIKE if_t100_message=>t100key OPTIONAL
                !previous LIKE previous OPTIONAL
                msgty     TYPE symsgty OPTIONAL
                msgv1     TYPE symsgv OPTIONAL
                msgv2     TYPE symsgv OPTIONAL
                msgv3     TYPE symsgv OPTIONAL
                msgv4     TYPE symsgv OPTIONAL.

    "! Creates a RAP behavior message from a T100 key.
    "! @parameter class    | Message class
    "! @parameter number   | Message number
    "! @parameter severity | RAP severity
    "! @parameter v1       | Placeholder 1
    "! @parameter v2       | Placeholder 2
    "! @parameter v3       | Placeholder 3
    "! @parameter v4       | Placeholder 4
    "! @parameter result   | Message instance
    CLASS-METHODS new_message
      IMPORTING !class        TYPE symsgid
                !number       TYPE symsgno
                severity      TYPE if_abap_behv_message=>t_severity
                v1            TYPE simple OPTIONAL
                v2            TYPE simple OPTIONAL
                v3            TYPE simple OPTIONAL
                v4            TYPE simple OPTIONAL
      RETURNING VALUE(result) TYPE REF TO if_abap_behv_message.

    "! Creates a RAP behavior message from a SYMSG structure. A, X and E map to
    "! error, W to warning, S to success, I to information.
    "! @parameter message | Message type, class, number and variables
    "! @parameter result  | Message instance
    CLASS-METHODS new_message_from_symsg
      IMPORTING !message      TYPE symsg
      RETURNING VALUE(result) TYPE REF TO if_abap_behv_message.

  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF c_placeholder_attribute,
        v1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        v2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        v3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        v4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF c_placeholder_attribute.

ENDCLASS.


CLASS zcx_cloud_logger_message IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    me->msgty = msgty.
    me->msgv1 = msgv1.
    me->msgv2 = msgv2.
    me->msgv3 = msgv3.
    me->msgv4 = msgv4.
    CLEAR me->textid.
    if_t100_message~t100key = COND #( WHEN textid IS INITIAL
                                      THEN if_t100_message=>default_textid
                                      ELSE textid ).
  ENDMETHOD.

  METHOD new_message.
    result = NEW zcx_cloud_logger_message(
        textid = VALUE #( msgid = class
                          msgno = number
                          attr1 = COND #( WHEN v1 IS NOT INITIAL THEN c_placeholder_attribute-v1 )
                          attr2 = COND #( WHEN v2 IS NOT INITIAL THEN c_placeholder_attribute-v2 )
                          attr3 = COND #( WHEN v3 IS NOT INITIAL THEN c_placeholder_attribute-v3 )
                          attr4 = COND #( WHEN v4 IS NOT INITIAL THEN c_placeholder_attribute-v4 ) )
        msgty  = SWITCH #( severity
                           WHEN if_abap_behv_message=>severity-error
                             THEN zif_cloud_logger=>c_message_type-error
                           WHEN if_abap_behv_message=>severity-warning
                             THEN zif_cloud_logger=>c_message_type-warning
                           WHEN if_abap_behv_message=>severity-success
                             THEN zif_cloud_logger=>c_message_type-success
                           ELSE zif_cloud_logger=>c_message_type-information )
        msgv1  = |{ v1 }|
        msgv2  = |{ v2 }|
        msgv3  = |{ v3 }|
        msgv4  = |{ v4 }| ).

    result->m_severity = severity.
  ENDMETHOD.

  METHOD new_message_from_symsg.
    result = new_message(
        class    = message-msgid
        number   = message-msgno
        severity = SWITCH #( message-msgty
                             WHEN zif_cloud_logger=>c_message_type-abandon
                               OR zif_cloud_logger=>c_message_type-terminate
                               OR zif_cloud_logger=>c_message_type-error
                               THEN if_abap_behv_message=>severity-error
                             WHEN zif_cloud_logger=>c_message_type-warning
                               THEN if_abap_behv_message=>severity-warning
                             WHEN zif_cloud_logger=>c_message_type-information
                               THEN if_abap_behv_message=>severity-information
                             WHEN zif_cloud_logger=>c_message_type-success
                               THEN if_abap_behv_message=>severity-success
                             ELSE if_abap_behv_message=>severity-none )
        v1       = message-msgv1
        v2       = message-msgv2
        v3       = message-msgv3
        v4       = message-msgv4 ).
  ENDMETHOD.

ENDCLASS.

