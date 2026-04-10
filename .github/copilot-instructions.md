# Testing Enforcement Rules — Todo CRUD (Java/Maven/Spring Boot)

## TDD Workflow (Non-Negotiable)
1. Write the test FIRST — see it fail (Red)
2. Write minimal code to pass — see it pass (Green)
3. Refactor — tests still pass (Refactor)

## Testing Pyramid
- Pure Unit Tests: No Spring context, no I/O, plain JUnit 5 assertions
- Integration Tests: @SpringBootTest + @AutoConfigureMockMvc, real H2 database
- Use shared fixtures from com.example.todo.fixtures.TodoFixtures

## Mock Tax Rule
If test file LOC > 2x source file LOC:
- DELETE the unit test
- Write an integration test instead
- Never try to "fix" or "reduce" the unit test

## Pre-commit Hooks
- NEVER use --no-verify to skip hooks
- Wait for hooks to pass before declaring work complete
- Fix failures, do not bypass them
- 11 pre-commit layers are active (file hygiene, secrets, branch naming, compile, tests, SRP, governance)

## Test Location
- Unit tests: `src/test/java/com/example/todo/unit/` (NO Spring context)
- Integration tests: `src/test/java/com/example/todo/integration/` (Spring context + MockMvc)
- Fixtures: `src/test/java/com/example/todo/fixtures/`
- Test naming: `*Test.java` for unit, `*IntegrationTest.java` for integration

## Test Runner
- Command: `./mvnw test -B`
- Coverage: JaCoCo with 80% line/branch threshold
- Unit only: `./mvnw test -B -Dtest="com.example.todo.unit.*"`
- Integration only: `./mvnw test -B -Dtest="com.example.todo.integration.*Test"`

## Before Every Change
1. Check if tests exist for the file being modified
2. If no tests exist, write them FIRST
3. Run `./mvnw test -B` before declaring complete

## Deprecated Patterns (Do NOT Use)
- `javax.persistence` → use `jakarta.persistence`
- `org.junit.Assert` → use `org.junit.jupiter.api.Assertions`
- `org.junit.Test` → use `org.junit.jupiter.api.Test`

## File Size Limits
- Max 600 LOC per file (error)
- Warning at 300 LOC (consider splitting)
- Max 50 LOC per method
