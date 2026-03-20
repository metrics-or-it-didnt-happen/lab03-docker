FROM python:3.12-slim

WORKDIR /workspace

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        cloc \
        curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN mkdir -p /workspace/repos /workspace/reports /workspace/notebooks /workspace/scripts

CMD ["bash"]
