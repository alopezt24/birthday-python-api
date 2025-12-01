# Multi-stage build for smaller image
FROM python:3.13.1-slim as builder

WORKDIR /app

# Copy requirements first for better caching
COPY app/requirements.txt .

# Install dependencies to a specific location
RUN pip install --no-cache-dir --user -r requirements.txt

# Runtime stage
FROM python:3.13.1-slim

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser -u 1000 appuser

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /root/.local /home/appuser/.local

# Copy application code
COPY app/ .

# Change ownership of application files
RUN chown -R appuser:appuser /app /home/appuser/.local

# Add local bin to PATH
ENV PATH=/home/appuser/.local/bin:$PATH

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Run application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]