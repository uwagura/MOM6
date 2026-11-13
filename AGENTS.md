# MOM6 agent instructions

MOM6 has a policy on AI-assisted contributions: `docs/Consortium-policy-on-AI.md`.

Read these when the task calls for them, not up front:

- Before writing or modifying Fortran: `docs/Code-style.md` (units, reproducible arithmetic, Doxygen)
- Before running or interpreting tests: `docs/agents/testing.md`
- Before committing or drafting a PR: `docs/agents/contributing.md`
- When adding a module, diagnostic, or runtime parameter: `docs/agents/recipes.md`
- To find where code lives: `docs/code_organization.rst`
- When citing prior work: `docs/references.bib`, `docs/zotero.bib`

## Answers must not change silently

MOM6 users run long production simulations, so results are expected to be bitwise
reproducible across releases. Any change to numerical answers -- bug fix, accuracy
improvement, or reordered arithmetic, however small -- needs a runtime switch whose default
keeps the old answers:

- `_BUG` flag: logical named `FEATURE_BUG`, description starting "If true, recover a bug
  that...". New flags default to `ENABLE_BUGS_BY_DEFAULT`, so users who opted into all fixes
  get the new one automatically:
  ```fortran
  call get_param(param_file, mdl, "ENABLE_BUGS_BY_DEFAULT", enable_bugs, &
                 default=.true., do_not_log=.true.)  ! This is logged from MOM.F90.
  call get_param(param_file, mdl, "OBC_TEMP_SALT_NEEDED_BUG", OBC%ts_needed_bug, &
                 "If true, recover a bug that OBC temperature and salinity can be ignored "//&
                 "even if they are registered tracers in the rest of the model.", &
                 default=enable_bugs)
  ```
- `*_ANSWER_DATE`: integer `YYYYMMDD` selecting an algorithm version, for changes that are
  improvements rather than bugs (`DEFAULT_ANSWER_DATE` sets all their defaults).

Trace secondary effects before concluding a change is answer-neutral, and always state the
answer impact ("All answers are bitwise identical", or what changes and why).

Code marked with a `!###` comment is a known answer-changing inaccuracy kept on purpose;
leave it alone unless asked.

## Parameters and units

Read runtime parameters with `get_param` rather than hardcoding values. Parameters are given
in MKS units and converted to MOM6's internal dimensional units with `scale=`; diagnostics
convert back with `conversion=`. The `test.dim.*` tests rescale internal units, so a missing
or wrong scale factor shows up as a test failure.

```fortran
call get_param(param_file, mdl, "PARAM_NAME", CS%variable, &
               "Description of this parameter.", &
               units="m s-1", default=1.0, scale=US%m_s_to_L_T)
```

Provide `default=` when one is sensible, otherwise `fail_if_missing=.true.`. Use
`do_not_log=.not.CS%feature` when a parent feature is off.

## Diagnostics

```fortran
CS%id_field = register_diag_field('ocean_model', 'field_name', diag%axesTL, Time, &
    'Long description of the field', units='m s-1', conversion=US%L_T_to_m_s)
...
if (CS%id_field > 0) call post_data(CS%id_field, field_array, CS%diag)
```

- Guard the computation, not just the `post_data` call, with `if (CS%id_field > 0)`.
- Do not fill arrays with a missing value or pass `mask=` for ordinary non-static diagnostics;
  the diag manager masks by the registered axes. Do pass `mask=` for static fields,
  non-standard masks, or sub-domain arrays.
- Never compare field values against `missing_value`: after rescaling, valid data can equal it.

## Fortran pitfalls

- Fortran does not short-circuit `.and.`/`.or.`, so `if (allocated(a) .and. a(i) > 0.)` can
  read an unallocated array. Nest the `allocated()`/`associated()` check in its own `if`.
- Arrays for optional features (e.g. `FRAZIL`) may be unallocated; check before use.
- Compare real masks with `== 1.`, not `== 1`.
- FATAL messages should name the file, subroutine, and offending condition or input.

## Infrastructure layering

`config_src/infra/` --> `src/framework/` --> everything else. The FMS wrappers in
`config_src/infra/` must never use `src/framework/`; duplicating code is preferred over
breaking this. FMS1 and FMS2 infra must expose the same API, and infra API changes must be
checked against downstream users (SIS2, ice shelf).

## Build, test, style

```bash
make -C .testing -j build/symmetric/MOM6        # reference executable
make -C .testing -j test                        # full suite
make -C .testing -j build.unit run.unit         # unit tests
./.testing/trailer.py -e TEOS10 -l 120 src config_src   # tabs, whitespace, line length
```

## Recurring agent mistakes

Add an entry only for a mistake that has been verified and seen more than once, and name the
agent or model if it is specific to one.

*(None yet.)*
