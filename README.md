# RabbitMQ Data Processing Solution Demo

A test environment demonstrating how RabbitMQ can handle high-volume data processing across multiple servers.

## Infrastructure
- **Linux1**: Hosts PostgreSQL database, API, and PHP app/producer
- **Windows**: Hosts RabbitMQ instance  
- **Linux2**: Hosts Python consumer

## Scenario 1: Reproducing The Problem

This stage demonstrates the PHP timeout issue when processing large datasets.

### Setup
- External API container generating 100,000 records
- PHP application attempting to insert records into PostgreSQL
- PostgreSQL database on Linux1

### Result
PHP application unable to insert 100,000 records within 30-second timeout limit, demonstrating the need for a message queue solution.

## Scenario 2: RabbitMQ Integration

The second stage shows successful message queuing using RabbitMQ.

### Setup
- Same External API container
- PHP producer sending messages to RabbitMQ instead of direct database writes (100 messages, each contains 1000 records to be added to the database)
- RabbitMQ instance on Windows server

### Result
Successfully queued all messages (100,000 records split into batches) to RabbitMQ in les than 3 seconds.

## Scenario 3: Asynchronous Processing

The final stage shows message consumption and database processing.

### Setup
- Python consumer on Linux2
- Dequeues messages from RabbitMQ
- Writes records to PostgreSQL on Linux1

for better performance or to ingest higher amounts of data, this architecture could be scaled up using a cluster with several Queues. 
The current projects uses a unique RabbitMQ node and a unique Queue

If you would like to build this infra. on Azure, please make sure to use the right subscription_id on Terraform/conf.tf