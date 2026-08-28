
# brew install tj-actions/tap/auto-doc
update-docs:
	auto-doc -f action.yml

# Unit tests. Requires bats: brew install bats-core
test:
	bats tests/

# Integration tests against the real pinned autotag binary. Linux only;
# on macOS run: docker run --rm -v "$$PWD":/w -w /w ubuntu:24.04 tests/integration.sh
test-integration:
	tests/integration.sh

.PHONY: update-docs test test-integration
