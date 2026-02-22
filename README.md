# Lab 03: Docker — pakujemy warsztat analityka

## Czy wiesz, że...

Według badań (które właśnie wymyśliłem), zdanie "u mnie działa" jest odpowiedzialne za 94% konfliktów w zespołach programistycznych. Docker został wynaleziony, żeby te konflikty zakończyć. Pozostałe 6% to spory o taby vs spacje.

## Kontekst

Na poprzednich labach instalowaliście Pythona, pip-a, radon-a, requests-a... a teraz wyobraźcie sobie, że musicie odtworzyć to środowisko na innej maszynie. Albo że kolega z pary ma Maca, a wy Linuxa. Albo że za rok wracacie do projektu i połowa bibliotek zmieniła API.

Docker rozwiązuje ten problem: pakujecie całe środowisko (system operacyjny, interpreter, biblioteki, narzędzia) do jednego "kontenera", który działa identycznie wszędzie. Dla analityka kodu to oznacza: jedno `docker-compose up` i macie gotowy warsztat z Jupyterem, radonem, lizardem i wszystkim co potrzebne.

## Cel laboratorium

Po tym laboratorium będziesz potrafić:
- napisać Dockerfile budujący obraz z narzędziami analitycznymi,
- stworzyć docker-compose.yml orkiestrujący wiele serwisów,
- używać wolumenów do trwałego przechowywania danych między sesjami,
- uruchomić Jupyter Notebook w kontenerze dostępnym z przeglądarki.

## Wymagania wstępne

- Docker Desktop zainstalowany i uruchomiony (sprawdź: `docker --version`)
- docker-compose (zazwyczaj wchodzi z Docker Desktop; sprawdź: `docker compose version`)
- Minimum 4 GB wolnej pamięci RAM (Docker + Jupyter + narzędzia)
- Podstawowa znajomość terminala

Jeśli Docker nie jest zainstalowany:
- **Linux:** `sudo apt install docker.io docker-compose-v2` + `sudo usermod -aG docker $USER`
- **Mac:** https://docs.docker.com/desktop/install/mac-install/
- **Windows:** https://docs.docker.com/desktop/install/windows-install/

## Zadania

### Zadanie 1: Mój pierwszy Dockerfile (45 min)

Czas zbudować obraz Dockerowy, który zawiera wszystkie narzędzia analityka kodu.

**Krok 1:** Stwórzcie plik `Dockerfile` w katalogu roboczym:

```dockerfile
FROM python:3.11-slim

WORKDIR /workspace

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        cloc \
        curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

CMD ["bash"]
```

**Krok 2:** Stwórzcie `requirements.txt` z narzędziami:

```
radon==6.0.1
lizard==1.17.10
matplotlib==3.9.2
seaborn==0.13.2
pandas==2.2.3
requests==2.32.3
PyGithub==2.5.0
jupyter==1.1.1
```

**Krok 3:** Zbudujcie obraz:

```bash
docker build -t code-analyzer .
```

To potrwa chwilę (pobieranie bazowego obrazu + instalacja). Przy kolejnych buildach cache Dockera przyspieszy sprawę.

**Krok 4:** Uruchomcie kontener i sprawdźcie, że wszystko działa:

```bash
docker run -it --rm code-analyzer

# Wewnątrz kontenera:
python --version
radon --version
lizard --version
cloc --version
git --version
```

**Krok 5:** Przetestujcie na prawdziwym repo:

```bash
# Uruchom kontener z dostępem do sieci
docker run -it --rm code-analyzer

# Wewnątrz kontenera:
git clone https://github.com/psf/requests.git
cd requests
cloc .
radon cc src/requests/api.py -s
```

Jeśli wszystko zadziałało — macie obraz analityka gotowy do użycia.

### Zadanie 2: docker-compose dla analityka (60 min)

Jeden kontener to za mało. Chcemy mieć:
- serwis `analyzer` z naszymi narzędziami (do pracy w terminalu),
- serwis `jupyter` z Jupyter Notebook (do interaktywnej analizy w przeglądarce),
- wspólny wolumen na dane (sklonowane repozytoria).

**Krok 1:** Stwórzcie `docker-compose.yml`:

```yaml
services:
  analyzer:
    build: .
    volumes:
      - repo-data:/workspace/repos
      - ./scripts:/workspace/scripts
    env_file:
      - .env
    stdin_open: true
    tty: true

  jupyter:
    build: .
    command: jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token=''
    ports:
      - "8888:8888"
    volumes:
      - repo-data:/workspace/repos
      - ./notebooks:/workspace/notebooks
    env_file:
      - .env

volumes:
  repo-data:
```

**Krok 2:** Stwórzcie plik `.env.example` (szablon konfiguracji):

```
GITHUB_TOKEN=ghp_your_token_here
```

I skopiujcie go jako `.env` z prawdziwym tokenem:

```bash
cp .env.example .env
# Edytuj .env i wstaw swój token
```

**Krok 3:** Stwórzcie katalogi na skrypty i notebooki:

```bash
mkdir -p scripts notebooks
```

**Krok 4:** Uruchomcie wszystko:

```bash
docker compose up -d
```

**Krok 5:** Sprawdźcie czy Jupyter działa — otwórzcie przeglądarkę na http://localhost:8888. Powinniście zobaczyć interfejs Jupytera.

**Krok 6:** Sklonujcie repo do wspólnego wolumenu (przez serwis analyzer):

```bash
docker compose exec analyzer bash

# Wewnątrz kontenera:
cd /workspace/repos
git clone https://github.com/psf/requests.git
```

**Krok 7:** W Jupyterze (w przeglądarce) stwórzcie nowy notebook i sprawdźcie, że widzicie sklonowane repo:

```python
import os
os.listdir("/workspace/repos")
# Powinno zwrócić ['requests']
```

**Krok 8:** Zatrzymajcie serwisy:

```bash
docker compose down
```

Dane w wolumenie `repo-data` przetrwają restart. Żeby je usunąć: `docker compose down -v`.

### Zadanie 3: Skrypt bootstrap (30 min) — dla ambitnych

Napiszcie skrypt `setup.sh`, który automatyzuje przygotowanie środowiska:

**Do zrobienia:**
- Sklonować wybrane repo OSS do wolumenu
- Uruchomić wstępną analizę (cloc, radon) i zapisać wyniki
- Wygenerować krótki raport w formacie tekstowym

```bash
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

echo "=== Analiza cloc ==="
cloc . --quiet --csv --out="/workspace/reports/${REPO_NAME}_cloc.csv"

echo "=== Analiza radon (złożoność) ==="
radon cc . -s -a -j > "/workspace/reports/${REPO_NAME}_radon_cc.json"

echo "=== Analiza radon (maintainability index) ==="
radon mi . -j > "/workspace/reports/${REPO_NAME}_radon_mi.json"

echo "=== Gotowe! Wyniki w /workspace/reports/ ==="
```

Przetestujcie go:

```bash
docker compose exec analyzer bash /workspace/scripts/setup.sh https://github.com/psf/requests.git
```

## Co oddajecie

W swoim branchu `lab03_nazwisko1_nazwisko2`:

1. **`Dockerfile`** — obraz z narzędziami analitycznymi
2. **`docker-compose.yml`** — orkiestracja serwisów
3. **`.env.example`** — szablon zmiennych środowiskowych (bez prawdziwego tokena!)
4. **`requirements.txt`** — zależności Pythonowe
5. *(opcjonalnie)* **`scripts/setup.sh`** — skrypt bootstrap z zadania 3

## Kryteria oceny

- `docker build` przechodzi bez błędów
- `docker compose up` uruchamia oba serwisy
- Jupyter jest dostępny na porcie 8888
- Wolumen jest współdzielony między serwisami (plik dodany w analyzer jest widoczny w jupyter)
- `.env.example` istnieje, `.env` nie jest commitowany
- Dockerfile używa wielowarstwowego cache (apt-get i pip w osobnych warstwach)

## FAQ

**P: Docker build trwa wieczność.**
O: Pierwszy build pobiera bazowy obraz (~150 MB) i instaluje pakiety. Kolejne będą szybsze dzięki cache. Upewnij się, że `COPY requirements.txt` jest PRZED `RUN pip install` — wtedy pip nie reinstaluje się przy każdej zmianie kodu.

**P: `docker compose up` nie działa, mam `docker-compose` (z myślnikiem).**
O: Starsza wersja. `docker-compose up` (z myślnikiem) też zadziała. Albo zaktualizuj Docker Desktop.

**P: Jupyter nie odpowiada na localhost:8888.**
O: Sprawdź `docker compose logs jupyter`. Częsty problem: port 8888 jest zajęty. Zmień na `"8889:8888"` w docker-compose.yml.

**P: Nie mam Docker Desktop, mogę użyć Podman?**
O: Tak, Podman jest kompatybilny z Dockerfile i docker-compose (przez podman-compose). Daj znać prowadzącemu.

**P: Mój komputer ma 4 GB RAM i Docker ledwo chodzi.**
O: Pracuj w parze na maszynie kolegi/koleżanki, albo użyj GitHub Codespaces (darmowy tier daje 60h/miesiąc).

## Przydatne linki

- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [Jupyter Docker Stacks](https://jupyter-docker-stacks.readthedocs.io/)
- [Best practices for writing Dockerfiles](https://docs.docker.com/build/building/best-practices/)

---
*"Kiedyś deploye robiło się na piechotę, pod górkę, w obie strony."* — każdy senior developer (źródło: trust me bro)
