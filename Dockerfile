# Build stage
FROM python:3.12-slim-bookworm AS builder

# Define build argument with default value
ARG PORT=8000
# Make it available as env variable at runtime
ENV OPTILLM_PORT=$PORT

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    gcc \
    g++ \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy only the requirements file first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Final stage
FROM python:3.12-slim-bookworm

# Add labels for the final image
LABEL org.opencontainers.image.source="https://github.com/codelion/optillm"
LABEL org.opencontainers.image.description="OptiLLM full image with model serving and API routing capabilities"
LABEL org.opencontainers.image.licenses="Apache-2.0"

# Install curl for the healthcheck
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy installed dependencies from builder stage
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY . .

# Create a non-root user and switch to it
RUN useradd -m appuser
USER appuser

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Use the ARG in EXPOSE
EXPOSE ${PORT}

# Run the application
ENTRYPOINT ["python", "optillm.py"]
