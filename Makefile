SHELL_FILES := $(shell find . -name '*.sh' -type f)

.PHONY: lint
lint:
	shellcheck $(SHELL_FILES)
