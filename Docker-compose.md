# Docker Compose para MySQL y Servidor de Monitoreo (Prometheus + Grafana)
Archivo docker-compose.yml
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

#Descripción de los Servicios
  MySQL: Servidor de base de datos MySQL con volúmenes persistentes y variables de entorno configuradas.
  Prometheus: Sistema de monitoreo que recolecta métricas de los servicios.
  Grafana: Herramienta de visualización de métricas para acceder a los datos monitorizados.
#Archivo prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'mysql'
    static_configs:
      - targets: ['mysql-server:3306']

#Comandos para Ejecutar los Servicios
Guarda ambos archivos en el mismo directorio.
Levanta los servicios con el siguiente comando:

docker-compose up -d


Este comando iniciará los contenedores de MySQL, Prometheus y Grafana, conectados en la misma red para monitoreo.

Con este archivo puedes levantar tu servidor MySQL y un sistema de monitoreo con Prometheus y Grafana.
