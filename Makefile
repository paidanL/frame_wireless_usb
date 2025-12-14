
.PHONY: deps check

deps:
	scripts/setup/install-deps.sh

check:
	scripts/setup/check-deps.sh
