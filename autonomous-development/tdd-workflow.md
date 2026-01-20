# Test-Driven Development Workflow

## The TDD Mandate
**TDD is not optional—it is the primary development methodology for this project.**

### Red-Green-Refactor Cycle
1. **Red**: Write failing test first
2. **Green**: Implement minimal code to make test pass
3. **Refactor**: Clean up implementation while keeping tests green
4. **Repeat**: Continue the cycle for each feature

## Detailed Workflow

### Step 1: Write Failing Tests
- **One test, one concept**: Each test should verify a single behavior
- **Test first, design later**: Let tests drive the API design
- **Descriptive naming**: Test names should explain what behavior they verify
- **Meaningful test data**: Use realistic examples, not just trivial cases

### Step 2: Verify Tests Fail
- **Correct failure reason**: Tests should fail for expected reasons
- **Clear error messages**: Failure should indicate what's missing
- **No broken tests**: Ensure existing tests still pass

### Step 3: Implement Minimal Code
- **Smallest possible implementation**: Write just enough to make tests pass
- **No extra features**: Don't add functionality not covered by tests
- **Focus on requirement**: Only implement what the test demands

### Step 4: Refactor While Green
- **Clean up implementation**: Improve code structure without changing behavior
- **Maintain test coverage**: All tests must continue passing
- **Remove duplication**: Extract common patterns to shared utilities

## Test Organization

### Unit Tests
- Test individual components in isolation
- Mock external dependencies
- Fast feedback for development

### Integration Tests
- Test component interactions
- Verify data flow between modules
- Use real implementations, not mocks

### End-to-End Tests
- Test complete workflows
- Verify system behavior as a whole
- Include realistic scenarios

## Test Quality Standards

### Good Tests
```python
# ✅ GOOD: Descriptive, indicates behavior
def test_user_creation_with_default_role():
    """Creating a user assigns the default 'viewer' role"""

def test_permission_check_denies_expired_token():
    """Permission check rejects tokens past their expiry time"""

def test_retry_handler_respects_max_attempts():
    """Retry handler stops after configured max attempts"""
```

### Bad Tests
```python
# ❌ BAD: Vague, doesn't indicate what's being tested
def test_user():
def test_permissions():
def test_retry():
```

## Running Tests

### Development Commands
```bash
# Run full test suite during TDD cycles
make test

# Run tests with verbose output
make test ARGS="--verbose"

# Run specific test categories
make test-unit
make test-integration
```

### Pre-Commit Verification
```bash
# Always run before committing
make test
```

## Common Pitfalls

### Don't
- Write implementation code before tests
- Skip the refactoring step
- Write tests that are too broad or vague
- Ignore failing tests
- Add functionality not covered by tests

### Do
- Follow the cycle religiously
- Write descriptive test names
- Test edge cases and error conditions
- Keep tests fast and focused
- Maintain high test coverage