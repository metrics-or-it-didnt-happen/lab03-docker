#!/bin/bash
set -euo pipefail

REPO_URL="${1:?Podaj URL repozytorium jako argument}"
REPO_NAME=$(basename "$REPO_URL" .git)
WORKSPACE="/workspace/repos"

echo "=== Klonuję $REPO_NAME ==="
if [ ! -d "$WORKSPACE/$REPO_NAME" ]; then
    git clone "$REPO_URL" "$WORKSPACE/$REPO_NAME"
else
    echo "Repo już istnieje, pomijam klonowanie"
fi

cd "$WORKSPACE/$REPO_NAME"

mkdir -p /workspace/reports

echo "=== Analiza cloc ==="
cloc . --quiet --csv --out="/workspace/reports/${REPO_NAME}_cloc.csv"

echo "=== Analiza radon (złożoność) ==="
radon cc . -s -a -j > "/workspace/reports/${REPO_NAME}_radon_cc.json"

echo "=== Analiza radon (maintainability index) ==="
radon mi . -j > "/workspace/reports/${REPO_NAME}_radon_mi.json"

echo "=== Gotowe! Wyniki w /workspace/reports/ ==="
