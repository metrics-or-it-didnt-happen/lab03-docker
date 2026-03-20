# Dockerfile for setting up a Python environment with necessary tools for repository analysis and reporting

# Use the official Python image from the Docker Hub
FROM python:3.11-slim
# Set the working directory to /workspace
WORKDIR /workspace
# Install necessary tools and clean up apt cache to reduce image size
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
# Install git for cloning repositories
        git \
# Install cloc for counting lines of code in repositories
        cloc \
# Install curl for downloading files if needed
        curl \
# Clean up apt cache to reduce image size
    && rm -rf /var/lib/apt/lists/*
# Copy the requirements file and install Python dependencies
COPY requirements.txt .
# Install the required Python packages specified in requirements.txt without using cache to reduce image size
RUN pip install --no-cache-dir -r requirements.txt
# Create necessary directories for repositories, reports, notebooks, and scripts
RUN mkdir -p /workspace/repos /workspace/reports /workspace/notebooks /workspace/scripts
# Set the default command to bash when the container starts
CMD ["bash"]
