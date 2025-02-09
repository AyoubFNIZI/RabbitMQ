FROM python:3.9-slim

WORKDIR /app

# Install PostgreSQL client libraries
RUN apt-get update && \
    apt-get install -y libpq-dev gcc && \
    apt-get clean


COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt


COPY consumer.py .

CMD ["python", "consumer.py"]
