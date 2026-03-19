SHELL_FILES := $(shell find . -name '*.sh' -type f)
STATUSLINE_SCRIPT ?= ./statusline-command.sh

MOCK_JSON := {"model":{"display_name":"Opus 4.6"},"workspace":{"current_dir":"$(CURDIR)"},"context_window":{"used_percentage":42.5,"context_window_size":1000000},"cost":{"total_duration_ms":5400000,"total_cost_usd":1.23}}

.PHONY: lint
lint:
	shellcheck $(SHELL_FILES)

.PHONY: test
test:
	@echo '$(MOCK_JSON)' | bash $(STATUSLINE_SCRIPT)

.PHONY: changelog
changelog:
	node scripts/update-changelog.js $(TAG)
