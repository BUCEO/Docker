# Guía Paso a Paso - Docker + Docker Compose + Proyecto BUCEO/Docker

## 1. Instalación de Docker y Docker Compose

### En Linux (Debian/Ubuntu)
```bash
sudo apt update
sudo apt install docker.io docker-compose -y
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```
> **Nota:** Cierra sesión y vuelve a entrar para que los cambios de permisos tengan efecto.

### En Windows/Mac
1. Descargar [Docker Desktop](https://www.docker.com/products/docker-desktop).
2. Instalar siguiendo el asistente.
3. Habilitar **Docker Compose** en las configuraciones.

---

## 2. Creación del Proyecto BUCEO/Docker

```bash
mkdir -p ~/proyectos/BUCEO-Docker
cd ~/proyectos/BUCEO-Docker
```

Estructura inicial:
```
BUCEO-Docker/
│── docker-compose.yml
│── app/
│   ├── index.php
│   ├── Dockerfile
│── db/
    └── init.sql
```

---

## 3. Contenedor PHP + Apache

Archivo `app/Dockerfile`:
```Dockerfile
FROM php:8.2-apache
RUN docker-php-ext-install mysqli pdo pdo_mysql
COPY . /var/www/html/
EXPOSE 80
```

Archivo `app/index.php`:
```php
<?php
$mysqli = new mysqli("db", "root", "rootpass", "buceo");
if ($mysqli->connect_error) {
    die("Error de conexión: " . $mysqli->connect_error);
}
echo "Conexión exitosa a la base de datos BUCEO 🚀";
?>
```

---

## 4. Contenedor MySQL

Archivo `db/init.sql`:
```sql
CREATE DATABASE buceo;
USE buceo;
CREATE TABLE inmersiones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    lugar VARCHAR(100),
    fecha DATE
);
INSERT INTO inmersiones (lugar, fecha) VALUES ('Isla de Lobos', '2025-01-15');
```

---

## 5. Archivo docker-compose.yml

```yaml
version: "3.9"
services:
  web:
    build: ./app
    ports:
      - "8080:80"
    volumes:
      - ./app:/var/www/html
    depends_on:
      - db

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
    volumes:
      - ./db:/docker-entrypoint-initdb.d
      - mysql_data:/var/lib/mysql

volumes:
  mysql_data:
```

---

## 6. Levantar el Proyecto

```bash
docker-compose up -d --build
```

Abrir en el navegador:
```
http://localhost:8080
```

---

## 7. Comandos Útiles

- Ver contenedores activos:
```bash
docker ps
```
- Ver logs:
```bash
docker-compose logs -f
```
- Detener contenedores:
```bash
docker-compose down
```
- Eliminar volúmenes:
```bash
docker-compose down -v
```

---

## 8. Conexión a la Base de Datos desde la terminal

```bash
docker exec -it nombre_contenedor_db mysql -u root -p
```

---

## 9. Respaldo y Restauración

**Backup:**
```bash
docker exec nombre_contenedor_db mysqldump -u root -p buceo > backup.sql
```

**Restaurar:**
```bash
docker exec -i nombre_contenedor_db mysql -u root -p buceo < backup.sql
```

---

## 10. Buenas Prácticas
- Usar `.env` para credenciales.
- No guardar datos sensibles en el repositorio.
- Versionar el `docker-compose.yml`.
- Mantener imágenes y contenedores limpios:
```bash
docker system prune -af
```

---

🚀 **Listo!** Ahora tienes un proyecto Docker funcional para pruebas y desarrollo del BUCEO/Docker.
