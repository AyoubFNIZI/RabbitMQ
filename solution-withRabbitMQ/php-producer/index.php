<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

// RabbitMQ connection parameters PLAIN TEXT please don't be upset this is for test purposes :) !
$rabbitmq_host = '52.143.169.216';
$rabbitmq_port = 5672;
$rabbitmq_user = 'upworkUser';
$rabbitmq_pass = 'pass123456';

try {
    // Connect to RabbitMQ with explicit credentials
    $connection = new AMQPConnection();
    $connection->setHost($rabbitmq_host);
    $connection->setPort($rabbitmq_port);
    $connection->setLogin($rabbitmq_user);
    $connection->setPassword($rabbitmq_pass);
    $connection->setVhost('/');
    
    $connection->connect();
    echo "Connected to RabbitMQ successfully.<br>";

    // Create channel
    $channel = new AMQPChannel($connection);
    
    // Create and declare exchange
    $exchange = new AMQPExchange($channel);
    $exchange->setName('upwork_exchange');
    $exchange->setType(AMQP_EX_TYPE_DIRECT);
    $exchange->declare();
    
    // Declare queue
    $queue = new AMQPQueue($channel);
    $queue->setName('upworkQueue');
    $queue->setFlags(AMQP_DURABLE); 
    $queue->declare();
    
    // Bind queue to exchange
    $queue->bind('upwork_exchange', 'upwork_routing_key');
    
    // Get data from API
    echo "Fetching data from API...<br>";
    $api_url = "http://ext-api:8000/data";
    $response = file_get_contents($api_url);
    $data = json_decode($response, true);
    echo "Received " . count($data) . " records.<br>";

    // Split into chunks of 1000 records
    $messages = array_chunk($data, 1000);
    $total_messages = count($messages);
    
    echo "Starting to publish messages (total messages: $total_messages)...<br>";
    $counter = 0;
    
    foreach ($messages as $batch) {
        $counter++;
        // Create message with batch of 1000 records
        $message = json_encode([
            'batch_number' => $counter,
            'total_batches' => $total_messages,
            'record_count' => count($batch),
            'records' => $batch
        ]);
        
        $exchange->publish($message, 'upwork_routing_key', AMQP_NOPARAM, [
            'delivery_mode' => 2  // Make message persistent
        ]);
        
        echo "Published message $counter of $total_messages (1000 records)<br>";
        flush(); 
    }
    
    echo "All messages published successfully! Total messages: $counter<br>";
    
    // Close connection
    $connection->disconnect();

} catch (AMQPConnectionException $e) {
    echo "RabbitMQ Connection error: " . $e->getMessage();
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
