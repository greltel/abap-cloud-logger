# Contributing

Thanks for taking the time. Bug reports, questions and pull requests are all welcome.

## Before you start

* The library is **ABAP for Cloud Development** only (except the `gui` sub-package). Use
  released APIs; do not read `sy-datum`, `sy-uzeit`, `sy-uname`, do not use `cl_salv_*`,
  `WRITE`, dynpros or function modules.
* Target release: S/4HANA 2023 (ABAP 7.58) and current SAP BTP ABAP Environment.
* Discuss larger changes in an issue first, especially anything that touches
  `zif_cloud_logger`: every change to that interface is a release decision.

## Setting up

You need Node.js 22 (see `.nvmrc`) and an SAP system with ADT for the final verification.

```bash
npm ci
npm run lint    # abaplint
npm test        # transpile + run the ABAP Unit tests on Node.js
```

Both must be green before you open a pull request. The GitHub Actions workflow runs the
same two commands.

## Coding standards

The code follows [Clean ABAP](https://github.com/SAP/styleguides/blob/main/clean-abap/CleanABAP.md).
The abaplint configuration enforces most of it; the points people most often trip over:

* No prefixes (`lv_`, `iv_`, `mo_`, ...). RETURNING parameters are called `result`, or `self`
  in fluent methods.
* Inline declarations (`DATA(x) = ...`), constructor expressions, `xsdbool( )`,
  `RAISE EXCEPTION NEW`, table expressions and `line_exists( )` instead of `READ TABLE`.
* Classes are `FINAL`; the logger is `CREATE PRIVATE` with a factory.
* ABAP Doc on every public type, constant and method. Comments explain *why*, not *what*.
* No commented-out code, no magic literals (use the constants in `zif_cloud_logger`),
  lines ≤ 120 characters.
* Environment access only through `zif_cloud_logger_system`, database access only through
  `zif_cloud_logger_persistence`.

## Tests

* Every behaviour change comes with a test. Test methods are named after the behaviour
  (`given_..._then_...`, `when_..._then_...`, ≤ 30 characters) and every assertion has a `msg`.
* `ltc_cloud_logger` tests the public factory against the in-memory Application Log.
  `ltc_cloud_logger_isolated` builds the logger directly with the doubles
  `ltd_fixed_system` and `ltd_persistence_spy`; put anything that depends on time, user or
  the database there.
* No `WAIT`, no `SELECT`, no `COMMIT WORK` in tests. `RISK LEVEL HARMLESS` means it.
* A test that cannot run off-stack (e.g. it needs the real Application Log object check) is
  skipped via `abap_transpile.json` with a note saying why.

## What the off-stack pipeline does not catch

Verified in ADT so far — please check these yourself before pushing:

* A character literal is **not** accepted as a row of a packed table type
  (`VALUE #( ( '20260916101500.0000000' ) )` for `timestampl`). Use typed constants.
* ABAP Doc links are written fully qualified (`{@link zcl_cloud_logger.METH:get_instance}`).
  A relative `.METH:` in object-level documentation resolves against the class pool.
* ABAP Doc for a chained `TYPES:` / `CONSTANTS:` block goes **after** the colon line,
  directly before `BEGIN OF`.
* Method names are limited to 30 characters (abaplint reports this one).

## Adding a message or an exception textid

1. Add the text to message class `Z_CLOUD_LOGGER` (next free number) and to
   `src/z_cloud_logger.msag.xml`.
2. Add the `CONSTANTS: BEGIN OF <textid> ... END OF <textid>` block to
   `zcx_cloud_logger_error`, with a one-line ABAP Doc above `BEGIN OF`.
3. Document it in the *Errors* table of the README and in `CHANGELOG.md`.

## Pull request checklist

- [ ] `npm run lint` and `npm test` are green
- [ ] ABAP Unit is green in ADT (`zcl_cloud_logger`, `zcl_cloud_logger_view_console`)
- [ ] ATC with the Cloud readiness variant of your system shows no new findings
- [ ] Public API changes are documented in ABAP Doc, README and `CHANGELOG.md`
- [ ] Breaking changes are called out in the pull-request description

## Versioning

Semantic versioning. The version is kept in three places: `zif_cloud_logger=>c_version`,
`package.json` and the README badge. `CHANGELOG.md` follows *Keep a Changelog*.
