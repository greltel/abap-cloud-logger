# Contributing

Thanks for taking the time. Bug reports, questions and pull requests are all welcome.

## Before you start

* The library is **ABAP for Cloud Development** only. Use
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
  `zif_cloud_logger_persistence` (the emergency log included).
* Anything the logger and `zcl_cloud_logger_fake` must do alike — severities, text
  conversions, searches — goes into `zcl_cloud_logger_conversion` as a pure function, not
  into both classes.

## Tests

* Every behaviour change comes with a test. Test methods are named after the behaviour
  (`given_..._then_...`, `when_..._then_...`, ≤ 30 characters) and every assertion has a `msg`.
* `ltc_cloud_logger` tests the public factory against the in-memory Application Log.
  `ltc_cloud_logger_isolated` builds the logger directly with the doubles
  `ltd_fixed_system` and `ltd_persistence_spy`; put anything that depends on time, user or
  the database there — the emergency log and `load( )` included. `ltd_rejecting_log` is an
  Application Log that refuses an item, for the error paths.
* `ltc_logger_contract` runs each scenario against the real logger and against
  `zcl_cloud_logger_fake` and compares what a consumer can observe. A change in the
  behaviour of a `log_*` or query method gets a scenario there.
* The pure conversions are tested in `zcl_cloud_logger_conversion`, the fake's own extras
  (counters, released flag) in `zcl_cloud_logger_fake`.
* No `WAIT`, no `SELECT`, no `COMMIT WORK` in tests. `RISK LEVEL HARMLESS` means it.
* Off-stack the tests run against an in-memory SQLite database (`offstack/setup.mjs`), which
  registers every `src/*.aplo.json` in BALOBJ / BALSUB, so the Application Log object check
  works there too. A new Application Log object only needs its `.aplo.json` in `src`.
* A test that still cannot run off-stack is skipped via `options.skip` in
  `abap_transpile.json` with a note saying why. Today that is one test:
  `ltc_cloud_logger->when_merge_then_items_copied` (the stub of
  `add_all_items_from_other_log` copies nothing). It must be green in ADT.

## What the off-stack pipeline does not catch

Verified in ADT so far — please check these yourself before pushing:

* A character literal is **not** accepted as a row of a packed table type
  (`VALUE #( ( '20260916101500.0000000' ) )` for `timestampl`). Use typed constants.
* ABAP Doc links are written fully qualified (`{@link zcl_cloud_logger.METH:get_instance}`).
  A relative `.METH:` in object-level documentation resolves against the class pool.
* ABAP Doc for a chained `TYPES:` / `CONSTANTS:` block goes **after** the colon line,
  directly before `BEGIN OF`.
* Method names are limited to 30 characters (abaplint reports this one).

And the other direction — things the system does right that the off-stack runtime does not:

* A `CONSTANTS` component whose `VALUE` refers to another constant is left blank off-stack.
  Constants that tests depend on are written as literals.
* `IS INSTANCE OF <interface>` is always false off-stack; a guarded `CAST` behaves correctly
  in both places. Access the attribute in a second statement
  (`DATA(t100) = CAST if_t100_message( x ). ... t100->t100key`), not chained on the cast.
* `cl_abap_tstmp=>subtract` never raises off-stack and only approximates; the real kernel
  rejected two `timestampl` operands. The logger computes durations itself.

The Application Log and XCO stubs are simpler than the kernel. A green pipeline says nothing
about these; check them in ADT when you touch the code around them:

* `if_bali_log~add_all_items_from_other_log` is an empty stub: `merge_logs( )` never moves
  items off-stack.
* `xco_cp_bal=>for` is unbound: the emergency log cannot run off-stack. The logger reaches it
  only through `zif_cloud_logger_persistence`, and the tests use the spy.
* `cl_bali_header_setter=>create` skips its checks for an initial object; the kernel does not.
* `get_all_items( )` returns an empty table for a log without items; the kernel raises
  `cx_bali_not_found`.
* `cl_bali_log_db` keeps a copy of a saved log in memory and `load_log` returns a copy of
  it: no database, no authorization check, no "already loaded".
* `add_item` never raises. Use `ltd_rejecting_log` to reach the error paths.
* `SORT` is stable on Node.js; on the kernel only with `STABLE`.
* `cl_abap_context_info`: date and time are local time, and the alias is the user name.
* `enqueue` and `dequeue` of the Application Log do not exist in the stub, nor does the
  class `xco_cp_message`. `release_memory` exists and invalidates the log, but nothing can
  be said off-stack about the memory it frees.
* The message runtime: `xco_cp=>message( )->get_text( )` never raises and never returns an
  empty text off-stack. A message that does not exist is rendered as `TYPE:CLASS:NUMBER`
  plus the variables, the format of `MESSAGE ... INTO`. Whether XCO returns the same on the
  kernel decides how the BAPIRET2 text fallback is reached there;
  `given_unknown_ret2_then_text` tells.
* The text pool always holds the master-language texts.
* `REF #( itab[ ... ] OPTIONAL )` raises `cx_sy_itab_line_not_found` off-stack when the line
  is missing. Use `line_exists( )` or `VALUE #( ... OPTIONAL )`.

And one that is neither: a NUMC field with value `000` **is initial** — on the system and
off-stack alike. Never use `IS INITIAL` on a message number to detect "no message"; check
the message class.

## Adding a message or an exception textid

1. Add the text to message class `Z_CLOUD_LOGGER` (next free number) and to
   `src/z_cloud_logger.msag.xml`.
2. Add the `CONSTANTS: BEGIN OF <textid> ... END OF <textid>` block to
   `zcx_cloud_logger_error`, with a one-line ABAP Doc above `BEGIN OF`.
3. Document it in the *Errors* table of the README and in `CHANGELOG.md`.

## Pull request checklist

- [ ] `npm run lint` and `npm test` are green
- [ ] ABAP Unit is green in ADT (`zcl_cloud_logger`, `zcl_cloud_logger_conversion`,
      `zcl_cloud_logger_fake`, `zcl_cloud_logger_view_console`)
- [ ] ATC with the Cloud readiness variant of your system shows no new findings
- [ ] Public API changes are documented in ABAP Doc, README and `CHANGELOG.md`
- [ ] Breaking changes are called out in the pull-request description

## Versioning

Semantic versioning. The version is kept in three places: `zif_cloud_logger=>c_version`,
`package.json` and the README badge. `CHANGELOG.md` follows *Keep a Changelog*.
