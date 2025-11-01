# Backend Dockerfile for PDFGrabber Web UI
# Use Playwright Python image which has browsers pre-installed
FROM mcr.microsoft.com/playwright/python:v1.40.0-jammy

WORKDIR /app

# Copy backend requirements and install
COPY backend/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Copy PDFGrabber core files
COPY utils.py /app/
COPY config.py /app/
COPY lib.py /app/
COPY services/ /app/services/
COPY config-default.ini /app/

# Copy backend application
COPY backend/ /app/backend/

# Create necessary directories
RUN mkdir -p /app/files

ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

EXPOSE 8080

CMD ["python", "-m", "uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8080"]

