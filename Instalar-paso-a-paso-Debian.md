1) Instalar Docker Engine + Docker Compose (Linux)

Tip: Compose v2 ya viene como plugin de Docker. El comando es docker compose (con espacio). 
Docker Documentation
+1

A. Ubuntu / Debian
# 0) Limpiar paquetes en conflicto (si existen)
sudo apt-get remove -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc

# 1) Paquetes base y keyring
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings

# 2) Agregar la clave GPG oficial y el repo (auto-detecta tu distro)
source /etc/os-release
curl -fsSL https://download.docker.com/linux/$ID/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID \
  $VERSION_CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 3) Instalar Docker + Buildx + Compose plugin
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4) Habilitar y probar
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker   # aplica el grupo sin reiniciar sesión
docker run --rm hello-world
docker compose version


(Fuente oficial: instalación Ubuntu/Debian y Compose plugin). 
Docker Documentation
+2
Docker Documentation
+2

B. Fedora / RHEL compatibles
# 0) Limpiar paquetes en conflicto (si existen)
sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

# 1) Habilitar repo oficial e instalar
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 2) Habilitar y probar
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker
docker run --rm hello-world
docker compose version


(Fuente oficial: instalación Fedora + Compose plugin). 
Docker Documentation
+1

2) Clonar el repositorio BUCEO/Docker

Si no tienes git: sudo apt-get install -y git (Ubuntu/Debian) o sudo dnf install -y git (Fedora).

# Clonar (HTTPS). Si es privado, configura SSH y usa la URL SSH.
git clone https://github.com/BUCEO/Docker.git
cd Docker


Si el repo trae .env.example, duplica a .env y edítalo:

cp .env.example .env 2>/dev/null || true
nano .env  # ajusta claves/puertos si hace falta

3) Levantar los contenedores con Compose
# Validar el archivo
docker compose config

# Levantar en segundo plano
docker compose up -d

# Ver estado
docker compose ps

# Ver logs en vivo (ejemplo: base de datos)
docker compose logs -f db


(Ver guía y referencia de Compose). 
Docker Documentation
+1

4) Operaciones de consola que van a usar en clase
Conectarse a MySQL dentro del contenedor
# Entrar con el cliente mysql (usuario de ejemplo)
docker exec -it db-mysql mysql -uuser -p example_db
# o como root
docker exec -it db-mysql mysql -uroot -p


Dentro del cliente:

SHOW DATABASES;
USE example_db;
SHOW TABLES;
SELECT * FROM products;

Parar, reiniciar, y limpiar
# Reiniciar sólo un servicio (ej: web)
docker compose restart web

# Parar todo
docker compose stop

# Bajar todo (manteniendo volúmenes)
docker compose down

# Bajar y borrar volúmenes (reset total de datos)
docker compose down -v


(Comandos de Compose). 
Docker Documentation

5) Errores comunes y cómo resolverlos (solo consola)

“permission denied while trying to connect to the Docker daemon”
Agrega tu usuario al grupo docker y recarga la sesión:

sudo usermod -aG docker $USER
newgrp docker


Puerto en uso (por ej. 80 o 3306)
Ver qué proceso usa el puerto y cambiar el mapeo en docker-compose.yml:

sudo lsof -i :80
# Edita ports: "8080:80" (ejemplo) y vuelve a levantar:
docker compose up -d


Contenedor reiniciando en loop
Ver logs del servicio:

docker compose logs -f web   # o db/php, etc.

“Hoja de ruta” para que no se pierdan (resumen)

Instalar Docker + Compose según distro (Ubuntu/Debian o Fedora). 
Docker Documentation
+2
Docker Documentation
+2

Probar: docker run --rm hello-world y docker compose version. 
Docker Documentation

Clonar BUCEO/Docker y entrar al directorio.

Configurar .env si hace falta.

Levantar: docker compose up -d. 
Docker Documentation

Ver logs y probar MySQL por consola con docker exec -it db-mysql mysql -u....

Reset de datos para repetir la práctica: docker compose down -v. 
Docker Documentation

Si quieres, adapto estos pasos a tu distro específica (Ubuntu, Debian, Fedora, etc.) y te genero un PDF imprimible para el aula con todas las consignas.
