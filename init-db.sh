#!/bin/bash
set -e

# Esperar a que MySQL esté disponible
while ! mysqladmin ping -h"mysql" --silent; do
    echo "Esperando a que MySQL esté disponible..."
    sleep 2
done

# Ejecutar script SQL para crear la base de datos y cargar datos de prueba
mysql -h"mysql" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" < /docker-entrypoint-initdb.d/init.sql

echo "Base de datos inicializada con datos de prueba."
exec "$@"
