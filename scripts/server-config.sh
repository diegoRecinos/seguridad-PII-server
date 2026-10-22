#!/bin/bash
# ==============================================================================
# Comandos utilizados: configuracion server
# ==============================================================================

echo "=== Actualizando catálogos y paquetes del sistema (Update & Upgrade) ==="
sudo dnf update -y && sudo dnf upgrade -y

echo "=== Identificando y listando servicios activos ==="
echo "Generando reporte de servicios activos en ejecución..."
sudo systemctl list-units --type=service --state=running > servicios_activos_reporte.txt
echo "Reporte guardado en 'servicios_activos_reporte.txt'"

echo "desabilitar servicios innecesarios"
sudo systemctl stop ModemManager.service abrt-oops.service abrt-xorg.service abrtd.service
sudo systemctl disable ModemManager.service abrt-oops.service abrt-xorg.service abrtd.service


#creacion de usuarios
sudo useradd -m -s /bin/bash diego
sudo useradd -m -s /bin/bash samuel
sudo useradd -m -s /bin/bash eduardo
sudo useradd -m -s /bin/bash vmsandbox
sudo useradd -m -s /bin/bash admin

# Crear un usuario específico para despliegues automatizados o con permisos limitados
sudo useradd -m -s /bin/bash webmaster

sudo passwd diego
sudo passwd samuel
sudo passwd eduardo
sudo passwd webmaster
sudo passwd vmsanbox
sudo passwd admin


# Crear grupo para administradores del sitio web
sudo groupadd webadmin


sudo usermod -aG webadmin webmaster
sudo usermod -aG webadmin admin

#super user do 
sudo usermod -aG wheel samuel
sudo usermod -aG wheel eduardo
sudo usermod -aG wheel diego

#agregando llaves ssh publicas al servidor por cada usuario y sus permisos
mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
#nano authorized_keys


#start: Inicia el servicio en ese preciso momento
#enable: Configura el servicio para que se encienda automáticamente cada vez que la PC o el servidor arranca
#reload sirve para recargar la configuración de un servicio sin apagarlo ni interrumpir a los usuarios
sudo dnf install nginx
sudo systemctl start nginx
sudo systemctl enable nginx

#carpeta de nginx /usr/share/nginx/html$
#ver puerto de nginx
sudo ss -tulpn | grep nginx
#ver puertos en general
sudo netstat -tulpn | grep -E 'nginx|httpd'

WEB_DIR="/usr/share/nginx/html"

# 1. Asignar el propietario raíz y el grupo webadmin al sitio web
sudo chown -R root:webadmin $WEB_DIR

# 2. Configurar carpetas con lectura y ejecución general (755)
sudo find $WEB_DIR -type d -exec chmod 755 {} +

# 3. Configurar archivos con lectura general para que Nginx pueda leerlos (644)
sudo find $WEB_DIR -type f -exec chmod 644 {} +

# Asegurar que el grupo del sitio web incluya acceso de lectura para Nginx
sudo chmod -R g+r $WEB_DIR

# 1. Permitir el servicio HTTP de forma permanente en el firewall
sudo firewall-cmd --permanent --add-service=http

# 2. Recargar las reglas del firewall para que surtan efecto
sudo firewall-cmd --reload

sudo dnf install httpd
sudo systemctl start httpd
sudo systemctl enable httpd

sudo dnf install nano -y

#Paso 1: Modificar el archivo de configuración de Apache cambiar Listen 80
sudo nano /etc/httpd/conf/httpd.conf

#Permitir el puerto 8080 en el Firewall
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

# Definir la variable para la carpeta web de Apache
APACHE_DIR="/var/www/html"

# Asegurar que la carpeta exista
sudo mkdir -p $APACHE_DIR

# 1. Asignar el propietario root y el grupo webadmin
sudo chown -R root:webadmin $APACHE_DIR

# 2. Configurar carpetas con permisos seguros (775 para que el grupo pueda escribir/modificar)
sudo find $APACHE_DIR -type d -exec chmod 775 {} +

# 3. Configurar archivos con permisos seguros (664)
sudo find $APACHE_DIR -type f -exec chmod 664 {} +

# Asegurar lectura para el grupo web
sudo chmod -R g+r $APACHE_DIR

# 1. Permitir el puerto 8080 de forma permanente
sudo firewall-cmd --permanent --add-port=8080/tcp

# 2. Recargar las reglas del firewall
sudo firewall-cmd --reload

sudo systemctl enable tailscaled

# 3. Activar SetGID en los directorios para que hereden el grupo webadmin automáticamente
sudo find $WEB_DIR -type d -exec chmod g+s {} +

sudo find $APACHE_DIR -type d -exec chmod g+s {} +

#revocar super user do
sudo gpasswd -d vmsandbox wheel

# Crear el nuevo grupo sysadmin
sudo groupadd sysadmin

# Agregar a samuel y eduardo al nuevo grupo
sudo usermod -aG sysadmin samuel
sudo usermod -aG sysadmin eduardo
sudo usermod -aG sysadmin admin

# Sacar a samuel y eduardo del grupo wheel (para quitarles el acceso total)
sudo gpasswd -d samuel wheel
sudo gpasswd -d eduardo wheel

# Asegurar que diego siga en wheel
sudo usermod -aG wheel diego

#Impedir el inicio de sesión directo de root.
sudo nano /etc/ssh/sshd_config

permitRootLogin no

sudo systemctl reload sshd

#permisos ssh para ciertos users
/etc/ssh/sshd_config

#ssh a groups
AllowGroups wheel sysadmin webadmin


# Permitir estrictamente el uso de llaves públicas
PubkeyAuthentication yes

# Desactivar por completo el uso de contraseñas
PasswordAuthentication no
PermitEmptyPasswords no

#mover las paginas
WEB_DIR="/usr/share/nginx/html"

# 1. Copiar el contenido de tu carpeta webpage al directorio de Nginx 
# (Asegúrate de estar en la ruta donde tienes la carpeta 'webpage')
sudo cp -r webpage/* $WEB_DIR/

# 2. Aplicar los permisos seguros de propietario y grupo (webadmin)
sudo chown -R root:webadmin $WEB_DIR

# 3. Configurar carpetas con lectura y ejecución (755 o 775 según tu grupo)
sudo find $WEB_DIR -type d -exec chmod 755 {} +

# 4. Configurar archivos con lectura general (644) para que Nginx pueda mostrarlos
sudo find $WEB_DIR -type f -exec chmod 644 {} +

# 5. Asegurar acceso de lectura para el servicio de Nginx
sudo chmod -R g+r $WEB_DIR

APACHE_DIR="/var/www/html"

# 1. Copiar tus archivos a la carpeta de Apache
sudo cp -r webpage/* $APACHE_DIR/

# 2. Asignar el propietario root y el grupo webadmin
sudo chown -R root:webadmin $APACHE_DIR

# 3. Configurar permisos seguros
sudo find $APACHE_DIR -type d -exec chmod 775 {} +
sudo find $APACHE_DIR -type f -exec chmod 664 {} +

# 4. Asegurar lectura para el grupo
sudo chmod -R g+r $APACHE_DIR

#Paso 1: Configurar Nginx para seguridad y ocultar la versión
#Ocultar la versión de Nginx (server_tokens off;):
sudo nano /etc/nginx/nginx.conf

#http {
#    # Ocultar la versión de Nginx en los errores y cabeceras HTTP
#    server_tokens off;
#    
#    # ... (lo demás que ya tengas)
#}

#server {
#    listen       80;
#    server_name  localhost;
#    root         /usr/share/nginx/html;
#
#    # 1. Deshabilitar el listado de directorios (si no hay index.html, da 403 Forbidden en vez de listar)
#    # Por defecto Nginx ya lo trae deshabilitado si no pones 'autoindex on', 
#    # pero puedes asegurarlo explícitamente:
#    autoindex off;
#
#    # Archivo de bienvenida por defecto
#    index index.html index.htm;
#
#    location / {
#        try_files $uri $uri/ =404;
#    }
#
#    # 2. Evitar que respaldos, credenciales, bases de datos y archivos de configuración (.bak, .sql, .env, .conf, .log, etc.) puedan descargarse desde la web
#    location ~* \.(bak|sql|env|conf|log|sh|ini|git)$ {
#        deny all;
#        return 404;
#    }
#
#    # Bloquear acceso a carpetas ocultas (como .git o .env ocultos)
#    location ~ /\. {
#        deny all;
#        return 404;
#    }
#}

sudo systemctl restart nginx


sudo tee /usr/share/nginx/html/404.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>404 - Página no encontrada</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 15%; color: #333; }
        h1 { font-size: 3em; margin-bottom: 0; }
        p { color: #777; }
    </style>
</head>
<body>
    <h1>404</h1>
    <p>La página que buscas no existe.</p>
    <a href="/">Volver al inicio</a>
</body>
</html>
EOF

sudo tee /usr/share/nginx/html/50x.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Error del servidor</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 15%; color: #333; }
        h1 { font-size: 3em; margin-bottom: 0; }
        p { color: #777; }
    </style>
</head>
<body>
    <h1>Error</h1>
    <p>Ocurrió un problema en el servidor. Intenta más tarde.</p>
</body>
</html>
EOF

sudo tee /etc/nginx/default.d/errores.conf > /dev/null << 'EOF'
error_page 404 /404.html;
error_page 400 401 403 405 408 413 414 /404.html;
error_page 500 502 503 504 /50x.html;

location = /404.html { internal; }
location = /50x.html { internal; }
EOF

sudo nginx -t && sudo systemctl reload nginx

curl -i http://localhost/loquesea

sudo dnf install -y nginx-mod-http-headers-more-filter
echo 'more_clear_headers Server;' | sudo tee /etc/nginx/conf.d/headers.conf
sudo nginx -t && sudo systemctl reload nginx