# Changelog

All notable changes to ABAP Cloud Logger are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/). The installed version is available at
runtime as `zif_cloud_logger=>c_version`.

## [Unreleased]

Hardening after a full audit of 2.2.0. No signature of the released API changed; the
behaviour changes are listed under *Changed* and *Fixed*.

### Fixed
- BAPIRET2 rows without a message class lost their text (the entry read `E::000`). Such a
  row is logged as free text with the row's severity; a row without class and without text
  is ignored. A row whose message cannot be resolved keeps the text the BAPI supplied.
- Free text converted for RAP, and mirrored to the emergency log, lost the blank at
  characters 50, 100 and 150 ("...order has" + "been..." became "...order hasbeen..."). The
  text is split so that no message variable ends on a blank.
- A blank or lower-case severity produced entries that `log_contains_*` and
  `get_message_count( )` did not see, and `min_severity = 'e'` filtered nothing. Every
  `log_*` method and the BAPIRET2 filter normalize the severity now: upper case, and a
  blank or unknown value becomes the default of the method (warning; error for exceptions;
  success for a BAPIRET2 row).
- A numeric attribute named in the T100 key of an exception arrived right-aligned in the
  message variable (47 blanks, then `42`). Attributes are formatted like in a string
  template; an attribute that is not elementary yields an empty variable instead of a
  conversion error.
- `load( )` of a log that was saved without entries: `get_all_items( )` is documented to
  raise `cx_bali_not_found` for such a log, which surfaced as `error_in_loading`. It loads
  as an empty logger.
- `log_bapiret2_table_add( )`: one row rejected by the Application Log no longer drops the
  rows behind it. The first rejection is raised after the table was processed.
- `reset_appl_log( abap_true )` deleted the persisted log before the new log existed. The new
  log is created first; if that fails, the old log is untouched.
- After a reset on a later day the registry kept the old default expiry, so spelling out the
  new default was reported as `config_mismatch`.
- `get_instance( )` with a negative `trim_limit` for a key that is in use raised
  `config_mismatch` instead of `invalid_trim_limit`; `load( )` validated `trim_limit` only
  after reading the database.
- A logger without Application Log object never worked on a real system: the Application
  Log refuses the header, which surfaced as `error_in_creation` (or, with the emergency
  log, as `error_in_emergency_log`). Off-stack it passed because the stub skips that check.
  `get_instance( )` without object raises `object_required` now, whatever `db_save` says
  (message 006, text adjusted), and the README no longer promises otherwise.
- Emergency log: exceptions were mirrored without their severity; the external id of a
  logger without `ext_number` was a UUID nobody could read back, generated outside the
  error handling. The handle of the main log is used instead.
- The merged internal error trail is sorted `STABLE`, so entries of the same instant keep
  their order on the kernel.
- The logger's own diagnostic texts (timer, no-op save, JSON failure) were empty in a logon
  language without translation; the text symbols carry their English text as fallback.
- `search_message( )` ignored `msgv1` to `msgv4`: a search for a variable alone matched any
  entry. Filled variables are compared now.
- `zcl_cloud_logger_fake` drifted from the logger: it dropped the T100 key of exceptions,
  showed the raw message parts instead of the T100 text, took BAPIRET2 rows differently,
  logged no timer warnings and raised on data that cannot be serialized.

### Changed
- Entry `date` and `time` are still system date and system time, but read as one moment:
  two separate readings could pair the old date with the new time around midnight. Entries
  read back by `load( )` carry UTC, as before.
- Entry `user_name` is the technical user name. The alias, up to 40 characters, was cut to
  the 12 characters of the field and matched neither the alias nor the user.
- `log_contains_error( )`, `log_contains_warning( )` and `get_message_count( )` read
  counters kept with the entries instead of scanning the log.
- `get_message_count( )` accepts the severity in lower case.
- The emergency log is written through `zif_cloud_logger_persistence`
  (`open_emergency_log`, `mirror_message`, `mirror_exception`), like every other database
  access. `zif_cloud_logger_system~system_time` became `system_moment` (date and time
  together). Both interfaces are internal seams,
  not released API.
- `zcl_cloud_logger_benchmark` prints the internal error trail after the volume run, so a
  refused delete is visible.

### Added
- `zcl_cloud_logger_conversion`: the pure conversions shared by logger and fake (severity,
  free-text split, exception key, text fallback, search). Internal, not released.
- Tests: 198 (93 before). A contract test runs 14 scenarios against the real logger and the
  fake and compares everything a consumer can observe; the emergency log, `load( )` through
  an injected persistence and the Application Log items (context prefix, cut at 200
  characters) are covered for the first time. One test (`when_merge_then_items_copied`)
  needs the real Application Log runtime and is skipped off-stack.
- README: emergency-log cost and life cycle, a RAP recipe (collect, save in the save phase,
  free in `cleanup`), *keep until expiry*, authorizations, the 999,999-item limit, "merge
  once", where the context is persisted. CONTRIBUTING: the list of kernel-only behaviour.

### Not in this release
- Releasing logs from Application Log memory (`release_memory`) waits for the off-stack stub.
- A logger that keeps its entries in memory only, without Application Log object. In unit
  tests `zcl_cloud_logger_fake` does that.

## [2.2.0] - 2026-09-17

### Added
- `zcl_cloud_logger=>load( handle )`: attaches to a persisted Application Log
  and continues writing to it. Persisted items become internal log entries
  (severity, text, T100 key; `item`/`context` initial, date/time UTC), the
  instance is registered under the log's key, `save_application_log( )` updates
  the same log. New textids `error_in_loading` (010, carries `log_handle`) and
  `already_active` (011, raised before the database is touched when the log is
  still held by a live logger of the session).
- `zif_cloud_logger_persistence~load_log( )` and the `loaded_log` structure; the
  production adapter maps `if_bali_item_getter` / `if_bali_message_getter` items.
- `zcl_cloud_logger_benchmark` (F9): timing of add / render / count / save /
  delete for a configurable number of entries, plus an emergency-log probe.

### Fixed
- Emergency log: free text is mirrored as message `Z_CLOUD_LOGGER 001` with its
  severity; XCO's `add_text` has none, so mirrored errors used to show as success.

### Measured
- S/4HANA 2023 FPS03, 20,000 entries: add 0.46 s, render 0.016 s, save 0.058 s,
  delete 0.010 s; emergency-log mirror persisted and visible in SLG1 without a
  commit. Numbers and setup in the README.

### Changed
- Off-stack pipeline: at release time the transpiler did not run its own syntax check
  (`ignoreSyntaxCheck`) and three `load( )` integration tests ran in ADT only. Both were
  lifted on `main` afterwards: the syntax check is on (`ignoreSyntaxCheck: false`) and the
  `load( )` tests run off-stack.

## [2.1.0] - 2026-09-16

### Added
- `zcl_cloud_logger_fake`: in-memory implementation of `zif_cloud_logger` for unit
  tests of consuming code. Fluent methods return the fake, queries work on what was
  logged, `save_calls` / `reset_calls` / `released` are exposed, the
  released-instance contract is mimicked. No Application Log, no database.
- `log_exception_add( )` keeps the T100 key and variables of exceptions that
  implement `if_t100_message`, so `search_message( )`, `get_messages_rap( )` and
  `get_messages_as_bapiret2( )` see the real message instead of free text.
- `zcx_cloud_logger_error=>log_object` names the Application Log object concerned;
  messages 002, 003, 004, 005, 007 and 009 show it as `&1`.
- README: text-length limit of the Application Log, `trim_limit = 0`, high-volume
  guidance, testing with the fake.

### Fixed
- Messages with number `000` were treated as free text by `get_messages_flat( )`,
  `get_messages_rap( )` and the exception-key extraction (`000` is the initial
  value of the NUMC field). The message class alone decides now.
- `get_instance( )` compares the effective expiry date, so spelling out the
  default explicitly is no longer reported as `config_mismatch`.

### Changed
- Emergency-log policy documented: a failure at creation raises (an explicit
  request that cannot be honoured), a failure during `reset_appl_log( )` is only
  trailed so the main log survives.

## [2.0.1] - 2026-09-16

### Fixed
- `free( )` on a stale reference (after a new instance with the same key was
  created) no longer removes the new instance from the registry.
- `merge_logs( )` with the logger itself as input is ignored instead of
  duplicating every entry.
- `log_message_add( )` with an initial severity defaults to warning; such entries
  were invisible to `log_contains_*` and `get_message_count( )`.
- The merged internal error trail is kept chronological, so trimming evicts the
  oldest entries.
- `user_name` in log entries falls back to the technical user name when no alias
  is maintained (typical on-premise).
- `c_default_message_attributes-type` is spelled as a literal; the off-stack
  runtime resolved the previous constant reference to blank, so default-severity
  behaviour differed between the pipeline and the system.

### Removed
- Unused text symbol 001 of `zcl_cloud_logger`.

## [2.0.0] - 2026-09-16

### Breaking
- A logger released with `free( )` is dead. Every writing method
  (`log_*`, `merge_logs`, `save_application_log`, `reset_appl_log`,
  `start_timer`, `stop_timer`) raises `zcx_cloud_logger_error` with textid
  `instance_released` (message 009) instead of silently discarding the call.
  Queries (`get_*`, `log_is_empty`, `search_message`, ...) return empty results.
  Request a new instance with `zcl_cloud_logger=>get_instance( )`.
- `log_message_add`: `symsg` is mandatory. An initial structure is still ignored.
- `log_data_add`, `start_timer`, `stop_timer`, `merge_logs` now declare
  `RAISING zcx_cloud_logger_error` (raised only for `instance_released`;
  serialization and Application Log problems keep going to the log / internal trail).
- RETURNING parameters renamed to `self` (fluent methods) and `result` (queries,
  `get_instance`). Callers are unaffected; classes that implement
  `zif_cloud_logger` themselves (e.g. test doubles) must rename the assignments.
- Removed the unused constants `c_message_type-error_pattern` and
  `c_message_type-warning_pattern`.
- Removed `zcl_cloud_logger_view_alv` (SAP GUI ALV popup, Standard ABAP). The
  library is ABAP for Cloud Development only; an ALV viewer is a few lines on top
  of `zif_cloud_logger_viewer` and `get_messages( )` in your own package.
- `log_syst_add` ignores an empty SY message instead of adding a blank entry.

### Added
- ABAP Doc on every public type, constant and method of `zif_cloud_logger`,
  `zif_cloud_logger_viewer` and the exception classes.
- `merge_logs` and `save_application_log` return the logger for chaining.
- Specific exception textids: `object_required` (006, `db_save = abap_true`
  without an Application Log object), `invalid_trim_limit` (008),
  `instance_released` (009).
- `zif_cloud_logger_system` / `zcl_cloud_logger_system`: single point of access
  to date, time, time stamp, user and the SY message.
- `zif_cloud_logger_persistence` / `zcl_cloud_logger_persistence`: single point
  of access to `cl_bali_log_db`. Both seams are injectable via the constructor.
- Constants `c_version`, `c_default_expiry_days`, `c_free_text_message`.
- `zcl_cloud_logger_view_console`: viewer for the ADT console
  (`if_oo_adt_classrun_out`), usable in ABAP for Cloud Development.
- `zcl_cloud_logger_demo`: runnable F9 demo of the typical flow.

### Fixed
- An unknown or malformed message class no longer dumps in `log_message_add`,
  `get_messages_flat` or `get_messages_rap`; the raw message components are
  rendered instead and the problem is recorded in the internal error trail.
- Constructor validation errors report their real cause instead of
  "Log object could not be created".
- Timer duration is computed with plain date/time arithmetic on the UTC time
  stamps; `cl_abap_tstmp=>subtract` rejected the long stamps with
  `cx_parameter_invalid_*` on S/4HANA 2023, so `stop_timer` logged
  "Error calculating timer duration" instead of the duration.

### Changed
- Test suite rewritten: behaviour-named tests, `msg` on every assertion, no
  `WAIT`, no database access, plus an isolated test class that runs the logger
  against fixed-clock and persistence doubles.
- Off-stack pipeline: full abaplint rule set curated to Clean ABAP (178 rules),
  API snapshot `steampunk-2305-api`, Error-level backstop for non-Cloud `sy`
  fields, Dependabot for the npm toolchain.
- README rewritten for 2.0.0; version history moved to this file; CONTRIBUTING.md
  and issue templates added.

## [1.6.0] - 2026-04-26

### Added
- Internal error trail: `get_internal_errors( )` / `clear_internal_errors( )` expose
  previously swallowed `cx_bali_runtime` exceptions; capped at 100 entries, FIFO.
- Strict multiton validation: `get_instance` raises `config_mismatch` on conflicting
  configuration instead of returning a mismatched instance.
- `save_application_log` records a no-op (`db_save = abap_false`) in the trail.
- `start_timer` double-call detection.
- Sticky context applies to every entry point, not only free text.

### Fixed
- Internal log no longer truncates messages to 50 characters.
- Emergency log dispatcher picks the correct XCO API per source type.
- `create_emergency_log` stopped mutating `ext_number`.
- `free( )` and `reset_appl_log( )` clear timer, context and recreate the emergency log.
- `merge_logs` no longer dumps on an unbound input.
- Constructor raises when `db_save = abap_true` is requested without an object.

### Performance
- Removed the unused secondary key on the internal log; simplified `get_messages_flat`;
  `log_contains_messages` no longer copies the items table.

## [1.5.0] - 2026-01-23
### Added
- Sticky context (`set_context` / `clear_context`) appended to all subsequent entries.

## [1.4.0] - 2026-01-18
### Added
- `display( viewer )` with `zif_cloud_logger_viewer` (Strategy pattern); ALV viewer.

## [1.3.0] - 2026-01-09
### Added
- `start_timer` / `stop_timer`.

## [1.2.0] - 2026-01-07
### Added
- `log_bapiret2_table_add` severity filter (`min_severity`).

## [1.1.0] - 2026-01-04
### Added
- `log_data_add`: any structure or table serialized to JSON via XCO.

## [1.0.0] - 2025-12-20
### Added
- Initial release: messages, strings, exceptions; fluent interface; Application Log (BAL)
  integration; ABAP Cloud / Clean Core compliance.
