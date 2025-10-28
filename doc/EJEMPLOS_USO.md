# 🎯 EJEMPLOS PRÁCTICOS DE USO
## Boilerplate PHP + MySQL + Docker

---

## 📖 TABLA DE CONTENIDOS

1. [Instalación Rápida](#instalacion-rapida)
2. [Ejemplos de Desarrollo](#ejemplos-desarrollo)
3. [Ejemplos de Deployment](#ejemplos-deployment)
4. [Casos de Uso Comunes](#casos-uso)
5. [Integración con Frameworks](#frameworks)
6. [Scripts Útiles](#scripts-utiles)

---

## 🚀 INSTALACIÓN RÁPIDA {#instalacion-rapida}

### Ejemplo 1: Proyecto Nuevo (sin repositorio existente)

```bash
# 1. Ejecutar el script
chmod +x setup-docker-php-mysql.sh
./setup-docker-php-mysql.sh

# 2. Responder las preguntas:
# Nombre del proyecto: mi-api-rest
# URL del repositorio GitHub: [DEJAR VACÍO]
# Branch: main
# Puerto App: 8080
# Puerto DB: 3306

# 3. Iniciar el ambiente
cd mi-api-rest
./start.sh

# 4. Verificar que funciona
curl http://localhost:8080
```

### Ejemplo 2: Clonar Proyecto Existente

```bash
# 1. Generar clave SSH (si no tienes)
ssh-keygen -t ed25519 -C "tu-email@example.com"
cat ~/.ssh/id_rsa.pub  # Copiar y agregar a GitHub

# 2. Ejecutar el script
./setup-docker-php-mysql.sh

# 3. Proporcionar datos:
# Nombre: mi-proyecto-existente
# URL: git@github.com:usuario/mi-proyecto.git
# Branch: develop
# Puerto App: 8080
# Puerto DB: 3306

# 4. El script clonará automáticamente el repo
# 5. Iniciar
cd mi-proyecto-existente
./start.sh
```

---

## 💻 EJEMPLOS DE DESARROLLO {#ejemplos-desarrollo}

### Ejemplo 3: Instalar Laravel

```bash
# Dentro del proyecto
cd mi-proyecto-php

# Instalar Laravel via Composer
./composer.sh create-project laravel/laravel .

# Configurar .env de Laravel
cat >> src/.env << EOF
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=${MYSQL_DATABASE}
DB_USERNAME=${MYSQL_USER}
DB_PASSWORD=${MYSQL_PASSWORD}
EOF

# Generar key
./composer.sh artisan key:generate

# Migrar base de datos
./composer.sh artisan migrate

# Acceder
open http://localhost:8080
```

### Ejemplo 4: Instalar Symfony

```bash
# Instalar Symfony
./composer.sh create-project symfony/skeleton:"^6.0" .

# Instalar componentes web
./composer.sh require webapp

# Configurar DATABASE_URL en .env
# DATABASE_URL="mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@mysql:3306/${MYSQL_DATABASE}"

# Crear entidades
./php.sh bin/console make:entity User

# Migrar
./php.sh bin/console doctrine:migrations:migrate

# Iniciar servidor
open http://localhost:8080
```

### Ejemplo 5: API REST Simple sin Framework

```bash
# Crear estructura básica
mkdir -p src/public/api
cd src/public

# Crear index.php
cat > index.php << 'EOF'
<?php
// Simple Router
$request_uri = $_SERVER['REQUEST_URI'];
$request_method = $_SERVER['REQUEST_METHOD'];

// CORS Headers
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Database Connection
try {
    $pdo = new PDO(
        "mysql:host=" . getenv('MYSQL_HOST') . ";dbname=" . getenv('MYSQL_DATABASE'),
        getenv('MYSQL_USER'),
        getenv('MYSQL_PASSWORD'),
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed']);
    exit;
}

// Simple Router
if ($request_uri === '/api/users' && $request_method === 'GET') {
    $stmt = $pdo->query("SELECT id, username, email FROM users");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($users);
    
} elseif ($request_uri === '/api/users' && $request_method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    $stmt = $pdo->prepare("INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)");
    $stmt->execute([$data['username'], $data['email'], password_hash($data['password'], PASSWORD_DEFAULT)]);
    
    http_response_code(201);
    echo json_encode(['id' => $pdo->lastInsertId(), 'message' => 'User created']);
    
} else {
    http_response_code(404);
    echo json_encode(['error' => 'Not Found']);
}
EOF

# Probar API
curl http://localhost:8080/api/users
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@example.com","password":"123456"}'
```

### Ejemplo 6: Desarrollo con Xdebug (PHPStorm)

```bash
# 1. Verificar que Xdebug esté activo
docker-compose exec php php -v | grep Xdebug

# 2. Configurar PHPStorm:
# - Settings → PHP → Debug
#   - Xdebug port: 9003
# - Settings → PHP → Servers
#   - Name: Docker
#   - Host: localhost
#   - Port: 8080
#   - Debugger: Xdebug
#   - Path mappings: ./src -> /var/www/html

# 3. Agregar breakpoint en tu código
# 4. Iniciar "Listen for PHP Debug Connections"
# 5. Cargar página en browser con ?XDEBUG_SESSION_START=PHPSTORM
```

### Ejemplo 7: Testing con PHPUnit

```bash
# Instalar PHPUnit
./composer.sh require --dev phpunit/phpunit

# Crear tests/ExampleTest.php
mkdir -p src/tests
cat > src/tests/ExampleTest.php << 'EOF'
<?php

use PHPUnit\Framework\TestCase;

class ExampleTest extends TestCase
{
    public function testDatabaseConnection()
    {
        $pdo = new PDO(
            "mysql:host=" . getenv('MYSQL_HOST') . ";dbname=" . getenv('MYSQL_DATABASE'),
            getenv('MYSQL_USER'),
            getenv('MYSQL_PASSWORD')
        );
        
        $this->assertInstanceOf(PDO::class, $pdo);
    }
    
    public function testUserCreation()
    {
        $user = ['username' => 'test', 'email' => 'test@example.com'];
        $this->assertArrayHasKey('username', $user);
    }
}
EOF

# Ejecutar tests
./composer.sh test
# o
./php.sh vendor/bin/phpunit tests/
```

---

## 🚀 EJEMPLOS DE DEPLOYMENT {#ejemplos-deployment}

### Ejemplo 8: Deploy a Producción (VPS/Servidor)

```bash
# En tu servidor de producción

# 1. Clonar el proyecto
git clone git@github.com:usuario/proyecto.git
cd proyecto

# 2. Copiar .env de producción
cp .env.example .env
nano .env  # Configurar para producción

# Configuración importante:
APP_ENV=production
APP_DEBUG=false
APP_PORT=80
XDEBUG_MODE=off

# 3. Configurar SSL (Let's Encrypt)
cat > docker/nginx/default.conf << 'EOF'
server {
    listen 80;
    server_name tudominio.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name tudominio.com;
    
    ssl_certificate /etc/letsencrypt/live/tudominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tudominio.com/privkey.pem;
    
    # ... resto de configuración ...
}
EOF

# 4. Obtener certificado SSL
sudo apt install certbot python3-certbot-nginx
sudo certbot certonly --webroot -w /var/www/html -d tudominio.com

# 5. Build y start
docker-compose build --no-cache
docker-compose up -d

# 6. Verificar
docker-compose ps
curl https://tudominio.com
```

### Ejemplo 9: Deploy con GitHub Actions (CI/CD)

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Copy files to server
        uses: appleboy/scp-action@master
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SERVER_SSH_KEY }}
          source: "."
          target: "/var/www/proyecto"
      
      - name: Deploy via SSH
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SERVER_SSH_KEY }}
          script: |
            cd /var/www/proyecto
            docker-compose pull
            docker-compose up -d --build
            docker-compose exec php composer install --no-dev
            docker-compose exec php php artisan migrate --force
            docker-compose exec php php artisan optimize
```

### Ejemplo 10: Deploy con Docker Swarm

```bash
# Inicializar Swarm
docker swarm init

# Crear docker-compose.prod.yml
cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  php:
    image: registro.example.com/proyecto-php:latest
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
    secrets:
      - db_password
      - app_key

secrets:
  db_password:
    external: true
  app_key:
    external: true
EOF

# Crear secrets
echo "my_secure_password" | docker secret create db_password -
echo "base64:..." | docker secret create app_key -

# Deploy stack
docker stack deploy -c docker-compose.prod.yml proyecto

# Verificar
docker stack services proyecto
```

---

## 🎯 CASOS DE USO COMUNES {#casos-uso}

### Ejemplo 11: Sistema de Login Completo

```php
<?php
// src/public/api/auth.php

session_start();

$pdo = new PDO(/* conexión */);

$action = $_GET['action'] ?? '';

switch($action) {
    case 'register':
        // POST /api/auth.php?action=register
        $data = json_decode(file_get_contents('php://input'), true);
        
        // Validar
        if (empty($data['username']) || empty($data['password'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing fields']);
            exit;
        }
        
        // Hash password
        $hash = password_hash($data['password'], PASSWORD_ARGON2ID);
        
        // Insertar
        $stmt = $pdo->prepare("INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)");
        $stmt->execute([$data['username'], $data['email'], $hash]);
        
        echo json_encode(['message' => 'User registered', 'id' => $pdo->lastInsertId()]);
        break;
        
    case 'login':
        // POST /api/auth.php?action=login
        $data = json_decode(file_get_contents('php://input'), true);
        
        $stmt = $pdo->prepare("SELECT * FROM users WHERE username = ?");
        $stmt->execute([$data['username']]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($user && password_verify($data['password'], $user['password_hash'])) {
            $_SESSION['user_id'] = $user['id'];
            $_SESSION['username'] = $user['username'];
            echo json_encode(['message' => 'Login successful', 'user' => $user['username']]);
        } else {
            http_response_code(401);
            echo json_encode(['error' => 'Invalid credentials']);
        }
        break;
        
    case 'logout':
        // POST /api/auth.php?action=logout
        session_destroy();
        echo json_encode(['message' => 'Logged out']);
        break;
        
    case 'me':
        // GET /api/auth.php?action=me
        if (isset($_SESSION['user_id'])) {
            echo json_encode(['user' => $_SESSION['username']]);
        } else {
            http_response_code(401);
            echo json_encode(['error' => 'Not authenticated']);
        }
        break;
}
```

### Ejemplo 12: Upload de Archivos Seguro

```php
<?php
// src/public/api/upload.php

$allowed_types = ['image/jpeg', 'image/png', 'image/gif'];
$max_size = 5 * 1024 * 1024; // 5 MB

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['file'])) {
    $file = $_FILES['file'];
    
    // Validar tipo
    if (!in_array($file['type'], $allowed_types)) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid file type']);
        exit;
    }
    
    // Validar tamaño
    if ($file['size'] > $max_size) {
        http_response_code(400);
        echo json_encode(['error' => 'File too large']);
        exit;
    }
    
    // Generar nombre seguro
    $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    $filename = bin2hex(random_bytes(16)) . '.' . $extension;
    $upload_path = '/var/www/html/storage/uploads/' . $filename;
    
    // Mover archivo
    if (move_uploaded_file($file['tmp_name'], $upload_path)) {
        // Guardar en BD
        $pdo = new PDO(/* conexión */);
        $stmt = $pdo->prepare("INSERT INTO uploads (filename, original_name, size) VALUES (?, ?, ?)");
        $stmt->execute([$filename, $file['name'], $file['size']]);
        
        echo json_encode([
            'message' => 'File uploaded',
            'url' => '/storage/uploads/' . $filename
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Upload failed']);
    }
}
```

### Ejemplo 13: API con Rate Limiting

```php
<?php
// src/public/middleware/rate_limit.php

class RateLimiter {
    private $redis;
    
    public function __construct() {
        $this->redis = new Redis();
        $this->redis->connect('redis', 6379);
    }
    
    public function check($ip, $limit = 60, $window = 60) {
        $key = "rate_limit:$ip";
        $current = $this->redis->incr($key);
        
        if ($current === 1) {
            $this->redis->expire($key, $window);
        }
        
        if ($current > $limit) {
            http_response_code(429);
            echo json_encode([
                'error' => 'Too many requests',
                'retry_after' => $this->redis->ttl($key)
            ]);
            exit;
        }
        
        return true;
    }
}

// Uso
$limiter = new RateLimiter();
$limiter->check($_SERVER['REMOTE_ADDR']);
```

---

## 🔧 INTEGRACIÓN CON FRAMEWORKS {#frameworks}

### Ejemplo 14: WordPress

```bash
# Descargar WordPress
cd src/public
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
mv wordpress/* .
rm -rf wordpress latest.tar.gz

# Crear wp-config.php
cat > wp-config.php << 'EOF'
<?php
define('DB_NAME', getenv('MYSQL_DATABASE'));
define('DB_USER', getenv('MYSQL_USER'));
define('DB_PASSWORD', getenv('MYSQL_PASSWORD'));
define('DB_HOST', 'mysql:3306');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

// Security keys (generar en https://api.wordpress.org/secret-key/1.1/salt/)
define('AUTH_KEY',         'tu-key-aqui');
// ... resto de keys ...

$table_prefix = 'wp_';
define('WP_DEBUG', false);

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF

# Acceder a instalación
open http://localhost:8080
```

### Ejemplo 15: CodeIgniter 4

```bash
# Instalar CodeIgniter
./composer.sh create-project codeigniter4/appstarter .

# Configurar database en .env
cat >> src/.env << 'EOF'
database.default.hostname = mysql
database.default.database = ${MYSQL_DATABASE}
database.default.username = ${MYSQL_USER}
database.default.password = ${MYSQL_PASSWORD}
database.default.DBDriver = MySQLi
EOF

# Ejecutar
open http://localhost:8080
```

---

## 🛠️ SCRIPTS ÚTILES {#scripts-utiles}

### Ejemplo 16: Script de Migración de Datos

```bash
#!/bin/bash
# migrate-data.sh

echo "Migrando datos desde backup..."

# Restaurar SQL
cat backups/old_database.sql | ./mysql.sh

# Ejecutar script de transformación
./php.sh scripts/transform_data.php

echo "Migración completada"
```

### Ejemplo 17: Script de Health Check

```bash
#!/bin/bash
# health-check.sh

# Verificar servicios
for service in php nginx mysql; do
    if docker-compose ps $service | grep -q "Up"; then
        echo "✓ $service: OK"
    else
        echo "✗ $service: FAIL"
        exit 1
    fi
done

# Verificar conectividad HTTP
if curl -f http://localhost:8080 > /dev/null 2>&1; then
    echo "✓ HTTP: OK"
else
    echo "✗ HTTP: FAIL"
    exit 1
fi

# Verificar MySQL
if ./mysql.sh -e "SELECT 1" > /dev/null 2>&1; then
    echo "✓ MySQL: OK"
else
    echo "✗ MySQL: FAIL"
    exit 1
fi

echo "All checks passed!"
```

### Ejemplo 18: Script de Optimización de Base de Datos

```bash
#!/bin/bash
# optimize-db.sh

echo "Optimizando base de datos..."

# Analizar tablas
./mysql.sh -e "
    SELECT 
        table_name, 
        ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb 
    FROM information_schema.tables 
    WHERE table_schema = '${MYSQL_DATABASE}'
    ORDER BY size_mb DESC;
"

# Optimizar todas las tablas
./mysql.sh -e "
    SELECT CONCAT('OPTIMIZE TABLE ', table_name, ';') 
    FROM information_schema.tables 
    WHERE table_schema = '${MYSQL_DATABASE}';
" | grep OPTIMIZE | ./mysql.sh

echo "Optimización completada"
```

---

## 🎓 CONCLUSIÓN

Este boilerplate proporciona una base sólida para desarrollar aplicaciones PHP profesionales con:

✅ Configuración Docker optimizada
✅ Seguridad hardening implementada
✅ Scripts de automatización incluidos
✅ Documentación completa
✅ Ejemplos prácticos ready-to-use

**Próximos pasos:**
1. Ejecutar el script de setup
2. Revisar la documentación técnica
3. Ejecutar el security check
4. Comenzar a desarrollar! 🚀

---

**Documento generado automáticamente**
