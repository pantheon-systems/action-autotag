
# brew install tj-actions/tap/auto-doc
update-docs:
	auto-doc -f action.yml

.PHONY: update-docs