#!/bin/bash
# autonomous-dev-loop.sh
# Runs Claude autonomous development in a loop until all tasks complete or require human input

set -euo pipefail

LOG_FILE="autonomous-dev-$(date +%Y%m%d-%H%M%S).log"
ITERATION=0

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓${NC} $*" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗${NC} $*" | tee -a "$LOG_FILE"
}

# Check if there's work to do and determine which skill to invoke
# Returns:
#   0 = regular tasks available (use autonomous-development)
#   1 = no work at all (exit loop)
#   2 = only human tasks (stop and notify)
#   3 = blocked tasks need review (run dependency checker)
#   4 = investigation tasks available (use investigate-blocker)
check_ready_work() {
    local ready_output
    ready_output=$(tk ready 2>/dev/null || echo "")

    # Check if no ready work
    if [ -z "$ready_output" ]; then
        # No ready work - check if there are blocked tasks that might need attention
        local blocked_count
        blocked_count=$(tk blocked 2>/dev/null | wc -l)
        if [ "$blocked_count" -gt 0 ]; then
            return 3 # No ready work, but blocked tasks exist
        fi
        return 1 # No work at all
    fi

    # Priority 1: Check if ANY HUMAN-TASK exists (grep the title column)
    local human_count
    human_count=$(echo "$ready_output" | grep -c "HUMAN-TASK:") || true
    if [ "$human_count" -gt 0 ]; then
        return 2 # Human tasks require stopping
    fi

    # Priority 2: Check for REQUIRES-INVESTIGATION tasks
    local investigation_count
    investigation_count=$(echo "$ready_output" | grep -c "REQUIRES-INVESTIGATION:") || true
    if [ "$investigation_count" -gt 0 ]; then
        return 4 # Investigation tasks available
    fi

    # Priority 3: Regular tasks available
    return 0 # Work available for autonomous-development
}

# Send notification
send_notification() {
    local message="$1"
    local priority="${2:-4}"  # Default priority 4 (high)
    log_warning "NOTIFICATION: $message"

    # Determine appropriate emoji tag based on message content
    local tags="computer"
    if [[ "$message" =~ "error" ]] || [[ "$message" =~ "Error" ]] || [[ "$message" =~ "fatal" ]]; then
        tags="computer,fire"
        priority=5  # Max priority for errors
    elif [[ "$message" =~ "input" ]] || [[ "$message" =~ "review" ]]; then
        tags="computer,warning"
    elif [[ "$message" =~ "complete" ]] || [[ "$message" =~ "finished" ]]; then
        tags="computer,white_check_mark"
        priority=3  # Normal priority for success
    fi

    # ntfy.sh notification (works on mobile/remote)
    # Set NTFY_TOPIC env var to configure, or defaults to "$USER-<dirname>"
    # Note: ntfy.sh topics are public by default. Use a unique/random topic for privacy,
    # or self-host ntfy for authenticated topics. See https://ntfy.sh
    local ntfy_topic="${NTFY_TOPIC:-${USER}-$(basename "$(pwd)")}"
    curl -s \
         -H "Title: Autonomous Dev" \
         -H "Priority: ${priority}" \
         -H "Tags: ${tags}" \
         -d "${message}" \
         https://ntfy.sh/${ntfy_topic} 2>/dev/null || true

    # macOS notification with sound (local desktop)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e "display notification \"$message\" with title \"Autonomous Dev\" sound name \"Submarine\"" 2>/dev/null

        # Alternative: Use terminal-notifier for better control (install with: brew install terminal-notifier)
        # This allows clicking the notification to activate Terminal/VS Code:
        # terminal-notifier -message "$message" -title "Autonomous Dev" -sound Submarine -activate com.apple.Terminal
        # Or for iTerm2:
        # terminal-notifier -message "$message" -title "Autonomous Dev" -sound Submarine -activate com.googlecode.iterm2
    fi

    # Optional: Slack webhook (set SLACK_WEBHOOK_URL environment variable)
    if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
        curl -s -X POST -H 'Content-type: application/json' \
          --data "{\"text\":\"$message\"}" \
          "$SLACK_WEBHOOK_URL" 2>/dev/null || true
    fi

    # Optional: Email (set EMAIL_ADDRESS environment variable, requires mailutils)
    if [ -n "${EMAIL_ADDRESS:-}" ]; then
        echo "$message" | mail -s "Autonomous Dev Alert" "$EMAIL_ADDRESS" 2>/dev/null || true
    fi
}

# Main loop
log "Starting autonomous development loop"
log "Log file: $LOG_FILE"

while true; do
    ((++ITERATION))
    log "=== Iteration $ITERATION ==="

    # Check if there's work to do
    # Note: Must capture exit code without triggering set -e on non-zero return
    check_ready_work && CHECK_RESULT=0 || CHECK_RESULT=$?

    if [ $CHECK_RESULT -eq 1 ]; then
        log_success "All tasks complete! 🎉"
        break
    elif [ $CHECK_RESULT -eq 2 ]; then
        log_warning "HUMAN-TASK detected - stopping immediately"
        send_notification "🚨 Autonomous development stopped - HUMAN-TASK requires manual intervention"

        # Show which tasks need human input
        tk ready | grep "HUMAN-TASK:" | tee -a "$LOG_FILE" || true
        break
    elif [ $CHECK_RESULT -eq 3 ]; then
        log_warning "No ready work, but blocked tasks exist - reviewing dependencies"

        # Have Claude review blocked tasks and fix dependency issues
        BLOCKED_COUNT=$(tk blocked 2>/dev/null | wc -l)
        log "Found $BLOCKED_COUNT blocked tasks - spawning reviewer to check dependencies"

        REVIEW_OUTPUT=$(claude --dangerously-skip-permissions --model=haiku -p "Review blocked tickets and fix dependency issues.

For each ticket shown by 'tk blocked':
1. Run 'tk show <id>' to see its dependencies
2. Check if ALL dependencies are actually done (not open)
3. If all deps are done, run: tk status <id> open
4. If the issue has notes suggesting investigation is needed but no subtask exists:
   - Consider creating a focused subtask for that investigation
   - Link it as a dependency with 'tk dep <blocked-id> <new-task-id>'

The tickets system automatically considers any issue with undone dependencies as blocked. Issues should be 'open' and their blocked state determined by their dependency links.

After reviewing all blocked tasks, report:
- How many were updated to 'open' (had no actual open blockers)
- How many still have legitimate open dependencies
- Any new tasks created for investigations

Be concise. Just fix what needs fixing and summarize." 2>&1) || {
            log_warning "Blocked task review failed, will retry next iteration"
            sleep 5
            continue
        }

        echo "$REVIEW_OUTPUT" >> "$LOG_FILE"
        log "Blocked task review complete - rechecking for ready work"
        sleep 2
        continue
    elif [ $CHECK_RESULT -eq 4 ]; then
        # REQUIRES-INVESTIGATION tasks available - use investigate-blocker skill
        log "REQUIRES-INVESTIGATION tasks detected - using investigate-blocker skill"
        OUTPUT=$(claude --dangerously-skip-permissions --model=opus -p "Use investigate-blocker skill" 2>&1) || {
            log_error "investigate-blocker skill failed with exit code $?"
            echo "$OUTPUT" | tee -a "$LOG_FILE"
            send_notification "🔥 Investigation skill error - loop continuing"
            sleep 5
            continue
        }
    else
        # Regular tasks available - use autonomous-development skill
        log "Running: claude -p \"Use autonomous-development skill\""
        OUTPUT=$(claude --dangerously-skip-permissions --model=opus -p "Run your autonomous-development skill. Ensure you always task separate verification subagents immediately following the completion of an implementation subagent task." 2>&1) || {
            log_error "Claude command failed with exit code $?"
            echo "$OUTPUT" | tee -a "$LOG_FILE"
            send_notification "🔥 Autonomous development error - claude command failed"
            exit 1
        }
    fi

    # Log full output
    echo "$OUTPUT" >> "$LOG_FILE"

    # Parse exit status from output
    if echo "$OUTPUT" | grep -q "EXIT_STATUS: COMPLETED"; then
        log_success "Task completed successfully"

        # Extract task ID from output if possible
        TASK_ID=$(echo "$OUTPUT" | sed -n 's/.*\*\*ID:\*\* \([^ ]*\).*/\1/p' | head -1)
        TASK_ID="${TASK_ID:-unknown}"
        log "  Completed: $TASK_ID"

        sleep 2
        continue

    elif echo "$OUTPUT" | grep -q "EXIT_STATUS: BLOCKED_HUMAN_INPUT"; then
        log_warning "Human input required"

        # Extract created task info
        CREATED_TASKS=$(echo "$OUTPUT" | sed -n '/## Created Tasks/,/## Blocking Issues/p' | grep -v "^#")
        if [ -n "$CREATED_TASKS" ]; then
            log "Created tasks requiring human input:"
            echo "$CREATED_TASKS" | tee -a "$LOG_FILE"
        fi

        send_notification "⏸️  Autonomous development needs human input - check created P0 tasks"

        # Continue loop - other tasks might be ready
        sleep 5
        continue

    elif echo "$OUTPUT" | grep -q "EXIT_STATUS: BLOCKED_SUBTASKS"; then
        log "Task broken down into subtasks"

        # Extract subtask info
        CREATED_TASKS=$(echo "$OUTPUT" | sed -n '/## Created Tasks/,/## Blocking Issues/p' | grep -v "^#")
        if [ -n "$CREATED_TASKS" ]; then
            log "Created subtasks:"
            echo "$CREATED_TASKS" | tee -a "$LOG_FILE"
        fi

        sleep 2
        continue

    elif echo "$OUTPUT" | grep -q "EXIT_STATUS: ERROR"; then
        log_error "Fatal error encountered"

        # Extract error info
        ERROR_INFO=$(echo "$OUTPUT" | sed -n '/## Blocking Issues/,/## Next Action/p' | grep -v "^#")
        if [ -n "$ERROR_INFO" ]; then
            log_error "Error details:"
            echo "$ERROR_INFO" | tee -a "$LOG_FILE"
        fi

        send_notification "🔥 Autonomous development fatal error - loop stopped"
        exit 1

    else
        log_warning "Unable to parse exit status from output"
        log "Last 20 lines of output:"
        echo "$OUTPUT" | tail -20 | tee -a "$LOG_FILE"

        # # Might be an incomplete run or unexpected format
        # # Be cautious and exit
        # log_error "Stopping loop due to unexpected output format"
        # send_notification "⚠️  Autonomous development stopped - unexpected output format"
        # exit 1

        # dev loop skill should be able to recover from failures. continue and let next iteration figure it out
        sleep 10
        continue
    fi
done

# Final summary
log "=== Loop complete after $ITERATION iterations ==="
log "Check log file for details: $LOG_FILE"

# Show final task status
log ""
log "Final task status:"
tk ready 2>/dev/null || log_warning "Unable to get task status"

log_success "Autonomous development loop finished"
