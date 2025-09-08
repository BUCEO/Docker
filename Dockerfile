# Usar la imagen base de PHP-FPM con Alpine
FROM php:8.3.4-fpm-alpine3.19

# Instalar dependencias de sistema
RUN apk --no-cache add apache2 apache2-ssl openssl bash

# Instalar extensiones de PHP necesarias, incluyendo mysqli
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Copiar configuraciones personalizadas de PHP y Apache
COPY ./php.ini-development /usr/local/etc/php/php.ini
COPY ./apache2.conf /etc/apache2/apache2.conf

# Configuración para usar PHP-FPM con Apache
RUN mkdir -p /etc/apache2/mods-enabled/

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
RUN ln -s /etc/apache2/mods-available/proxy_fcgi.load /etc/apache2/mods-enabled/
RUN ln -s /etc/apache2/mods-available/setenvif.load /etc/apache2/mods-enabled/
RUN ln -s /etc/apache2/mods-available/actions.load /etc/apache2/mods-enabled/

# Crear directorios requeridos y permisos
RUN mkdir -p /var/www/html/public
RUN chown -R www-data:www-data /var/www/html

# Exponer el puerto 80 para Apache
EXPOSE 80

# Comando por defecto para iniciar Apache y PHP-FPM
CMD ["sh", "-c", "php-fpm -D && apachectl -D FOREGROUND"]