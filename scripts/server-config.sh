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

# Crear un usuario específico para despliegues automatizados o con permisos limitados
sudo useradd -m -s /bin/bash webmaster

sudo passwd diego
sudo passwd samuel
sudo passwd eduardo
sudo passwd webmaster
sudo passwd vmsanbox


# Crear grupo para administradores del sitio web
sudo groupadd webadmin

sudo usermod -aG webadmin diego
sudo usermod -aG webadmin samuel
sudo usermod -aG webadmin eduardo
sudo usermod -aG webadmin webmaster

#super user do 
sudo usermod -aG wheel samuel
sudo usermod -aG wheel eduardo
sudo usermod -aG wheel diego
sudo usermod -aG wheel vmsandbox

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