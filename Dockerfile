FROM python:3.11-slim

WORKDIR /workspace

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        cloc \
        curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
COPY --chmod=755 setup.sh .
RUN pip install --no-cache-dir -r requirements.txt

RUN mkdir -p /workspace/repos /workspace/reports /workspace/notebooks /workspace/scripts

CMD ["bash"]
