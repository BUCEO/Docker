# 🐳 Boilerplate Profesional: PHP + MySQL + Docker + SSH

[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg)](https://www.docker.com/)
[![PHP](https://img.shields.io/badge/PHP-8.3-purple.svg)](https://www.php.net/)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-orange.svg)](https://www.mysql.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> Setup completo y automatizado de ambiente de desarrollo con Docker, incluyendo clonación de repositorio GitHub vía SSH, configuración optimizada y hardening de seguridad.

---

## 📦 ¿QUÉ INCLUYE ESTE BOILERPLATE?

### ✨ Características Principales

- **🚀 Setup Automatizado**: Script interactivo que configura todo en minutos
- **🐳 Docker Compose**: Orquestación completa de servicios
- **🔐 Seguridad Hardening**: Configuraciones de seguridad implementadas
- **📊 Optimizado**: Configuraciones de performance para PHP, MySQL y Nginx
- **🔧 Scripts Auxiliares**: Comandos útiles para desarrollo diario
- **📚 Documentación Completa**: Guías detalladas y ejemplos prácticos
- **🔍 Security Audit**: Script de verificación de seguridad incluido
- **🗄️ Backups Automatizados**: Sistema de respaldo integrado

### 🛠️ Stack Tecnológico

```
┌─────────────────────────────────────────┐
│  Nginx Alpine (Reverse Proxy)          │
│  ↓                                      │
│  PHP 8.3 FPM (Alpine)                  │
│  ├─ Xdebug (Debugging)                 │
│  ├─ Composer (Dependencies)            │
│  └─ Extensiones optimizadas            │
│  ↓                                      │
│  MySQL 8.0 (Base de Datos)             │
│  └─ PHPMyAdmin (opcional)              │
│  ↓                                      │
│  Redis 7 (Cache - opcional)            │
└─────────────────────────────────────────┘
```

---

## 🚀 INICIO RÁPIDO

### Prerequisitos

```bash
✓ Docker >= 20.10
✓ Docker Compose >= 2.0
✓ Git >= 2.30
✓ SSH configurado (para GitHub)
```

### Instalación en 3 Pasos

```bash
# 1. Dar permisos de ejecución
chmod +x setup-docker-php-mysql.sh

# 2. Ejecutar el script
./setup-docker-php-mysql.sh

# 3. Iniciar el ambiente (después del setup)
cd mi-proyecto
./start.sh
```

### Verificación

```bash
# Verificar que todo funcione
curl http://localhost:8080

# Ver estado de servicios
docker-compose ps

# Ver logs
./logs.sh
```

---

## 📁 ESTRUCTURA DEL PROYECTO

Después del setup, obtendrás esta estructura:

```
mi-proyecto/
├── 📄 docker-compose.yml       # Orquestación de servicios
├── 📄 .env                     # Variables de entorno (⚠️ NO COMMITEAR)
├── 📄 .gitignore               # Archivos ignorados por Git
├── 📖 README.md                # Documentación del proyecto
│
├── 🐳 docker/                  # Configuraciones Docker
│   ├── php/
│   │   ├── Dockerfile          # Imagen custom PHP
│   │   ├── php.ini            # Config PHP
│   │   ├── xdebug.ini         # Config Xdebug
│   │   └── www.conf           # Pool PHP-FPM
│   ├── nginx/
│   │   ├── nginx.conf         # Config principal
│   │   └── default.conf       # Virtual host
│   └── mysql/
│       ├── my.cnf             # Config MySQL
│       └── init/
│           └── 01-init.sql    # Script inicial
│
├── 💻 src/                     # Código fuente (tu aplicación)
│   └── public/                # DocumentRoot
│       └── index.php
│
├── 📊 logs/                    # Logs de servicios
│   ├── php/
│   ├── nginx/
│   └── mysql/
│
├── 💾 backups/                 # Respaldos automáticos
│
└── 🔧 Scripts auxiliares
    ├── start.sh               # Iniciar ambiente
    ├── stop.sh                # Detener ambiente
    ├── logs.sh                # Ver logs
    ├── composer.sh            # Ejecutar Composer
    ├── php.sh                 # Ejecutar PHP
    ├── mysql.sh               # MySQL CLI
    └── backup.sh              # Crear backup
```

---

## 📖 DOCUMENTACIÓN

Este boilerplate incluye documentación completa:

### 📚 Archivos de Documentación

| Archivo | Descripción |
|---------|-------------|
| **README.md** | Este archivo - Visión general |
| **DOCUMENTACION_TECNICA.md** | Arquitectura, seguridad, optimizaciones |
| **EJEMPLOS_USO.md** | Casos de uso prácticos y ejemplos |
| **SECURITY_GUIDE.md** | Guía de seguridad y hardening |

### 🎯 Quick Links

- [📐 Arquitectura del Sistema](DOCUMENTACION_TECNICA.md#arquitectura)
- [🔒 Guía de Seguridad](DOCUMENTACION_TECNICA.md#seguridad)
- [⚡ Optimizaciones](DOCUMENTACION_TECNICA.md#optimizaciones)
- [🔧 Troubleshooting](DOCUMENTACION_TECNICA.md#troubleshooting)
- [💡 Mejores Prácticas](DOCUMENTACION_TECNICA.md#mejores-practicas)
- [🎓 Ejemplos Prácticos](EJEMPLOS_USO.md)

---

## 🎮 USO BÁSICO

### Comandos Esenciales

```bash
# Iniciar todos los servicios
./start.sh

# Detener todos los servicios
./stop.sh

# Ver logs en tiempo real
./logs.sh
./logs.sh php    # Solo de PHP
./logs.sh nginx  # Solo de Nginx

# Ejecutar Composer
./composer.sh install
./composer.sh require vendor/package

# Ejecutar scripts PHP
./php.sh script.php

# Acceder a MySQL
./mysql.sh

# Crear backup
./backup.sh
```

### Acceso a URLs

```bash
# Aplicación web
http://localhost:8080

# PHPMyAdmin (si habilitado)
http://localhost:8081

# MySQL directo
mysql -h localhost -P 3306 -u [usuario] -p
```

---

## 🔐 SEGURIDAD

### ✅ Medidas Implementadas

- ✓ Usuario no-root en contenedores
- ✓ Red Docker aislada
- ✓ Credenciales generadas aleatoriamente
- ✓ Security headers en Nginx
- ✓ PHP hardening (expose_php=Off, etc.)
- ✓ MySQL hardening (local_infile=0, etc.)
- ✓ Xdebug solo en desarrollo
- ✓ Health checks configurados

### 🔍 Verificación de Seguridad

Incluye un script de auditoría de seguridad:

```bash
chmod +x security-check.sh
./security-check.sh
```

Esto verificará:
- Configuraciones de seguridad
- Permisos de archivos
- Contraseñas débiles
- Configuración de SSL/TLS
- Y más...

### ⚠️ Checklist para Producción

Antes de llevar a producción, asegúrate de:

```
[ ] Cambiar TODAS las contraseñas
[ ] Configurar HTTPS/SSL
[ ] Deshabilitar Xdebug
[ ] APP_DEBUG=false
[ ] Configurar firewall
[ ] Implementar backups automáticos
[ ] Configurar monitoring
[ ] Ejecutar security-check.sh
```

---

## ⚡ PERFORMANCE

### Optimizaciones Incluidas

#### PHP
- ✓ OPcache habilitado y configurado
- ✓ PHP-FPM con dynamic process manager
- ✓ Memory limits optimizados
- ✓ Timeouts ajustados

#### MySQL
- ✓ InnoDB buffer pool optimizado
- ✓ Query logging para debugging
- ✓ Índices sugeridos en schema inicial

#### Nginx
- ✓ Gzip compression habilitado
- ✓ Static file caching
- ✓ FastCGI buffering optimizado
- ✓ Keepalive connections

---

## 🧪 DESARROLLO

### Debugging con Xdebug

Xdebug está preconfigurado en el puerto 9003:

```bash
# 1. Verificar que esté activo
docker-compose exec php php -v | grep Xdebug

# 2. Configurar IDE
# Puerto: 9003
# Path mapping: ./src -> /var/www/html

# 3. Agregar breakpoint y empezar a debuggear!
```

### Testing

```bash
# Instalar PHPUnit
./composer.sh require --dev phpunit/phpunit

# Ejecutar tests
./composer.sh test
```

### Linting

```bash
# Instalar PHP_CodeSniffer
./composer.sh require --dev squizlabs/php_codesniffer

# Ejecutar linter
./composer.sh phpcs src/
```

---

## 🔄 INTEGRACIÓN CON FRAMEWORKS

Compatible con cualquier framework PHP:

- ✅ **Laravel** - [Ver ejemplo](EJEMPLOS_USO.md#ejemplo-3)
- ✅ **Symfony** - [Ver ejemplo](EJEMPLOS_USO.md#ejemplo-4)
- ✅ **CodeIgniter** - [Ver ejemplo](EJEMPLOS_USO.md#ejemplo-15)
- ✅ **WordPress** - [Ver ejemplo](EJEMPLOS_USO.md#ejemplo-14)
- ✅ **API REST Custom** - [Ver ejemplo](EJEMPLOS_USO.md#ejemplo-5)

---

## 📊 MONITOREO

### Logs Disponibles

```bash
# Logs agregados en tiempo real
./logs.sh

# Logs históricos
ls -la logs/

logs/
├── php/
│   ├── error.log
│   └── access.log
├── nginx/
│   ├── error.log
│   └── access.log
└── mysql/
    ├── error.log
    └── slow.log
```

### Métricas

```bash
# Ver uso de recursos
docker stats

# Inspeccionar contenedor específico
docker stats mi-proyecto_php
```

---

## 💾 BACKUPS

### Backup Manual

```bash
# Crear backup ahora
./backup.sh

# Se crearán:
# - backups/db_backup_TIMESTAMP.sql
# - backups/src_backup_TIMESTAMP.tar.gz
```

### Backup Automático

```bash
# Configurar crontab para backup diario a las 2 AM
crontab -e

# Agregar:
0 2 * * * cd /path/to/proyecto && ./backup.sh >> logs/backup.log 2>&1
```

### Restore

```bash
# Restaurar base de datos
cat backups/db_backup_20251024_120000.sql | ./mysql.sh

# Restaurar código
tar -xzf backups/src_backup_20251024_120000.tar.gz
```

---

## 🚀 DEPLOYMENT

### Environments Soportados

- ✅ VPS/Servidor Dedicado
- ✅ AWS EC2
- ✅ DigitalOcean Droplets
- ✅ Google Cloud Compute
- ✅ Docker Swarm
- ✅ Kubernetes (con adaptaciones)

### CI/CD

Ejemplos de integración con:
- GitHub Actions
- GitLab CI
- Jenkins
- CircleCI

[Ver ejemplos de deployment](EJEMPLOS_USO.md#ejemplos-deployment)

---

## 🤝 CONTRIBUTING

¡Las contribuciones son bienvenidas!

1. Fork del proyecto
2. Crear feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit de cambios (`git commit -m 'Add AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

---

## 📝 CHANGELOG

### Version 2.0.0 (2025-10-24)

#### ✨ Features
- Setup automatizado completo con script Bash
- Clonación de repositorio GitHub con SSH
- Configuración optimizada de PHP 8.3, MySQL 8.0, Nginx
- Hardening de seguridad implementado
- Scripts auxiliares para operaciones comunes
- Sistema de backups automatizado
- Health checks configurados
- Documentación completa

#### 🔐 Security
- Usuario no-root en contenedores
- Credenciales generadas aleatoriamente
- Security headers en Nginx
- PHP y MySQL hardening
- Script de auditoría de seguridad

#### ⚡ Performance
- OPcache habilitado
- InnoDB optimizado
- Gzip compression
- Static file caching

---

## 📄 LICENCIA

Este proyecto está bajo la licencia MIT. Ver archivo `LICENSE` para más detalles.

---

## 🆘 SOPORTE

### ¿Problemas?

1. Revisar [Troubleshooting](DOCUMENTACION_TECNICA.md#troubleshooting)
2. Ejecutar `./security-check.sh` para diagnóstico
3. Ver logs: `./logs.sh`
4. Abrir un issue en GitHub

### ¿Preguntas?

- 📖 Lee la [Documentación Técnica](DOCUMENTACION_TECNICA.md)
- 🎓 Revisa los [Ejemplos de Uso](EJEMPLOS_USO.md)
- 💬 Abre una discusión en GitHub

---

## 🌟 CARACTERÍSTICAS DESTACADAS

### Para Desarrolladores

```yaml
✓ Setup en < 5 minutos
✓ Hot reload (volúmenes montados)
✓ Xdebug preconfigurado
✓ Composer integrado
✓ PHPMyAdmin opcional
✓ Redis opcional para cache
```

### Para DevOps

```yaml
✓ Configuraciones optimizadas
✓ Health checks incluidos
✓ Logs centralizados
✓ Backups automatizables
✓ Fácil escalabilidad
✓ CI/CD ready
```

### Para Security

```yaml
✓ Hardening implementado
✓ Audit script incluido
✓ Secrets management
✓ Isolated network
✓ Non-root users
✓ Security headers
```

---

## 🎯 CASOS DE USO

Este boilerplate es perfecto para:

- 🚀 **Proyectos nuevos**: Setup rápido y profesional
- 🔄 **Migración a Docker**: Containerizar apps existentes
- 📚 **Aprendizaje**: Entender Docker y best practices
- 🏢 **Desarrollo de equipos**: Ambiente consistente para todos
- 🧪 **Testing**: Ambiente aislado para pruebas
- 📦 **Deployment**: Base sólida para producción

---

## 📞 CONTACTO Y RECURSOS

### Links Útiles

- 🌐 [Documentación de Docker](https://docs.docker.com/)
- 📘 [PHP Manual](https://www.php.net/manual/)
- 🗄️ [MySQL Docs](https://dev.mysql.com/doc/)
- 🌍 [Nginx Docs](https://nginx.org/en/docs/)

### Autor

Creado con ❤️ para la comunidad de desarrolladores PHP

---

## ⭐ AGRADECIMIENTOS

Gracias a la comunidad de código abierto por las herramientas increíbles:

- Docker & Docker Compose
- PHP & Xdebug
- MySQL
- Nginx
- Y todos los contribuidores

---

<div align="center">

**¿Te fue útil este boilerplate?** ⭐ Dale una estrella al repositorio!

Made with ☕ and 💻

</div>
