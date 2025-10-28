# ✅ CHECKLIST COMPLETO
## Setup, Desarrollo y Deployment

---

## 📋 FASE 1: PREPARACIÓN INICIAL

### Prerequisitos del Sistema
```
[ ] Docker instalado (versión >= 20.10)
    Verificar: docker --version
    
[ ] Docker Compose instalado (versión >= 2.0)
    Verificar: docker-compose --version
    
[ ] Git instalado (versión >= 2.30)
    Verificar: git --version
    
[ ] SSH configurado
    Verificar: ls -la ~/.ssh/
```

### Configuración de GitHub (si vas a clonar repo)
```
[ ] Clave SSH generada
    ssh-keygen -t ed25519 -C "tu-email@example.com"
    
[ ] Clave SSH agregada a ssh-agent
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_rsa
    
[ ] Clave SSH agregada a GitHub
    cat ~/.ssh/id_rsa.pub
    Ir a: https://github.com/settings/keys
    
[ ] Conexión SSH verificada
    ssh -T git@github.com
```

---

## 📋 FASE 2: INSTALACIÓN

### Ejecución del Script
```
[ ] Descargar el boilerplate
    
[ ] Dar permisos de ejecución
    chmod +x setup-docker-php-mysql.sh
    
[ ] Ejecutar script
    ./setup-docker-php-mysql.sh
    
[ ] Proporcionar información cuando se solicite:
    [ ] Nombre del proyecto
    [ ] URL del repositorio (opcional)
    [ ] Branch a clonar
    [ ] Puerto de la aplicación
    [ ] Puerto de MySQL
```

### Verificación Post-Instalación
```
[ ] Directorio del proyecto creado
    ls -la [nombre-proyecto]/
    
[ ] Archivo .env generado
    cat [nombre-proyecto]/.env
    ⚠️ Verificar que NO esté en Git
    
[ ] Archivos Docker generados
    [ ] docker-compose.yml
    [ ] docker/php/Dockerfile
    [ ] docker/nginx/default.conf
    [ ] docker/mysql/my.cnf
    
[ ] Scripts auxiliares creados
    [ ] start.sh
    [ ] stop.sh
    [ ] logs.sh
    [ ] composer.sh
    [ ] php.sh
    [ ] mysql.sh
    [ ] backup.sh
```

---

## 📋 FASE 3: PRIMERA EJECUCIÓN

### Iniciar el Ambiente
```
[ ] Navegar al directorio del proyecto
    cd [nombre-proyecto]
    
[ ] Build de imágenes Docker
    docker-compose build
    ⏱️ Tiempo estimado: 5-10 minutos
    
[ ] Iniciar servicios
    ./start.sh
    o
    docker-compose up -d
    
[ ] Verificar estado de contenedores
    docker-compose ps
    ✓ Todos deben estar "Up (healthy)"
```

### Verificación de Servicios
```
[ ] Nginx respondiendo
    curl http://localhost:8080
    ✓ Debe retornar 200 OK
    
[ ] PHP funcionando
    curl http://localhost:8080 | grep "PHP"
    ✓ Debe mostrar info de PHP
    
[ ] MySQL conectando
    ./mysql.sh -e "SELECT 1"
    ✓ Debe retornar "1"
    
[ ] Logs sin errores críticos
    ./logs.sh | grep -i error
```

---

## 📋 FASE 4: CONFIGURACIÓN DE DESARROLLO

### Configuración del Código
```
[ ] Si clonaste repositorio:
    [ ] Instalar dependencias
        ./composer.sh install
        
    [ ] Copiar .env de la aplicación (si aplica)
        cp src/.env.example src/.env
        
    [ ] Configurar variables de entorno
        nano src/.env
        
    [ ] Migrar base de datos (si aplica)
        ./php.sh artisan migrate
        o
        ./php.sh bin/console doctrine:migrations:migrate

[ ] Si es proyecto nuevo:
    [ ] Inicializar Git
        cd src/
        git init
        
    [ ] Crear .gitignore
        (ya generado automáticamente)
        
    [ ] Primer commit
        git add .
        git commit -m "Initial commit"
```

### Configuración del IDE
```
[ ] Configurar path mappings para Xdebug
    ./src → /var/www/html
    
[ ] Configurar puerto de Xdebug: 9003
    
[ ] Configurar interpretador PHP remoto (opcional)
    Docker → mi-proyecto_php
    
[ ] Instalar extensiones útiles:
    [ ] PHP Intelephense
    [ ] Docker
    [ ] Remote - Containers (VS Code)
```

---

## 📋 FASE 5: SEGURIDAD Y HARDENING

### Verificación de Seguridad
```
[ ] Ejecutar script de seguridad
    chmod +x security-check.sh
    ./security-check.sh
    
[ ] Resolver todos los FAILS marcados en rojo
    
[ ] Revisar WARNINGS en amarillo
    
[ ] Score de seguridad >= 80/100
```

### Configuración de Seguridad Básica
```
[ ] Cambiar passwords default (si las hay)
    nano .env
    Buscar: changeme, password, 123456
    
[ ] Verificar permisos de .env
    chmod 600 .env
    
[ ] Verificar que .env NO esté en Git
    git ls-files --error-unmatch .env
    ✓ Debe dar error (eso es bueno)
    
[ ] Configurar .gitignore
    ✓ Ya generado automáticamente
```

### Hardening Adicional (Recomendado)
```
[ ] Cambiar puertos default (opcional)
    nano .env
    APP_PORT=8081  # En lugar de 8080
    DB_PORT=33061  # En lugar de 3306
    
[ ] Deshabilitar PHPMyAdmin en producción
    docker-compose down phpmyadmin
    
[ ] Configurar rate limiting (aplicación)
    (Ver EJEMPLOS_USO.md)
    
[ ] Implementar CSRF protection
    (Ver EJEMPLOS_USO.md)
```

---

## 📋 FASE 6: DESARROLLO ACTIVO

### Workflow Diario
```
[ ] Iniciar ambiente al comenzar el día
    ./start.sh
    
[ ] Verificar que todo esté up
    docker-compose ps
    
[ ] Ver logs si hay problemas
    ./logs.sh
    
[ ] Instalar dependencias cuando sea necesario
    ./composer.sh require vendor/package
    
[ ] Ejecutar tests regularmente
    ./composer.sh test
    
[ ] Crear backup antes de cambios grandes
    ./backup.sh
    
[ ] Detener ambiente al terminar el día
    ./stop.sh
```

### Git Workflow
```
[ ] Crear feature branch
    git checkout -b feature/nueva-funcionalidad
    
[ ] Hacer commits frecuentes y descriptivos
    git commit -m "feat: descripción del cambio"
    
[ ] Push al repositorio
    git push origin feature/nueva-funcionalidad
    
[ ] Crear Pull Request
    (En GitHub)
    
[ ] Code review
    
[ ] Merge a main/develop
```

---

## 📋 FASE 7: TESTING Y QA

### Tests
```
[ ] Configurar PHPUnit
    ./composer.sh require --dev phpunit/phpunit
    
[ ] Escribir tests
    mkdir -p src/tests
    
[ ] Ejecutar tests
    ./composer.sh test
    
[ ] Code coverage
    ./composer.sh test -- --coverage-html coverage/
    
[ ] Coverage >= 70%
```

### Quality Assurance
```
[ ] Linting
    ./composer.sh require --dev phpstan/phpstan
    ./composer.sh phpstan analyze src/
    
[ ] Code style
    ./composer.sh require --dev squizlabs/php_codesniffer
    ./composer.sh phpcs src/
    
[ ] Security audit
    ./composer.sh audit
```

---

## 📋 FASE 8: PRE-DEPLOYMENT

### Preparación para Producción
```
[ ] Ejecutar todos los tests
    ./composer.sh test
    ✓ Todos pasando
    
[ ] Verificar configuración de producción
    [ ] APP_ENV=production en .env
    [ ] APP_DEBUG=false en .env
    [ ] XDEBUG_MODE=off en .env
    
[ ] Optimizar autoloader
    ./composer.sh dump-autoload --optimize
    
[ ] Crear backup final de desarrollo
    ./backup.sh
    
[ ] Ejecutar security check
    ./security-check.sh
    ✓ Score >= 90/100 para producción
```

### Configuración de SSL/HTTPS
```
[ ] Obtener certificado SSL
    Opción 1: Let's Encrypt (gratis)
    Opción 2: Certificado comercial
    
[ ] Configurar Nginx para HTTPS
    nano docker/nginx/default.conf
    (Ver EJEMPLOS_USO.md#ejemplo-8)
    
[ ] Forzar redirección HTTP → HTTPS
    
[ ] Habilitar session.cookie_secure en PHP
    nano docker/php/php.ini
    session.cookie_secure = 1
```

---

## 📋 FASE 9: DEPLOYMENT

### Deploy a Servidor
```
[ ] Servidor preparado
    [ ] Docker instalado
    [ ] Docker Compose instalado
    [ ] Firewall configurado
    [ ] SSH configurado
    
[ ] Clonar repositorio en servidor
    git clone git@github.com:usuario/proyecto.git
    
[ ] Copiar .env de producción
    cp .env.example .env
    nano .env
    (Configurar para producción)
    
[ ] Build y start
    docker-compose build --no-cache
    docker-compose up -d
    
[ ] Verificar servicios
    docker-compose ps
    ✓ Todos healthy
```

### Configuración Post-Deployment
```
[ ] Verificar acceso web
    curl https://tudominio.com
    
[ ] Probar endpoints críticos
    
[ ] Verificar logs
    ./logs.sh
    
[ ] Configurar backup automático
    crontab -e
    0 2 * * * cd /path/to/proyecto && ./backup.sh
    
[ ] Configurar monitoring (opcional)
    [ ] Prometheus
    [ ] Grafana
    [ ] Alertas
```

---

## 📋 FASE 10: POST-DEPLOYMENT

### Monitoreo
```
[ ] Verificar logs diariamente
    ./logs.sh
    
[ ] Monitorear uso de recursos
    docker stats
    
[ ] Revisar slow queries MySQL
    cat logs/mysql/slow.log
    
[ ] Verificar espacio en disco
    df -h
```

### Mantenimiento
```
[ ] Backups funcionando
    ls -la backups/
    ✓ Archivos nuevos diariamente
    
[ ] Actualizar dependencias regularmente
    ./composer.sh update
    
[ ] Actualizar imágenes Docker
    docker-compose pull
    docker-compose up -d --build
    
[ ] Renovar certificados SSL (cada 90 días)
    certbot renew
```

### Optimización Continua
```
[ ] Analizar performance
    [ ] Queries lentas en MySQL
    [ ] Endpoints lentos en aplicación
    [ ] Uso de memoria
    
[ ] Optimizar código identificado
    
[ ] Implementar caché donde sea necesario
    [ ] Redis para sesiones
    [ ] OPcache ya configurado
    [ ] Browser caching
    
[ ] Scaling horizontal (si es necesario)
    [ ] Load balancer
    [ ] Múltiples instancias de PHP
    [ ] Read replicas de MySQL
```

---

## 📋 TROUBLESHOOTING RÁPIDO

### Problemas Comunes y Soluciones
```
❌ Puerto ya en uso
✅ Cambiar puerto en .env o detener servicio:
   sudo lsof -i :8080
   sudo kill -9 <PID>

❌ MySQL no inicia
✅ Verificar permisos:
   sudo chown -R 999:999 data/mysql
   docker-compose restart mysql

❌ PHP no conecta a MySQL
✅ Verificar .env y reiniciar:
   cat .env | grep MYSQL
   docker-compose restart php

❌ 502 Bad Gateway
✅ PHP no está respondiendo:
   docker-compose logs php
   docker-compose restart php

❌ Permisos negados
✅ Ajustar permisos:
   sudo chmod -R 775 src/storage
   sudo chown -R 1000:1000 src/storage
```

---

## 🎯 RESUMEN EJECUTIVO

### Tiempo Estimado por Fase

```
Fase 1: Preparación        → 15 minutos
Fase 2: Instalación        → 10 minutos
Fase 3: Primera Ejecución  → 15 minutos
Fase 4: Configuración      → 30 minutos
Fase 5: Seguridad          → 20 minutos
Fase 6: Desarrollo         → Continuo
Fase 7: Testing            → 2 horas
Fase 8: Pre-Deployment     → 1 hora
Fase 9: Deployment         → 30 minutos
Fase 10: Post-Deployment   → Continuo

Total Setup Inicial: ~2 horas
```

### Prioridades

```
🔴 CRÍTICO (hacer inmediatamente):
- Fase 1, 2, 3: Setup básico
- Fase 5: Seguridad básica
- Fase 9: Deployment (cuando estés listo)

🟡 IMPORTANTE (hacer pronto):
- Fase 4: Configuración completa
- Fase 7: Tests
- Fase 8: Pre-deployment checks

🟢 RECOMENDADO (hacer cuando sea posible):
- Fase 5: Hardening adicional
- Fase 10: Optimización continua
```

---

## ✅ CHECKLIST MÍNIMO PARA PRODUCCIÓN

```
[ ] Setup completado exitosamente
[ ] Seguridad verificada (security-check.sh pasando)
[ ] Tests escritos y pasando
[ ] SSL/HTTPS configurado
[ ] Backups automáticos configurados
[ ] Monitoring básico implementado
[ ] Documentación actualizada
[ ] Variables de producción configuradas
[ ] Deploy exitoso verificado
[ ] Plan de rollback definido
```

---

**¡Felicitaciones!** 🎉

Si completaste este checklist, tienes un ambiente de desarrollo
profesional, seguro y listo para producción.

---

**Última actualización:** 2025-10-24
**Versión del checklist:** 2.0.0
