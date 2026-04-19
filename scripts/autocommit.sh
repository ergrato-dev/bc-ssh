#!/bin/bash
# ====================================
# 🔐 Bootcamp SSH - Autocommit Script
# ====================================
# Runs every 5 minutes via cron
# Conventional Commits + English
# Format: <type>: <what> | <for> | <impact>
# ====================================

# Configuration
REPO_DIR="/home/epti/Documents/epti-dev/bc-channel/bc-ssh"
LOG_FILE="${REPO_DIR}/scripts/autocommit.log"
BRANCH="main"

# Colors for terminal output (disabled in cron)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" >> "$LOG_FILE"
    echo -e "${timestamp} [${level}] ${message}"
}

# Navigate to repository
cd "$REPO_DIR" || {
    log "ERROR" "Cannot access repository: $REPO_DIR"
    exit 1
}

# Check if it's a git repository
if [ ! -d ".git" ]; then
    log "ERROR" "Not a git repository: $REPO_DIR"
    exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
if [ -z "$CURRENT_BRANCH" ]; then
    log "ERROR" "Cannot determine current branch"
    exit 1
fi

# Check for changes
if git diff --quiet && git diff --cached --quiet; then
    log "INFO" "No changes to commit"
    exit 0
fi

# Stage all changes
git add -A

# Analyze changes for commit message
CHANGED_FILES=$(git diff --cached --name-only)
ADDED_COUNT=$(git diff --cached --name-status | grep -c "^A")
MODIFIED_COUNT=$(git diff --cached --name-status | grep -c "^M")
DELETED_COUNT=$(git diff --cached --name-status | grep -c "^D")

# Determine commit type based on changes
determine_type() {
    local files="$1"
    
    # Check for specific patterns
    if echo "$files" | grep -qE "^docs/|README\.md|\.md$"; then
        echo "docs"
        return
    fi
    
    if echo "$files" | grep -qE "^week-[0-9]+-[a-z_]+/1-teoria/"; then
        echo "docs"
        return
    fi
    
    if echo "$files" | grep -qE "^week-[0-9]+-[a-z_]+/2-practicas/"; then
        echo "feat"
        return
    fi
    
    if echo "$files" | grep -qE "^week-[0-9]+-[a-z_]+/3-proyecto/"; then
        echo "feat"
        return
    fi
    
    if echo "$files" | grep -qE "^week-[0-9]+-[a-z_]+/4-recursos/"; then
        echo "docs"
        return
    fi
    
    if echo "$files" | grep -qE "^week-[0-9]+-[a-z_]+/5-glosario/"; then
        echo "docs"
        return
    fi
    
    if echo "$files" | grep -qE "^week-[0-9]+-[a-z_]+/0-assets/"; then
        echo "style"
        return
    fi
    
    if echo "$files" | grep -qE "^scripts/|\.sh$"; then
        echo "chore"
        return
    fi
    
    if echo "$files" | grep -qE "\.gitignore|\.github/"; then
        echo "chore"
        return
    fi
    
    if echo "$files" | grep -qE "RUBRICA|evaluacion"; then
        echo "docs"
        return
    fi
    
    # Default based on operation counts
    if [ "$ADDED_COUNT" -gt "$MODIFIED_COUNT" ]; then
        echo "feat"
    elif [ "$DELETED_COUNT" -gt 0 ]; then
        echo "refactor"
    else
        echo "chore"
    fi
}

# Determine what was changed
determine_what() {
    local files="$1"
    
    # Check for week-specific changes
    local week=$(echo "$files" | grep -oE "week-[0-9]+-[a-z_]+" | head -1)
    if [ -n "$week" ]; then
        local week_num=$(echo "$week" | grep -oE "[0-9]+" | head -1)
        
        if echo "$files" | grep -qE "1-teoria/"; then
            echo "week ${week_num} theory modules"
            return
        fi
        
        if echo "$files" | grep -qE "2-practicas/"; then
            echo "week ${week_num} practice exercises"
            return
        fi
        
        if echo "$files" | grep -qE "3-proyecto/"; then
            echo "week ${week_num} integrative project"
            return
        fi
        
        if echo "$files" | grep -qE "4-recursos/"; then
            echo "week ${week_num} learning resources"
            return
        fi
        
        if echo "$files" | grep -qE "5-glosario/"; then
            echo "week ${week_num} glossary terms"
            return
        fi
        
        if echo "$files" | grep -qE "0-assets/"; then
            echo "week ${week_num} visual assets"
            return
        fi
        
        echo "week ${week_num} content"
        return
    fi
    
    # Check for specific file types
    if echo "$files" | grep -qE "^docs/"; then
        echo "bootcamp documentation"
        return
    fi
    
    if echo "$files" | grep -qE "^scripts/"; then
        echo "automation scripts"
        return
    fi
    
    if echo "$files" | grep -qE "copilot-instructions"; then
        echo "copilot configuration"
        return
    fi
    
    if echo "$files" | grep -qE "\.gitignore"; then
        echo "git configuration"
        return
    fi
    
    if echo "$files" | grep -qE "README\.md"; then
        echo "project readme"
        return
    fi
    
    # Default description
    local file_count=$(echo "$files" | wc -l)
    echo "${file_count} files"
}

# Determine purpose (for what)
determine_for() {
    local files="$1"
    local type="$2"
    
    case "$type" in
        "docs")
            if echo "$files" | grep -qE "teoria|theory"; then
                echo "SSH concept learning"
            elif echo "$files" | grep -qE "recursos|resources"; then
                echo "student reference material"
            elif echo "$files" | grep -qE "glosario|glossary"; then
                echo "technical terminology"
            else
                echo "bootcamp documentation"
            fi
            ;;
        "feat")
            if echo "$files" | grep -qE "practicas|practice"; then
                echo "hands-on skill development"
            elif echo "$files" | grep -qE "proyecto|project"; then
                echo "real-world application"
            else
                echo "bootcamp curriculum"
            fi
            ;;
        "style")
            echo "visual learning support"
            ;;
        "chore")
            echo "project maintenance"
            ;;
        "refactor")
            echo "content organization"
            ;;
        *)
            echo "bootcamp improvement"
            ;;
    esac
}

# Determine impact
determine_impact() {
    local added="$1"
    local modified="$2"
    local deleted="$3"
    
    local total=$((added + modified + deleted))
    
    if [ "$total" -eq 1 ]; then
        echo "minor update"
    elif [ "$total" -le 5 ]; then
        echo "incremental progress"
    elif [ "$total" -le 15 ]; then
        echo "significant content addition"
    else
        echo "major content milestone"
    fi
}

# Generate commit message
TYPE=$(determine_type "$CHANGED_FILES")
WHAT=$(determine_what "$CHANGED_FILES")
FOR=$(determine_for "$CHANGED_FILES" "$TYPE")
IMPACT=$(determine_impact "$ADDED_COUNT" "$MODIFIED_COUNT" "$DELETED_COUNT")

# Build commit message
# Format: <type>: <what> | <for> | <impact>
COMMIT_MSG="${TYPE}: ${WHAT} | ${FOR} | ${IMPACT}"

# Add file stats to commit body
COMMIT_BODY="Files: +${ADDED_COUNT} ~${MODIFIED_COUNT} -${DELETED_COUNT}
Timestamp: $(date '+%Y-%m-%d %H:%M:%S')
Auto-commit by autocommit.sh"

# Perform commit
git commit -m "$COMMIT_MSG" -m "$COMMIT_BODY"

if [ $? -eq 0 ]; then
    log "SUCCESS" "Committed: $COMMIT_MSG"
    log "INFO" "Stats: +${ADDED_COUNT} added, ~${MODIFIED_COUNT} modified, -${DELETED_COUNT} deleted"
else
    log "ERROR" "Commit failed"
    exit 1
fi

# Optional: Auto-push (uncomment if desired)
# git push origin "$CURRENT_BRANCH"
# if [ $? -eq 0 ]; then
#     log "SUCCESS" "Pushed to origin/$CURRENT_BRANCH"
# else
#     log "ERROR" "Push failed"
# fi

exit 0
