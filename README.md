# Ejecutar Docker en WSL2 en solo 5 minutes (via systemd, sin Docker Desktop!)
wsl --install Ubuntu-22.04

# Asegurarse que /etc/wsl.conf tenga el siguiente contenido

[boot]
systemd=true

# Configurar WSL ( "Ubuntu-22.04" ):

# Abrir  "Ubuntu-22.04"
wsl --distribution Ubuntu-22.04

# Habilitar  systemd via /etc/wsl.conf
{
cat <<EOT
[boot]
systemd=true
EOT
} | sudo tee /etc/wsl.conf

exit


# Reiniciar WSL:

wsl --shutdown
wsl --distribution Ubuntu-22.04


#Chequear que systemd este funcionando, deberia de tener el mensaje  'OK: Systemd is running' 

systemctl --no-pager status user.slice > /dev/null 2>&1 && echo 'OK: Systemd is running' || echo 'FAIL: Systemd not running'


# INSTALAR docker-ce :

## Instalar  Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-compose-plugin

## Agregar un link simbolico  docker-compose
sudo ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose

# Agregar al usuario el grupo de  docker 
sudo usermod -aG docker $USER

# Es importante !!!! Salir del bash - 
exit

Volver a iniciar (Tambien es imporante):

wsl --distribution Ubuntu-22.04


Ahora tu puedes ejecutar Docker sin necesidad de utilizar  Docker Desktop 🙂:

Pruebalo
docker run --rm -it hello-world
