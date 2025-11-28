# 💻 Práctica 01: Instalación del Cliente SSH

![Dificultad](https://img.shields.io/badge/Dificultad-⭐_Básica-green?style=flat-square)
![Duración](https://img.shields.io/badge/Duración-30_minutos-blue?style=flat-square)
![Puntos](https://img.shields.io/badge/Puntos-10-orange?style=flat-square)

---

## 🎯 Objetivo

Instalar y verificar el cliente SSH en tu sistema operativo. Al finalizar, tendrás OpenSSH funcionando correctamente y conocerás los comandos básicos para verificar su estado.

---

## 📋 Prerequisitos

- Acceso a una terminal/consola
- Permisos de administrador (para instalación si es necesario)
- Conexión a internet (para descargar paquetes)

---

## 🐧 Instalación en Linux

### Ubuntu / Debian

```bash
# Verificar si SSH ya está instalado
ssh -V

# Si no está instalado, instalar OpenSSH client
sudo apt update
sudo apt install openssh-client -y

# Verificar la instalación
ssh -V
# Salida esperada: OpenSSH_8.9p1 Ubuntu-3ubuntu0.4, OpenSSL 3.0.2
```

### Fedora / RHEL / CentOS

```bash
# Verificar si SSH ya está instalado
ssh -V

# Si no está instalado
sudo dnf install openssh-clients -y

# En versiones antiguas con yum
sudo yum install openssh-clients -y

# Verificar la instalación
ssh -V
```

### Arch Linux

```bash
# Verificar si SSH ya está instalado
ssh -V

# Si no está instalado
sudo pacman -S openssh

# Verificar la instalación
ssh -V
```

---

## 🍎 Instalación en macOS

macOS viene con OpenSSH preinstalado. Solo necesitas verificarlo:

```bash
# Verificar versión de SSH
ssh -V
# Salida esperada: OpenSSH_9.0p1, LibreSSL 3.3.6

# Verificar ubicación del binario
which ssh
# Salida: /usr/bin/ssh

# Ver opciones disponibles
ssh --help
```

### Actualizar OpenSSH en macOS (opcional)

Si necesitas una versión más reciente:

```bash
# Instalar Homebrew si no lo tienes
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instalar OpenSSH más reciente
brew install openssh

# Verificar nueva versión (puede requerir reiniciar terminal)
ssh -V
```

---

## 🪟 Instalación en Windows

### Opción A: OpenSSH Nativo (Windows 10/11) - Recomendado

Windows 10 (versión 1809+) y Windows 11 incluyen OpenSSH como característica opcional.

**Verificar si está instalado:**

```powershell
# En PowerShell
ssh -V

# Si aparece la versión, ya está instalado
# Si no, continúa con la instalación
```

**Instalar via Configuración (GUI):**

1. Abre **Configuración** → **Aplicaciones** → **Características opcionales**
2. Busca "OpenSSH Client"
3. Si no aparece instalado, haz clic en **Agregar una característica**
4. Busca "OpenSSH Client" y haz clic en **Instalar**

**Instalar via PowerShell (como Administrador):**

```powershell
# Verificar disponibilidad
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'

# Instalar cliente SSH
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

# Verificar instalación
ssh -V
```

### Opción B: Git Bash (Alternativa)

Git para Windows incluye SSH:

1. Descarga Git desde https://git-scm.com/download/win
2. Durante la instalación, asegúrate de incluir Git Bash
3. Abre Git Bash y verifica:

```bash
ssh -V
```

### Opción C: WSL2 (Windows Subsystem for Linux)

La mejor experiencia SSH en Windows es usando WSL2:

```powershell
# En PowerShell como Administrador
wsl --install

# Reinicia el PC
# Abre Ubuntu desde el menú inicio

# Ya tendrás SSH disponible
ssh -V
```

---

## ✅ Verificación de la Instalación

Ejecuta estos comandos para confirmar que SSH funciona correctamente:

### 1. Verificar versión

```bash
ssh -V
```

**Salida esperada:**

```
OpenSSH_9.0p1, OpenSSL 3.0.2 15 Mar 2022
```

### 2. Ver ayuda del comando

```bash
ssh --help
```

**Salida esperada (parcial):**

```
usage: ssh [-46AaCfGgKkMNnqsTtVvXxYy] [-B bind_interface]
           [-b bind_address] [-c cipher_spec] [-D [bind_address:]port]
           [-E log_file] [-e escape_char] [-F configfile] [-I pkcs11]
           ...
```

### 3. Verificar ubicación del binario

```bash
# Linux/macOS
which ssh

# Windows PowerShell
Get-Command ssh
```

### 4. Verificar que el directorio SSH existe

```bash
# Linux/macOS
ls -la ~/.ssh

# Si no existe, créalo
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Windows PowerShell
ls $env:USERPROFILE\.ssh

# Si no existe
mkdir $env:USERPROFILE\.ssh
```

---

## 🔧 Configuración Inicial del Directorio SSH

El directorio `~/.ssh` es donde se almacenan las configuraciones y llaves SSH.

```bash
# Crear directorio si no existe
mkdir -p ~/.ssh

# Establecer permisos correctos (IMPORTANTE para seguridad)
chmod 700 ~/.ssh

# Verificar permisos
ls -la ~ | grep .ssh
# Salida esperada: drwx------ .ssh
```

### Estructura del directorio ~/.ssh

```
~/.ssh/
├── config          # Archivo de configuración (lo crearemos en práctica 3)
├── known_hosts     # Servidores conocidos (se llena automáticamente)
├── id_rsa          # Llave privada RSA (semana 2)
├── id_rsa.pub      # Llave pública RSA (semana 2)
├── id_ed25519      # Llave privada Ed25519 (semana 2)
└── id_ed25519.pub  # Llave pública Ed25519 (semana 2)
```

---

## 🐛 Troubleshooting

### Error: "ssh: command not found"

**Linux:**

```bash
sudo apt install openssh-client  # Debian/Ubuntu
sudo dnf install openssh-clients # Fedora
```

**macOS:**

```bash
# SSH debería estar preinstalado
# Si no, reinstala Xcode Command Line Tools
xcode-select --install
```

**Windows:**

```powershell
# Instalar via PowerShell como Admin
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

### Error: Permisos incorrectos en ~/.ssh

```bash
# El directorio debe ser solo accesible por el usuario
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
```

### Error: "WARNING: UNPROTECTED PRIVATE KEY FILE!"

```bash
# Las llaves privadas deben tener permisos 600
chmod 600 ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_ed25519
```

---

## 📝 Checklist de Verificación

Antes de continuar, asegúrate de que:

- [ ] `ssh -V` muestra una versión de OpenSSH
- [ ] El directorio `~/.ssh` existe
- [ ] Los permisos de `~/.ssh` son 700 (drwx------)
- [ ] Puedes ver la ayuda con `ssh --help`

---

## 🎯 Entregable

Captura de pantalla mostrando:

1. Salida de `ssh -V`
2. Salida de `ls -la ~/.ssh` (o equivalente en Windows)

---

## ⏭️ Siguiente Práctica

[Práctica 02: Primera Conexión Remota →](practica-02-primera-conexion.md)

---

<div align="center">

**Semana 01 • Práctica 01 de 03**

[← Volver al índice](README.md)

</div>
