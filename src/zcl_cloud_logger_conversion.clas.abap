"! <p class="shorttext synchronized" lang="en">Cloud Logger message conversions</p>
"! Pure conversions shared by {@link zcl_cloud_logger} and
"! {@link zcl_cloud_logger_fake}, so that both treat severities, free text,
"! exceptions and searches in exactly the same way. No state, no database, no
"! clock - everything here is a function of its input.
CLASS zcl_cloud_logger_conversion DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Returns a valid severity: upper case, and the fallback when the value is
    "! blank or not one of I, S, W, E, A, X.
    "! @parameter msgty    | Severity as received from the caller
    "! @parameter fallback | Severity used for a blank or unknown value
    "! @parameter result   | Valid severity, or the fallback
    CLASS-METHODS normalized_severity
      IMPORTING msgty         TYPE symsgty
                fallback      TYPE symsgty
      RETURNING VALUE(result) TYPE symsgty.

    "! Tells whether a severity is at or above a minimum: <em>W</em> keeps
    "! W/E/A/X, <em>E</em> keeps E/A/X, <em>A</em> or <em>X</em> keeps A/X.
    "! Any other minimum (initial, I, S, unknown) keeps everything. Both values
    "! are compared in upper case.
    "! @parameter severity | Severity of the entry
    "! @parameter minimum  | Lowest severity to keep
    "! @parameter result   | abap_true when the entry is kept
    CLASS-METHODS reaches_severity
      IMPORTING severity      TYPE symsgty
                minimum       TYPE symsgty
      RETURNING VALUE(result) TYPE abap_boolean.

    "! Returns the entries that reach a minimum severity, in their order. A
    "! minimum that filters nothing (initial, I, S, unknown) returns all entries.
    "! @parameter entries | Log entries
    "! @parameter minimum | Lowest severity to keep, see {@link zcl_cloud_logger_conversion.METH:reaches_severity}
    "! @parameter result  | Entries at or above the minimum
    CLASS-METHODS entries_reaching
      IMPORTING entries       TYPE zif_cloud_logger=>log_messages
                minimum       TYPE symsgty
      RETURNING VALUE(result) TYPE zif_cloud_logger=>log_messages.

    "! Packs free text into the carrier message
    "! {@link zif_cloud_logger.DATA:c_free_text_message} (&amp;1&amp;2&amp;3&amp;4).
    "! The text is cut into at most four slices of at most 50 characters. A slice
    "! never ends on a blank while text follows - the blank opens the next slice
    "! instead, because a trailing blank of a message variable is dropped when
    "! the message is put together. Text that does not fit is cut off.
    "! @parameter text   | Free text
    "! @parameter msgty  | Severity; blank or unknown becomes information
    "! @parameter result | Carrier message with the text in its variables
    CLASS-METHODS text_to_symsg
      IMPORTING !text         TYPE string
                msgty         TYPE symsgty
      RETURNING VALUE(result) TYPE symsg.

    "! Returns the T100 key and the message variables of an exception. For an
    "! exception without T100 key only the severity is filled. Attributes named
    "! in the key are formatted like a string template formats them; an
    "! attribute that is not elementary yields an empty variable.
    "! @parameter exception | Exception to read
    "! @parameter severity  | Severity of the resulting message
    "! @parameter result    | Message type, class, number and variables
    CLASS-METHODS symsg_from_exception
      IMPORTING !exception    TYPE REF TO cx_root
                severity      TYPE symsgty
      RETURNING VALUE(result) TYPE symsg.

    "! Chooses the text of a T100 message: the resolved text, unless the message
    "! could not be resolved. The message runtime renders a message that does
    "! not exist as <em>TYPE:CLASS:NUMBER</em>; in that case, and for an empty
    "! text, the fallback is taken, or without fallback the raw message parts.
    "! @parameter symsg    | Message that was resolved
    "! @parameter resolved | Text the message runtime returned
    "! @parameter fallback | Text supplied with the message, e.g. by a BAPI
    "! @parameter result   | Text for the log entry, never empty for a filled message
    CLASS-METHODS text_or_fallback
      IMPORTING symsg         TYPE symsg
                resolved      TYPE string
                fallback      TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE string.

    "! Tells whether a message matches a search. Initial components of the
    "! search are not compared; message number 000 is the initial value of the
    "! NUMC field and therefore means "any number". The severity of the search
    "! is matched in upper or lower case, all other components exactly.
    "! @parameter symsg  | Message of a log entry
    "! @parameter search | Message parts to match
    "! @parameter result | abap_true when every filled search component matches
    CLASS-METHODS matches_search
      IMPORTING symsg         TYPE symsg
                !search       TYPE symsg
      RETURNING VALUE(result) TYPE abap_boolean.

  PRIVATE SECTION.
    TYPES text_slices TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    " symsgv holds 50 characters and the carrier message has four placeholders
    CONSTANTS slice_length TYPE i VALUE 50.
    CONSTANTS slice_count  TYPE i VALUE 4.
    CONSTANTS blank        TYPE string VALUE ` `.

    CONSTANTS valid_severities TYPE string VALUE `ISWEAX`.

    " Order of the severities that a minimum severity can exclude
    CONSTANTS:
      BEGIN OF severity_rank,
        unranked TYPE i VALUE 0,
        warning  TYPE i VALUE 1,
        error    TYPE i VALUE 2,
        fatal    TYPE i VALUE 3,
      END OF severity_rank.

    " Attribute names a T100 key uses for dynamic message variables
    CONSTANTS:
      BEGIN OF dyn_msg_attribute,
        prefix TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~*',
        v1     TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        v2     TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        v3     TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        v4     TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF dyn_msg_attribute.

    CLASS-METHODS rank_of
      IMPORTING severity      TYPE symsgty
      RETURNING VALUE(result) TYPE i.

    " Cuts the text into message variables without losing a word break
    CLASS-METHODS slices_of
      IMPORTING !text         TYPE string
      RETURNING VALUE(result) TYPE text_slices.

    CLASS-METHODS length_without_blanks
      IMPORTING !text         TYPE string
      RETURNING VALUE(result) TYPE i.

    " Value of an exception attribute named in a T100 key, as message variable
    CLASS-METHODS attribute_as_variable
      IMPORTING !exception    TYPE REF TO cx_root
                attribute     TYPE scx_attrname
      RETURNING VALUE(result) TYPE symsgv.

    " Variable held in if_t100_dyn_msg (exceptions raised with RAISE ... MESSAGE)
    CLASS-METHODS dynamic_message_variable
      IMPORTING !exception    TYPE REF TO cx_root
                attribute     TYPE scx_attrname
      RETURNING VALUE(result) TYPE symsgv.

    " The message runtime's rendering of a message that does not exist
    CLASS-METHODS is_unresolved
      IMPORTING symsg         TYPE symsg
                resolved      TYPE string
      RETURNING VALUE(result) TYPE abap_boolean.

    CLASS-METHODS key_matches
      IMPORTING symsg         TYPE symsg
                !search       TYPE symsg
      RETURNING VALUE(result) TYPE abap_boolean.

    CLASS-METHODS variables_match
      IMPORTING symsg         TYPE symsg
                !search       TYPE symsg
      RETURNING VALUE(result) TYPE abap_boolean.

ENDCLASS.


CLASS zcl_cloud_logger_conversion IMPLEMENTATION.

  METHOD normalized_severity.
    DATA(upper_case) = CONV symsgty( to_upper( msgty ) ).

    result = COND #( WHEN upper_case IS NOT INITIAL AND upper_case CA valid_severities
                     THEN upper_case
                     ELSE fallback ).
  ENDMETHOD.

  METHOD reaches_severity.
    result = xsdbool( rank_of( severity ) >= rank_of( minimum ) ).
  ENDMETHOD.

  METHOD entries_reaching.
    DATA(threshold) = rank_of( minimum ).

    " No filter, no loop: the unfiltered getters stay as cheap as they were
    IF threshold = severity_rank-unranked.
      result = entries.
      RETURN.
    ENDIF.

    LOOP AT entries REFERENCE INTO DATA(entry).
      IF rank_of( entry->type ) >= threshold.
        INSERT entry->* INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD rank_of.
    result = SWITCH #( to_upper( severity )
                       WHEN zif_cloud_logger=>c_message_type-warning
                         THEN severity_rank-warning
                       WHEN zif_cloud_logger=>c_message_type-error
                         THEN severity_rank-error
                       WHEN zif_cloud_logger=>c_message_type-abandon
                         OR zif_cloud_logger=>c_message_type-terminate
                         THEN severity_rank-fatal
                       ELSE severity_rank-unranked ).
  ENDMETHOD.

  METHOD text_to_symsg.
    DATA(slices) = slices_of( text ).

    result = VALUE #( msgid = zif_cloud_logger=>c_free_text_message-msgid
                      msgno = zif_cloud_logger=>c_free_text_message-msgno
                      msgty = normalized_severity( msgty    = msgty
                                                   fallback = zif_cloud_logger=>c_message_type-information )
                      msgv1 = VALUE string( slices[ 1 ] OPTIONAL )
                      msgv2 = VALUE string( slices[ 2 ] OPTIONAL )
                      msgv3 = VALUE string( slices[ 3 ] OPTIONAL )
                      msgv4 = VALUE string( slices[ 4 ] OPTIONAL ) ).
  ENDMETHOD.

  METHOD slices_of.
    DATA(remaining) = text.

    DO slice_count TIMES.
      IF remaining IS INITIAL.
        RETURN.
      ENDIF.

      DATA(length) = nmin( val1 = strlen( remaining )
                           val2 = slice_length ).

      IF strlen( remaining ) <= length.
        INSERT remaining INTO TABLE result.
        RETURN.
      ENDIF.

      " Text follows: a blank at the end of this slice would be dropped when the
      " variables are put together, so it opens the next slice instead. A slice
      " of blanks only has nothing to hold on to and is taken as it is.
      DATA(anchored) = length_without_blanks( substring( val = remaining
                                                         len = length ) ).
      IF anchored > 0.
        length = anchored.
      ENDIF.

      INSERT substring( val = remaining
                        len = length ) INTO TABLE result.
      remaining = substring( val = remaining
                             off = length ).
    ENDDO.
  ENDMETHOD.

  METHOD length_without_blanks.
    result = strlen( text ).

    WHILE result > 0.
      IF substring( val = text
                    off = result - 1
                    len = 1 ) <> blank.
        RETURN.
      ENDIF.
      result -= 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD symsg_from_exception.
    result-msgty = severity.

    " CAST instead of IS INSTANCE OF on purpose: the off-stack runtime does not
    " evaluate IS INSTANCE OF against interfaces, the cast check it does.
    TRY.
        DATA(t100_message) = CAST if_t100_message( exception ).
      CATCH cx_sy_move_cast_error.
        RETURN.
    ENDTRY.

    DATA(t100key) = t100_message->t100key.

    " Only the class decides: message number 000 is a valid number and IS INITIAL for NUMC
    IF t100key-msgid IS INITIAL.
      RETURN.
    ENDIF.

    result-msgid = t100key-msgid.
    result-msgno = t100key-msgno.
    result-msgv1 = attribute_as_variable( exception = exception
                                          attribute = t100key-attr1 ).
    result-msgv2 = attribute_as_variable( exception = exception
                                          attribute = t100key-attr2 ).
    result-msgv3 = attribute_as_variable( exception = exception
                                          attribute = t100key-attr3 ).
    result-msgv4 = attribute_as_variable( exception = exception
                                          attribute = t100key-attr4 ).
  ENDMETHOD.

  METHOD attribute_as_variable.
    FIELD-SYMBOLS <value> TYPE any.

    IF attribute IS INITIAL.
      RETURN.
    ENDIF.

    " Interface attributes are not reachable by dynamic name; the dynamic message
    " variables are read through their interface instead.
    IF attribute CP dyn_msg_attribute-prefix.
      result = dynamic_message_variable( exception = exception
                                         attribute = attribute ).
      RETURN.
    ENDIF.

    ASSIGN exception->(attribute) TO <value>.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " A reference, a table or a structure named in a T100 key cannot become a
    " message variable and must not bring the logger down
    DATA(type) = cl_abap_typedescr=>describe_by_data( <value> ).
    IF type->kind <> cl_abap_typedescr=>kind_elem.
      RETURN.
    ENDIF.

    " The template formats a number as text; a plain assignment would right-align it
    result = |{ <value> }|.
  ENDMETHOD.

  METHOD dynamic_message_variable.
    TRY.
        DATA(variables) = CAST if_t100_dyn_msg( exception ).
      CATCH cx_sy_move_cast_error.
        RETURN.
    ENDTRY.

    result = SWITCH #( attribute
                       WHEN dyn_msg_attribute-v1 THEN variables->msgv1
                       WHEN dyn_msg_attribute-v2 THEN variables->msgv2
                       WHEN dyn_msg_attribute-v3 THEN variables->msgv3
                       WHEN dyn_msg_attribute-v4 THEN variables->msgv4 ).
  ENDMETHOD.

  METHOD text_or_fallback.
    DATA(usable) = xsdbool( resolved IS NOT INITIAL AND is_unresolved( symsg    = symsg
                                                                       resolved = resolved ) = abap_false ).

    " Without a fallback the rendering of the message runtime is still the best text there is
    IF usable = abap_true OR ( resolved IS NOT INITIAL AND fallback IS INITIAL ).
      result = resolved.
      RETURN.
    ENDIF.

    result = COND #( WHEN fallback IS NOT INITIAL
                     THEN fallback
                     ELSE condense( |{ symsg-msgid } { symsg-msgno } { symsg-msgv1 } { symsg-msgv2 }| &&
                                    | { symsg-msgv3 } { symsg-msgv4 }| ) ).
  ENDMETHOD.

  METHOD is_unresolved.
    DATA(not_found) = |{ symsg-msgty }:{ symsg-msgid }:{ symsg-msgno }|.

    IF strlen( resolved ) < strlen( not_found ).
      RETURN.
    ENDIF.

    result = xsdbool( substring( val = resolved
                                 len = strlen( not_found ) ) = not_found ).
  ENDMETHOD.

  METHOD matches_search.
    result = xsdbool(
          key_matches( symsg  = symsg
                       search = search ) = abap_true
      AND variables_match( symsg  = symsg
                           search = search ) = abap_true ).
  ENDMETHOD.

  METHOD key_matches.
    " Entries carry their severity in upper case; a search may spell it either way
    DATA(search_severity) = CONV symsgty( to_upper( search-msgty ) ).

    result = xsdbool(
          ( search-msgid IS INITIAL OR symsg-msgid = search-msgid )
      AND ( search-msgno IS INITIAL OR symsg-msgno = search-msgno )
      AND ( search-msgty IS INITIAL OR symsg-msgty = search_severity ) ).
  ENDMETHOD.

  METHOD variables_match.
    result = xsdbool(
          ( search-msgv1 IS INITIAL OR symsg-msgv1 = search-msgv1 )
      AND ( search-msgv2 IS INITIAL OR symsg-msgv2 = search-msgv2 )
      AND ( search-msgv3 IS INITIAL OR symsg-msgv3 = search-msgv3 )
      AND ( search-msgv4 IS INITIAL OR symsg-msgv4 = search-msgv4 ) ).
  ENDMETHOD.

ENDCLASS.
