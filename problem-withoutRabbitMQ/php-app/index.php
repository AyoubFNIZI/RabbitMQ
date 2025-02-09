<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

//Timeout control
set_time_limit(30); // Sets 30secondz timeout
$start_time = microtime(true);
echo "Current timeout setting: " . ini_get('max_execution_time') . " seconds<br>";
echo "Start time: " . date('H:i:s') . "<br>";

// Database connection params
$host = '10.0.20.4'; 
$dbname = 'upwork-db';
$user = 'upwork-user';
$password = 'upwork-pass';

try {
    // Connect to DB
    $pdo = new PDO("pgsql:host=$host;dbname=$dbname", $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "Connected to database successfully.<br>";
    
    // Create table if not exists
    $pdo->exec("CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        firstname VARCHAR(50),
        lastname VARCHAR(50),
        age INTEGER
    )");
    echo "Table created/verified successfully.<br>";
    
    // Get data from ext_API
    echo "Fetching data from API...<br>";
    $api_url = "http://ext-api:8000/data";
    $response = file_get_contents($api_url);
    $data = json_decode($response, true);
    echo "Received " . count($data) . " records.<br>";
    
    // Prepare insert statement
    $stmt = $pdo->prepare("INSERT INTO users (firstname, lastname, age) VALUES (:firstname, :lastname, :age)");
    
    // Try to insert all records with timeout check
    echo "Starting database insertion...<br>";
    $counter = 0;
    foreach ($data as $record) {
        // Check if we've exceeded timeout
        $execution_time = microtime(true) - $start_time;
        if ($execution_time > 30) {
            throw new Exception("Script execution time ($execution_time seconds) exceeded timeout limit (30 seconds)");
        }
        
        $stmt->execute([
            ':firstname' => $record['firstname'],
            ':lastname' => $record['lastname'],
            ':age' => $record['age']
        ]);
        
        $counter++;
        if ($counter % 1000 == 0) {
            echo "Processed $counter records at " . date('H:i:s') . " (Execution time: " . round($execution_time, 2) . " seconds)<br>";
            flush(); // Force output buffer to flush
        }
    }
    echo "Insertion complete! Total records processed: $counter<br>";
    
} catch (PDOException $e) {
    echo "Database error: " . $e->getMessage();
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}

$total_time = microtime(true) - $start_time;
echo "End time: " . date('H:i:s') . " (Total execution time: " . round($total_time, 2) . " seconds)<br>";
?>