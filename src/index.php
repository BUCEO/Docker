<?php
echo "<h1>Hola, Proyecto de Pasaje de Grado</h1>";

// Conexi�n a MySQL
$servername = getenv('MYSQL_HOST');
$username = getenv('MYSQL_USER');
$password = getenv('MYSQL_PASSWORD');
$dbname = getenv('MYSQL_DATABASE');

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Conexi�n fallida: " . $conn->connect_error);
}
echo "<p>Conexi�n exitosa a la base de datos!</p>";
