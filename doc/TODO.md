Proyecto de Pasaje de Grado - PHP y MySQL con Docker
Este proyecto provee un entorno Dockerizado para desarrollar una aplicación web utilizando PHP-FPM y MySQL. El código fuente y los archivos estáticos están organizados en volúmenes mapeados, y la base de datos utiliza un volumen persistente.

Estructura del Proyecto
bash
Copy code
project/
├── docker-compose.yml         # Configuración de Docker Compose
├── Dockerfile                 # Dockerfile para PHP-FPM y Apache
├── php.ini-development         # Configuración PHP para desarrollo
├── php.ini-production          # Configuración PHP para producción
├── apache-test.conf            # Configuración Apache para desarrollo
├── apache-prod.conf            # Configuración Apache para producción
├── src/                        # Código PHP
│   └── index.php               # Archivo PHP de ejemplo
├── public/                     # Archivos públicos (HTML, CSS, JS)
│   ├── index.html              # Ejemplo de archivo HTML
│   ├── style.css               # Ejemplo de archivo CSS
│   └── app.js                  # Ejemplo de archivo JS
└── mysql_data/                 # Volumen de datos de MySQL
Servicios
1. PHP-Apache
Imagen: php:8.3.4-fpm-alpine
Servidor Apache con soporte para PHP-FPM.
Volúmenes mapeados:
Código fuente PHP: ./src:/var/www/html
Archivos estáticos (HTML, CSS, JS): ./public:/var/www/html/public
Puertos mapeados:
8080:80 (HTTP)
8443:443 (HTTPS)
Variables de entorno para conexión a MySQL.
2. MySQL
Imagen: mysql:8.0
Configuración de base de datos:
Base de datos: pasantias
Usuario: user
Contraseña: password
Contraseña root: rootpassword
Puerto mapeado: 3306:3306
Volumen para datos persistentes: mysql_data:/var/lib/mysql
Redes
frontend: Red para la comunicación del cliente (navegador) con el servidor web.
backend: Red interna para la comunicación entre PHP/Apache y MySQL.
Instrucciones
Construir los contenedores:

bash
Copy code
docker-compose build
Levantar los contenedores:

bash
Copy code
docker-compose up -d
Acceder a la aplicación:

Abre un navegador y ve a: http://localhost:8080
Verificar el estado de los contenedores:

bash
Copy code
docker-compose ps
Archivos de Configuración
1. PHP (php.ini)
Se incluyen dos configuraciones:
Desarrollo: php.ini-development
Producción: php.ini-production
2. Apache (apache.conf)
Configuración personalizada para:
Desarrollo: apache-test.conf
Producción: apache-prod.conf
Código Ejemplo
PHP (src/index.php)
php
Copy code
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
Consideraciones Finales
Este proyecto proporciona un entorno completo y modular para desarrollar una aplicación web utilizando Docker, con soporte para PHP, Apache y MySQL. Incluye configuraciones separadas para desarrollo y producción, así como volúmenes persistentes para la base de datos.
