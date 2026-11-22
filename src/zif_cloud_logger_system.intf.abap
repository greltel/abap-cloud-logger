"! <p class="shorttext synchronized" lang="en">Cloud Logger system access</p>
"! The one place where the logger reads its environment: date, time, time
"! stamp, user and the message held in the system fields. Production uses
"! {@link zcl_cloud_logger_system}; tests inject a fixed double so entries,
"! timers and the internal trail become deterministic.
INTERFACE zif_cloud_logger_system
  PUBLIC.

  TYPES:
    "! Date and time that belong to the same instant
    BEGIN OF moment,
      date TYPE d,
      time TYPE t,
    END OF moment.

  "! @parameter result | Current system date
  METHODS system_date
    RETURNING VALUE(result) TYPE d.

  "! Date and time of one instant in system time. Both belong together: a
  "! reading around midnight never pairs the old date with the new time.
  "! @parameter result | Current system date and system time
  METHODS system_moment
    RETURNING VALUE(result) TYPE moment.

  "! @parameter result | Current UTC time stamp in the long form
  METHODS now
    RETURNING VALUE(result) TYPE timestampl.

  "! @parameter result | Technical name of the current user
  METHODS user_name
    RETURNING VALUE(result) TYPE syuname.

  "! @parameter result | Message currently held in SY-MSGTY, SY-MSGID, SY-MSGNO, SY-MSGV1..4
  METHODS current_message
    RETURNING VALUE(result) TYPE symsg.

ENDINTERFACE.
