<?php
echo "<h1>Hola, Proyecto de Pasantía</h1>";

// Conexión a MySQL
$servername = getenv('MYSQL_HOST');
$username = getenv('MYSQL_USER');
$password = getenv('MYSQL_PASSWORD');
$dbname = getenv('MYSQL_DATABASE');

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Conexión fallida: " . $conn->connect_error);
}
echo "<p>Conexión exitosa a la base de datos!</p>";

// Verificar si los datos de prueba están en la tabla "alumnos"
$sql = "SELECT * FROM alumnos";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    echo "<p>Datos cargados exitosamente:</p><ul>";
    while($row = $result->fetch_assoc()) {
        echo "<li>" . $row['nombre'] . " " . $row['apellido'] . "</li>";
    }
    echo "</ul>";
} else {
    echo "<p>No se encontraron datos de prueba en la tabla 'alumnos'.</p>";
}

$conn->close();
