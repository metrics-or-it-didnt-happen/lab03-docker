#!/bin/bash
set -euo pipefail

REPO_URL="${1:?Podaj URL repozytorium jako argument}"
REPO_NAME=$(basename "$REPO_URL" .git)
WORKSPACE="/workspace/repos"
REPORTS_DIR="/workspace/reports"

mkdir -p "$REPORTS_DIR"

echo "=== Klonuję $REPO_NAME ==="
if [ ! -d "$WORKSPACE/$REPO_NAME" ]; then
    git clone "$REPO_URL" "$WORKSPACE/$REPO_NAME"
else
    echo "Repo już istnieje, pomijam klonowanie"
fi

cd "$WORKSPACE/$REPO_NAME"

echo "=== Analiza cloc ==="
cloc . --quiet --csv --out="${REPORTS_DIR}/${REPO_NAME}_cloc.csv"

echo "=== Analiza radon (złożoność) ==="
radon cc . -s -a -j > "${REPORTS_DIR}/${REPO_NAME}_radon_cc.json"

echo "=== Analiza radon (maintainability index) ==="
radon mi . -j > "${REPORTS_DIR}/${REPO_NAME}_radon_mi.json"

echo "=== Generowanie raportu tekstowego ==="
REPORT_FILE="${REPORTS_DIR}/${REPO_NAME}_summary.txt"

echo "RAPORT Z ANALIZY KODU: $REPO_NAME" > "$REPORT_FILE"
echo "Data: $(date)" >> "$REPORT_FILE"
echo "URL: $REPO_URL" >> "$REPORT_FILE"
echo "==========================================" >> "$REPORT_FILE"
echo "Zgrubne podsumowanie objętości (cloc):" >> "$REPORT_FILE"
cloc . --quiet | tail -n 12 >> "$REPORT_FILE"
echo "==========================================" >> "$REPORT_FILE"
echo "Szczegółowe dane (complexity, maintainability index)" >> "$REPORT_FILE"
echo "zostały zapisane w formacie JSON oraz CSV w katalogu:" >> "$REPORT_FILE"
echo "$REPORTS_DIR" >> "$REPORT_FILE"

echo "=== Gotowe! Wyniki zapisano w $REPORTS_DIR ==="