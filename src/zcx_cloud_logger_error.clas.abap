"! <p class="shorttext synchronized" lang="en">Cloud Logger error</p>
"! Raised by {@link zcl_cloud_logger} when the logger cannot be created,
"! configured, written to or saved. <em>log_object</em> names the Application
"! Log object concerned; the <em>previous</em> exception carries the original
"! Application Log or XCO error where one exists.
CLASS zcx_cloud_logger_error DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_message.
    INTERFACES if_t100_dyn_msg.

    CONSTANTS:
      "! The Application Log could not be saved
      BEGIN OF error_release,
        msgid TYPE symsgid VALUE 'Z_CLOUD_LOGGER',
        msgno TYPE symsgno VALUE '002',
        attr1 TYPE scx_attrname VALUE 'LOG_OBJECT',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF error_release.
    CONSTANTS:
      "! The Application Log object could not be created
      BEGIN OF error_in_creation,
        msgid TYPE symsgid VALUE 'Z_CLOUD_LOGGER',
        msgno TYPE symsgno VALUE '003',
        attr1 TYPE scx_attrname VALUE 'LOG_OBJECT',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF error_in_creation.
    CONSTANTS:
      "! The Application Log rejected an entry
      BEGIN OF error_in_logging,
        msgid TYPE symsgid VALUE 'Z_CLOUD_LOGGER',
        msgno TYPE symsgno VALUE '004',
        attr1 TYPE scx_attrname VALUE 'LOG_OBJECT',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF error_in_logging.
    CONSTANTS:
      "! The XCO emergency log could not be created
      BEGIN OF error_in_emergency_log,
        msgid TYPE symsgid VALUE 'Z_CLOUD_LOGGER',
        msgno TYPE symsgno VALUE '005',
        attr1 TYPE scx_attrname VALUE 'LOG_OBJECT',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF error_in_emergency_log.
    CONSTANTS:
      "! db_save = abap_true was requested without an Application Log object
      BEGIN OF object_required,
        msgid TYPE symsgid VALUE 'Z_CLOUD_LOGGER',
        msgno TYPE symsgno VALUE '006',
        attr1 TYPE scx_attrname VALUE 'LOG_OBJECT',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF object_required.
    CONSTANTS:
      "! An instance with the same key exists with a different configuration
      BEGIN OF config_mismatch,
        msgid TYPE symsgid VALUE 'Z_CLOUD_LOGGER',
        msgno TYPE symsgno VALUE '007',
        attr1 TYPE scx_attrname VALUE 'LOG_OBJECT',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF config_mismatch.
    CONSTANTS:
      "! trim_limit must be zero or positive
      BEGIN OF invalid_trim_limit,
        msgid TYPE symsgid VALUE 'Z_CLOUD_LOGGER',
        msgno TYPE symsgno VALUE '008',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF invalid_trim_limit.
    CONSTANTS:
      "! A persisted log could not be loaded by its handle
      BEGIN OF error_in_loading,
        msgid TYPE symsgid VALUE 'Z_CLOUD_LOGGER',
        msgno TYPE symsgno VALUE '010',
        attr1 TYPE scx_attrname VALUE 'LOG_HANDLE',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF error_in_loading.
    CONSTANTS:
      "! A logger with the loaded log's key is already active in this session
      BEGIN OF already_active,
        msgid TYPE symsgid VALUE 'Z_CLOUD_LOGGER',
        msgno TYPE symsgno VALUE '011',
        attr1 TYPE scx_attrname VALUE 'LOG_OBJECT',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF already_active.
    CONSTANTS:
      "! The instance was released with free( ) and must not be used any more
      BEGIN OF instance_released,
        msgid TYPE symsgid VALUE 'Z_CLOUD_LOGGER',
        msgno TYPE symsgno VALUE '009',
        attr1 TYPE scx_attrname VALUE 'LOG_OBJECT',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF instance_released.

    "! Application Log object the failing logger belongs to (may be initial)
    DATA log_object TYPE cl_bali_header_setter=>ty_object READ-ONLY.
    "! Application Log handle concerned, for load failures (may be initial)
    DATA log_handle TYPE balloghndl READ-ONLY.

    "! @parameter textid     | One of the T100 keys declared above
    "! @parameter previous   | Original exception, if any
    "! @parameter log_object | Application Log object of the logger concerned
    "! @parameter log_handle | Application Log handle concerned
    METHODS constructor
      IMPORTING !textid    LIKE if_t100_message=>t100key OPTIONAL
                !previous  LIKE previous OPTIONAL
                log_object TYPE cl_bali_header_setter=>ty_object OPTIONAL
                log_handle TYPE balloghndl OPTIONAL.

ENDCLASS.


CLASS zcx_cloud_logger_error IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    me->log_object = log_object.
    me->log_handle = log_handle.
    CLEAR me->textid.
    if_t100_message~t100key = COND #( WHEN textid IS INITIAL
                                      THEN if_t100_message=>default_textid
                                      ELSE textid ).
  ENDMETHOD.

ENDCLASS.
