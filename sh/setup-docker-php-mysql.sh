#!/bin/bash

################################################################################
# SCRIPT DE APROVISIONAMIENTO: Ambiente PHP + MySQL + Docker
# Autor: Sistema de Aprovisionamiento Automatizado
# Versión: 2.0.0
# Fecha: 2025-10-24
# Descripción: Configura un ambiente completo de desarrollo con Docker,
#              clonación de repositorio GitHub vía SSH y docker-compose
################################################################################

set -euo pipefail  # Exit on error, undefined variables, pipe failures

################################################################################
# CONFIGURACIÓN Y VARIABLES GLOBALES
################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/setup.log"
readonly ENV_FILE="${SCRIPT_DIR}/.env"
readonly COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"

# Colores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Variables configurables (se pueden override con argumentos)
PROJECT_NAME="${PROJECT_NAME:-mi-proyecto-php}"
GIT_REPO="${GIT_REPO:-}"
GIT_BRANCH="${GIT_BRANCH:-main}"
PHP_VERSION="${PHP_VERSION:-8.3}"
MYSQL_VERSION="${MYSQL_VERSION:-8.0}"
APP_PORT="${APP_PORT:-8080}"
DB_PORT="${DB_PORT:-3306}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_rsa}"

################################################################################
# FUNCIONES DE UTILIDAD
################################################################################

# Log con timestamp
log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Log de error
error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE" >&2
}

# Log de éxito
success() {
    echo -e "${GREEN}[✓]${NC} $*" | tee -a "$LOG_FILE"
}

# Log de advertencia
warning() {
    echo -e "${YELLOW}[!]${NC} $*" | tee -a "$LOG_FILE"
}

# Log de información
info() {
    echo -e "${BLUE}[i]${NC} $*" | tee -a "$LOG_FILE"
}

# Banner del script
print_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🐳 SETUP: Ambiente Docker PHP + MySQL + SSH              ║
║                                                              ║
║   Configuración profesional de desarrollo                   ║
║   con hardening de seguridad                                ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Verificar si comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar prerequisitos
check_prerequisites() {
    info "Verificando prerequisitos del sistema..."
    
    local missing_deps=()
    
    # Verificar Docker
    if ! command_exists docker; then
        missing_deps+=("docker")
    else
        success "Docker encontrado: $(docker --version)"
    fi
    
    # Verificar Docker Compose
    if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
        missing_deps+=("docker-compose")
    else
        success "Docker Compose encontrado"
    fi
    
    # Verificar Git
    if ! command_exists git; then
        missing_deps+=("git")
    else
        success "Git encontrado: $(git --version)"
    fi
    
    # Verificar OpenSSH
    if ! command_exists ssh; then
        missing_deps+=("openssh-client")
    else
        success "SSH encontrado: $(ssh -V 2>&1 | head -n1)"
    fi
    
    # Si faltan dependencias, mostrar error
    if [ ${#missing_deps[@]} -ne 0 ]; then
        error "Faltan las siguientes dependencias:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo ""
        info "Instalar con:"
        echo "  sudo apt update && sudo apt install -y ${missing_deps[*]}"
        exit 1
    fi
    
    success "Todos los prerequisitos están instalados"
}

################################################################################
# CONFIGURACIÓN DE SSH
################################################################################

setup_ssh_key() {
    info "Configurando clave SSH para GitHub..."
    
    # Verificar si existe la clave SSH
    if [ ! -f "$SSH_KEY_PATH" ]; then
        warning "No se encontró clave SSH en: $SSH_KEY_PATH"
        read -p "¿Desea generar una nueva clave SSH? (s/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            read -p "Ingrese su email para la clave SSH: " ssh_email
            ssh-keygen -t ed25519 -C "$ssh_email" -f "$SSH_KEY_PATH" -N ""
            success "Clave SSH generada en: $SSH_KEY_PATH"
            
            # Iniciar ssh-agent y agregar clave
            eval "$(ssh-agent -s)"
            ssh-add "$SSH_KEY_PATH"
            
            info "Clave pública generada:"
            echo -e "${YELLOW}"
            cat "${SSH_KEY_PATH}.pub"
            echo -e "${NC}"
            
            warning "IMPORTANTE: Agregar esta clave pública a GitHub:"
            echo "  1. Ir a: https://github.com/settings/keys"
            echo "  2. Click en 'New SSH key'"
            echo "  3. Pegar la clave pública mostrada arriba"
            echo ""
            read -p "Presione ENTER cuando haya agregado la clave a GitHub..."
        else
            error "Se requiere una clave SSH para continuar"
            exit 1
        fi
    else
        success "Clave SSH encontrada: $SSH_KEY_PATH"
        
        # Verificar si la clave está agregada al ssh-agent
        if ! ssh-add -l | grep -q "$SSH_KEY_PATH"; then
            eval "$(ssh-agent -s)"
            ssh-add "$SSH_KEY_PATH"
        fi
    fi
    
    # Verificar conexión con GitHub
    info "Verificando conexión con GitHub..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        success "Conexión con GitHub exitosa"
    else
        warning "No se pudo verificar la conexión con GitHub"
        warning "Asegúrese de haber agregado la clave SSH a su cuenta"
    fi
}

################################################################################
# CONFIGURACIÓN DEL PROYECTO
################################################################################

prompt_project_config() {
    info "Configuración del proyecto..."
    echo ""
    
    # Nombre del proyecto
    read -p "Nombre del proyecto [$PROJECT_NAME]: " input
    PROJECT_NAME="${input:-$PROJECT_NAME}"
    
    # Repositorio Git
    if [ -z "$GIT_REPO" ]; then
        read -p "URL del repositorio GitHub (SSH): " GIT_REPO
        
        # Validar formato SSH
        if [[ ! "$GIT_REPO" =~ ^git@github\.com:.+\.git$ ]]; then
            warning "La URL debe estar en formato SSH: git@github.com:usuario/repo.git"
            read -p "URL del repositorio GitHub (SSH): " GIT_REPO
        fi
    fi
    
    # Branch
    read -p "Branch a clonar [$GIT_BRANCH]: " input
    GIT_BRANCH="${input:-$GIT_BRANCH}"
    
    # Puerto de la aplicación
    read -p "Puerto para la aplicación PHP [$APP_PORT]: " input
    APP_PORT="${input:-$APP_PORT}"
    
    # Puerto de MySQL
    read -p "Puerto para MySQL [$DB_PORT]: " input
    DB_PORT="${input:-$DB_PORT}"
    
    echo ""
    info "Configuración:"
    echo "  Proyecto: $PROJECT_NAME"
    echo "  Repositorio: $GIT_REPO"
    echo "  Branch: $GIT_BRANCH"
    echo "  Puerto App: $APP_PORT"
    echo "  Puerto DB: $DB_PORT"
    echo ""
    
    read -p "¿Es correcta esta configuración? (S/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        prompt_project_config
    fi
}

################################################################################
# CREACIÓN DE ESTRUCTURA DE DIRECTORIOS
################################################################################

create_directory_structure() {
    info "Creando estructura de directorios..."
    
    local dirs=(
        "$PROJECT_NAME"
        "$PROJECT_NAME/docker"
        "$PROJECT_NAME/docker/php"
        "$PROJECT_NAME/docker/mysql"
        "$PROJECT_NAME/docker/nginx"
        "$PROJECT_NAME/logs"
        "$PROJECT_NAME/data"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            success "Creado: $dir"
        fi
    done
}

################################################################################
# GENERACIÓN DE ARCHIVOS DE CONFIGURACIÓN
################################################################################

generate_env_file() {
    info "Generando archivo .env..."
    
    # Generar passwords aleatorios seguros
    local db_root_pass=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    local db_pass=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    
    cat > "$PROJECT_NAME/.env" << EOF
# ============================================
# Configuración del Ambiente de Desarrollo
# ============================================
# Generado automáticamente: $(date)
# ⚠️  NO COMMITEAR ESTE ARCHIVO A GIT

# === INFORMACIÓN DEL PROYECTO ===
PROJECT_NAME=$PROJECT_NAME
COMPOSE_PROJECT_NAME=$PROJECT_NAME

# === PHP ===
PHP_VERSION=$PHP_VERSION

# === BASE DE DATOS ===
MYSQL_VERSION=$MYSQL_VERSION
MYSQL_HOST=mysql
MYSQL_PORT=$DB_PORT
MYSQL_DATABASE=${PROJECT_NAME//-/_}_db
MYSQL_USER=${PROJECT_NAME//-/_}_user
MYSQL_PASSWORD=$db_pass
MYSQL_ROOT_PASSWORD=$db_root_pass

# === APLICACIÓN ===
APP_ENV=development
APP_DEBUG=true
APP_PORT=$APP_PORT
APP_URL=http://localhost:$APP_PORT

# === TIMEZONE ===
TZ=America/Montevideo

# === XDEBUG (para debugging) ===
XDEBUG_MODE=develop,debug,coverage
XDEBUG_CONFIG=client_host=host.docker.internal

# === COMPOSER ===
COMPOSER_MEMORY_LIMIT=-1
EOF
    
    success "Archivo .env generado"
    warning "⚠️  Passwords generados automáticamente - guardar en lugar seguro"
}

generate_dockerfile() {
    info "Generando Dockerfile optimizado..."
    
    cat > "$PROJECT_NAME/docker/php/Dockerfile" << 'EOF'
# ============================================
# Dockerfile: PHP con extensiones optimizadas
# ============================================
FROM php:8.3-fpm-alpine

LABEL maintainer="DevOps Team"
LABEL description="PHP-FPM optimizado con extensiones necesarias"

# Variables de build
ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_DATE
ARG VCS_REF

# Metadata
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="1.0"

# Instalar dependencias del sistema
RUN apk add --no-cache \
    # Build dependencies
    $PHPIZE_DEPS \
    linux-headers \
    # Runtime dependencies
    bash \
    git \
    curl \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    icu-dev \
    oniguruma-dev \
    libxml2-dev \
    postgresql-dev \
    && rm -rf /var/cache/apk/*

# Configurar extensiones de PHP
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg

# Instalar extensiones de PHP
RUN docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    mysqli \
    zip \
    gd \
    intl \
    mbstring \
    xml \
    opcache \
    exif \
    bcmath

# Instalar Redis
RUN pecl install redis && docker-php-ext-enable redis

# Instalar Xdebug (solo para desarrollo)
RUN pecl install xdebug && docker-php-ext-enable xdebug

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configuración de PHP
COPY php.ini /usr/local/etc/php/conf.d/custom.ini
COPY xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Configuración de PHP-FPM
COPY www.conf /usr/local/etc/php-fpm.d/www.conf

# Usuario no root para seguridad
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

# Directorio de trabajo
WORKDIR /var/www/html

# Permisos
RUN chown -R appuser:appuser /var/www/html

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
    CMD php-fpm -t || exit 1

USER appuser

EXPOSE 9000

CMD ["php-fpm"]
EOF

    success "Dockerfile generado"
}

generate_php_config() {
    info "Generando configuraciones de PHP..."
    
    # php.ini
    cat > "$PROJECT_NAME/docker/php/php.ini" << 'EOF'
[PHP]
; Configuración optimizada para desarrollo

; Errores
display_errors = On
display_startup_errors = On
error_reporting = E_ALL
log_errors = On
error_log = /var/log/php/error.log

; Límites
memory_limit = 256M
max_execution_time = 300
max_input_time = 300
post_max_size = 100M
upload_max_filesize = 100M

; Zona horaria
date.timezone = America/Montevideo

; Opcache (para mejor performance)
opcache.enable = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1

; Seguridad
expose_php = Off
allow_url_fopen = On
allow_url_include = Off

; Sesiones
session.cookie_httponly = 1
session.cookie_secure = 0
session.use_strict_mode = 1
session.cookie_samesite = Lax

; Charset
default_charset = "UTF-8"
EOF

    # xdebug.ini
    cat > "$PROJECT_NAME/docker/php/xdebug.ini" << 'EOF'
[xdebug]
; Configuración de Xdebug 3.x

; Modo
xdebug.mode = develop,debug,coverage

; Cliente
xdebug.client_host = host.docker.internal
xdebug.client_port = 9003

; Inicio
xdebug.start_with_request = yes

; Logs
xdebug.log = /var/log/xdebug.log
xdebug.log_level = 7

; IDE Key
xdebug.idekey = PHPSTORM

; Cobertura
xdebug.coverage_enable = 1
EOF

    # www.conf
    cat > "$PROJECT_NAME/docker/php/www.conf" << 'EOF'
[www]
; Pool de PHP-FPM

user = appuser
group = appuser

listen = 9000

; Process Manager
pm = dynamic
pm.max_children = 20
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 10
pm.max_requests = 500

; Logs
access.log = /var/log/php-fpm/access.log
slowlog = /var/log/php-fpm/slow.log
request_slowlog_timeout = 10s

; Environment
clear_env = no

; Security
php_admin_value[error_log] = /var/log/php-fpm/error.log
php_admin_flag[log_errors] = on
EOF

    success "Configuraciones de PHP generadas"
}

generate_docker_compose() {
    info "Generando docker-compose.yml..."
    
    cat > "$PROJECT_NAME/docker-compose.yml" << 'EOF'
# ============================================
# Docker Compose: PHP + MySQL + Nginx
# ============================================
version: '3.8'

services:
  # ==========================================
  # PHP-FPM Service
  # ==========================================
  php:
    build:
      context: ./docker/php
      args:
        BUILD_DATE: ${BUILD_DATE:-2025-10-24}
        VCS_REF: ${VCS_REF:-dev}
    container_name: ${PROJECT_NAME}_php
    restart: unless-stopped
    working_dir: /var/www/html
    volumes:
      - ./src:/var/www/html:cached
      - ./logs/php:/var/log/php
      - ./logs/php-fpm:/var/log/php-fpm
      - ./docker/php/php.ini:/usr/local/etc/php/conf.d/custom.ini:ro
    environment:
      - PHP_IDE_CONFIG=serverName=Docker
      - XDEBUG_MODE=${XDEBUG_MODE:-off}
      - XDEBUG_CONFIG=${XDEBUG_CONFIG}
    networks:
      - app-network
    depends_on:
      mysql:
        condition: service_healthy

  # ==========================================
  # Nginx Service
  # ==========================================
  nginx:
    image: nginx:alpine
    container_name: ${PROJECT_NAME}_nginx
    restart: unless-stopped
    ports:
      - "${APP_PORT:-8080}:80"
    volumes:
      - ./src:/var/www/html:cached
      - ./docker/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
      - ./logs/nginx:/var/log/nginx
    networks:
      - app-network
    depends_on:
      - php
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # ==========================================
  # MySQL Service
  # ==========================================
  mysql:
    image: mysql:${MYSQL_VERSION:-8.0}
    container_name: ${PROJECT_NAME}_mysql
    restart: unless-stopped
    command: --default-authentication-plugin=mysql_native_password
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      TZ: ${TZ:-America/Montevideo}
    ports:
      - "${DB_PORT:-3306}:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./docker/mysql/init:/docker-entrypoint-initdb.d:ro
      - ./docker/mysql/my.cnf:/etc/mysql/conf.d/custom.cnf:ro
      - ./logs/mysql:/var/log/mysql
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    security_opt:
      - seccomp:unconfined

  # ==========================================
  # PHPMyAdmin (Opcional - solo desarrollo)
  # ==========================================
  phpmyadmin:
    image: phpmyadmin:latest
    container_name: ${PROJECT_NAME}_phpmyadmin
    restart: unless-stopped
    environment:
      PMA_HOST: mysql
      PMA_PORT: 3306
      PMA_ARBITRARY: 1
      UPLOAD_LIMIT: 100M
    ports:
      - "8081:80"
    networks:
      - app-network
    depends_on:
      mysql:
        condition: service_healthy
    profiles:
      - tools

  # ==========================================
  # Redis (Opcional - para caché y sesiones)
  # ==========================================
  redis:
    image: redis:7-alpine
    container_name: ${PROJECT_NAME}_redis
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD:-changeme}
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    profiles:
      - tools

# ==========================================
# Networks
# ==========================================
networks:
  app-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

# ==========================================
# Volumes
# ==========================================
volumes:
  mysql_data:
    driver: local
  redis_data:
    driver: local
EOF

    success "docker-compose.yml generado"
}

generate_nginx_config() {
    info "Generando configuración de Nginx..."
    
    mkdir -p "$PROJECT_NAME/docker/nginx"
    
    # nginx.conf
    cat > "$PROJECT_NAME/docker/nginx/nginx.conf" << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 2048;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss
               application/rss+xml font/truetype font/opentype
               application/vnd.ms-fontobject image/svg+xml;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Include server configs
    include /etc/nginx/conf.d/*.conf;
}
EOF

    # default.conf
    cat > "$PROJECT_NAME/docker/nginx/default.conf" << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /var/www/html/public;
    index index.php index.html index.htm;

    charset utf-8;

    # Logs
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Disable .htaccess and other hidden files
    location ~ /\.(?!well-known).* {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Main location
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # PHP-FPM
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
        
        # Timeouts
        fastcgi_read_timeout 300;
        fastcgi_send_timeout 300;
        
        # Buffer
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 16k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
    }

    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|otf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Deny access to sensitive files
    location ~ /\.(ht|git|env) {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

    success "Configuración de Nginx generada"
}

generate_mysql_config() {
    info "Generando configuración de MySQL..."
    
    mkdir -p "$PROJECT_NAME/docker/mysql/init"
    
    # my.cnf
    cat > "$PROJECT_NAME/docker/mysql/my.cnf" << 'EOF'
[mysqld]
# ============================================
# Configuración optimizada de MySQL
# ============================================

# Configuración general
default-authentication-plugin = mysql_native_password
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
skip-character-set-client-handshake

# InnoDB
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Performance
max_connections = 200
thread_cache_size = 8
table_open_cache = 2000
sort_buffer_size = 2M
read_buffer_size = 1M
read_rnd_buffer_size = 2M
join_buffer_size = 2M

# Query cache (disabled in MySQL 8.0+)
# query_cache_type = 0
# query_cache_size = 0

# Logs
general_log = 0
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
log_queries_not_using_indexes = 1

# Binary log (para replicación y backup)
log_bin = /var/log/mysql/mysql-bin.log
expire_logs_days = 7
max_binlog_size = 100M

# Seguridad
local_infile = 0
symbolic-links = 0

[client]
default-character-set = utf8mb4

[mysql]
default-character-set = utf8mb4
EOF

    # Script de inicialización
    cat > "$PROJECT_NAME/docker/mysql/init/01-init.sql" << 'EOF'
-- ============================================
-- Script de inicialización de la base de datos
-- ============================================

-- Crear usuario con privilegios limitados (si no existe)
-- CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED BY 'secure_password';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON database_name.* TO 'app_user'@'%';
-- FLUSH PRIVILEGES;

-- Crear tablas de ejemplo
CREATE TABLE IF NOT EXISTS `users` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `email` VARCHAR(100) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_username` (`username`),
    INDEX `idx_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertar datos de ejemplo
INSERT INTO `users` (`username`, `email`, `password_hash`) VALUES
    ('admin', 'admin@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
    ('user1', 'user1@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi')
ON DUPLICATE KEY UPDATE `updated_at` = CURRENT_TIMESTAMP;

-- Mensaje de éxito
SELECT 'Base de datos inicializada correctamente' AS message;
EOF

    success "Configuración de MySQL generada"
}

################################################################################
# CLONACIÓN DEL REPOSITORIO
################################################################################

clone_repository() {
    if [ -z "$GIT_REPO" ]; then
        warning "No se especificó repositorio Git, omitiendo clonación..."
        
        # Crear estructura básica
        mkdir -p "$PROJECT_NAME/src/public"
        
        cat > "$PROJECT_NAME/src/public/index.php" << 'EOF'
<?php
/**
 * Archivo de inicio de la aplicación
 */

phpinfo();
EOF
        
        success "Estructura básica creada"
        return 0
    fi
    
    info "Clonando repositorio desde GitHub..."
    
    # Verificar que no exista ya el directorio
    if [ -d "$PROJECT_NAME/src" ]; then
        warning "El directorio src ya existe"
        read -p "¿Desea eliminarlo y volver a clonar? (s/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            rm -rf "$PROJECT_NAME/src"
        else
            warning "Omitiendo clonación..."
            return 0
        fi
    fi
    
    # Clonar repositorio
    if git clone -b "$GIT_BRANCH" "$GIT_REPO" "$PROJECT_NAME/src"; then
        success "Repositorio clonado exitosamente"
        
        # Si no existe public, crearlo
        if [ ! -d "$PROJECT_NAME/src/public" ]; then
            mkdir -p "$PROJECT_NAME/src/public"
            
            cat > "$PROJECT_NAME/src/public/index.php" << 'EOF'
<?php
/**
 * Archivo de inicio de la aplicación
 */

echo "<h1>Ambiente de desarrollo listo!</h1>";
echo "<p>PHP " . phpversion() . "</p>";

// Información de conexión a BD
try {
    $pdo = new PDO(
        "mysql:host=" . getenv('MYSQL_HOST') . ";dbname=" . getenv('MYSQL_DATABASE'),
        getenv('MYSQL_USER'),
        getenv('MYSQL_PASSWORD')
    );
    echo "<p style='color: green;'>✓ Conexión a base de datos exitosa</p>";
} catch (PDOException $e) {
    echo "<p style='color: red;'>✗ Error de conexión: " . $e->getMessage() . "</p>";
}
EOF
        fi
    else
        error "Error al clonar el repositorio"
        error "Verifique:"
        echo "  1. La URL del repositorio es correcta"
        echo "  2. La clave SSH está configurada en GitHub"
        echo "  3. Tiene permisos de acceso al repositorio"
        exit 1
    fi
}

################################################################################
# SCRIPTS AUXILIARES
################################################################################

create_helper_scripts() {
    info "Creando scripts auxiliares..."
    
    # Script para iniciar el ambiente
    cat > "$PROJECT_NAME/start.sh" << 'EOF'
#!/bin/bash
echo "🚀 Iniciando ambiente de desarrollo..."
docker-compose up -d
echo "✅ Ambiente iniciado"
echo ""
echo "URLs disponibles:"
echo "  - Aplicación: http://localhost:${APP_PORT:-8080}"
echo "  - PHPMyAdmin: http://localhost:8081 (perfil: tools)"
echo ""
echo "Para ver logs: docker-compose logs -f"
EOF
    chmod +x "$PROJECT_NAME/start.sh"
    
    # Script para detener el ambiente
    cat > "$PROJECT_NAME/stop.sh" << 'EOF'
#!/bin/bash
echo "🛑 Deteniendo ambiente de desarrollo..."
docker-compose down
echo "✅ Ambiente detenido"
EOF
    chmod +x "$PROJECT_NAME/stop.sh"
    
    # Script para ver logs
    cat > "$PROJECT_NAME/logs.sh" << 'EOF'
#!/bin/bash
SERVICE=${1:-}
if [ -z "$SERVICE" ]; then
    docker-compose logs -f
else
    docker-compose logs -f "$SERVICE"
fi
EOF
    chmod +x "$PROJECT_NAME/logs.sh"
    
    # Script para ejecutar composer
    cat > "$PROJECT_NAME/composer.sh" << 'EOF'
#!/bin/bash
docker-compose exec php composer "$@"
EOF
    chmod +x "$PROJECT_NAME/composer.sh"
    
    # Script para ejecutar comandos en PHP
    cat > "$PROJECT_NAME/php.sh" << 'EOF'
#!/bin/bash
docker-compose exec php php "$@"
EOF
    chmod +x "$PROJECT_NAME/php.sh"
    
    # Script para acceder a MySQL
    cat > "$PROJECT_NAME/mysql.sh" << 'EOF'
#!/bin/bash
source .env
docker-compose exec mysql mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"
EOF
    chmod +x "$PROJECT_NAME/mysql.sh"
    
    # Script de backup
    cat > "$PROJECT_NAME/backup.sh" << 'EOF'
#!/bin/bash
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "📦 Creando backup..."

# Backup de la base de datos
source .env
docker-compose exec -T mysql mysqldump \
    -u"$MYSQL_USER" \
    -p"$MYSQL_PASSWORD" \
    "$MYSQL_DATABASE" \
    > "$BACKUP_DIR/db_backup_$TIMESTAMP.sql"

# Backup del código
tar -czf "$BACKUP_DIR/src_backup_$TIMESTAMP.tar.gz" src/

echo "✅ Backup completado: $BACKUP_DIR"
ls -lh "$BACKUP_DIR/"*"$TIMESTAMP"*
EOF
    chmod +x "$PROJECT_NAME/backup.sh"
    
    success "Scripts auxiliares creados"
}

################################################################################
# DOCUMENTACIÓN
################################################################################

create_documentation() {
    info "Generando documentación..."
    
    cat > "$PROJECT_NAME/README.md" << EOF
# $PROJECT_NAME

Ambiente de desarrollo con Docker, PHP, MySQL y Nginx.

## 🚀 Inicio Rápido

\`\`\`bash
# Iniciar el ambiente
./start.sh

# Detener el ambiente
./stop.sh

# Ver logs
./logs.sh [servicio]
\`\`\`

## 📋 Prerequisitos

- Docker >= 20.10
- Docker Compose >= 2.0
- Git >= 2.30

## 🛠️ Tecnologías

- **PHP**: $PHP_VERSION-FPM
- **MySQL**: $MYSQL_VERSION
- **Nginx**: Alpine (última versión)
- **Redis**: 7-alpine (opcional)

## 🌐 URLs

- Aplicación: http://localhost:$APP_PORT
- PHPMyAdmin: http://localhost:8081 (con perfil tools)

## 📁 Estructura del Proyecto

\`\`\`
$PROJECT_NAME/
├── docker/                # Configuraciones de Docker
│   ├── php/              # Dockerfile y configs de PHP
│   ├── nginx/            # Configuración de Nginx
│   └── mysql/            # Configuración de MySQL
├── src/                  # Código fuente de la aplicación
│   └── public/           # Directorio público (DocumentRoot)
├── logs/                 # Logs de los servicios
├── data/                 # Datos persistentes
├── docker-compose.yml    # Orquestación de servicios
├── .env                  # Variables de entorno
└── *.sh                  # Scripts auxiliares
\`\`\`

## 🔧 Scripts Disponibles

### Gestión del Ambiente

- \`./start.sh\` - Inicia todos los servicios
- \`./stop.sh\` - Detiene todos los servicios
- \`./logs.sh [servicio]\` - Muestra logs

### Desarrollo

- \`./composer.sh [comando]\` - Ejecuta Composer
- \`./php.sh [archivo]\` - Ejecuta scripts PHP
- \`./mysql.sh\` - Accede a MySQL CLI

### Mantenimiento

- \`./backup.sh\` - Crea backup de DB y código

## 🔐 Credenciales

Las credenciales se generan automáticamente en el archivo \`.env\`:

\`\`\`bash
# Ver configuración de base de datos
cat .env | grep MYSQL
\`\`\`

## 🐛 Debug con Xdebug

Xdebug está configurado en el puerto 9003:

1. Configurar IDE con puerto 9003
2. Establecer path mapping: \`./src -> /var/www/html\`
3. IDE Key: \`PHPSTORM\`

## 📦 Composer

\`\`\`bash
# Instalar dependencias
./composer.sh install

# Agregar paquete
./composer.sh require vendor/package

# Actualizar dependencias
./composer.sh update
\`\`\`

## 🗄️ Base de Datos

### Conexión desde la aplicación

\`\`\`php
\$pdo = new PDO(
    "mysql:host=" . getenv('MYSQL_HOST') . ";dbname=" . getenv('MYSQL_DATABASE'),
    getenv('MYSQL_USER'),
    getenv('MYSQL_PASSWORD')
);
\`\`\`

### Acceso directo a MySQL

\`\`\`bash
./mysql.sh
\`\`\`

### Backup y Restore

\`\`\`bash
# Crear backup
./backup.sh

# Restaurar backup
cat backups/db_backup_TIMESTAMP.sql | ./mysql.sh
\`\`\`

## 🔒 Seguridad

### En Desarrollo

- Xdebug habilitado
- Display errors habilitado
- Contraseñas aleatorias generadas

### Para Producción

1. Deshabilitar Xdebug
2. Configurar \`APP_DEBUG=false\`
3. Cambiar todas las contraseñas
4. Configurar SSL/TLS
5. Implementar firewall

## 🧪 Testing

\`\`\`bash
# Ejecutar tests con PHPUnit (si está instalado)
./composer.sh test
\`\`\`

## 📊 Monitoreo

### Logs

\`\`\`bash
# Ver todos los logs
./logs.sh

# Ver logs de un servicio específico
./logs.sh php
./logs.sh nginx
./logs.sh mysql
\`\`\`

### Health Checks

Los servicios tienen health checks configurados:

\`\`\`bash
docker-compose ps
\`\`\`

## 🔄 Actualización

\`\`\`bash
# Actualizar código
cd src/
git pull origin $GIT_BRANCH

# Reiniciar servicios
cd ..
./stop.sh
./start.sh
\`\`\`

## 🐳 Docker Profiles

Servicios opcionales están en perfiles:

\`\`\`bash
# Iniciar con PHPMyAdmin
docker-compose --profile tools up -d

# Iniciar con Redis
docker-compose --profile tools up -d redis
\`\`\`

## 📝 Configuración Adicional

### Variables de Entorno

Editar \`.env\` para cambiar configuraciones:

- Puertos de servicios
- Credenciales de BD
- Configuración de PHP
- Modo de Xdebug

### PHP Configuration

Editar \`docker/php/php.ini\` para ajustes de PHP.

### Nginx Configuration

Editar \`docker/nginx/default.conf\` para configuración del servidor web.

## 🤝 Contribución

1. Fork del proyecto
2. Crear feature branch
3. Commit de cambios
4. Push al branch
5. Crear Pull Request

## 📄 Licencia

Este proyecto es privado.

## 📞 Soporte

Para problemas o preguntas, abrir un issue en el repositorio.

---

**Generado automáticamente por setup-docker-php-mysql.sh**
EOF

    success "Documentación generada"
}

create_gitignore() {
    info "Generando .gitignore..."
    
    cat > "$PROJECT_NAME/.gitignore" << 'EOF'
# ============================================
# Gitignore para proyecto PHP con Docker
# ============================================

# === Archivos de entorno ===
.env
.env.local
.env.*.local

# === Docker ===
docker-compose.override.yml

# === Logs ===
logs/
*.log

# === Datos persistentes ===
data/
backups/

# === Composer ===
/vendor/
composer.lock
composer.phar

# === IDE ===
.idea/
.vscode/
*.swp
*.swo
*~
.DS_Store

# === Sistema Operativo ===
Thumbs.db
.DS_Store
.AppleDouble
.LSOverride

# === PHP ===
*.cache
.php_cs.cache
.phpunit.result.cache

# === Uploads temporales ===
uploads/
tmp/
temp/

# === Node (si se usa) ===
node_modules/
npm-debug.log
yarn-error.log
EOF

    success ".gitignore generado"
}

################################################################################
# VERIFICACIÓN Y TESTING
################################################################################

test_environment() {
    info "Verificando ambiente..."
    
    cd "$PROJECT_NAME" || exit 1
    
    # Build de imágenes
    info "Construyendo imágenes Docker..."
    if docker-compose build; then
        success "Imágenes construidas exitosamente"
    else
        error "Error al construir imágenes"
        exit 1
    fi
    
    # Iniciar servicios
    info "Iniciando servicios..."
    if docker-compose up -d; then
        success "Servicios iniciados"
    else
        error "Error al iniciar servicios"
        exit 1
    fi
    
    # Esperar a que los servicios estén listos
    info "Esperando a que los servicios estén listos..."
    sleep 10
    
    # Verificar estado de servicios
    info "Verificando estado de servicios..."
    docker-compose ps
    
    # Test de conexión HTTP
    info "Testeando conexión HTTP..."
    if curl -f "http://localhost:$APP_PORT" > /dev/null 2>&1; then
        success "Servidor web respondiendo correctamente"
    else
        warning "Servidor web no responde aún (puede tomar unos segundos más)"
    fi
    
    cd - > /dev/null || exit 1
}

################################################################################
# FUNCIÓN PRINCIPAL
################################################################################

main() {
    print_banner
    
    # Verificar prerequisitos
    check_prerequisites
    
    # Configuración interactiva
    prompt_project_config
    
    # Setup SSH
    setup_ssh_key
    
    # Crear estructura
    create_directory_structure
    
    # Generar archivos de configuración
    generate_env_file
    generate_dockerfile
    generate_php_config
    generate_docker_compose
    generate_nginx_config
    generate_mysql_config
    
    # Clonar repositorio
    clone_repository
    
    # Crear scripts y documentación
    create_helper_scripts
    create_documentation
    create_gitignore
    
    # Test del ambiente (opcional)
    echo ""
    read -p "¿Desea iniciar y probar el ambiente ahora? (S/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        test_environment
    fi
    
    # Resumen final
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅  SETUP COMPLETADO EXITOSAMENTE${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo ""
    success "Proyecto: $PROJECT_NAME"
    success "Directorio: $(pwd)/$PROJECT_NAME"
    echo ""
    info "Próximos pasos:"
    echo "  1. cd $PROJECT_NAME"
    echo "  2. ./start.sh"
    echo "  3. Abrir http://localhost:$APP_PORT"
    echo ""
    info "Para más información: cat $PROJECT_NAME/README.md"
    echo ""
}

################################################################################
# EJECUCIÓN
################################################################################

# Trap para cleanup en caso de error
trap 'error "Script interrumpido"; exit 1' INT TERM

# Ejecutar función principal
main "$@"

exit 0
EOF
