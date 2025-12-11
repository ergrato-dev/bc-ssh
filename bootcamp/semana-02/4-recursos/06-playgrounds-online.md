# 🎮 Playgrounds Online - Semana 02

## 💻 Entornos de Práctica SSH

### Plataformas Interactivas

| Plataforma              | Descripción                     | Acceso                                                             |
| ----------------------- | ------------------------------- | ------------------------------------------------------------------ |
| **OverTheWire: Bandit** | Wargame para aprender Linux/SSH | [overthewire.org/bandit](https://overthewire.org/wargames/bandit/) |
| **TryHackMe**           | Labs de seguridad con SSH       | [tryhackme.com](https://tryhackme.com/)                            |
| **HackTheBox**          | Plataforma de pentesting        | [hackthebox.com](https://www.hackthebox.com/)                      |
| **Killercoda**          | Escenarios interactivos         | [killercoda.com](https://killercoda.com/)                          |
| **Play with Docker**    | Contenedores con SSH            | [labs.play-with-docker.com](https://labs.play-with-docker.com/)    |

### Recomendado: OverTheWire Bandit

El wargame **Bandit** es perfecto para practicar SSH:

```bash
# Nivel 0 - Primera conexión SSH
ssh bandit0@bandit.labs.overthewire.org -p 2220
# Contraseña: bandit0

# Cada nivel te enseña comandos Linux y SSH
# Progresión gradual de dificultad
```

**Niveles relevantes para llaves SSH:**

- Level 13 → 14: Usar llave privada para conectar
- Level 14 → 15: Conexiones a localhost
- Level 16 → 17: Escaneo de puertos + SSH

---

## 🐳 Docker para Práctica Local

### Contenedor SSH Simple

```bash
# Crear contenedor con SSH
docker run -d --name ssh-lab -p 2222:22 \
  rastasheep/ubuntu-sshd:18.04

# Conectar (user: root, pass: root)
ssh root@localhost -p 2222

# Practicar ssh-copy-id
ssh-copy-id -p 2222 root@localhost
```

### Múltiples Servidores

```bash
# Crear red de práctica
docker network create ssh-lab

# Servidor 1 (produccion)
docker run -d --name prod --network ssh-lab \
  -p 2221:22 rastasheep/ubuntu-sshd:18.04

# Servidor 2 (desarrollo)
docker run -d --name dev --network ssh-lab \
  -p 2222:22 rastasheep/ubuntu-sshd:18.04

# Practicar con múltiples llaves
ssh-keygen -t ed25519 -f ~/.ssh/id_prod -C "prod"
ssh-keygen -t ed25519 -f ~/.ssh/id_dev -C "dev"
```

---

## ☁️ VPS Gratuitos/Económicos

### Para Práctica Real

| Proveedor        | Oferta                 | Ideal para            |
| ---------------- | ---------------------- | --------------------- |
| **Oracle Cloud** | Always Free tier       | VPS permanente gratis |
| **Google Cloud** | $300 crédito inicial   | 3 meses de práctica   |
| **AWS**          | Free tier 12 meses     | EC2 t2.micro gratis   |
| **DigitalOcean** | $200 crédito (60 días) | Droplets básicos      |
| **Linode**       | $100 crédito           | VPS Linux             |
| **Vultr**        | $100 crédito           | Múltiples regiones    |

### Configuración Rápida en Oracle Cloud

```bash
# 1. Crear cuenta en cloud.oracle.com
# 2. Crear instancia "Always Free" (VM.Standard.E2.1.Micro)
# 3. Descargar llave privada .key
# 4. Conectar:

chmod 600 ~/Downloads/ssh-key.key
ssh -i ~/Downloads/ssh-key.key ubuntu@IP_PUBLICA
```

---

## 🖥️ Máquinas Virtuales Locales

### VirtualBox + Vagrant

```bash
# Instalar Vagrant
# https://www.vagrantup.com/downloads

# Crear VM Ubuntu con SSH
mkdir ~/ssh-lab && cd ~/ssh-lab
vagrant init ubuntu/jammy64
vagrant up

# Conectar
vagrant ssh

# O con SSH directo
ssh -i .vagrant/machines/default/virtualbox/private_key \
    -p 2222 vagrant@localhost
```

### Multipass (Ubuntu)

```bash
# Instalar Multipass
sudo snap install multipass

# Crear VM
multipass launch --name ssh-lab

# Obtener IP
multipass info ssh-lab

# Conectar
multipass shell ssh-lab
# O con SSH
ssh ubuntu@$(multipass info ssh-lab | grep IPv4 | awk '{print $2}')
```

---

## 💡 Plan de Práctica Sugerido

### Semana 02

1. **Día 1-2**: OverTheWire Bandit (niveles 0-5)
2. **Día 3**: Contenedor Docker local
3. **Día 4-5**: VPS gratuito (Oracle/GCP)
4. **Día 6-7**: Proyecto semanal en VPS

### Comandos a Practicar

```bash
# Generación de llaves
ssh-keygen -t ed25519 -C "email"

# Despliegue
ssh-copy-id usuario@servidor

# Múltiples llaves
ssh -i ~/.ssh/llave_especifica usuario@servidor

# Verificación
ssh -v usuario@servidor
```

---

[← Volver a Recursos](README.md)
