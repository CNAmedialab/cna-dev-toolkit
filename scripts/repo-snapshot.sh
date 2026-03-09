#!/bin/bash
# repo-snapshot.sh - Generate repo structure snapshot and embed in CLAUDE.md
# Usage: bash scripts/repo-snapshot.sh [path-to-repo]
#
# Updates the <!-- SNAPSHOT:START --> ... <!-- SNAPSHOT:END --> block in CLAUDE.md

set -e

REPO_DIR="${1:-.}"
CLAUDE_MD="$REPO_DIR/CLAUDE.md"

# Validate CLAUDE.md exists and has markers
if [[ ! -f "$CLAUDE_MD" ]]; then
    echo "Error: $CLAUDE_MD not found" >&2
    exit 1
fi

if ! grep -q '<!-- SNAPSHOT:START -->' "$CLAUDE_MD"; then
    echo "Error: SNAPSHOT markers not found in $CLAUDE_MD" >&2
    exit 1
fi

# Build snapshot content into a temp file
SNAP_CONTENT=$(mktemp)

echo "## Repo Snapshot" >> "$SNAP_CONTENT"
echo '```' >> "$SNAP_CONTENT"

# 1. Directory tree
if command -v tree &> /dev/null; then
    (cd "$REPO_DIR" && tree -I 'node_modules|.git|__pycache__|.venv|venv|dist|build|coverage|.next|.nuxt|.cache|.parcel-cache|.DS_Store' --dirsfirst -a --noreport 2>/dev/null || echo "(tree output unavailable)") >> "$SNAP_CONTENT"
else
    (cd "$REPO_DIR" && find . -not -path './.git/*' -not -path '*/node_modules/*' -not -path '*/__pycache__/*' -not -path '*/.venv/*' -not -name '.DS_Store' | sort | head -50) >> "$SNAP_CONTENT"
fi

echo '```' >> "$SNAP_CONTENT"

# 2. package.json summary (if exists)
PKG="$REPO_DIR/package.json"
if [[ -f "$PKG" ]]; then
    echo "" >> "$SNAP_CONTENT"
    echo "### package.json" >> "$SNAP_CONTENT"

    PKG_NAME=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$PKG" | head -1 | sed 's/"name"[[:space:]]*:[[:space:]]*//;s/"//g')
    PKG_VERSION=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$PKG" | head -1 | sed 's/"version"[[:space:]]*:[[:space:]]*//;s/"//g')
    echo "- **name**: $PKG_NAME" >> "$SNAP_CONTENT"
    echo "- **version**: $PKG_VERSION" >> "$SNAP_CONTENT"

    if command -v node &> /dev/null; then
        PKG_SCRIPTS=$(node -e "try{const p=require('$PKG');console.log(Object.keys(p.scripts||{}).join(', '))}catch(e){}" 2>/dev/null)
        if [[ -n "$PKG_SCRIPTS" ]]; then
            echo "- **scripts**: $PKG_SCRIPTS" >> "$SNAP_CONTENT"
        fi

        node -e "
            try {
                const p = require('$PKG');
                const d = Object.keys(p.dependencies || {});
                const dd = Object.keys(p.devDependencies || {});
                if (d.length) console.log('- **deps**: ' + d.join(', '));
                if (dd.length) console.log('- **devDeps**: ' + dd.join(', '));
            } catch(e) {}
        " 2>/dev/null >> "$SNAP_CONTENT"
    fi
fi

# 3. OpenSpec specs (if available)
if [[ -d "$REPO_DIR/openspec/specs" ]] && command -v openspec &> /dev/null; then
    SPECS_OUTPUT=$(cd "$REPO_DIR" && openspec list --specs 2>/dev/null || true)
    if [[ -n "$SPECS_OUTPUT" ]]; then
        echo "" >> "$SNAP_CONTENT"
        echo "### OpenSpec Capabilities" >> "$SNAP_CONTENT"
        echo '```' >> "$SNAP_CONTENT"
        echo "$SPECS_OUTPUT" >> "$SNAP_CONTENT"
        echo '```' >> "$SNAP_CONTENT"
    fi
fi

# 4. Replace SNAPSHOT block in CLAUDE.md
# Strategy: write lines before START, insert marker + content + end marker, skip old content, write lines after END
TMPFILE=$(mktemp)
{
    # Print everything up to and including SNAPSHOT:START
    sed -n '1,/<!-- SNAPSHOT:START -->/p' "$CLAUDE_MD"
    # Print new snapshot content
    cat "$SNAP_CONTENT"
    # Print SNAPSHOT:END and everything after
    sed -n '/<!-- SNAPSHOT:END -->/,$p' "$CLAUDE_MD"
} > "$TMPFILE"

mv "$TMPFILE" "$CLAUDE_MD"
rm -f "$SNAP_CONTENT"
echo "Snapshot updated in $CLAUDE_MD"
