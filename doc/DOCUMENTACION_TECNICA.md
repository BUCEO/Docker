# 📚 DOCUMENTACIÓN TÉCNICA COMPLETA
## Boilerplate PHP + MySQL + Docker con SSH

---

## 📋 ÍNDICE

1. [Arquitectura del Sistema](#arquitectura)
2. [Seguridad (Hardening)](#seguridad)
3. [Guía de Uso Detallada](#guia-uso)
4. [Optimizaciones](#optimizaciones)
5. [Troubleshooting](#troubleshooting)
6. [Mejores Prácticas](#mejores-practicas)

---

## 🏗️ ARQUITECTURA DEL SISTEMA {#arquitectura}

### Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────┐
│                        HOST MACHINE                              │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Docker Network                           │ │
│  │                  (172.20.0.0/16)                           │ │
│  │                                                             │ │
│  │  ┌──────────────┐      ┌──────────────┐      ┌──────────┐ │ │
│  │  │   Nginx      │─────▶│   PHP-FPM    │─────▶│  MySQL   │ │ │
│  │  │  (Alpine)    │      │   (8.3-fpm)  │      │  (8.0)   │ │ │
│  │  │              │      │              │      │          │ │ │
│  │  │ Port: 80     │      │ Port: 9000   │      │Port: 3306│ │ │
│  │  └──────────────┘      └──────────────┘      └──────────┘ │ │
│  │        │                      │                     │      │ │
│  │        │                      │                     │      │ │
│  │        ▼                      ▼                     ▼      │ │
│  │  ┌──────────────┐      ┌──────────────┐      ┌──────────┐ │ │
│  │  │   Volumes    │      │   Volumes    │      │ Volumes  │ │ │
│  │  │   ./src      │      │   ./logs     │      │mysql_data│ │ │
│  │  └──────────────┘      └──────────────┘      └──────────┘ │ │
│  │                                                             │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │              Redis (Opcional)                        │ │ │
│  │  │              Port: 6379                              │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Puertos Expuestos:                                             │
│  ├─ 8080 → Nginx (Aplicación Web)                              │
│  ├─ 3306 → MySQL (Base de Datos)                               │
│  ├─ 8081 → PHPMyAdmin (opcional)                               │
│  └─ 6379 → Redis (opcional)                                    │
└─────────────────────────────────────────────────────────────────┘
```

### Flujo de Solicitud HTTP

```
┌──────────┐       ┌──────────┐       ┌──────────┐       ┌──────────┐
│ Cliente  │──────▶│  Nginx   │──────▶│ PHP-FPM  │──────▶│  MySQL   │
│(Browser) │       │  :8080   │       │  :9000   │       │  :3306   │
└──────────┘       └──────────┘       └──────────┘       └──────────┘
     │                   │                   │                   │
     │  HTTP Request     │   FastCGI         │   PDO/MySQLi     │
     │ ─────────────────▶│ ─────────────────▶│ ─────────────────▶│
     │                   │                   │                   │
     │  HTML Response    │   PHP Output      │   Query Result   │
     │◀───────────────── │◀───────────────── │◀───────────────── │
     │                   │                   │                   │
```

### Ciclo de Vida del Contenedor

```
┌─────────────────────────────────────────────────────────────────┐
│                    LIFECYCLE MANAGEMENT                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. BUILD                                                        │
│     └─▶ docker-compose build                                    │
│         ├─ Construye imagen PHP custom                          │
│         ├─ Descarga imágenes oficiales (nginx, mysql)           │
│         └─ Aplica configuraciones personalizadas                │
│                                                                  │
│  2. START                                                        │
│     └─▶ docker-compose up -d                                    │
│         ├─ Crea network bridge                                  │
│         ├─ Monta volúmenes                                      │
│         ├─ Inicia contenedores en orden (depends_on)           │
│         └─ Ejecuta health checks                                │
│                                                                  │
│  3. RUNTIME                                                      │
│     ├─ Health checks cada 30s                                   │
│     ├─ Logs agregados en ./logs/                               │
│     ├─ Auto-restart si falla (unless-stopped)                  │
│     └─ Persistencia de datos en volumes                        │
│                                                                  │
│  4. STOP                                                         │
│     └─▶ docker-compose down                                     │
│         ├─ Detiene contenedores gracefully                      │
│         ├─ Remueve containers y network                        │
│         └─ Preserva volúmenes (datos persistentes)             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔒 SEGURIDAD Y HARDENING {#seguridad}

### Medidas Implementadas

#### 1. **Contenedores**

```yaml
Aislamiento de Red:
├─ Red privada (172.20.0.0/16)
├─ Comunicación solo entre servicios necesarios
└─ Puertos mínimos expuestos al host

Usuario No-Root:
├─ PHP-FPM corre como 'appuser' (UID 1000)
├─ Sin privilegios de root dentro del contenedor
└─ Principio de mínimo privilegio
```

#### 2. **PHP Hardening**

```ini
; php.ini - Configuraciones de seguridad
expose_php = Off              # Oculta versión de PHP
allow_url_include = Off       # Previene RFI
open_basedir = /var/www/html  # Limita acceso al filesystem
disable_functions = exec,passthru,shell_exec,system,proc_open,popen
session.cookie_httponly = 1   # Previene XSS en cookies
session.cookie_secure = 0     # Activar en producción con HTTPS
session.use_strict_mode = 1   # Validación estricta de session ID
```

#### 3. **MySQL Hardening**

```ini
; my.cnf - Configuraciones de seguridad
local_infile = 0              # Previene LOAD DATA INFILE
symbolic-links = 0            # Deshabilita symlinks
skip-name-resolve             # Usa solo IPs (no DNS)

Usuarios con Privilegios Mínimos:
├─ Root solo para admin
├─ Usuario app con permisos limitados (SELECT, INSERT, UPDATE, DELETE)
└─ Sin acceso remoto para root
```

#### 4. **Nginx Security Headers**

```nginx
# Security Headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;

# Deny access to sensitive files
location ~ /\.(ht|git|env) {
    deny all;
}
```

#### 5. **Gestión de Secretos**

```bash
✅ Usar .env para credenciales
✅ .env en .gitignore (nunca commitear)
✅ Passwords generados aleatoriamente (32 chars)
✅ Rotación periódica de credenciales
✅ Usar secrets de Docker en producción
```

### Checklist de Seguridad para Producción

```
┌─────────────────────────────────────────────────────────────┐
│              PRODUCTION SECURITY CHECKLIST                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [ ] Cambiar TODAS las contraseñas default                 │
│  [ ] Configurar HTTPS/SSL (Let's Encrypt)                  │
│  [ ] Habilitar session.cookie_secure en PHP                │
│  [ ] Deshabilitar Xdebug en producción                     │
│  [ ] Configurar APP_DEBUG=false                            │
│  [ ] Implementar rate limiting (fail2ban)                  │
│  [ ] Configurar firewall (UFW/iptables)                    │
│  [ ] Habilitar audit logs                                  │
│  [ ] Configurar backups automáticos                        │
│  [ ] Implementar monitoring (Prometheus/Grafana)           │
│  [ ] Actualizar imágenes de Docker periódicamente          │
│  [ ] Escanear vulnerabilidades (Trivy, Snyk)              │
│  [ ] Configurar Content Security Policy (CSP)              │
│  [ ] Implementar CORS correctamente                        │
│  [ ] Usar Docker secrets para credenciales                 │
│  [ ] Limitar recursos (CPU, memoria) por contenedor       │
│  [ ] Configurar log rotation                               │
│  [ ] Implementar health checks robustos                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📖 GUÍA DE USO DETALLADA {#guia-uso}

### Instalación Inicial

#### 1. Clonar o Ejecutar el Script

```bash
# Opción A: Ejecutar script directamente
chmod +x setup-docker-php-mysql.sh
./setup-docker-php-mysql.sh

# El script solicitará:
# - Nombre del proyecto
# - URL del repositorio GitHub (SSH)
# - Branch a clonar
# - Puertos para la aplicación y BD
```

#### 2. Configuración de SSH (Automática)

El script verifica y configura SSH automáticamente:

```bash
# Si no existe clave SSH, el script:
1. Genera nueva clave (ed25519)
2. Agrega al ssh-agent
3. Muestra la clave pública para agregar a GitHub

# Agregar clave a GitHub:
# https://github.com/settings/keys
```

#### 3. Estructura Generada

```
mi-proyecto-php/
├── docker/
│   ├── php/
│   │   ├── Dockerfile         # Imagen custom PHP
│   │   ├── php.ini           # Configuración PHP
│   │   ├── xdebug.ini        # Configuración Xdebug
│   │   └── www.conf          # Pool PHP-FPM
│   ├── nginx/
│   │   ├── nginx.conf        # Config principal Nginx
│   │   └── default.conf      # Virtual host config
│   └── mysql/
│       ├── my.cnf            # Config MySQL
│       └── init/
│           └── 01-init.sql   # Script de inicialización
├── src/                       # Código fuente (clonado de GitHub)
│   └── public/               # DocumentRoot
│       └── index.php
├── logs/                      # Logs de servicios
│   ├── php/
│   ├── nginx/
│   └── mysql/
├── backups/                   # Backups automáticos
├── docker-compose.yml         # Orquestación
├── .env                      # Variables de entorno (⚠️ secreto)
├── .gitignore
├── README.md
└── Scripts auxiliares:
    ├── start.sh              # Iniciar ambiente
    ├── stop.sh               # Detener ambiente
    ├── logs.sh               # Ver logs
    ├── composer.sh           # Ejecutar Composer
    ├── php.sh                # Ejecutar PHP
    ├── mysql.sh              # Acceder a MySQL CLI
    └── backup.sh             # Crear backup
```

### Operaciones Diarias

#### Iniciar Ambiente

```bash
cd mi-proyecto-php
./start.sh

# Verificar estado
docker-compose ps

# Salida esperada:
# NAME                     STATUS
# mi-proyecto-php_php      Up (healthy)
# mi-proyecto-php_nginx    Up (healthy)
# mi-proyecto-php_mysql    Up (healthy)
```

#### Detener Ambiente

```bash
./stop.sh

# Detiene todos los contenedores
# Preserva datos en volúmenes
```

#### Ver Logs en Tiempo Real

```bash
# Todos los servicios
./logs.sh

# Servicio específico
./logs.sh php
./logs.sh nginx
./logs.sh mysql

# Últimas N líneas
docker-compose logs --tail=100 php
```

#### Ejecutar Composer

```bash
# Instalar dependencias
./composer.sh install

# Agregar paquete
./composer.sh require guzzlehttp/guzzle

# Actualizar todo
./composer.sh update

# Autoload dump
./composer.sh dump-autoload
```

#### Ejecutar Scripts PHP

```bash
# Ejecutar script
./php.sh src/scripts/migracion.php

# Ejecutar con argumentos
./php.sh -v

# Acceder al contenedor PHP
docker-compose exec php bash
```

#### Acceder a Base de Datos

```bash
# MySQL CLI
./mysql.sh

# Ejecutar query directamente
echo "SELECT * FROM users;" | ./mysql.sh

# PHPMyAdmin (si está habilitado)
# http://localhost:8081
docker-compose --profile tools up -d phpmyadmin
```

### Manejo de Código Fuente

#### Actualizar desde GitHub

```bash
cd src/
git pull origin main
cd ..
./stop.sh
./start.sh
```

#### Commit y Push

```bash
cd src/
git add .
git commit -m "feat: nueva funcionalidad"
git push origin main
```

#### Trabajar con Branches

```bash
cd src/
git checkout -b feature/nueva-funcionalidad
# ... hacer cambios ...
git add .
git commit -m "feat: implementar X"
git push origin feature/nueva-funcionalidad
```

### Backups y Restore

#### Crear Backup

```bash
./backup.sh

# Genera:
# - backups/db_backup_YYYYMMDD_HHMMSS.sql
# - backups/src_backup_YYYYMMDD_HHMMSS.tar.gz
```

#### Restaurar Backup

```bash
# Restaurar base de datos
cat backups/db_backup_20251024_143000.sql | ./mysql.sh

# Restaurar código fuente
tar -xzf backups/src_backup_20251024_143000.tar.gz -C ./
```

#### Backup Automático con Cron

```bash
# Agregar a crontab
crontab -e

# Backup diario a las 2 AM
0 2 * * * cd /path/to/proyecto && ./backup.sh >> logs/backup.log 2>&1

# Backup cada 6 horas
0 */6 * * * cd /path/to/proyecto && ./backup.sh >> logs/backup.log 2>&1
```

---

## ⚡ OPTIMIZACIONES {#optimizaciones}

### Performance de PHP

#### 1. **OPcache Configurado**

```ini
; Mejora significativa en performance
opcache.enable = 1
opcache.memory_consumption = 128      # MB de RAM para opcache
opcache.interned_strings_buffer = 8   # Buffer para strings
opcache.max_accelerated_files = 10000 # Archivos cacheados
opcache.revalidate_freq = 2           # Segundos entre checks
opcache.fast_shutdown = 1             # Shutdown más rápido
```

#### 2. **PHP-FPM Pool Optimizado**

```ini
; www.conf - Proceso Manager
pm = dynamic                    # Gestión dinámica de workers
pm.max_children = 20           # Máximo de procesos hijos
pm.start_servers = 5           # Procesos al iniciar
pm.min_spare_servers = 5       # Mínimo de procesos idle
pm.max_spare_servers = 10      # Máximo de procesos idle
pm.max_requests = 500          # Requests antes de reciclar worker
```

**Cálculo de max_children:**
```
RAM disponible para PHP: 2 GB = 2048 MB
RAM por proceso PHP: ~50 MB (promedio)
max_children = 2048 / 50 = ~40

Usar 20 para dejar margen de seguridad
```

### Performance de MySQL

#### 1. **InnoDB Buffer Pool**

```ini
; El buffer más importante de MySQL
innodb_buffer_pool_size = 256M    # 70% de RAM disponible (ideal)

; Para servidor con 1 GB RAM dedicado a MySQL
innodb_buffer_pool_size = 700M
```

#### 2. **Query Cache** (MySQL < 8.0)

```ini
; Nota: Query cache removido en MySQL 8.0
; Usar Redis/Memcached para cache externo
```

#### 3. **Índices Óptimos**

```sql
-- Ejemplo de índices bien diseñados
CREATE INDEX idx_username ON users(username);
CREATE INDEX idx_email ON users(email);
CREATE INDEX idx_created_at ON users(created_at);

-- Índice compuesto para queries comunes
CREATE INDEX idx_user_status_date ON users(status, created_at);

-- Analizar uso de índices
EXPLAIN SELECT * FROM users WHERE username = 'admin';
```

### Performance de Nginx

#### 1. **Gzip Compression**

```nginx
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css text/xml text/javascript
           application/json application/javascript application/xml+rss;
```

#### 2. **FastCGI Cache**

```nginx
# En nginx.conf (nivel http)
fastcgi_cache_path /var/cache/nginx levels=1:2 
                   keys_zone=phpcache:100m inactive=60m;
fastcgi_cache_key "$scheme$request_method$host$request_uri";

# En default.conf (nivel location ~ \.php$)
fastcgi_cache phpcache;
fastcgi_cache_valid 200 60m;
fastcgi_cache_bypass $http_pragma $http_authorization;
```

#### 3. **Static Files Caching**

```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    access_log off;
}
```

### Monitoreo de Performance

#### Herramientas Incluidas

```bash
# Ver uso de recursos
docker stats

# Logs de queries lentas (MySQL)
docker-compose exec mysql tail -f /var/log/mysql/slow.log

# Profile de PHP con Xdebug
# Usar IDE para generar callgrind
# Analizar con KCacheGrind/QCacheGrind
```

#### Métricas Clave

```
┌─────────────────────────────────────────────────────────┐
│                 MÉTRICAS A MONITOREAR                   │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  PHP-FPM:                                               │
│  ├─ Response time promedio: < 200ms                    │
│  ├─ Procesos idle: 3-5                                 │
│  ├─ Queue length: 0 (ideal)                            │
│  └─ Slow requests: < 1% del total                      │
│                                                          │
│  MySQL:                                                  │
│  ├─ Query time promedio: < 50ms                        │
│  ├─ Conexiones activas: < 50                           │
│  ├─ Slow queries: < 10/min                             │
│  └─ InnoDB buffer pool hit rate: > 99%                 │
│                                                          │
│  Nginx:                                                  │
│  ├─ Request time: < 100ms                              │
│  ├─ Error rate: < 0.1%                                 │
│  ├─ Upstream response time: < 200ms                    │
│  └─ Cache hit rate: > 80%                              │
│                                                          │
│  Sistema:                                                │
│  ├─ CPU usage: < 70%                                   │
│  ├─ Memory usage: < 80%                                │
│  ├─ Disk I/O wait: < 20%                               │
│  └─ Network latency: < 10ms                            │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 TROUBLESHOOTING {#troubleshooting}

### Problemas Comunes

#### 1. Puerto ya en uso

```bash
# Error: port is already allocated

# Solución 1: Cambiar puerto en .env
echo "APP_PORT=8081" >> .env

# Solución 2: Detener servicio usando el puerto
sudo lsof -i :8080
sudo kill -9 <PID>

# Solución 3: Usar puerto diferente temporalmente
APP_PORT=8082 docker-compose up -d
```

#### 2. MySQL no inicia (permisos)

```bash
# Error: mysqld: Can't create/write to file

# Solución: Ajustar permisos del volumen
docker-compose down
sudo chown -R 999:999 $(pwd)/data/mysql
docker-compose up -d
```

#### 3. PHP no puede conectar a MySQL

```bash
# Error: Connection refused

# Verificar que MySQL esté healthy
docker-compose ps mysql

# Verificar variables de entorno
docker-compose exec php env | grep MYSQL

# Verificar conectividad
docker-compose exec php ping mysql

# Reiniciar servicios en orden
docker-compose down
docker-compose up -d mysql
# Esperar 30 segundos
docker-compose up -d
```

#### 4. Xdebug no funciona

```bash
# Verificar que Xdebug esté habilitado
docker-compose exec php php -v | grep Xdebug

# Verificar configuración
docker-compose exec php php -i | grep xdebug

# Ajustar client_host si es necesario
# En .env:
XDEBUG_CONFIG=client_host=192.168.1.100

# Reiniciar PHP
docker-compose restart php
```

#### 5. Composer out of memory

```bash
# Error: Allowed memory size exhausted

# Solución: Aumentar memory_limit temporalmente
./composer.sh -d memory_limit=-1 install

# O en .env:
COMPOSER_MEMORY_LIMIT=-1
```

#### 6. Permisos de archivos (uploads, cache)

```bash
# Error: Permission denied writing to logs/cache

# Solución dentro del contenedor:
docker-compose exec php chmod -R 775 storage/ cache/ logs/
docker-compose exec php chown -R appuser:appuser storage/ cache/

# O desde host (si mounted):
sudo chmod -R 775 src/storage src/cache
sudo chown -R 1000:1000 src/storage src/cache
```

### Comandos de Diagnóstico

```bash
# Estado de contenedores
docker-compose ps

# Logs de todos los servicios
docker-compose logs --tail=100

# Logs de un servicio específico
docker-compose logs -f php

# Ejecutar comando en contenedor
docker-compose exec php bash

# Verificar configuración de docker-compose
docker-compose config

# Listar networks
docker network ls

# Inspeccionar network
docker network inspect mi-proyecto-php_app-network

# Ver uso de recursos
docker stats

# Limpiar todo (⚠️ destruye datos)
docker-compose down -v
```

### Regenerar Ambiente

```bash
# Si algo está muy roto, regenerar todo:

# 1. Backup de datos importantes
./backup.sh

# 2. Limpiar completamente
docker-compose down -v
docker system prune -a --volumes

# 3. Rebuild desde cero
docker-compose build --no-cache
docker-compose up -d

# 4. Restaurar datos
cat backups/db_backup_TIMESTAMP.sql | ./mysql.sh
```

---

## 💡 MEJORES PRÁCTICAS {#mejores-practicas}

### Desarrollo

```yaml
✅ Siempre usar .env para configuración
✅ Commitear .env.example (sin secretos)
✅ Usar feature branches (git flow)
✅ Correr tests antes de commit
✅ Usar pre-commit hooks (husky)
✅ Code review antes de merge
✅ Documentar código (PHPDoc)
✅ Versionado semántico (semantic versioning)
✅ Changelog actualizado (CHANGELOG.md)
```

### Git Workflow

```bash
# Configurar repositorio
git init
git remote add origin git@github.com:usuario/proyecto.git

# Feature branch workflow
git checkout -b feature/nueva-funcionalidad
# ... desarrollo ...
git add .
git commit -m "feat: descripción del cambio"
git push origin feature/nueva-funcionalidad
# ... abrir PR ...

# Hotfix workflow
git checkout -b hotfix/bug-critico
# ... fix ...
git commit -m "fix: resolver bug crítico"
git push origin hotfix/bug-critico
```

### Estructura de Commits

```bash
# Seguir Conventional Commits
feat: nueva funcionalidad
fix: corrección de bug
docs: cambios en documentación
style: formateo de código
refactor: refactorización
test: agregar/modificar tests
chore: tareas de mantenimiento
perf: mejora de performance
```

### Testing

```bash
# Estructura de tests
tests/
├── Unit/           # Tests unitarios
├── Integration/    # Tests de integración
└── E2E/           # Tests end-to-end

# Ejecutar tests
./composer.sh test

# Coverage
./composer.sh test -- --coverage-html coverage/
```

### CI/CD

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build Docker images
        run: docker-compose build
      - name: Run tests
        run: docker-compose run php ./vendor/bin/phpunit
      - name: Security scan
        run: docker scan mi-proyecto-php_php
```

### Documentación

```markdown
# Mantener actualizado:
- README.md (visión general)
- ARCHITECTURE.md (arquitectura técnica)
- API.md (documentación de API)
- CHANGELOG.md (historial de cambios)
- CONTRIBUTING.md (guía de contribución)
```

### Seguridad

```yaml
Código:
├─ Validar TODOS los inputs
├─ Usar prepared statements (PDO)
├─ Escapar outputs (htmlspecialchars)
├─ Implementar CSRF protection
├─ Rate limiting en endpoints críticos
└─ Sanitizar file uploads

Credenciales:
├─ NUNCA hardcodear passwords
├─ Usar .env para secretos
├─ Rotar credenciales periódicamente
└─ Usar secrets manager en producción

Dependencias:
├─ Auditar regularmente (composer audit)
├─ Actualizar librerías (composer update)
├─ Verificar vulnerabilidades conocidas
└─ Usar versiones específicas (semantic)
```

---

## 📞 SOPORTE Y RECURSOS

### Documentación Oficial

- **Docker**: https://docs.docker.com/
- **PHP**: https://www.php.net/manual/
- **MySQL**: https://dev.mysql.com/doc/
- **Nginx**: https://nginx.org/en/docs/
- **Composer**: https://getcomposer.org/doc/

### Herramientas Útiles

```bash
# Linters
composer require --dev phpstan/phpstan
composer require --dev squizlabs/php_codesniffer

# Testing
composer require --dev phpunit/phpunit

# Debugging
composer require symfony/var-dumper

# Performance
composer require --dev phpbench/phpbench
```

### Comunidad

- Stack Overflow: [php] [docker] [mysql]
- Reddit: r/PHP, r/docker
- Discord: PHPCommunity

---

**Documento generado automáticamente**
**Última actualización: 2025-10-24**
