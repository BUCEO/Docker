#!/bin/bash

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Función para imprimir mensajes
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARN: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Función para detectar la distribución de Linux
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        error "No se pudo detectar la distribución de Linux"
    fi
}

# Función para verificar privilegios de root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Este script debe ejecutarse como root o con sudo"
    fi
}

# Función para instalar UFW si no está presente
install_ufw() {
    if command -v ufw &> /dev/null; then
        log "UFW ya está instalado"
        return
    fi

    log "Instalando UFW..."
    case "$OS" in
        ubuntu|debian)
            apt-get update -qq
            apt-get install -y -qq ufw
            ;;
        centos|rhel)
            yum install -y -q epel-release
            yum install -y -q ufw
            ;;
        fedora)
            dnf install -y -q ufw
            ;;
    esac
    log "UFW instalado correctamente"
}

# Función para configurar UFW básico
setup_ufw_basic() {
    log "Configurando políticas por defecto de UFW..."
    
    # Establecer políticas por defecto
    ufw default deny incoming
    ufw default allow outgoing
    
    # Permitir SSH
    ufw allow ssh
    ufw allow 22/tcp
    
    # Permitir puertos esenciales para Docker y aplicaciones web
    ufw allow 80/tcp   # HTTP
    ufw allow 443/tcp  # HTTPS
    ufw allow 9000/tcp # PHP-FPM (si se monitoriza externamente)
    
    # Si necesitas otros puertos para servicios específicos
    # ufw allow 3306/tcp # MySQL (solo si es necesario acceso externo)
    # ufw allow 5432/tcp # PostgreSQL
    # ufw allow 6379/tcp # Redis
    
    log "Políticas básicas de UFW configuradas"
}

# Función para configurar UFW con Docker
setup_ufw_docker() {
    log "Configurando UFW para trabajar con Docker..."
    
    # Ajustar la configuración de UFW para Docker
    if ! grep -q "Docker" /etc/ufw/after.rules; then
        cat >> /etc/ufw/after.rules << 'EOF'

# BEGIN DOCKER UFW RULES
# Rules for Docker containers
*filter
:ufw-user-forward - [0:0]
:ufw-docker-logging-deny - [0:0]
:DOCKER-USER - [0:0]
-A DOCKER-USER -j ufw-user-forward

-A DOCKER-USER -j RETURN -s 10.0.0.0/8
-A DOCKER-USER -j RETURN -s 172.16.0.0/12
-A DOCKER-USER -j RETURN -s 192.168.0.0/16

-A DOCKER-USER -p udp -m udp --sport 53 -j RETURN
-A DOCKER-USER -p tcp -m tcp --dport 53 -j RETURN
-A DOCKER-USER -p udp -m udp --dport 53 -j RETURN

-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0/16
-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0/8
-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0/12
-A DOCKER-USER -j ufw-docker-logging-deny -p udp -m udp --dport 0:65535 -d 192.168.0.0/16
-A DOCKER-USER -j ufw-docker-logging-deny -p udp -m udp --dport 0:65535 -d 10.0.0.0/8
-A DOCKER-USER -j ufw-docker-logging-deny -p udp -m udp --dport 0:65535 -d 172.16.0.0/12

-A DOCKER-USER -j RETURN

-A ufw-docker-logging-deny -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix "[UFW DOCKER BLOCK] "
-A ufw-docker-logging-deny -j DROP

# END DOCKER UFW RULES
EOF
    fi
    
    # Configurar UFW para que no gestione las interfaces de Docker
    if [ -f /etc/ufw/ufw.conf ]; then
        sed -i 's/IPT_SYSCTL=/IPT_SYSCTL=\/lib\/ufw\/ufw-init_functions.override\nIPT_SYSCTL=/' /etc/ufw/ufw.conf
    fi
    
    # Crear archivo de override para UFW
    mkdir -p /etc/ufw/applications.d
    cat > /etc/ufw/applications.d/docker << 'EOF'
[Docker]
title=Docker Container Runtime
description=Docker container runtime and its services
ports=2375/tcp|2376/tcp
EOF

    log "Configuración de UFW para Docker completada"
}

# Función para configurar iptables directamente
setup_iptables_rules() {
    log "Configurando reglas iptables adicionales..."
    
    # Crear cadena personalizada para Docker
    iptables -N DOCKER-USER 2>/dev/null || true
    
    # Permitir tráfico establecido y relacionado
    iptables -A DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    
    # Permitir redes privadas
    iptables -A DOCKER-USER -s 10.0.0.0/8 -j ACCEPT
    iptables -A DOCKER-USER -s 172.16.0.0/12 -j ACCEPT
    iptables -A DOCKER-USER -s 192.168.0.0/16 -j ACCEPT
    
    # Permitir loopback
    iptables -A DOCKER-USER -i lo -j ACCEPT
    
    # Reglas específicas para contenedores
    # Ejemplo: Permitir acceso a un contenedor específico en puerto 8080
    # iptables -A DOCKER-USER -p tcp --dport 8080 -j ACCEPT
    
    # Política por defecto para DOCKER-USER
    iptables -A DOCKER-USER -j RETURN
    
    # Guardar reglas iptables persistentemente
    if command -v iptables-save &> /dev/null && [ -d /etc/iptables ]; then
        iptables-save > /etc/iptables/rules.v4
        ip6tables-save > /etc/iptables/rules.v6
    fi
    
    log "Reglas iptables configuradas"
}

# Función para configurar SELinux (CentOS/RHEL)
setup_selinux() {
    if [ "$OS" != "centos" ] && [ "$OS" != "rhel" ]; then
        warn "SELinux solo es relevante para CentOS/RHEL. Saltando..."
        return
    fi
    
    log "Configurando SELinux para Docker..."
    
    # Verificar si SELinux está instalado y activo
    if ! command -v sestatus &> /dev/null; then
        warn "SELinux no está instalado. Instalando..."
        yum install -y -q policycoreutils policycoreutils-python selinux-policy selinux-policy-targeted libselinux-utils
    fi
    
    # Asegurarse de que SELinux está en modo enforcing
    if [ "$(getenforce)" != "Enforcing" ]; then
        warn "SELinux no está en modo Enforcing. Configurando..."
        setenforce 1
        sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
    fi
    
    # Instalar políticas necesarias para Docker
    yum install -y -q container-selinux
    
    # Configurar contextos para Docker
    semanage port -a -t http_port_t -p tcp 8080
    semanage port -a -t http_port_t -p tcp 9000
    
    # Ajustar políticas para contenedores Docker
    setsebool -P container_manage_cgroup 1
    
    log "SELinux configurado para Docker"
}

# Función para configurar AppArmor (Ubuntu/Debian)
setup_apparmor() {
    if [ "$OS" != "ubuntu" ] && [ "$OS" != "debian" ]; then
        warn "AppArmor solo es relevante para Ubuntu/Debian. Saltando..."
        return
    fi
    
    log "Configurando AppArmor para Docker..."
    
    # Verificar si AppArmor está activo
    if ! aa-status --enabled 2>/dev/null; then
        warn "AppArmor no está activo. Activando..."
        systemctl enable apparmor
        systemctl start apparmor
    fi
    
    # Instalar perfiles necesarios
    apt-get install -y -qq apparmor-profiles apparmor-utils
    
    # Cargar perfiles de Docker
    if [ -f /etc/apparmor.d/docker ]; then
        apparmor_parser -r /etc/apparmor.d/docker
    fi
    
    log "AppArmor configurado para Docker"
}

# Función para configurar el kernel con sysctl
setup_kernel_security() {
    log "Configurando parámetros de seguridad del kernel..."
    
    # Configurar sysctl para mejorar seguridad
    cat > /etc/sysctl.d/99-security.conf << 'EOF'
# Prevenir IP spoofing
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1

# No aceptar redirecciones ICMP
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0

# No aceptar paquetes de source routing
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv6.conf.all.accept_source_route=0

# Protección contra SYN floods
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=2048
net.ipv4.tcp_synack_retries=2

# Protección contra time-wait assassination
net.ipv4.tcp_rfc1337=1

# Deshabilitar ICMP broadcast
net.ipv4.icmp_echo_ignore_broadcasts=1

# Deshabilitar profiling del kernel
kernel.kptr_restrict=2
kernel.perf_event_paranoid=3

# Mejorar la protección de memoria
vm.overcommit_memory=1
kernel.kexec_load_disabled=1

# Configuraciones para Docker
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-arptables=1
EOF
    
    # Aplicar configuraciones
    sysctl -p /etc/sysctl.d/99-security.conf
    
    log "Parámetros de seguridad del kernel configurados"
}

# Función para configurar seguridad de Docker
setup_docker_security() {
    log "Configurando medidas de seguridad para Docker..."
    
    # Crear directorio de configuración de Docker si no existe
    mkdir -p /etc/docker
    
    # Configurar daemon.json de Docker con opciones de seguridad
    cat > /etc/docker/daemon.json << 'EOF'
{
  "userns-remap": "default",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65536,
      "Soft": 65536
    }
  },
  "icc": false
}
EOF
    
    # Configurar límites para contenedores
    if [ ! -f /etc/security/limits.d/docker.conf ]; then
        cat > /etc/security/limits.d/docker.conf << 'EOF'
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF
    fi
    
    # Reiniciar Docker para aplicar configuraciones
    systemctl restart docker
    
    log "Medidas de seguridad para Docker configuradas"
}

# Función para configurar logging y auditoría
setup_logging_audit() {
    log "Configurando logging y auditoría..."
    
    # Instalar y configurar auditd si no está presente
    if ! command -v auditctl &> /dev/null; then
        case "$OS" in
            ubuntu|debian)
                apt-get install -y -qq auditd audispd-plugins
                ;;
            centos|rhel|fedora)
                yum install -y -q audit
                ;;
        esac
    fi
    
    # Reglas de auditoría para Docker
    cat > /etc/audit/rules.d/docker.rules << 'EOF'
-w /usr/bin/docker -k docker
-w /var/lib/docker -k docker
-w /etc/docker -k docker
-w /etc/default/docker -k docker
-w /etc/docker/daemon.json -k docker
-w /usr/lib/systemd/system/docker.service -k docker
-w /usr/lib/systemd/system/docker.socket -k docker
-w /etc/default/docker -k docker
-w /etc/docker/daemon.json -k docker
-w /usr/bin/docker-containerd -k docker
-w /usr/bin/docker-runc -k docker
EOF
    
    # Reiniciar servicio de auditoría
    if systemctl is-active --quiet auditd; then
        systemctl restart auditd
    fi
    
    # Configurar logrotate para logs de Docker
    if [ ! -f /etc/logrotate.d/docker ]; then
        cat > /etc/logrotate.d/docker << 'EOF'
/var/lib/docker/containers/*/*.log {
  rotate 7
  daily
  compress
  size=10M
  missingok
  delaycompress
  copytruncate
}
EOF
    fi
    
    log "Logging y auditoría configurados"
}

# Función para aplicar todas las configuraciones
apply_all_configurations() {
    log "Iniciando hardening de seguridad completo..."
    
    check_root
    detect_os
    
    install_ufw
    setup_ufw_basic
    setup_ufw_docker
    setup_iptables_rules
    
    # Configurar seguridad según la distribución
    if [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        setup_selinux
    else
        setup_apparmor
    fi
    
    setup_kernel_security
    setup_docker_security
    setup_logging_audit
    
    # Habilitar y iniciar UFW
    ufw --force enable
    systemctl enable ufw
    systemctl start ufw
    
    log "Hardening de seguridad completado exitosamente!"
    
    # Mostrar resumen
    info "Resumen de configuraciones aplicadas:"
    info "1. UFW configurado y habilitado"
    info "2. Reglas iptables personalizadas para Docker"
    info "3. $(if [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then echo "SELinux"; else echo "AppArmor"; fi) configurado"
    info "4. Parámetros de seguridad del kernel aplicados"
    info "5. Medidas de seguridad específicas para Docker"
    info "6. Sistema de logging y auditoría configurado"
    
    warn "Recomendaciones adicionales:"
    warn "- Revisa las reglas de UFW: ufw status verbose"
    warn "- Ajusta las reglas iptables según tus necesidades específicas"
    warn "- Monitorea los logs regularmente: journalctl -u docker -f"
    warn "- Considera usar certificates TLS para Docker daemon"
    warn "- Actualiza regularmente el sistema y los contenedores"
}

# Función principal
main() {
    case "${1:-}" in
        "apply")
            apply_all_configurations
            ;;
        "test")
            # Modo de prueba que muestra qué se haría sin aplicar cambios
            warn "MODO DE PRUEBA - No se aplicarán cambios reales"
            check_root
            detect_os
            info "Se detectó el sistema operativo: $OS $OS_VERSION"
            info "Las siguientes configuraciones se aplicarían:"
            info "- Instalación y configuración de UFW"
            info "- Reglas iptables para Docker"
            info "- Configuración de $(if [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then echo "SELinux"; else echo "AppArmor"; fi)"
            info "- Hardening del kernel"
            info "- Medidas de seguridad para Docker"
            info "- Configuración de logging y auditoría"
            ;;
        *)
            echo "Uso: $0 [apply|test]"
            echo "  apply - Aplica todas las configuraciones de seguridad"
            echo "  test  - Muestra qué configuraciones se aplicarían sin hacer cambios"
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"