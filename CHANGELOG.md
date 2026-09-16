# Changelog

All notable changes to ABAP Cloud Logger are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/). The installed version is available at
runtime as `zif_cloud_logger=>c_version`.

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

### Changed
- Test suite rewritten: behaviour-named tests, `msg` on every assertion, no
  `WAIT`, no database access, plus an isolated test class that runs the logger
  against fixed-clock and persistence doubles.
- Off-stack pipeline: full abaplint rule set curated to Clean ABAP (178 rules),
  API snapshot `steampunk-2305-api`, Error-level backstop for non-Cloud `sy`
  fields, Dependabot for the npm toolchain.
- `zcl_cloud_logger_view_alv` moved to the `gui` sub-package (Standard ABAP); the
  root package is ABAP for Cloud Development only.
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
