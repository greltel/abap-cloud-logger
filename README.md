# ABAP Cloud Logger

[![Version](https://img.shields.io/badge/version-2.3.0-blue)](CHANGELOG.md)
[![Tests](https://github.com/greltel/abap-cloud-logger/actions/workflows/ci.yml/badge.svg)](https://github.com/greltel/abap-cloud-logger/actions/workflows/ci.yml)
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
   Every logger needs an object, also with `db_save = abap_false`: the Application Log
   accepts no log without one. In unit tests, `zcl_cloud_logger_fake` needs none.
3. Run the ABAP Unit tests of `zcl_cloud_logger`, `zcl_cloud_logger_conversion`,
   `zcl_cloud_logger_fake` and `zcl_cloud_logger_view_console`.

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
    object               = 'ZMYAPP'          " Application Log object (required)
    subobject            = 'IMPORT'
    ext_number           = |{ run_id }|      " part of the instance key
    db_save              = abap_true         " abap_false: save_application_log( ) is a no-op
    expiry_date          = CONV #( cl_abap_context_info=>get_system_date( ) + 30 )
    enable_emergency_log = abap_false        " abap_true mirrors every entry into a second log (see below)
    trim_limit           = 100 ).            " cap of the internal error trail
```

The same object / subobject / external id always returns the same instance. Supplying a
different `db_save`, `expiry_date`, `trim_limit` or `enable_emergency_log` for an existing
instance raises `config_mismatch`; omitting a parameter means "no preference". A negative
`trim_limit` raises `invalid_trim_limit`, whether or not the key is in use.

### Emergency log

With `enable_emergency_log = abap_true` every entry is also written, immediately and
independently of your commit, into a second Application Log through the XCO BAL API (same
object and subobject; external id = yours, or the handle of the main log when you gave none,
so the two logs can be matched). It is meant for the case where the main log never gets
saved — a dump after logging, a rollback — and it is best effort: a failed mirror goes to the
internal error trail, never to the caller.

What it costs and what it leaves behind:

* **One commit per entry.** XCO writes each entry on a second database connection and commits
  it. 20,000 entries are 20,000 commits; switch it on for the processes that need it, not
  everywhere.
* **Nothing is cleaned up.** `reset_appl_log( )` opens a new emergency log for the fresh main
  log; `reset_appl_log( abap_true )` and `free( )` delete neither the old nor the new one.
  They stay on the database until they expire.
* **Merged entries are not mirrored.** `merge_logs( )` copies entries that the other logger
  already mirrored itself, if it had an emergency log.

Free text is mirrored as message `Z_CLOUD_LOGGER 001` so the severity survives; exceptions
are mirrored with their severity (A and X as error — XCO has no higher one). XCO records an
exception as five lines (text, class, source position), so counts in that log differ from
`get_message_count( )`.

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

**Severities** are accepted in upper or lower case and stored in upper case. A blank or
unknown severity becomes the default of the method: warning for text, messages and data,
error for exceptions, success for a BAPIRET2 row (BAPIs leave the type of success rows blank).
`min_severity` compares the same way.

**BAPIRET2 rows.** A row with a message class is logged as T100 message; if the message
cannot be resolved, the text the BAPI put into `message` is kept. A row without message class
is logged as free text when it has a `message`, and ignored when it has none. If the
Application Log rejects a row of a table, the rows behind it are still logged and the first
rejection is raised afterwards.

Exceptions that carry a T100 key (`if_t100_message`) keep their message class, number and
variables in the internal log, so `search_message( )`, `get_messages_rap( )` and
`get_messages_as_bapiret2( )` see the real message rather than free text. Attributes named
in the key are formatted like a string template formats them (an integer is `42`, not a
right-aligned field); an attribute that is not elementary yields an empty variable.

**Text length:** the Application Log stores free text (`log_string_add`, `log_data_add`)
up to 200 characters, and the `[context] ` prefix counts. Longer texts are cut in the
persisted log only; `get_messages( )` and `get_messages_flat( )` always return the full text.

### Sticky context

```abap
logger->set_context( `Order 4711` ).
logger->log_string_add( `Price checked` ).      " persisted as "[Order 4711] Price checked"
logger->clear_context( ).
```

Every entry of the internal log carries the context, and `get_messages_flat( )` shows it for
all of them. In the persisted Application Log only free text is prefixed: T100 messages,
BAPIRET2 rows and exceptions are stored as they are, so after `load( )` their context is
gone, and the RAP and BAPIRET2 conversions never carry it.

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
DATA(for_4711) = logger->search_message( VALUE #( msgid = 'ZMYAPP' msgv1 = '4711' ) ).
DATA(entries)  = logger->get_messages( ).                " full internal log
DATA(lines)    = logger->get_messages_flat( ).           " "[ctx] E001(ZMYAPP) - text"
DATA(bapiret2) = logger->get_messages_as_bapiret2( ).
```

`search_message( )` compares the components you fill — class, number, severity, variables —
and ignores the initial ones. The severity queries and `get_message_count( )` read counters
that are kept with the entries; they do not scan the log.

Each entry carries the technical user name and the system date and system time at which it
was added; the two are read together, so they cannot disagree around midnight. Entries that
`load( )` reads back from the database carry UTC, because that is what the Application Log
stores.

### RAP

```abap
METHOD validate_order.
  ...
  LOOP AT logger->get_messages_rap( ) INTO DATA(message).
    APPEND VALUE #( %tky = order-%tky %msg = message ) TO reported-order.
  ENDLOOP.
ENDMETHOD.
```

T100 messages, and exceptions that carry a T100 key, keep their own message. Free text and
exceptions without T100 key are wrapped in message `Z_CLOUD_LOGGER 001` (four 50-character
placeholders, 200 characters in total; a blank that would end a placeholder opens the next
one instead, so word breaks survive). The messages carry no key: you bind `%tky` and
`%element` yourself.

**Where to log, where to save.** The logger is not aware of the LUW: entries survive a
rollback, and an instance lives until `free( )`.

```abap
" Handler (validation, determination, action): collect only
logger->log_string_add( `Price missing` ).

" Saver, save_modified: persist with the business data, the framework commits
TRY.
    logger->save_application_log( ).
  CATCH zcx_cloud_logger_error.
    " the save phase must not fail because of the log
ENDTRY.

" Saver, cleanup: runs after the save and after a rollback - release the instance
logger->free( ).
```

In a managed behavior definition the saver's `cleanup` is only called with
`with additional save and cleanup` (or `with unmanaged save and cleanup`).

A default-connection save is a database change, so it belongs in the save phase, not in a
validation or determination. When the log has to survive a rollback — the request failed and
that is exactly what you want to see — save with `use_2nd_db_connection = abap_true`: the
Application Log then commits on a connection of its own, which is allowed inside the LUW.
One logger per document (`ext_number`) without `free( )` keeps every instance registered for
the rest of the session.

### Save

```abap
logger->save_application_log( ).
COMMIT WORK.
```

The caller owns the commit. Where `COMMIT WORK` is not allowed (RAP), use
`save_application_log( use_2nd_db_connection = abap_true )`, which lets `cl_bali_log_db`
commit on its own connection. With `db_save = abap_false` the call does nothing and is
recorded in the internal error trail.

Good to know:

* Logs are saved with *keep until expiry*: housekeeping leaves them alone until
  `expiry_date` (default: today + 5 days), so choose a far-future expiry date with that in
  mind. SAP documents the flag as "it is not allowed to delete the log before the expiry
  date"; on S/4HANA 2023 FPS03 `reset_appl_log( abap_true )` nevertheless deleted a saved log
  before its expiry date (checked in SLG1). If your system refuses the delete, the refusal
  is in the internal error trail.
* One Application Log holds at most 999,999 items; for more, save and reset per batch.
* Authorizations (`S_APPL_LOG` for the log object and subobject): activity 03 to read a log
  back with `load( )`, activity 06 to delete one with `reset_appl_log( abap_true )`.
* Newer releases mark the parameter behind `use_2nd_db_connection` as deprecated in favour of
  a separate method of `cl_bali_log_db`. That method is not part of the API level this
  library is checked against, so the parameter stays.

### Attach to a persisted log

A log saved earlier — by a previous run, another session, a job step — can be picked up again
by its handle and continued:

```abap
DATA(logger) = zcl_cloud_logger=>load( handle ).      " BALLOGHNDL from get_handle( ) or the log tables

logger->log_string_add( `second run started` ).       " appends to the persisted items
IF logger->log_contains_error( ).                     " queries see the persisted history
  ...
ENDIF.
logger->save_application_log( ).                      " updates the same log
```

The loaded logger is registered under the log's own object / subobject / external id, so a
later `get_instance( )` with that key returns it. Persisted items become internal log
entries with the item's severity, text and T100 key; their `item` reference and `context`
stay initial. A log that was saved without entries loads as an empty logger. Loading a log
that is still held by a live logger in the session — same handle or same key — raises
`already_active` (`free( )` it first); an unknown handle raises `error_in_loading`; a
negative `trim_limit` raises `invalid_trim_limit` before the database is read.

### Reset, merge, free

```abap
logger->reset_appl_log( ).                     " fresh log, same instance and configuration
logger->reset_appl_log( abap_true ).           " also delete the persisted log

logger->merge_logs( other_logger ).            " copies entries and trail, other stays unchanged

logger->free( ).                               " deregisters; any further write raises instance_released
```

* `reset_appl_log( )` creates the fresh log first. If that fails, the old log is untouched,
  in memory and on the database. A delete the database refuses (never saved, missing
  authorization, *keep until expiry*) goes to the internal error trail and does not stop the
  reset.
* `merge_logs( )` once per source: nothing is de-duplicated, a second merge of the same
  logger appends its entries again. Merging a fake or a released logger copies the internal
  entries only — there are no Application Log items to copy.
* `free( )` deletes nothing from the database.

### Internal error trail

Problems the logger swallows on purpose (failed emergency mirror, no-op save, unresolvable
message text, failed delete during reset) are not lost:

```abap
LOOP AT logger->get_internal_errors( ) INTO DATA(problem).
  ...  " problem-timestamp, problem-method, problem-error_text
ENDLOOP.
logger->clear_internal_errors( ).
```

The trail is capped at `trim_limit` entries (default 100, oldest evicted first);
`trim_limit = 0` switches the trail off.

### High volume

Every entry is kept twice while the logger lives: as an Application Log item and as a row of
the internal log (`get_messages( )` copies that table). For jobs that log hundreds of
thousands of lines, save and reset per batch — `save_application_log( )` then
`reset_appl_log( )` — instead of holding one log for the whole run, and keep `trim_limit`
at its default. `reset_appl_log( )` and `free( )` release the old log from Application Log
memory (`if_bali_log~release_memory`), so the batches do not pile up there. A reference you
took from `get_log_handle( )` before is dead after that. `get_messages_flat( )` renders every entry, so call it once, not per line.
`log_contains_error( )`, `log_contains_warning( )` and `get_message_count( )` are constant
time, so asking after every document is fine.

`zcl_cloud_logger_benchmark` (F9) measures adding, rendering, counting, saving and deleting
`entries` entries on your system and checks the emergency-log mirror; raise the constant to
find your limit. After each run it prints the internal error trail, so a delete or a mirror
that was refused shows as such instead of as a fast step. Watch memory from outside
(SM04 / SM50) — the memory utilities are not released for ABAP Cloud.

Measured on S/4HANA 2023 FPS03 (on-premise, 2026-09-17), 20,000 entries, every 10th an error:

| Step | Time | Per entry |
|---|---|---|
| `log_string_add` × 20,000 | 0.46 s | 0.023 ms |
| `get_messages_flat( )` (20,000 lines) | 0.016 s | 0.001 ms |
| `get_message_count( 'E' )` | 0.002 s | — |
| `save_application_log( )` + `COMMIT WORK` | 0.058 s | 0.003 ms |
| `reset_appl_log( abap_true )` + `COMMIT WORK` | 0.010 s | — |

Emergency-log mirror: 3 entries, 0 internal errors, visible in SLG1 without a commit. At these numbers the in-memory copy is
not the bottleneck for typical jobs; save-and-reset per batch remains the advice for runs
that keep hundreds of thousands of entries alive at once.

## API overview

| Group | Methods |
|---|---|
| Instance | `zcl_cloud_logger=>get_instance( )`, `zcl_cloud_logger=>load( handle )`, `free( )`, `reset_appl_log( )`, `merge_logs( )` |
| Add | `log_string_add`, `log_message_add`, `log_syst_add`, `log_exception_add`, `log_bapiret2_structure_add`, `log_bapiret2_table_add`, `log_data_add` |
| Context / timer | `set_context`, `clear_context`, `start_timer`, `stop_timer` |
| Query | `log_is_empty`, `log_contains_messages`, `log_contains_error`, `log_contains_warning`, `get_message_count`, `search_message` |
| Read | `get_messages`, `get_messages_flat`, `get_messages_as_bapiret2`, `get_messages_rap`, `get_handle`, `get_log_handle` |
| Persist / show | `save_application_log`, `display( viewer )` |
| Diagnostics | `get_internal_errors`, `clear_internal_errors`, `zif_cloud_logger=>c_version` |
| Testing | `zcl_cloud_logger_fake` — in-memory implementation of the interface for consumer tests |

Every public method is documented with ABAP Doc; hover in ADT for parameters and behaviour.

## Errors

All failures surface as `zcx_cloud_logger_error`. Check `if_t100_message~t100key` against
the class constants:

| textid | Message | When |
|---|---|---|
| `error_in_creation` | 003 | `cl_bali_log` refused to create the log or header (e.g. unknown log object) |
| `object_required` | 006 | no Application Log object was passed |
| `invalid_trim_limit` | 008 | negative `trim_limit`, in `get_instance( )` and `load( )` |
| `config_mismatch` | 007 | an instance with the same key exists with different settings |
| `error_in_logging` | 004 | the Application Log rejected an entry (for a BAPIRET2 table: the first rejected row, raised after all rows) |
| `error_release` | 002 | `cl_bali_log_db` could not save the log |
| `error_in_emergency_log` | 005 | the XCO emergency log could not be created |
| `instance_released` | 009 | writing method called after `free( )` |
| `error_in_loading` | 010 | `load( )` found no log for the handle (`log_handle` names it) |
| `already_active` | 011 | `load( )` for a log still held by a live logger in this session (same handle or key) |

The original `cx_bali_runtime` / XCO exception is chained in `previous`, and `log_object`
names the Application Log object concerned; the message texts show it as `&1`.

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

In the test, inject `zcl_cloud_logger_fake`: an in-memory implementation of the whole
interface that never writes an Application Log. Fluent methods return the fake, the query
methods work on what was logged, saves and resets are counted, and the released-instance
contract is mimicked.

The fake is held to the real logger by a contract test: the same scenarios run against both,
and entries, flat lines, BAPIRET2 and RAP conversions, counts and searches must be equal.
Severities, BAPIRET2 rows, exception keys and free text go through the same code in both.
What the fake does not have: an Application Log (`get_handle( )` and `get_log_handle( )` stay
initial), a clock (`user_name`, `date` and `time` of an entry stay initial, the timer reports
0.000 seconds) and translations (its own diagnostic texts are English).

```abap
METHOD given_missing_price_then_error_logged.
  DATA(logger) = NEW zcl_cloud_logger_fake( ).
  DATA(cut)    = NEW zcl_import( logger ).

  cut->import( order_without_price ).

  cl_abap_unit_assert=>assert_equals( act = logger->zif_cloud_logger~log_contains_error( )
                                      exp = abap_true
                                      msg = `A missing price must be logged as error` ).
  cl_abap_unit_assert=>assert_equals( act = logger->save_calls
                                      exp = 1
                                      msg = `The log must be saved once` ).
ENDMETHOD.
```

`cl_abap_testdouble=>create( 'zif_cloud_logger' )` works as well when you need to script
specific return values. The library's own tests show that style with hand-written doubles
for the two internal seams (`zif_cloud_logger_system`, `zif_cloud_logger_persistence`).

## Design

* **Multiton.** One instance per object / subobject / external id, created lazily by
  `get_instance( )`, removed by `free( )`. A released instance is dead: writes raise
  `instance_released`, queries return empty results.
* **Two seams.** All environment access (date, time, time stamp, user, `sy-msg*`) goes
  through `zif_cloud_logger_system`; all database access — saving, loading, deleting and the
  emergency log — through `zif_cloud_logger_persistence`. Production defaults are injected
  by the constructor; the tests inject fixed-clock and spy doubles, so the unit tests never
  touch the database or a real clock.
* **One place for conversions.** Severity normalization, the split of free text into message
  variables, the T100 key of an exception and the search comparison live in
  `zcl_cloud_logger_conversion`, pure functions used by the logger and by the fake.
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

## Quality and verification

| Check | Result | Where |
|---|---|---|
| ABAP Unit | 203 tests, all green | ADT on S/4HANA 2023 FPS03 (ABAP 7.58); off-stack on every commit (202, one needs the real Application Log runtime) |
| ATC, variant `ABAP_CLOUD_READINESS` | 0 findings | ADT on S/4HANA 2023 FPS03, 2026-09-16 |
| ATC, variant `S4HANA_READINESS_2023` | 0 findings | ADT on S/4HANA 2023 FPS03, 2026-09-16 |
| abaplint, 178 rules, language version Cloud, API snapshot `steampunk-2305-api` | 0 findings | [GitHub Actions](https://github.com/greltel/abap-cloud-logger/actions/workflows/ci.yml) |

Verified on:

| System | Status |
|---|---|
| SAP S/4HANA 2023 FPS03 on-premise, ABAP for Cloud Development | verified with every release |
| SAP BTP ABAP Environment | not yet verified — a pull and an ABAP Unit run on a BTP system would be a welcome contribution ([issue template](.github/ISSUE_TEMPLATE/bug_report.yml)) |
| SAP S/4HANA Cloud Public Edition | not yet verified |

The library uses released APIs only; the checks above are what backs that statement, and the
table says exactly where it has been run.

## Changelog and roadmap

The version history lives in [CHANGELOG.md](CHANGELOG.md). Planned:

* Enqueue / dequeue support of `cl_bali_log_db`.
* Asynchronous saving via the Background Processing Framework for high-volume scenarios.
* A RAP service and Fiori dashboard for log analysis.

Issues and pull requests are welcome.

## License and author

[MIT](LICENSE). Created and maintained by [George Drakos](https://www.linkedin.com/in/george-drakos/).
