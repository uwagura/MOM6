# Testing MOM6

Tests in `.testing/` pass only when output is bitwise identical between the two runs
being compared, checked via `ocean.stats` (total energy at machine precision) and
`chksum_diag` (mean/min/max/bitcount checksums over the physical domain).

```bash
make -C .testing -j build/symmetric/MOM6   # reference executable
make -C .testing -j test                   # all tests below
make -C .testing -j test.<name>            # one test, e.g. test.restart
make -C .testing -j build.unit run.unit    # unit tests
```

| Test | Compares |
|------|----------|
| `test.grid` | symmetric vs asymmetric memory |
| `test.layout` | serial vs parallel decomposition |
| `test.rotate` | rotated vs unrotated domain |
| `test.restart` | continuous run vs restart-and-continue |
| `test.repro` | DEBUG vs REPRO builds |
| `test.openmp` | serial vs OpenMP |
| `test.nan` | NaN-initialized vs normal memory |
| `test.dim.{t,l,h,z,q,r}` | dimensional rescaling of time, length, thickness, depth, enthalpy, density |
| `test.regression` | this branch vs the target branch (PRs only); shows answer changes |

Test configurations:

- `tc0`: unit tests
- `tc1`, `tc1.a`, `tc1.b`: benchmark (split RK2, unsplit RK3, unsplit RK2)
- `tc2`, `tc2.a`: ALE with tides; sigma coordinate with PPM_H4
- `tc3`: open boundary conditions
- `tc4`: sponges and I/O initialization

A `test.dim.*` failure usually means a missing or wrong `scale=`/`conversion=` factor or a
unit-inconsistent expression. A `test.rotate` failure usually means asymmetric treatment of
the u and v directions.
