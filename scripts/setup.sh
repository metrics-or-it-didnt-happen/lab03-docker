#!/bin/bash
set -euo pipefail

REPO_URL="${1:?Podaj URL repozytorium jako argument}"
REPO_NAME=$(basename "$REPO_URL" .git)

WORKSPACE="/workspace/repos"
REPORTS="/workspace/reports"

mkdir -p "$REPORTS"

echo "=== Klonuję repozytorium: $REPO_NAME ==="

if [ ! -d "$WORKSPACE/$REPO_NAME" ]; then
    git clone "$REPO_URL" "$WORKSPACE/$REPO_NAME"
else
    echo "Repozytorium już istnieje — pomijam klonowanie"
fi

cd "$WORKSPACE/$REPO_NAME"

echo "=== Analiza cloc ==="
cloc . --quiet --csv --out="$REPORTS/${REPO_NAME}_cloc.csv"

echo "=== Analiza radon CC ==="
radon cc . -s -a -j > "$REPORTS/${REPO_NAME}_radon_cc.json"

echo "=== Analiza radon MI ==="
radon mi . -j > "$REPORTS/${REPO_NAME}_radon_mi.json"

echo "=== Generowanie raportu tekstowego ==="

{
    echo "Raport analizy repozytorium: $REPO_NAME"
    echo "Data: $(date)"
    echo ""
    echo "Pliki wynikowe:"
    echo "- ${REPO_NAME}_cloc.csv"
    echo "- ${REPO_NAME}_radon_cc.json"
    echo "- ${REPO_NAME}_radon_mi.json"
} > "$REPORTS/${REPO_NAME}_report.txt"

echo "=== Gotowe! Wyniki zapisane w $REPORTS ==="