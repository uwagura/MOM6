# Platform Testing Configuration
#
# This file defines which platforms to test and where to find their test suites.
# Each platform has its own repository containing regression baselines and a
# Makefile that implements the test interface.
#
# To add a new platform:
# 1. Add the platform name to the PLATFORMS variable
# 2. Define PLATFORM_<name>_REPO_URL for the stats repository
# 3. Define PLATFORM_<name>_REPO_BRANCH for the branch to use
#
# Example:
#   PLATFORMS += myplatform
#   PLATFORM_myplatform_REPO_URL := https://github.com/org/myplatform-stats.git
#   PLATFORM_myplatform_REPO_BRANCH := main

#---
# Active platforms
# This list can be overridden via command line: make test PLATFORMS="gaea"
PLATFORMS ?= gaea

#---
# Platform: Gaea (GFDL HPC System)
PLATFORM_gaea_REPO_URL := https://gitlab.gfdl.noaa.gov/Utheri.Wagura/Gaea-stats-MOM6-examples.git
PLATFORM_gaea_REPO_BRANCH := refactor/unified-test-api

#---
# Platform: Example (template for future platforms - currently disabled)
# Uncomment and modify to add a new platform:
#
# PLATFORMS += example
# PLATFORM_example_REPO_URL := https://github.com/org/example-stats-MOM6.git
# PLATFORM_example_REPO_BRANCH := main
