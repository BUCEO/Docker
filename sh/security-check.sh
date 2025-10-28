#!/bin/bash

################################################################################
# SCRIPT DE VERIFICACIÓN DE SEGURIDAD
# Verifica el hardening y configuración de seguridad del ambiente
################################################################################

set -euo pipefail

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Banner
print_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🔒 SECURITY AUDIT & HARDENING CHECK                    ║
║                                                           ║
║   Verificación de configuración de seguridad             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Funciones de log
pass() {
    echo -e "${GREEN}[✓ PASS]${NC} $*"
    ((CHECKS_PASSED++))
}

fail() {
    echo -e "${RED}[✗ FAIL]${NC} $*"
    ((CHECKS_FAILED++))
}

warn() {
    echo -e "${YELLOW}[! WARN]${NC} $*"
    ((CHECKS_WARNING++))
}

info() {
    echo -e "${BLUE}[i INFO]${NC} $*"
}

section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$*${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

################################################################################
# VERIFICACIONES
################################################################################

check_env_file() {
    section "1. VERIFICACIÓN DE ARCHIVO .ENV"
    
    if [ ! -f ".env" ]; then
        fail "Archivo .env no encontrado"
        return 1
    fi
    pass "Archivo .env existe"
    
    # Verificar permisos
    local perms=$(stat -c "%a" .env 2>/dev/null || stat -f "%A" .env 2>/dev/null)
    if [ "$perms" != "600" ] && [ "$perms" != "400" ]; then
        fail "Permisos de .env inseguros: $perms (debería ser 600)"
    else
        pass "Permisos de .env correctos: $perms"
    fi
    
    # Verificar que no esté en git
    if git ls-files --error-unmatch .env >/dev/null 2>&1; then
        fail ".env está trackeado en Git (PELIGRO: credenciales expuestas)"
    else
        pass ".env no está en Git"
    fi
    
    # Verificar contraseñas default
    if grep -q "changeme\|password\|123456\|admin" .env; then
        fail "Se encontraron contraseñas default en .env"
    else
        pass "No se encontraron contraseñas default"
    fi
}

check_php_security() {
    section "2. VERIFICACIÓN DE SEGURIDAD PHP"
    
    if [ ! -f "docker/php/php.ini" ]; then
        warn "Archivo php.ini no encontrado"
        return 1
    fi
    
    # expose_php
    if grep -q "expose_php = Off" docker/php/php.ini; then
        pass "expose_php está deshabilitado"
    else
        fail "expose_php debería estar Off"
    fi
    
    # allow_url_include
    if grep -q "allow_url_include = Off" docker/php/php.ini; then
        pass "allow_url_include está deshabilitado"
    else
        fail "allow_url_include debería estar Off"
    fi
    
    # session.cookie_httponly
    if grep -q "session.cookie_httponly = 1" docker/php/php.ini; then
        pass "session.cookie_httponly está habilitado"
    else
        fail "session.cookie_httponly debería estar en 1"
    fi
    
    # display_errors (en producción)
    if grep -q "APP_ENV=production" .env; then
        if grep -q "display_errors = Off" docker/php/php.ini; then
            pass "display_errors Off (producción)"
        else
            fail "display_errors debería estar Off en producción"
        fi
    else
        info "display_errors On (desarrollo - OK)"
    fi
}

check_mysql_security() {
    section "3. VERIFICACIÓN DE SEGURIDAD MYSQL"
    
    if [ ! -f "docker/mysql/my.cnf" ]; then
        warn "Archivo my.cnf no encontrado"
        return 1
    fi
    
    # local_infile
    if grep -q "local_infile = 0" docker/mysql/my.cnf; then
        pass "local_infile está deshabilitado"
    else
        fail "local_infile debería estar en 0"
    fi
    
    # symbolic-links
    if grep -q "symbolic-links = 0" docker/mysql/my.cnf; then
        pass "symbolic-links deshabilitado"
    else
        fail "symbolic-links debería estar en 0"
    fi
    
    # Verificar contraseñas en .env
    source .env 2>/dev/null || true
    
    if [ ${#MYSQL_ROOT_PASSWORD} -lt 20 ]; then
        fail "MYSQL_ROOT_PASSWORD muy corta (mínimo 20 caracteres)"
    else
        pass "MYSQL_ROOT_PASSWORD tiene longitud adecuada"
    fi
    
    if [ ${#MYSQL_PASSWORD} -lt 20 ]; then
        fail "MYSQL_PASSWORD muy corta (mínimo 20 caracteres)"
    else
        pass "MYSQL_PASSWORD tiene longitud adecuada"
    fi
}

check_nginx_security() {
    section "4. VERIFICACIÓN DE SEGURIDAD NGINX"
    
    if [ ! -f "docker/nginx/default.conf" ]; then
        warn "Archivo default.conf no encontrado"
        return 1
    fi
    
    # Security headers
    local headers=(
        "X-Frame-Options"
        "X-Content-Type-Options"
        "X-XSS-Protection"
    )
    
    for header in "${headers[@]}"; do
        if grep -q "$header" docker/nginx/default.conf; then
            pass "Header $header configurado"
        else
            fail "Header $header no encontrado"
        fi
    done
    
    # Protección de archivos sensibles
    if grep -q "location ~ /\\\\..*{" docker/nginx/default.conf; then
        pass "Protección de archivos ocultos configurada"
    else
        fail "Falta protección de archivos ocultos (.env, .git)"
    fi
}

check_docker_security() {
    section "5. VERIFICACIÓN DE SEGURIDAD DOCKER"
    
    if [ ! -f "docker-compose.yml" ]; then
        fail "docker-compose.yml no encontrado"
        return 1
    fi
    
    # Verificar user no-root en PHP
    if grep -q "USER appuser" docker/php/Dockerfile 2>/dev/null; then
        pass "PHP corre con usuario no-root"
    else
        fail "PHP debería correr con usuario no-root"
    fi
    
    # Verificar health checks
    if grep -q "healthcheck:" docker-compose.yml; then
        pass "Health checks configurados"
    else
        warn "No se encontraron health checks"
    fi
    
    # Verificar restart policy
    if grep -q "restart: unless-stopped" docker-compose.yml; then
        pass "Restart policy configurado"
    else
        warn "Restart policy no configurado"
    fi
    
    # Verificar uso de secrets (ideal para producción)
    if grep -q "secrets:" docker-compose.yml; then
        pass "Docker secrets en uso"
    else
        warn "Considerar usar Docker secrets en producción"
    fi
}

check_ssl_configuration() {
    section "6. VERIFICACIÓN SSL/TLS"
    
    source .env 2>/dev/null || true
    
    if [ "$APP_ENV" = "production" ]; then
        if grep -q "ssl_certificate" docker/nginx/default.conf 2>/dev/null; then
            pass "SSL configurado"
        else
            fail "SSL no configurado (REQUERIDO en producción)"
        fi
        
        if grep -q "session.cookie_secure = 1" docker/php/php.ini; then
            pass "session.cookie_secure habilitado"
        else
            fail "session.cookie_secure debería estar en 1 (producción)"
        fi
    else
        info "SSL no requerido en desarrollo"
    fi
}

check_backups() {
    section "7. VERIFICACIÓN DE BACKUPS"
    
    if [ -f "backup.sh" ]; then
        pass "Script de backup existe"
        
        if [ -x "backup.sh" ]; then
            pass "Script de backup es ejecutable"
        else
            warn "Script de backup no es ejecutable"
        fi
    else
        fail "Script de backup no encontrado"
    fi
    
    if [ -d "backups" ]; then
        local backup_count=$(find backups -name "*.sql" 2>/dev/null | wc -l)
        if [ "$backup_count" -gt 0 ]; then
            pass "Se encontraron $backup_count backups"
        else
            warn "No se encontraron backups"
        fi
    else
        warn "Directorio de backups no existe"
    fi
    
    # Verificar crontab (si existe)
    if crontab -l 2>/dev/null | grep -q "backup.sh"; then
        pass "Backup automático configurado en crontab"
    else
        warn "Backup automático no configurado en crontab"
    fi
}

check_logs() {
    section "8. VERIFICACIÓN DE LOGS"
    
    if [ -d "logs" ]; then
        pass "Directorio de logs existe"
        
        # Verificar permisos
        local perms=$(stat -c "%a" logs 2>/dev/null || stat -f "%A" logs 2>/dev/null)
        if [ "$perms" = "755" ] || [ "$perms" = "775" ]; then
            pass "Permisos de logs correctos"
        else
            warn "Permisos de logs: $perms (debería ser 755 o 775)"
        fi
    else
        fail "Directorio de logs no existe"
    fi
    
    # Verificar log rotation
    if [ -f "/etc/logrotate.d/docker-php" ]; then
        pass "Log rotation configurado"
    else
        warn "Log rotation no configurado"
    fi
}

check_permissions() {
    section "9. VERIFICACIÓN DE PERMISOS"
    
    # Archivos que no deberían ser ejecutables
    local files_to_check=(".env" "README.md" "docker-compose.yml")
    
    for file in "${files_to_check[@]}"; do
        if [ -f "$file" ]; then
            if [ -x "$file" ]; then
                warn "$file es ejecutable (no debería serlo)"
            else
                pass "$file no es ejecutable"
            fi
        fi
    done
    
    # Scripts que deberían ser ejecutables
    local scripts=("start.sh" "stop.sh" "backup.sh")
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                pass "$script es ejecutable"
            else
                warn "$script no es ejecutable"
            fi
        fi
    done
}

check_dependencies() {
    section "10. VERIFICACIÓN DE DEPENDENCIAS"
    
    # Verificar composer.lock si existe composer.json
    if [ -f "src/composer.json" ]; then
        if [ -f "src/composer.lock" ]; then
            pass "composer.lock existe (versionado correcto)"
        else
            warn "composer.lock no existe (ejecutar composer install)"
        fi
        
        # Verificar vulnerabilidades conocidas (si composer está disponible)
        if command -v composer >/dev/null 2>&1; then
            info "Ejecutando composer audit..."
            if composer audit -d src/ 2>/dev/null; then
                pass "No se encontraron vulnerabilidades conocidas"
            else
                fail "Se encontraron vulnerabilidades en dependencias"
            fi
        fi
    else
        info "composer.json no encontrado (puede ser normal)"
    fi
}

check_documentation() {
    section "11. VERIFICACIÓN DE DOCUMENTACIÓN"
    
    local docs=("README.md" ".gitignore")
    
    for doc in "${docs[@]}"; do
        if [ -f "$doc" ]; then
            pass "$doc existe"
        else
            warn "$doc no encontrado"
        fi
    done
}

check_network_security() {
    section "12. VERIFICACIÓN DE CONFIGURACIÓN DE RED"
    
    # Verificar que MySQL no esté expuesto innecesariamente
    source .env 2>/dev/null || true
    
    if [ "$APP_ENV" = "production" ]; then
        if [ "${DB_PORT:-3306}" = "3306" ]; then
            warn "MySQL expuesto en puerto default (considerar cambiar o restringir)"
        fi
    fi
    
    # Verificar configuración de red en docker-compose
    if grep -q "networks:" docker-compose.yml; then
        pass "Red Docker personalizada configurada"
    else
        warn "Usando red Docker default (considerar red personalizada)"
    fi
}

################################################################################
# RECOMENDACIONES DE HARDENING ADICIONAL
################################################################################

print_recommendations() {
    section "RECOMENDACIONES ADICIONALES"
    
    echo ""
    echo "📋 Hardening Adicional Recomendado:"
    echo ""
    echo "1. Implementar rate limiting con fail2ban"
    echo "2. Configurar firewall (UFW/iptables)"
    echo "3. Implementar WAF (Web Application Firewall)"
    echo "4. Configurar monitoring (Prometheus + Grafana)"
    echo "5. Implementar IDS/IPS (Intrusion Detection/Prevention)"
    echo "6. Configurar 2FA para accesos administrativos"
    echo "7. Implementar audit logging completo"
    echo "8. Escanear vulnerabilidades con Trivy/Snyk"
    echo "9. Implementar secrets rotation automática"
    echo "10. Configurar Security Headers adicionales (CSP, HSTS)"
    echo ""
    
    echo "🔐 Checklist de Seguridad para Producción:"
    echo ""
    echo "  [ ] Cambiar todas las contraseñas default"
    echo "  [ ] Habilitar HTTPS/SSL"
    echo "  [ ] Configurar firewall"
    echo "  [ ] Deshabilitar Xdebug"
    echo "  [ ] Configurar backups automáticos"
    echo "  [ ] Implementar monitoring"
    echo "  [ ] Configurar log aggregation"
    echo "  [ ] Realizar penetration testing"
    echo "  [ ] Configurar alertas de seguridad"
    echo "  [ ] Documentar procedimientos de incidentes"
    echo ""
}

################################################################################
# FUNCIÓN PRINCIPAL
################################################################################

main() {
    print_banner
    
    info "Iniciando auditoría de seguridad..."
    info "Directorio: $SCRIPT_DIR"
    echo ""
    
    # Cambiar al directorio del proyecto
    cd "$SCRIPT_DIR" || exit 1
    
    # Ejecutar todas las verificaciones
    check_env_file
    check_php_security
    check_mysql_security
    check_nginx_security
    check_docker_security
    check_ssl_configuration
    check_backups
    check_logs
    check_permissions
    check_dependencies
    check_documentation
    check_network_security
    
    # Resumen
    echo ""
    section "RESUMEN DE AUDITORÍA"
    echo ""
    echo -e "${GREEN}✓ Checks Pasados:   $CHECKS_PASSED${NC}"
    echo -e "${YELLOW}! Advertencias:      $CHECKS_WARNING${NC}"
    echo -e "${RED}✗ Checks Fallados:   $CHECKS_FAILED${NC}"
    echo ""
    
    # Calcular score
    local total=$((CHECKS_PASSED + CHECKS_WARNING + CHECKS_FAILED))
    local score=$((CHECKS_PASSED * 100 / total))
    
    echo -e "Score de Seguridad: ${BLUE}$score/100${NC}"
    echo ""
    
    if [ $CHECKS_FAILED -eq 0 ]; then
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  ✓ AUDITORÍA COMPLETADA - NO SE ENCONTRARON FALLOS  ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
        
        if [ $CHECKS_WARNING -gt 0 ]; then
            echo ""
            echo -e "${YELLOW}⚠️  Hay $CHECKS_WARNING advertencias que deberían revisarse${NC}"
        fi
    else
        echo -e "${RED}╔═══════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  ✗ SE ENCONTRARON $CHECKS_FAILED PROBLEMAS DE SEGURIDAD        ║${NC}"
        echo -e "${RED}║     DEBEN SER CORREGIDOS ANTES DE PRODUCCIÓN         ║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════╝${NC}"
    fi
    
    # Recomendaciones
    print_recommendations
    
    # Exit code
    if [ $CHECKS_FAILED -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Ejecutar
main "$@"
