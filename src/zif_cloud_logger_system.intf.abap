"! <p class="shorttext synchronized" lang="en">Cloud Logger system access</p>
"! The one place where the logger reads its environment: date, time, time
"! stamp, user and the message held in the system fields. Production uses
"! {@link zcl_cloud_logger_system}; tests inject a fixed double so entries,
"! timers and the internal trail become deterministic.
INTERFACE zif_cloud_logger_system
  PUBLIC.

  "! @parameter result | Current system date
  METHODS system_date
    RETURNING VALUE(result) TYPE d.

  "! @parameter result | Current system time
  METHODS system_time
    RETURNING VALUE(result) TYPE t.

  "! @parameter result | Current time stamp in the long form
  METHODS now
    RETURNING VALUE(result) TYPE timestampl.

  "! @parameter result | Current user: alias when maintained, technical name otherwise
  METHODS user_name
    RETURNING VALUE(result) TYPE syuname.

  "! @parameter result | Message currently held in SY-MSGTY, SY-MSGID, SY-MSGNO, SY-MSGV1..4
  METHODS current_message
    RETURNING VALUE(result) TYPE symsg.

ENDINTERFACE.
