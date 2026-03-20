#!/bin/bash
set -euo pipefail

REPO_URL="${1:?Usage: setup.sh <repo-url>}"
REPO_NAME="$(basename "$REPO_URL" .git)"
WORKSPACE="/workspace/repos"
REPORTS="/workspace/reports"

mkdir -p "$REPORTS"

echo "=== Cloning $REPO_NAME ==="
if [ ! -d "$WORKSPACE/$REPO_NAME" ]; then
    git clone --depth 1 "$REPO_URL" "$WORKSPACE/$REPO_NAME"
else
    echo "Repository already exists, skipping clone"
fi

cd "$WORKSPACE/$REPO_NAME"

echo "=== cloc analysis ==="
cloc . --quiet --csv --out="$REPORTS/${REPO_NAME}_cloc.csv"
cloc . --quiet
echo ""

echo "=== radon cyclomatic complexity ==="
radon cc . -s -a -j > "$REPORTS/${REPO_NAME}_radon_cc.json"
radon cc . -s -a --total-average | tail -5
echo ""

echo "=== radon maintainability index ==="
radon mi . -j > "$REPORTS/${REPO_NAME}_radon_mi.json"
echo ""

echo "=== lizard complexity ==="
lizard . --csv -o "$REPORTS/${REPO_NAME}_lizard.csv" 2>/dev/null || true
lizard . -w 2>/dev/null | tail -10
echo ""

echo "=== Done! Reports saved to $REPORTS/ ==="
ls -lh "$REPORTS/${REPO_NAME}"_* 2>/dev/null || ls -lh "$REPORTS/"
