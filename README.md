# ABAP Cloud Logger

[![Version](https://img.shields.io/badge/version-2.0.0-blue)](CHANGELOG.md)
[![Tests](https://github.com/greltel/abap-cloud-logger/actions/workflows/test.yml/badge.svg)](https://github.com/greltel/abap-cloud-logger/actions/workflows/test.yml)
[![ABAP Cloud](https://img.shields.io/badge/ABAP-Cloud%20Ready-green)](https://abaplint.app/stats/greltel/abap-cloud-logger/object_classifications)
[![Code Statistics](https://img.shields.io/badge/CodeStatistics-abaplint-blue)](https://abaplint.app/stats/greltel/abap-cloud-logger)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A fluent, unit-tested logging library for **ABAP for Cloud Development** (SAP S/4HANA Cloud,
SAP BTP ABAP Environment, S/4HANA on-premise with ABAP Cloud). It wraps the released
Application Log API (`cl_bali_log`) and adds the things you end up writing yourself every
time: chaining, an in-memory copy of the log, conversions to BAPIRET2 and RAP messages,
sticky context, a stopwatch, and a trail of the problems the logger itself swallowed.

```abap
DATA(logger) = zcl_cloud_logger=>get_instance( object    = 'ZMYAPP'
                                               subobject = 'IMPORT' ).

logger->set_context( |Order { order_id }|
  )->log_string_add( `Validation started`
  )->log_bapiret2_table_add( bapiret2_t   = bapi_return
                             min_severity = zif_cloud_logger=>c_message_type-warning
  )->log_exception_add( import_error
  )->clear_context(
  )->save_application_log( ).
```

## Contents

1. [Why not `cl_bali_log` directly?](#why-not-cl_bali_log-directly)
2. [Requirements](#requirements)
3. [Installation](#installation)
4. [Quick start](#quick-start)
5. [Usage](#usage)
6. [API overview](#api-overview)
7. [Errors](#errors)
8. [Viewers](#viewers)
9. [Testing code that uses the logger](#testing-code-that-uses-the-logger)
10. [Design](#design)
11. [Development](#development)
12. [Changelog and roadmap](#changelog-and-roadmap)
13. [License and author](#license-and-author)

## Why not `cl_bali_log` directly?

`cl_bali_log` is the right foundation and this library never hides it (`get_log_handle( )`
returns the `if_bali_log` object). What it adds:

| You want to | With `cl_bali_log` alone | With ABAP Cloud Logger |
|---|---|---|
| Share one log across classes of a process | pass the handle around | `get_instance( )` returns the same instance for the same object / subobject / external id |
| Log a string, a T100 message, `sy-msg*`, an exception, a BAPIRET2 table, any data as JSON | one setter class each, no filtering | one `log_*` method each, chainable, BAPIRET2 severity filter |
| Read back what was logged | `get_all_items( )` and unpack setters | `get_messages( )`, `get_messages_flat( )`, `get_messages_as_bapiret2( )`, `get_messages_rap( )` |
| Ask "did anything fail?" | loop over items | `log_contains_error( )`, `get_message_count( 'E' )`, `search_message( )` |
| Tag entries with the document being processed | build the text yourself | `set_context( )` / `clear_context( )` |
| Know that a save or a mirror silently failed | you don't | `get_internal_errors( )` |
| Unit-test the code that logs | mock `if_bali_log` | mock the small `zif_cloud_logger` interface |

## Requirements

* SAP S/4HANA 2023 or higher, SAP S/4HANA Cloud, or SAP BTP ABAP Environment
* ABAP language version *ABAP for Cloud Development* for every object
* Released APIs only: `cl_bali_log`, `cl_bali_log_db`, `cl_abap_context_info`, XCO

## Installation

1. Pull the repository with [abapGit](https://abapgit.org) into a package of your choice
   (ABAP language version *ABAP for Cloud Development*).
2. The Application Log object `Z_CLOUD_LOG_SAMPLE` (sub-object `SETUP`) ships with the
   repository and is used by the tests and the demo. For your own logs create an Application
   Log object in the *Maintain Application Log Object* app (Fiori) or `SLG0` (on-premise).
   `db_save = abap_true` requires an object; `db_save = abap_false` works without one.
3. Run the ABAP Unit tests of `zcl_cloud_logger` and `zcl_cloud_logger_view_console`.

## Quick start

Run `zcl_cloud_logger_demo` with **F9** in ADT. It logs a small process (context, T100
message, filtered BAPIRET2 table, exception, JSON data, timer) and prints the result on the
console without persisting anything.

## Usage

Every `log_*` method returns the logger, so calls chain. Every writing method raises
`zcx_cloud_logger_error`; wrap the logging block once instead of every call.

### Get an instance

```abap
DATA(logger) = zcl_cloud_logger=>get_instance(
    object               = 'ZMYAPP'          " Application Log object (required when db_save = abap_true)
    subobject            = 'IMPORT'
    ext_number           = |{ run_id }|      " part of the instance key
    db_save              = abap_true         " abap_false: save_application_log( ) is a no-op
    expiry_date          = CONV #( cl_abap_context_info=>get_system_date( ) + 30 )
    enable_emergency_log = abap_false        " abap_true mirrors every entry via XCO BAL (best effort)
    trim_limit           = 100 ).            " cap of the internal error trail
```

The same object / subobject / external id always returns the same instance. Supplying a
different `db_save`, `expiry_date`, `trim_limit` or `enable_emergency_log` for an existing
instance raises `config_mismatch`; omitting a parameter means "no preference".

### Add entries

```abap
logger->log_string_add( `Free text` ).                                   " default severity W
logger->log_string_add( string = `Failed`  msgty = zif_cloud_logger=>c_message_type-error ).

logger->log_message_add( VALUE #( msgty = 'E' msgid = 'ZMYAPP' msgno = '001' msgv1 = order_id ) ).

MESSAGE e002(zmyapp) WITH order_id INTO DATA(dummy) ##NEEDED.
logger->log_syst_add( ).                                                 " takes sy-msg*

logger->log_exception_add( exception ).                                  " default severity E
logger->log_exception_add( exception = exception  severity = 'W' ).

logger->log_bapiret2_structure_add( bapiret2 ).
logger->log_bapiret2_table_add( bapiret2_t   = bapiret2_table
                                min_severity = 'E' ).                    " keeps E, A, X

logger->log_data_add( any_structure_or_table ).                          " serialized to JSON via XCO
```

Initial structures and unbound exceptions are ignored, so chains do not need guards.

### Sticky context

```abap
logger->set_context( `Order 4711` ).
logger->log_string_add( `Price checked` ).      " persisted as "[Order 4711] Price checked"
logger->clear_context( ).
```

### Timer

```abap
logger->start_timer( ).
" ... work ...
logger->stop_timer( `Pricing` ).                " logs "Timer Result: Pricing took 0.421 seconds."
```

### Read the log

```abap
IF logger->log_contains_error( ).             " E, A or X present
  ...
ENDIF.

DATA(errors)   = logger->get_message_count( zif_cloud_logger=>c_message_type-error ).
DATA(found)    = logger->search_message( VALUE #( msgid = 'ZMYAPP' msgno = '001' ) ).
DATA(entries)  = logger->get_messages( ).                " full internal log
DATA(lines)    = logger->get_messages_flat( ).           " "[ctx] E001(ZMYAPP) - text"
DATA(bapiret2) = logger->get_messages_as_bapiret2( ).
```

### RAP

```abap
METHOD validate_order.
  ...
  LOOP AT logger->get_messages_rap( ) INTO DATA(message).
    APPEND VALUE #( %tky = order-%tky %msg = message ) TO reported-order.
  ENDLOOP.
ENDMETHOD.
```

Free-text and exception entries are wrapped in message `Z_CLOUD_LOGGER 001` (four 50-character
placeholders).

### Save

```abap
logger->save_application_log( ).
COMMIT WORK.
```

The caller owns the commit. Where `COMMIT WORK` is not allowed (RAP), use
`save_application_log( use_2nd_db_connection = abap_true )`, which lets `cl_bali_log_db`
commit on its own connection. With `db_save = abap_false` the call does nothing and is
recorded in the internal error trail.

### Reset, merge, free

```abap
logger->reset_appl_log( ).                     " fresh log, same instance and configuration
logger->reset_appl_log( abap_true ).           " also delete the persisted log

logger->merge_logs( other_logger ).            " copies entries and trail, other stays unchanged

logger->free( ).                               " deregisters; any further write raises instance_released
```

### Internal error trail

Problems the logger swallows on purpose (failed emergency mirror, no-op save, unresolvable
message text, failed delete during reset) are not lost:

```abap
LOOP AT logger->get_internal_errors( ) INTO DATA(problem).
  ...  " problem-timestamp, problem-method, problem-error_text
ENDLOOP.
logger->clear_internal_errors( ).
```

The trail is capped at `trim_limit` entries (default 100, oldest evicted first).

## API overview

| Group | Methods |
|---|---|
| Instance | `zcl_cloud_logger=>get_instance( )`, `free( )`, `reset_appl_log( )`, `merge_logs( )` |
| Add | `log_string_add`, `log_message_add`, `log_syst_add`, `log_exception_add`, `log_bapiret2_structure_add`, `log_bapiret2_table_add`, `log_data_add` |
| Context / timer | `set_context`, `clear_context`, `start_timer`, `stop_timer` |
| Query | `log_is_empty`, `log_contains_messages`, `log_contains_error`, `log_contains_warning`, `get_message_count`, `search_message` |
| Read | `get_messages`, `get_messages_flat`, `get_messages_as_bapiret2`, `get_messages_rap`, `get_handle`, `get_log_handle` |
| Persist / show | `save_application_log`, `display( viewer )` |
| Diagnostics | `get_internal_errors`, `clear_internal_errors`, `zif_cloud_logger=>c_version` |

Every public method is documented with ABAP Doc; hover in ADT for parameters and behaviour.

## Errors

All failures surface as `zcx_cloud_logger_error`. Check `if_t100_message~t100key` against
the class constants:

| textid | Message | When |
|---|---|---|
| `error_in_creation` | 003 | `cl_bali_log` refused to create the log or header (e.g. unknown log object) |
| `object_required` | 006 | `db_save = abap_true` without an Application Log object |
| `invalid_trim_limit` | 008 | negative `trim_limit` |
| `config_mismatch` | 007 | an instance with the same key exists with different settings |
| `error_in_logging` | 004 | the Application Log rejected an entry |
| `error_release` | 002 | `cl_bali_log_db` could not save the log |
| `error_in_emergency_log` | 005 | the XCO emergency log could not be created |
| `instance_released` | 009 | writing method called after `free( )` |

The original `cx_bali_runtime` / XCO exception is chained in `previous`.

## Viewers

`display( viewer )` hands the logger to any implementation of `zif_cloud_logger_viewer`
(one method: `view( logger )`).

* `zcl_cloud_logger_view_console` – writes header, entries and internal error trail to an
  `if_oo_adt_classrun_out` console.
* Your own – e.g. an ALV popup on an SAP GUI system, a Fiori app or a monitoring endpoint.
  `get_messages( )` and `get_messages_flat( )` give you the data in table form.

## Testing code that uses the logger

Depend on `zif_cloud_logger`, not on the class, and inject it:

```abap
CLASS zcl_import DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor IMPORTING logger TYPE REF TO zif_cloud_logger OPTIONAL.
  ...
ENDCLASS.
```

In the test, `cl_abap_testdouble=>create( 'zif_cloud_logger' )` gives you a double whose
fluent methods can be configured to return the double itself. The library's own tests show
the pattern with hand-written doubles for the two internal seams
(`zif_cloud_logger_system`, `zif_cloud_logger_persistence`).

## Design

* **Multiton.** One instance per object / subobject / external id, created lazily by
  `get_instance( )`, removed by `free( )`. A released instance is dead: writes raise
  `instance_released`, queries return empty results.
* **Two seams.** All environment access (date, time, time stamp, user, `sy-msg*`) goes
  through `zif_cloud_logger_system`; all database access through
  `zif_cloud_logger_persistence`. Production defaults are injected by the constructor;
  the tests inject fixed-clock and spy doubles, so the unit tests never touch the
  database or a real clock.
* **Never bring the caller down.** Problems inside the logger (emergency mirror, text
  resolution, no-op save, delete during reset) are recorded in the internal error trail
  instead of raised. Problems in the Application Log API itself are raised, wrapped.
* **Strategy for output.** The logger knows nothing about UIs; viewers implement
  `zif_cloud_logger_viewer`.
* **Clean ABAP.** No Hungarian notation, final classes, ≤ 3 parameters where the API
  allows it (`get_instance` is the documented exception), ABAP Doc on every public element.
  Clean Core: released APIs only, checked by abaplint with the `steampunk-2305-api` snapshot.

## Development

The repository runs off-stack without an SAP system:

```bash
npm ci
npm run lint     # abaplint, full rule set curated to Clean ABAP, language version Cloud
npm test         # transpiles to JavaScript and runs the ABAP Unit tests on Node.js
```

GitHub Actions runs both on every push and pull request. Some things only the real compiler
catches; see [CONTRIBUTING.md](CONTRIBUTING.md) for the list and for the pull-request
checklist.

## Changelog and roadmap

The version history lives in [CHANGELOG.md](CHANGELOG.md). Planned:

* Load a persisted log into an instance (`cl_bali_log_db=>load_log`).
* Enqueue / dequeue support of `cl_bali_log_db`.
* Asynchronous saving via the Background Processing Framework for high-volume scenarios.
* A RAP service and Fiori dashboard for log analysis.

Issues and pull requests are welcome.

## License and author

[MIT](LICENSE). Created and maintained by [George Drakos](https://www.linkedin.com/in/george-drakos/).
