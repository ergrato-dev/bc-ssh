# 🎮 Playgrounds y Entornos de Práctica

## Lugares para Practicar SCP, SFTP y rsync

---

## Entornos Locales

### Máquinas Virtuales

#### VirtualBox + Ubuntu Server

1. Descargar VirtualBox: https://www.virtualbox.org
2. Descargar Ubuntu Server: https://ubuntu.com/download/server
3. Crear VM y habilitar SSH:

```bash
# En la VM
sudo apt update
sudo apt install openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh

# Obtener IP
ip addr show
```

#### Vagrant

- **URL**: https://www.vagrantup.com
- Crear VMs rápidamente

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.network "private_network", ip: "192.168.56.10"
end
```

```bash
vagrant up
vagrant ssh
# Practicar desde tu máquina host
```

---

### Docker

#### Contenedor SSH Simple

```dockerfile
# Dockerfile
FROM ubuntu:22.04
RUN apt update && apt install -y openssh-server rsync
RUN mkdir /run/sshd
RUN echo 'root:password' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
```

```bash
# Construir y ejecutar
docker build -t ssh-server .
docker run -d -p 2222:22 --name ssh-lab ssh-server

# Conectar
ssh -p 2222 root@localhost
# Password: password

# Probar SCP
scp -P 2222 archivo.txt root@localhost:/root/

# Probar SFTP
sftp -P 2222 root@localhost
```

#### Docker Compose Multi-servidor

```yaml
# docker-compose.yml
version: '3.8'
services:
  staging:
    build: .
    ports:
      - '2222:22'
    hostname: staging

  production:
    build: .
    ports:
      - '2223:22'
    hostname: production
```

```bash
docker-compose up -d

# Servidor staging
ssh -p 2222 root@localhost

# Servidor production
ssh -p 2223 root@localhost
```

---

## Servicios Cloud (Capa Gratuita)

### DigitalOcean

- **URL**: https://www.digitalocean.com
- **Oferta**: $200 de crédito gratis (60 días)
- **Droplets desde**: $4/mes

```bash
# Crear droplet vía CLI
doctl compute droplet create \
  --image ubuntu-22-04-x64 \
  --size s-1vcpu-512mb-10gb \
  --region nyc1 \
  --ssh-keys TU_KEY_ID \
  ssh-lab
```

### Linode (Akamai)

- **URL**: https://www.linode.com
- **Oferta**: $100 de crédito (60 días)
- **Linodes desde**: $5/mes

### AWS EC2

- **URL**: https://aws.amazon.com/ec2
- **Oferta**: Capa gratuita (750 horas/mes por 12 meses)
- **t2.micro**: Gratuito

### Google Cloud

- **URL**: https://cloud.google.com/compute
- **Oferta**: $300 de crédito (90 días)
- **e2-micro**: Gratuito siempre

### Oracle Cloud

- **URL**: https://www.oracle.com/cloud/free
- **Oferta**: 2 VMs gratuitas permanentemente
- **Mejor opción gratuita a largo plazo**

---

## Playgrounds Online

### Killercoda (antes Katacoda)

- **URL**: https://killercoda.com
- **Descripción**: Entornos Linux interactivos en navegador
- **Buscar**: Escenarios de SSH, Linux basics

### Play with Docker

- **URL**: https://labs.play-with-docker.com
- **Descripción**: Contenedores Docker temporales
- **Uso**: Crear contenedores SSH y practicar

### Linux Journey

- **URL**: https://linuxjourney.com
- **Descripción**: Tutorial interactivo de Linux
- **Sección**: Networking, SSH

---

## Raspberry Pi

### Configurar como Servidor SSH

```bash
# Habilitar SSH en Raspberry Pi OS
sudo raspi-config
# Interface Options > SSH > Enable

# O crear archivo ssh vacío en boot
touch /boot/ssh
```

**Ventajas**:

- Servidor real
- Bajo consumo
- Siempre disponible
- Costo único

---

## Configuración Recomendada para Prácticas

### ~/.ssh/config para Labs

```ssh-config
# Labs locales
Host lab-vm
    HostName 192.168.56.10
    User vagrant
    IdentityFile ~/.vagrant.d/insecure_private_key

Host lab-docker
    HostName localhost
    Port 2222
    User root
    StrictHostKeyChecking no

Host lab-staging
    HostName localhost
    Port 2222
    User root

Host lab-prod
    HostName localhost
    Port 2223
    User root

# Cloud
Host lab-digital
    HostName IP_DEL_DROPLET
    User root
    IdentityFile ~/.ssh/id_ed25519
```

---

## 💡 Recomendaciones

1. **Para empezar**: Docker (más rápido)
2. **Para practicar serio**: VirtualBox/Vagrant
3. **Para simular producción**: Cloud (DigitalOcean/Linode)
4. **Para uso continuo**: Raspberry Pi u Oracle Cloud (gratis)

---

<div align="center">

**🎮 Playgrounds y Entornos de Práctica**

</div>
