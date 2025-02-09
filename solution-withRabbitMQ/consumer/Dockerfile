FROM python:3.9-slim

WORKDIR /app

# Install PostgreSQL client libraries
RUN apt-get update && \
    apt-get install -y libpq-dev gcc && \
    apt-get clean

# Copy requirements first (for better caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy consumer script
COPY consumer.py .

CMD ["python", "consumer.py"]