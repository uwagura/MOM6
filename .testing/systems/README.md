# System Configurations for MOM6 Regression Testing

This directory contains system-specific configurations for running MOM6
regression tests on different HPC systems.

## Current Systems

- `gaea.mk` - GFDL Gaea c5 cluster

## Adding a New System

To add regression testing support for a new system (e.g., Derecho):

### 1. Create the configuration file

Create `systems/derecho.mk` with the following sections:

```makefile
# System identification
SYSTEM_NAME := derecho

# Stats repository (contains regression baselines)
# You'll need to create a corresponding stats repository for your system
STATS_REPO_URL ?= https://github.com/your-org/Derecho-stats-MOM6-examples.git
STATS_REPO_BRANCH ?= main

# Batch scheduler settings (Slurm/PBS/etc.)
SLURM_CLUSTER ?= derecho
SLURM_ACCOUNT ?= your_account
SLURM_QOS ?= regular
SLURM_NODES ?= 8
SLURM_TIME ?= 30:00

# Compilers to test
COMPILERS ?= gnu intel

# Test codes per compiler (S=symmetric, N=non-symmetric, L=layout, etc.)
TEST_CODES_gnu ?= SNL
TEST_CODES_intel ?= SNL

# Module environments
define MODULES_gnu
module load gcc netcdf-fortran openmpi
endef
export MODULES_gnu
```

### 2. Create the system Makefile

Create `Makefile.derecho` in the `.testing/` directory, following the pattern
of `Makefile.gaea`. You may need to adjust:

- Batch submission commands (sbatch vs qsub)
- Job directory paths
- Any system-specific quirks

### 3. Create a stats repository

The stats repository structure should match `Gaea-stats-MOM6-examples`:
- Contains a `regressions/` directory with expected output checksums
- Contains MOM6-examples as a submodule
- MOM6-examples contains MOM6 as a submodule

### 4. Add the target to the main Makefile

Add to `.testing/Makefile`:

```makefile
test-Derecho:
	$(MAKE) -f Makefile.derecho test-Derecho
```

## Configuration Variables

| Variable | Description |
|----------|-------------|
| `SYSTEM_NAME` | Identifier for the system |
| `STATS_REPO_URL` | Git URL for regression baselines repository |
| `STATS_REPO_BRANCH` | Branch to use for baselines |
| `CONFIGS_REPO_BRANCH` | Branch for MOM6-examples (usually same as STATS) |
| `SLURM_*` | Slurm batch scheduler settings |
| `COMPILERS` | List of compilers to test |
| `TEST_CODES_<compiler>` | Test codes to run (S/N/L/D/T/R) |
| `MODULES_<compiler>` | Module load commands for each compiler |
| `MPIRUN` | MPI launcher command |

## Test Codes Reference

| Code | Test Type | Description |
|------|-----------|-------------|
| S | Symmetric | Default symmetric grid mode |
| N | Non-symmetric | Asymmetric grid comparison |
| L | Layout | Alternate domain decomposition |
| D | Debug | Debug build verification |
| T | Static | Static memory allocation |
| R | Restart | Restart reproducibility |
