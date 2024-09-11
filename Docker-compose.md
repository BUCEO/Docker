archivo docker-compose.yml para un entorno con un servidor MySQL y un servidor de monitoreo, usando Prometheus y Grafana para monitoreo. Este ejemplo levanta los contenedores necesarios y configura las redes entre ellos.

docker-compose.yml
yaml
Copy code
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: mysql-server
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: example_db
      MYSQL_USER: user
      MYSQL_PASSWORD: user_password
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - monitoring_net

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    networks:
      - monitoring_net

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin_password
    ports:
      - "3000:3000"
    networks:
      - monitoring_net

volumes:
  mysql_data:

networks:
  monitoring_net:
    driver: bridge
Descripción de los Servicios
mysql:

Usa la imagen oficial de MySQL 8.0.
Define variables de entorno para configurar el usuario y las credenciales.
El puerto 3306 está mapeado para acceder a MySQL desde el host.
Usa un volumen para persistir los datos de la base de datos en mysql_data.
prometheus:

Prometheus se usa para recolectar métricas.
Mapea el puerto 9090 para la interfaz web de Prometheus.
Espera un archivo de configuración prometheus.yml en el directorio actual.
grafana:

Grafana es la interfaz para visualizar los datos monitoreados.
El puerto 3000 está mapeado para acceder a la interfaz de Grafana.
La contraseña de administrador de Grafana está configurada en la variable de entorno GF_SECURITY_ADMIN_PASSWORD.
Archivo prometheus.yml
Para que Prometheus monitoree MySQL y otros servicios, debes crear un archivo prometheus.yml en el mismo directorio donde está el docker-compose.yml:

yaml
Copy code
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'mysql'
    static_configs:
      - targets: ['mysql-server:3306']
Cómo levantar los servicios
Guarda ambos archivos en el mismo directorio.

Ejecuta el siguiente comando para levantar los servicios:

bash
Copy code
docker-compose up -d
Esto iniciará los contenedores de MySQL, Prometheus y Grafana, conectados en la misma red para que puedan comunicarse entre ellos.
