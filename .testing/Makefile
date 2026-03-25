# MOM6 Platform Testing Makefile
#
# This Makefile provides a platform-agnostic interface for running MOM6
# regression test suites across multiple platforms by delegating to
# platform-specific test repositories.
#
# Usage:
#   make test                     # Test all configured platforms
#   make test PLATFORMS="gaea"    # Test specific platform(s)
#   make help                     # Show available targets

SHELL = bash

#---
# Compute paths BEFORE including other files (MAKEFILE_LIST changes with includes)
# Get the directory containing this Makefile (.testing/), then go up one level
THIS_MAKEFILE := $(abspath $(lastword $(MAKEFILE_LIST)))
TESTING_DIR := $(dir $(THIS_MAKEFILE))
CI_PROJECT_DIR := $(abspath $(TESTING_DIR)/..)

#---
# Include platform configuration
include $(TESTING_DIR)/platforms.mk

#---
# Derived paths and environment

# Job directory - configurable, defaults to timestamped directory under .testing
JOB_TS := $(shell date +%Y%m%d-%H%M%S)
JOB_DIR ?= $(TESTING_DIR)/job-${JOB_TS}

# Commit to test (defaults to current HEAD)
#CI_COMMIT_SHA ?= $(shell git -C $(CI_PROJECT_DIR) rev-parse HEAD)
CI_COMMIT_SHA ?= a5da88f87e66c4d675f807ed5361e84c6e6ea210

#---
# Main targets

.PHONY: test setup-platform test-platform clean help

# Validate platform configuration
define VALIDATE_PLATFORM
$(if $(PLATFORM_$(1)_REPO_URL),,$(error Platform $(1): PLATFORM_$(1)_REPO_URL not defined))
$(if $(PLATFORM_$(1)_REPO_BRANCH),,$(error Platform $(1): PLATFORM_$(1)_REPO_BRANCH not defined))
endef

# Main test target - iterate through all platforms
test:
	@echo ""
	@echo "=========================================="
	@echo "  MOM6 Multi-Platform Test Suite"
	@echo "=========================================="
	@echo "Testing platforms: $(PLATFORMS)"
	@echo "MOM6 commit: $(CI_COMMIT_SHA)"
	@echo "Job directory: $(JOB_DIR)"
	@echo ""
	@FAILED_PLATFORMS=""; \
	PASSED_PLATFORMS=""; \
	for platform in $(PLATFORMS); do \
		echo ""; \
		echo "=========================================="; \
		echo "  Testing platform: $$platform"; \
		echo "=========================================="; \
		if $(MAKE) test-platform PLATFORM=$$platform; then \
			PASSED_PLATFORMS="$$PASSED_PLATFORMS $$platform"; \
			echo "✓ Platform $$platform: PASSED"; \
		else \
			FAILED_PLATFORMS="$$FAILED_PLATFORMS $$platform"; \
			echo "✗ Platform $$platform: FAILED"; \
		fi; \
	done; \
	echo ""; \
	echo "=========================================="; \
	echo "  Test Summary"; \
	echo "=========================================="; \
	if [ -n "$$PASSED_PLATFORMS" ]; then \
		echo "Passed:$$PASSED_PLATFORMS"; \
	fi; \
	if [ -n "$$FAILED_PLATFORMS" ]; then \
		echo "Failed:$$FAILED_PLATFORMS"; \
		echo ""; \
		echo "Some platforms failed. See output above for details."; \
		exit 1; \
	else \
		echo "All platforms passed!"; \
	fi

# Test a single platform (called by test target)
# Requires: PLATFORM variable set
test-platform: setup-platform
	@if [ -z "$(PLATFORM)" ]; then \
		echo "ERROR: PLATFORM variable not set"; \
		exit 1; \
	fi
	$(eval $(call VALIDATE_PLATFORM,$(PLATFORM)))
	@PLATFORM_REPO_DIR="$(JOB_DIR)/$(PLATFORM)-stats"; \
	echo "Delegating to $$PLATFORM_REPO_DIR/Makefile..."; \
	$(MAKE) -C $$PLATFORM_REPO_DIR -f Makefile.filebased test \
		MOM6_SOURCE=$(CI_PROJECT_DIR) \
		MOM6_COMMIT=$(CI_COMMIT_SHA)

# Setup for a single platform - clone stats repo
# Requires: PLATFORM variable set
setup-platform:
	@if [ -z "$(PLATFORM)" ]; then \
		echo "ERROR: PLATFORM variable not set"; \
		exit 1; \
	fi
	$(eval $(call VALIDATE_PLATFORM,$(PLATFORM)))
	@PLATFORM_REPO_URL="$(PLATFORM_$(PLATFORM)_REPO_URL)"; \
	PLATFORM_REPO_BRANCH="$(PLATFORM_$(PLATFORM)_REPO_BRANCH)"; \
	PLATFORM_REPO_DIR="$(JOB_DIR)/$(PLATFORM)-stats"; \
	echo "Setting up platform: $(PLATFORM)"; \
	echo "  Repo: $$PLATFORM_REPO_URL ($$PLATFORM_REPO_BRANCH)"; \
	echo "  Directory: $$PLATFORM_REPO_DIR"; \
	mkdir -p $(JOB_DIR); \
	if [ ! -d "$$PLATFORM_REPO_DIR/.git" ]; then \
		echo "Cloning $$PLATFORM_REPO_URL..."; \
		git clone $$PLATFORM_REPO_URL $$PLATFORM_REPO_DIR; \
		cd $$PLATFORM_REPO_DIR && git checkout $$PLATFORM_REPO_BRANCH; \
		echo "Platform stats repository cloned successfully"; \
	else \
		echo "Platform stats repo already exists at $$PLATFORM_REPO_DIR"; \
	fi

#---
# Cleanup

clean:
	@echo "Cleaning job directory: $(JOB_DIR)"
	rm -rf $(JOB_DIR)

#---
# Help

help:
	@echo "MOM6 Platform Testing"
	@echo ""
	@echo "This interface delegates testing to platform-specific repositories."
	@echo "Each platform provides a Makefile with a 'test' target that implements"
	@echo "its test suite."
	@echo ""
	@echo "Usage:"
	@echo "  make test                     Test all configured platforms"
	@echo "  make test PLATFORMS=\"p1 p2\"  Test specific platforms"
	@echo "  make clean                    Remove job directory"
	@echo "  make help                     Show this help message"
	@echo ""
	@echo "Configuration:"
	@echo "  Platforms are defined in platforms.mk"
	@echo "  Edit platforms.mk to add/remove/configure platforms"
	@echo ""
	@echo "Current configuration:"
	@echo "  Configured platforms: $(PLATFORMS)"
	@echo "  Job directory:        $(JOB_DIR)"
	@echo "  Commit to test:       $(CI_COMMIT_SHA)"
	@echo ""
	@echo "Adding a new platform:"
	@echo "  1. Edit platforms.mk"
	@echo "  2. Add platform name to PLATFORMS variable"
	@echo "  3. Define PLATFORM_<name>_REPO_URL"
	@echo "  4. Define PLATFORM_<name>_REPO_BRANCH"
	@echo ""
	@echo "Platform requirements:"
	@echo "  Each platform repo must provide a Makefile with a 'test' target"
	@echo "  that accepts MOM6_SOURCE and MOM6_COMMIT variables"
