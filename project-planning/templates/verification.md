# Executable Verification Reference

Verification commands must be **immediately runnable by an autonomous agent**.

## The Test: Is This Executable?

Ask: Can an agent run this RIGHT NOW with no human involvement?

**Yes (executable)**:
- `npm test src/auth/`
- `curl -s localhost:3000/api/users | jq .`
- `psql $DATABASE_URL -c "SELECT count(*) FROM users"`
- `npx playwright test tests/e2e/login.spec.ts`

**No (not executable)**:
- "Have QA verify the feature"
- "Check that performance is acceptable"
- "Test with 100 concurrent users"
- "Get user feedback"
- "Monitor production logs"

## Verification Structure

Every task should have:

```markdown
## Verification

### Automated
[Commands that run tests]

### Manual Check
[Commands to inspect state/behavior directly]

### Success Criteria
[Specific, observable outcomes]
```

## Patterns by Domain

### Node.js/TypeScript API

```bash
# Unit tests
npm test src/api/users/__tests__/getUser.test.ts

# Integration tests
npm run test:integration -- --grep "GET /users"

# Manual check - happy path
curl -s http://localhost:3000/api/users/123 | jq .
# Expected: { "id": "123", "name": "...", "email": "..." }

# Manual check - error case
curl -s http://localhost:3000/api/users/nonexistent
# Expected: 404 with { "error": "User not found" }

# Manual check - auth required
curl -s http://localhost:3000/api/users/123
# Expected: 401 Unauthorized

curl -s -H "Authorization: Bearer $TOKEN" http://localhost:3000/api/users/123
# Expected: 200 with user data
```

### Database Changes

```bash
# Run migration
npm run migrate:up

# Verify column exists
psql $DATABASE_URL -c "\d users" | grep "api_key"
# Expected: api_key | character varying(64)

# Verify constraint
psql $DATABASE_URL -c "INSERT INTO users (api_key) VALUES (NULL)"
# Expected: ERROR violates not-null constraint

# Test rollback
npm run migrate:down
psql $DATABASE_URL -c "\d users" | grep "api_key"
# Expected: no output (column gone)

# Re-apply
npm run migrate:up
```

### React/UI Components

```bash
# Unit tests
npm test src/components/Modal/__tests__/Modal.test.tsx

# E2E tests
npx playwright test tests/e2e/modal.spec.ts

# Storybook visual check
npm run storybook &
# Open http://localhost:6006
# Navigate to Modal story
# Verify: opens on click, closes on Escape, focus trapped

# Accessibility
npm run a11y-check src/components/Modal/
```

### Salesforce/Apex

```bash
# Deploy to scratch org
sf project deploy start --target-org scratch

# Run Apex tests
sf apex run test --target-org scratch --class-names MyClassTest --result-format human

# Verify object exists
sf sobject describe --sobject-name CustomObject__c --target-org scratch | grep "fields"

# Check trigger fires
sf apex run --target-org scratch --file scripts/test-trigger.apex
# Expected output: [specific log pattern]

# Query verification
sf data query --query "SELECT Id, Status__c FROM CustomObject__c WHERE Name='Test'" --target-org scratch
# Expected: Status__c = 'Active'
```

### Docker/Kubernetes

```bash
# Build image
docker build -t myapp:test .

# Run container
docker run -d --name myapp-test -p 3000:3000 myapp:test

# Health check
curl -s http://localhost:3000/health | jq .status
# Expected: "healthy"

# Check logs for startup
docker logs myapp-test 2>&1 | grep "Server listening"
# Expected: Server listening on port 3000

# Cleanup
docker stop myapp-test && docker rm myapp-test
```

```bash
# Kubernetes deployment
kubectl apply -f k8s/deployment.yaml --dry-run=client
# Expected: deployment.apps/myapp configured (dry run)

# Verify manifest syntax
kubectl apply -f k8s/ --dry-run=server
# Expected: no errors

# Check rollout (if deployed)
kubectl rollout status deployment/myapp --timeout=60s
# Expected: deployment "myapp" successfully rolled out
```

### CLI Tools

```bash
# Test help output
./mycli --help
# Expected: Usage: mycli [options] <command>

# Test basic command
./mycli process --input test.txt --output out.txt
echo $?
# Expected: 0

# Verify output
cat out.txt | head -5
# Expected: [specific content]

# Test error handling
./mycli process --input nonexistent.txt 2>&1
# Expected: Error: File not found: nonexistent.txt
```

### Background Jobs/Workers

```bash
# Unit tests
npm test src/workers/email/__tests__/

# Enqueue test job
npm run job:enqueue email-worker -- --test --data '{"to":"test@example.com"}'
# Expected: Job enqueued: job-123

# Process queue
npm run worker:process -- --once
# Expected: Processed job-123

# Verify side effect
grep "Sent email to test@example.com" /var/log/worker.log
# Expected: log entry exists
```

### Configuration Changes

```bash
# Validate config syntax
npm run config:validate -- config/production.json
# Expected: Configuration valid

# Test config loading
CONFIG_PATH=config/test.json npm run start:dry
# Expected: Loaded configuration from config/test.json

# Verify feature flag
curl -s http://localhost:3000/api/config | jq '.features.newDashboard'
# Expected: true
```

## Verification for Different Task Types

### New Feature
1. Unit tests for new code
2. Integration tests for interactions
3. Manual API/UI check
4. Boundary/edge case tests

### Bug Fix
1. Regression test that would have caught the bug
2. Manual reproduction attempt (should fail now)
3. Related area tests still pass

### Refactor
1. All existing tests still pass
2. No behavior change in manual checks
3. Performance not degraded (if applicable)

### Security Fix
1. Attack scenario test (should be blocked)
2. Normal flow still works
3. Security scan passes

### Performance Improvement
1. Benchmark before/after
2. Load test (reasonable scale)
3. No functional regression

## Anti-Patterns

**Vague criteria**:
```
# BAD
Verify the feature works correctly.

# GOOD
curl -s localhost:3000/api/users/123 | jq -e '.id == "123"'
```

**External dependencies**:
```
# BAD
Check production metrics dashboard.

# GOOD
npm run test:performance -- --threshold=100ms
```

**Human required**:
```
# BAD
Have QA team verify the UI.

# GOOD
npx playwright test tests/e2e/ui-flow.spec.ts
```

**Future conditions**:
```
# BAD
Monitor for errors over the next week.

# GOOD
npm run test:integration && npm run test:e2e
```

**Unrealistic scale**:
```
# BAD
Load test with 1000 concurrent users.

# GOOD (for pre-release)
npm run test:load -- --users=10 --duration=30s
```
