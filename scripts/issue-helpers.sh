#!/bin/bash
# Issue Helper Functions
# Source this file to get convenient functions: source scripts/issue-helpers.sh

# Default repo (central hub)
REPO="${GITHUB_REPO:-u0401006/main-brain}"

# Repository labels mapping
declare -A REPO_LABELS=(
  ["main-brain"]="repo:main-brain"
  ["video-quotes"]="repo:video-quotes"
  ["ctb"]="repo:ctb"
  ["personal-site"]="repo:personal-site"
  ["news-editor-agent"]="repo:news-editor-agent"
)

# Quick bug issue
ghib() {
  local title="$1"
  local body="${2:-}"
  local target_repo="${3:-main-brain}"  # 預設 main-brain

  if [ -z "$title" ]; then
    echo "Usage: ghib \"Title\" [\"Body\"] [target_repo]"
    echo "Example: ghib \"Script error\" \"Error message\" \"video-quotes\""
    return 1
  fi

  local repo_label="${REPO_LABELS[$target_repo]:-repo:main-brain}"

  gh issue create \
    --repo "$REPO" \
    --title "[bug] $title" \
    --body "$body" \
    --label "bug,priority: high,$repo_label"
}

# Quick feature issue
ghif() {
  local title="$1"
  local body="${2:-}"
  local target_repo="${3:-main-brain}"

  if [ -z "$title" ]; then
    echo "Usage: ghif \"Title\" [\"Body\"] [target_repo]"
    return 1
  fi

  local repo_label="${REPO_LABELS[$target_repo]:-repo:main-brain}"

  gh issue create \
    --repo "$REPO" \
    --title "[feat] $title" \
    --body "$body" \
    --label "feature-request,priority: medium,$repo_label"
}

# Quick video issue
ghiv() {
  local url="$1"
  local note="${2:-}"

  if [ -z "$url" ]; then
    echo "Usage: ghiv \"https://youtu.be/...\" [\"Special instructions\"]"
    return 1
  fi

  local body="$url"
  if [ -n "$note" ]; then
    body="$body\n\n$note"
  fi

  # Video issues always go to video-quotes repo
  gh issue create \
    --repo "$REPO" \
    --title "[video] $(date +'%Y-%m-%d') video processing request" \
    --body "$body" \
    --label "video-processing,priority: medium,repo:video-quotes"
}

# Quick docs issue
ghid() {
  local title="$1"
  local body="${2:-}"
  local target_repo="${3:-main-brain}"

  if [ -z "$title" ]; then
    echo "Usage: ghid \"Title\" [\"Body\"] [target_repo]"
    return 1
  fi

  local repo_label="${REPO_LABELS[$target_repo]:-repo:main-brain}"

  gh issue create \
    --repo "$REPO" \
    --title "[docs] $title" \
    --body "$body" \
    --label "documentation,priority: low,$repo_label"
}

# List open issues with filters
ghil() {
  local filter="${1:-}"

  if [ -n "$filter" ]; then
    gh issue list --repo "$REPO" --label "$filter" --state open
  else
    gh issue list --repo "$REPO" --state open
  fi
}

# List issues by target repo
ghil_repo() {
  local target_repo="${1:-main-brain}"

  local repo_label="${REPO_LABELS[$target_repo]}"
  if [ -z "$repo_label" ]; then
    echo "Unknown repo: $target_repo"
    echo "Available: ${!REPO_LABELS[@]}"
    return 1
  fi

  echo "Issues for: $target_repo"
  gh issue list --repo "$REPO" --label "$repo_label" --state open
}

# View issue details
ghiv_detail() {
  local issue_num="$1"

  if [ -z "$issue_num" ]; then
    echo "Usage: ghiv_detail <issue_number>"
    return 1
  fi

  gh issue view "$issue_num" --repo "$REPO"
}

# Claim an issue (add yourself as assignee)
ghiclaim() {
  local issue_num="$1"
  local assignee="${2:-$(gh api user --jq .login)}"

  if [ -z "$issue_num" ]; then
    echo "Usage: ghiclaim <issue_number> [assignee]"
    return 1
  fi

  gh issue edit "$issue_num" --repo "$REPO" --add-assignee "$assignee"
  gh issue comment "$issue_num" --repo "$REPO" --body "I'll handle this."

  echo "✅ Claimed issue #$issue_num"
}

# Close issue with comment
ghiclose() {
  local issue_num="$1"
  local reason="${2:-Completed}"

  if [ -z "$issue_num" ]; then
    echo "Usage: ghiclose <issue_number> [reason]"
    return 1
  fi

  gh issue comment "$issue_num" --repo "$REPO" --body "✅ $reason"
  gh issue close "$issue_num" --repo "$REPO"

  echo "✅ Closed issue #$issue_num"
}

# Show issue statistics
ghistats() {
  echo "Repository: $REPO"
  echo ""
  echo "Open Issues by Label:"
  gh issue list --repo "$REPO" --state open --json labels \
    --jq '.[] | .labels[].name' | sort | uniq -c | sort -rn

  echo ""
  echo "Open Issues by Priority:"
  gh issue list --repo "$REPO" --state open --json labels \
    --jq '.[] | .labels[] | select(.name | startswith("priority:")) | .name' \
    | sort | uniq -c | sort -rn

  echo ""
  echo "Total Open: $(gh issue list --repo "$REPO" --state open --json number --jq '. | length')"
  echo "Total Closed: $(gh issue list --repo "$REPO" --state closed --limit 1000 --json number --jq '. | length')"
}

# Print usage
ghi_help() {
  cat << 'EOF'
GitHub Issue Helper Functions

Quick Create:
  ghib "Title" ["Body"] [repo]       - Create bug issue (high priority)
  ghif "Title" ["Body"] [repo]       - Create feature issue (medium priority)
  ghiv "URL" ["Notes"]               - Create video processing issue
  ghid "Title" ["Body"] [repo]       - Create docs issue (low priority)

Manage:
  ghil [label]                       - List open issues (filter by label)
  ghil_repo <repo>                   - List issues for specific repo
  ghiv_detail <num>                  - View issue details
  ghiclaim <num> [assignee]          - Claim an issue
  ghiclose <num> [reason]            - Close issue with comment
  ghistats                           - Show issue statistics

Examples:
  # Create issues for different repos
  ghib "Script fails on macOS" "Error msg" "main-brain"
  ghif "Add dark mode" "Use case..." "personal-site"
  ghiv "https://youtu.be/abc123" "Focus on AI"
  ghid "Add API docs" "Missing docs" "ctb"

  # List issues
  ghil "bug"                         - List all bugs
  ghil "priority: high"              - List high priority
  ghil_repo "video-quotes"           - List video-quotes issues
  ghil_repo "ctb"                    - List ctb issues

  # Manage
  ghiclaim 123                       - Claim issue #123
  ghiclose 123 "Fixed in PR #124"

Available repos: main-brain, video-quotes, ctb, personal-site
EOF
}

# Auto-load message
echo "✅ GitHub Issue helpers loaded. Type 'ghi_help' for usage."
