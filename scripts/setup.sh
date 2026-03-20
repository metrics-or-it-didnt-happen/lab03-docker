#!/bin/bash
set -euo pipefail

REPO_URL="${1:?Podaj URL repozytorium jako argument}"
REPO_NAME=$(basename "$REPO_URL" .git)

WORKSPACE="/workspace"
REPOS_DIR="$WORKSPACE/repos"
REPORTS_DIR="$WORKSPACE/reports"

echo "=== Setup środowiska ==="

# Tworzenie katalogów
mkdir -p "$REPOS_DIR"
mkdir -p "$REPORTS_DIR"

# Sprawdzenie zależności
echo "=== Sprawdzam zależności ==="

if ! command -v git &> /dev/null; then
    echo "Brak git — instaluję..."
    apt-get update && apt-get install -y git
fi

if ! command -v cloc &> /dev/null; then
    echo "Brak cloc — instaluję..."
    apt-get update && apt-get install -y cloc
fi

if ! command -v radon &> /dev/null; then
    echo "Brak radon — instaluję..."
    pip install radon
fi

echo "=== Klonuję repozytorium ==="

if [ ! -d "$REPOS_DIR/$REPO_NAME" ]; then
    git clone "$REPO_URL" "$REPOS_DIR/$REPO_NAME"
else
    echo "Repo już istnieje, pomijam klonowanie"
fi

cd "$REPOS_DIR/$REPO_NAME"

echo "=== Analiza cloc ==="
cloc . --quiet --csv --out="$REPORTS_DIR/${REPO_NAME}_cloc.csv"

echo "=== Analiza radon (CC) ==="
radon cc . -s -a -j > "$REPORTS_DIR/${REPO_NAME}_radon_cc.json"

echo "=== Analiza radon (MI) ==="
radon mi . -j > "$REPORTS_DIR/${REPO_NAME}_radon_mi.json"

echo "=== Generowanie raportu ==="

REPORT_FILE="$REPORTS_DIR/${REPO_NAME}_report.txt"

echo "Raport analizy repozytorium: $REPO_NAME" > "$REPORT_FILE"
echo "==========================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "=== Statystyki kodu (cloc) ===" >> "$REPORT_FILE"
cat "$REPORTS_DIR/${REPO_NAME}_cloc.csv" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "=== Złożoność kodu (radon cc - średnia) ===" >> "$REPORT_FILE"
jq '.average_complexity' "$REPORTS_DIR/${REPO_NAME}_radon_cc.json" >> "$REPORT_FILE" 2>/dev/null || echo "Brak jq do parsowania JSON" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "=== Maintainability Index (radon mi) ===" >> "$REPORT_FILE"
cat "$REPORTS_DIR/${REPO_NAME}_radon_mi.json" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "=== GOTOWE ==="
echo "Raport: $REPORT_FILE"
