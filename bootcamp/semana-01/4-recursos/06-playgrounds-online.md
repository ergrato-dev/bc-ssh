# 🎮 Playgrounds Online - Semana 01

![Tipo](https://img.shields.io/badge/Tipo-Práctica_Online-green?style=flat-square)
![Costo](https://img.shields.io/badge/Costo-Gratis-brightgreen?style=flat-square)

---

## 🎯 Entornos de Práctica sin Instalación

Plataformas donde puedes practicar SSH sin necesidad de crear tu propio servidor.

---

## 🖥️ Terminales Linux Online

### 1. JSLinux

- **URL:** https://bellard.org/jslinux/
- **Descripción:** Linux completo en el navegador
- **SSH:** Puedes practicar comandos básicos
- **Limitación:** No conexión externa

### 2. Copy.sh Linux

- **URL:** https://copy.sh/v86/
- **Descripción:** Varias distros Linux en el navegador
- **Opciones:** Arch Linux, FreeBSD, Windows 98
- **SSH:** Práctica de comandos locales

### 3. Webminal

- **URL:** https://www.webminal.org/
- **Descripción:** Terminal Linux para aprender
- **Cuenta:** Gratis con registro
- **SSH:** Entorno aislado para practicar

---

## 🎓 Plataformas de Aprendizaje con Labs

### 4. OverTheWire - Bandit

- **URL:** https://overthewire.org/wargames/bandit/
- **Descripción:** Juego de guerra para aprender Linux/SSH
- **Nivel:** Principiante a Intermedio
- **Cómo conectar:**

```bash
ssh bandit0@bandit.labs.overthewire.org -p 2220
# Password: bandit0
```

- **Por qué es genial:** Aprendes SSH resolviendo puzzles

### 5. HackTheBox

- **URL:** https://www.hackthebox.com/
- **Descripción:** Plataforma de hacking ético
- **SSH:** Prácticas reales de conexión
- **Cuenta:** Gratis (limitada) / Pago

### 6. TryHackMe

- **URL:** https://tryhackme.com/
- **Descripción:** Aprendizaje guiado de seguridad
- **SSH:** Múltiples máquinas para practicar
- **Cuenta:** Gratis (limitada) / Pago
- **Recomendado:** Room "Linux Fundamentals"

---

## ☁️ Cloud Shells (Gratis)

### 7. Google Cloud Shell

- **URL:** https://shell.cloud.google.com/
- **Descripción:** Terminal Linux completa en la nube
- **Requisito:** Cuenta de Google
- **SSH:** Puedes conectarte a otros servidores
- **Bonus:** 5GB de almacenamiento persistente

### 8. AWS CloudShell

- **URL:** https://console.aws.amazon.com/cloudshell/
- **Descripción:** Terminal en AWS
- **Requisito:** Cuenta de AWS
- **SSH:** Cliente SSH disponible

### 9. Azure Cloud Shell

- **URL:** https://shell.azure.com/
- **Descripción:** Terminal en Azure
- **Requisito:** Cuenta de Microsoft/Azure
- **SSH:** Bash o PowerShell con SSH

---

## 🐳 Entornos Docker Online

### 10. Play with Docker

- **URL:** https://labs.play-with-docker.com/
- **Descripción:** Docker en el navegador
- **SSH:** Puedes crear contenedores con SSH
- **Duración:** Sesiones de 4 horas

**Crear servidor SSH en Play with Docker:**

```bash
# En la terminal de Play with Docker
docker run -d --name ssh-server -p 2222:22 lscr.io/linuxserver/openssh-server

# Obtener password generado
docker logs ssh-server

# Conectar (desde otra instancia)
ssh linuxserver.io@localhost -p 2222
```

---

## 🎮 Servidores SSH Públicos (Solo para Pruebas)

> ⚠️ **ADVERTENCIA:** Estos servidores son solo para pruebas rápidas.
> NUNCA uses datos reales o sensibles.

### 11. SDF Public Access Unix

- **URL:** https://sdf.org/
- **Descripción:** Sistema Unix público desde 1987
- **Cómo acceder:**

```bash
ssh new@sdf.org
# Crear cuenta gratuita
```

### 12. Tilde.club

- **URL:** https://tilde.club/
- **Descripción:** Comunidad de servidores públicos
- **Acceso:** Solicitar cuenta

---

## 📚 Tutoriales Interactivos

### 13. Katacoda (ahora O'Reilly)

- **URL:** https://www.katacoda.com/ (migrado a O'Reilly)
- **Descripción:** Labs interactivos
- **SSH:** Escenarios específicos de SSH

### 14. Linux Journey

- **URL:** https://linuxjourney.com/
- **Descripción:** Curso interactivo de Linux
- **SSH:** Sección de Command Line + SSH

### 15. LearnShell

- **URL:** https://www.learnshell.org/
- **Descripción:** Tutorial interactivo de Bash
- **SSH:** Fundamentos de terminal necesarios para SSH

---

## 🏆 Desafíos y CTFs con SSH

### 16. PicoCTF

- **URL:** https://picoctf.org/
- **Descripción:** CTF educativo
- **SSH:** Varios desafíos requieren SSH

### 17. OverTheWire (Todos los juegos)

- **URL:** https://overthewire.org/wargames/
- **Juegos:** Bandit, Leviathan, Narnia, etc.
- **SSH:** Todos usan conexión SSH

---

## 💡 Cómo Usar Estos Recursos

### Para Principiantes Absolutos

1. Empieza con **Webminal** para familiarizarte con la terminal
2. Usa **Google Cloud Shell** para tener un entorno real
3. Prueba **OverTheWire Bandit** nivel 0-5

### Para Practicar Conexiones SSH

1. Usa **OverTheWire Bandit** - conexión real
2. Prueba **Google Cloud Shell** → conectar a tu VPS
3. Experimenta con **Play with Docker**

### Para Aprender Más

1. Completa **TryHackMe Linux Fundamentals**
2. Avanza en **OverTheWire Bandit** hasta nivel 15+
3. Explora **HackTheBox** si te interesa seguridad

---

## 📋 Checklist de Práctica

- [ ] Crear cuenta en Google Cloud Shell
- [ ] Conectar a OverTheWire Bandit nivel 0
- [ ] Completar niveles 0-5 de Bandit
- [ ] Probar Play with Docker
- [ ] Explorar Linux Journey

---

<div align="center">

[← Herramientas SSH](05-herramientas-ssh.md) • [Volver a Recursos](README.md) • [Comunidades →](07-comunidades-sysadmin.md)

</div>
