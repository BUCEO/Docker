# Dockerfile para PHP-FPM con Apache
FROM php:8.3.4-fpm-alpine3.19

# Instalar extensiones necesarias (mysqli, zip y otras)
RUN docker-php-ext-install mysqli

# Copiar configuraciones de PHP y Apache
COPY ./php.ini /usr/local/etc/php/php.ini
COPY ./apache.conf /etc/apache2/sites-available/000-default.conf

# Instalar apache2 y otras dependencias
RUN apk add --no-cache apache2 apache2-ssl

# Agregar un script SQL para inicialización de base de datos
COPY ./init-db.sh /docker-entrypoint-initdb.d/
COPY ./init.sql /docker-entrypoint-initdb.d/

# Asignar los permisos necesarios al script
RUN chmod +x /docker-entrypoint-initdb.d/init-db.sh

# Exponer puertos 80 (HTTP) y 443 (HTTPS)
EXPOSE 80 443

# Definir el comando de inicio (entrypoint)
ENTRYPOINT ["/docker-entrypoint-initdb.d/init-db.sh"]
CMD ["apachectl", "-D", "FOREGROUND"]
