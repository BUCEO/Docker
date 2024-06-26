﻿# Docker
Run Docker in WSL2 in 5 minutes (via systemd, without Docker Desktop!)
#docker#wsl2
Now WSL2 has systemd support, we can run Docker in WSL without Docker desktop!
TL;DR
Ensure /etc/wsl.conf has

[boot]
systemd=true


Restart WSL

wsl --shutdown
wsl --distribution Ubuntu


Install docker-cli - see my guide
Log back into WSL > Profit 💫
Complete Guide
Ensure WSL is up-to-date:

wsl --update


(Optional) Install + configure Ubuntu distro (if you haven't already):

wsl --install Ubuntu


Configure WSL (assuming "Ubuntu" is your distro):

# Open up "Ubuntu"
wsl --distribution Ubuntu

# Enable systemd via /etc/wsl.conf
{
cat <<EOT
[boot]
systemd=true
EOT
} | sudo tee /etc/wsl.conf

exit


Restart WSL:

wsl --shutdown
wsl --distribution Ubuntu


Check systemd is running - You should see 'OK: Systemd is running' message:

systemctl --no-pager status user.slice > /dev/null 2>&1 && echo 'OK: Systemd is running' || echo 'FAIL: Systemd not running'


Install docker-ce (cmds from my post):

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-compose-plugin

# Install docker-compose
sudo ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose

# Add yourself to the docker group
sudo usermod -aG docker $USER

# Exit bash - this is important!!!
exit


Re-login (this is important!):

wsl --distribution Ubuntu


You can now run docker-cli without Docker Desktop 🙂:

docker run --rm -it hello-world
