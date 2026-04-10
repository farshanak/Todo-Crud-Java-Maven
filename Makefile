.PHONY: test test-unit test-integration test-tia

test:
	./mvnw test -B

test-unit:
	./mvnw test -B -Dtest="com.example.todo.unit.*"

test-integration:
	./mvnw test -B -Dtest="com.example.todo.integration.*Test"

test-tia:
	@if [ "$$CI" = "true" ]; then \
		echo "CI Safety Latch: running ALL tests"; \
		./mvnw test -B; \
	else \
		echo "TIA: running tests for changed packages"; \
		CHANGED=$$(git diff --name-only origin/main...HEAD 2>/dev/null | grep '\.java$$' | grep -v 'src/test' | head -20); \
		if [ -z "$$CHANGED" ]; then \
			echo "No source files changed — no tests to run"; \
			exit 0; \
		fi; \
		echo "Changed files: $$CHANGED"; \
		./mvnw test -B; \
	fi
