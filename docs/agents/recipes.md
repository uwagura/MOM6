# Common development recipes

Follow the patterns of nearby code; the snippets for `get_param`, `register_diag_field`,
and `_BUG` flags are in `AGENTS.md`.

## New parameterization module

1. Create `MOM_new_param.F90` in the appropriate `src/parameterizations/` subdirectory.
2. Define a control structure `new_param_CS` with `private` members.
3. `new_param_init()`: `log_version`, read parameters with `get_param`, register diagnostics.
4. The main computational routine.
5. `new_param_end()` to deallocate.
6. Call it from the driver (e.g. `MOM_diabatic_driver.F90`).
7. Add unit tests in `config_src/drivers/unit_tests/` where practical.

Module header pattern:

```fortran
#include "version_variable.h"
character(len=40) :: mdl = "MOM_new_param"
...
call log_version(param_file, mdl, version, "")
```

## New diagnostic

1. Add `integer :: id_new_diag = -1` to the control structure.
2. Register it in the module's `_init` with `conversion=` to MKS; use `v_extensive=.true.`
   for vertically integrated quantities and a CMOR name where one applies.
3. Compute and post inside `if (CS%id_new_diag > 0)`.

## New runtime parameter

1. Add the control-structure member with units in its comment.
2. Read it with `get_param`, using `scale=` to convert from MKS.
3. If it could change answers, default to the existing behavior.
