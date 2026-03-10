# Gaea c5 cluster configuration for MOM6 regression testing
#
# This file defines system-specific settings for running the MOM6 regression
# test suite on GFDL's Gaea HPC system.
#
# Usage:
#   Included by Makefile.gaea - not meant to be used directly

#---
# System identification
SYSTEM_NAME := gaea

#---
# Stats repository (contains regression baselines)
STATS_REPO_URL ?= https://gitlab.gfdl.noaa.gov/ogrp/Gaea-stats-MOM6-examples.git
STATS_REPO_BRANCH ?= dev/gfdl

# Configs repository branch (MOM6-examples)
CONFIGS_REPO_BRANCH ?= $(STATS_REPO_BRANCH)

#---
# Slurm batch settings
SLURM_CLUSTER ?= c5
#SLURM_ACCOUNT ?= gfdl_o
SLURM_ACCOUNT ?= cefi
SLURM_QOS ?= debug
SLURM_NODES ?= 12
SLURM_TIME ?= 15:00

#---
# Compilers to test
COMPILERS ?= gnu intel pgi

# Test codes per compiler
# S = symmetric, N = non-symmetric, L = layout, D = debug, T = static, R = restart
#TEST_CODES_gnu ?= SNLDT
TEST_CODES_gnu ?= SNL
TEST_CODES_intel ?= SNL
TEST_CODES_pgi ?= SNL

# GNU also runs restart tests (separate workspace)
TEST_CODES_gnu_restart ?= R

#---
# Module environments
#
# These are expanded in shell commands with: eval "$$MODULES_<COMPILER>"

define MODULES_gnu
module unload darshan-runtime intel PrgEnv-intel 2>/dev/null || true
module load PrgEnv-gnu/8.5.0 cray-hdf5 cray-netcdf
module switch gcc-native/12.3
endef
export MODULES_gnu

define MODULES_intel
module unload darshan-runtime intel cray-mpich PrgEnv-intel 2>/dev/null || true
module load PrgEnv-intel intel/2023.2.0 cray-hdf5 cray-netcdf cray-mpich
module unload cray-libsci 2>/dev/null || true
endef
export MODULES_intel

define MODULES_pgi
module unload darshan-runtime intel PrgEnv-intel 2>/dev/null || true
module load PrgEnv-nvidia cray-hdf5 cray-netcdf
endef
export MODULES_pgi

#---
# MPI runner for Slurm
MPIRUN ?= srun -mblock --exclusive
