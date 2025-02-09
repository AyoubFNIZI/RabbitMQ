import pika
import json
import psycopg2
from psycopg2 import extras  # For batch inserts

# RabbitMQ connection parameters
rabbitmq_params = pika.ConnectionParameters(
    host='52.143.169.216',
    port=5672,
    credentials=pika.PlainCredentials('upworkUser', 'pass123456'),
    virtual_host='/'
)

# Psql connection parameters
pg_params = {
    'host': '52.143.171.237',
    'database': 'upwork-db',
    'user': 'upwork-user',
    'password': 'upwork-pass'
}

def process_message(ch, method, properties, body):
    try:
        # Parse mess
        message = json.loads(body)
        batch_number = message['batch_number']
        records = message['records']
        
        # Connect to PostgreSQL
        with psycopg2.connect(**pg_params) as conn:
            with conn.cursor() as cur:
                # Prepare data for batch insert
                data = [(r['firstname'], r['lastname'], r['age']) for r in records]
                
                # Execute batch insert
                extras.execute_batch(cur, 
                    "INSERT INTO users (firstname, lastname, age) VALUES (%s, %s, %s)",
                    data
                )
                conn.commit()
                
        print(f"Processed batch {batch_number} - {len(records)} records inserted")
        ch.basic_ack(delivery_tag=method.delivery_tag)
        
    except Exception as e:
        print(f"Error processing batch {batch_number}: {str(e)}")
        # Nack message to retry
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)

def main():
    # Connect to RabbitMQ
    connection = pika.BlockingConnection(rabbitmq_params)
    channel = connection.channel()
    
    # Declare queue (same as producer)
    channel.queue_declare(queue='upworkQueue', durable=True)
    
    # Set QoS (prefetch_count=1 means process one message at a time)
    channel.basic_qos(prefetch_count=1)
    
    # Set up consumer
    channel.basic_consume(
        queue='upworkQueue',
        on_message_callback=process_message
    )
    
    print("Starting to consume messages...")
    channel.start_consuming()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("Stopping consumer...")