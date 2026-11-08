# 🏷️ Práctica 01: Aliases y Configuración Básica

## Crear tu Archivo ~/.ssh/config

![Dificultad](https://img.shields.io/badge/Dificultad-⭐_Básica-green?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-30_min-blue?style=for-the-badge)

---

## 🎯 Objetivo

Crear y configurar el archivo `~/.ssh/config` con aliases para tus servidores, eliminando la necesidad de recordar IPs, usuarios y opciones.

---

## 📋 Prerequisitos

- [ ] OpenSSH cliente instalado
- [ ] Al menos una llave SSH generada
- [ ] Acceso a al menos un servidor remoto

---

## 📝 Escenario

Actualmente conectas a tus servidores así:

```bash
# Cada vez que conectas...
ssh -i ~/.ssh/id_ed25519 -p 22 admin@192.168.1.100
ssh -i ~/.ssh/id_trabajo usuario@servidor.empresa.com
ssh -i ~/.ssh/id_personal yo@mi-vps.com -p 2222
```

**Al finalizar esta práctica**, conectarás con:

```bash
ssh servidor-local
ssh trabajo
ssh personal
```

---

## 🔨 Parte 1: Crear el Archivo de Configuración

### Paso 1.1: Verificar Directorio SSH

```bash
# Verificar que existe ~/.ssh
ls -la ~/.ssh/

# Si no existe, crearlo
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

### Paso 1.2: Crear el Archivo config

```bash
# Crear archivo si no existe
touch ~/.ssh/config

# Establecer permisos correctos (IMPORTANTE)
chmod 600 ~/.ssh/config

# Verificar permisos
ls -l ~/.ssh/config
# -rw------- 1 usuario usuario 0 dic 10 10:00 /home/usuario/.ssh/config
```

> ⚠️ **Importante**: Si los permisos no son `600`, SSH puede ignorar el archivo.

### Paso 1.3: Editar con tu Editor Favorito

```bash
# Con nano
nano ~/.ssh/config

# Con vim
vim ~/.ssh/config

# Con VS Code
code ~/.ssh/config
```

---

## 🔨 Parte 2: Configurar tu Primer Host

### Paso 2.1: Sintaxis Básica

Añade tu primer servidor al archivo:

```ssh-config
# Mi primer servidor SSH
Host mi-servidor
    HostName 192.168.1.100
    User admin
    Port 22
    IdentityFile ~/.ssh/id_ed25519
```

### Paso 2.2: Probar la Conexión

```bash
# Antes (sin config)
ssh -i ~/.ssh/id_ed25519 admin@192.168.1.100

# Ahora (con config)
ssh mi-servidor
```

### Paso 2.3: Verificar Configuración Aplicada

```bash
# Ver qué configuración aplica SSH
ssh -G mi-servidor | grep -E "^(hostname|user|port|identityfile)"
```

**Salida esperada:**

```
hostname 192.168.1.100
user admin
port 22
identityfile ~/.ssh/id_ed25519
```

---

## 🔨 Parte 3: Añadir Múltiples Hosts

### Paso 3.1: Configuración Completa

Expande tu archivo con múltiples servidores:

```ssh-config
# ~/.ssh/config
# Configuración SSH Personal
# Última actualización: 2024

# ============================================
# SERVIDOR LOCAL / HOMELAB
# ============================================
Host local
    HostName 192.168.1.100
    User admin
    IdentityFile ~/.ssh/id_ed25519

Host nas
    HostName 192.168.1.50
    User root
    Port 22
    IdentityFile ~/.ssh/id_ed25519

# ============================================
# TRABAJO
# ============================================
Host trabajo-dev
    HostName dev.empresa.com
    User miusuario
    IdentityFile ~/.ssh/id_trabajo

Host trabajo-prod
    HostName prod.empresa.com
    User deploy
    IdentityFile ~/.ssh/id_trabajo
    # Producción = más cuidado
    StrictHostKeyChecking yes

# ============================================
# PROYECTOS PERSONALES
# ============================================
Host mi-vps
    HostName 203.0.113.50
    User yo
    Port 2222
    IdentityFile ~/.ssh/id_personal

# ============================================
# GITHUB
# ============================================
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_github
    IdentitiesOnly yes

# ============================================
# CONFIGURACIÓN GLOBAL
# ============================================
Host *
    AddKeysToAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### Paso 3.2: Probar Cada Conexión

```bash
# Probar conexiones
ssh local
ssh trabajo-dev
ssh mi-vps

# Probar GitHub
ssh -T github.com
# Hi usuario! You've successfully authenticated...
```

---

## 🔨 Parte 4: Usar Patrones y Wildcards

### Paso 4.1: Agrupar Servidores Similares

```ssh-config
# Todos los servidores web usan misma configuración
Host web-*
    User www-data
    IdentityFile ~/.ssh/id_webservers

# Definir servidores específicos
Host web-01
    HostName 10.0.1.10

Host web-02
    HostName 10.0.1.11

Host web-03
    HostName 10.0.1.12
```

### Paso 4.2: Probar Patrones

```bash
# Verificar que el patrón aplica
ssh -G web-01 | grep user
# user www-data

ssh -G web-02 | grep user
# user www-data
```

---

## 🔨 Parte 5: Opciones Avanzadas Útiles

### Paso 5.1: Añadir Opciones de Seguridad

```ssh-config
Host servidor-seguro
    HostName secure.example.com
    User admin

    # Solo autenticación por llave
    PreferredAuthentications publickey
    PasswordAuthentication no

    # Verificar siempre el host
    StrictHostKeyChecking yes

    # No preguntar por hosts desconocidos
    # StrictHostKeyChecking accept-new  # Alternativa moderna
```

### Paso 5.2: Aliases Múltiples para un Servidor

```ssh-config
# Un servidor, múltiples nombres
Host produccion prod p
    HostName 192.168.100.10
    User deploy

# Ahora puedes usar cualquiera:
# ssh produccion
# ssh prod
# ssh p
```

### Paso 5.3: Comentarios Descriptivos

```ssh-config
# ============================================
# CLIENTE: Acme Corporation
# Contacto: admin@acme.com
# VPN requerida: Sí
# ============================================
Host acme-*
    User consultor
    IdentityFile ~/.ssh/id_acme

# Servidor web principal
Host acme-web
    HostName 10.20.30.40

# Base de datos (solo lectura)
Host acme-db
    HostName 10.20.30.50
    # CUIDADO: Producción, solo SELECT
```

---

## ✅ Verificación Final

### Checklist de Completación

- [ ] Archivo `~/.ssh/config` existe
- [ ] Permisos son `600` (`-rw-------`)
- [ ] Al menos 3 hosts configurados
- [ ] Conexión exitosa con alias (`ssh nombre`)
- [ ] Patrón wildcard configurado
- [ ] Configuración global `Host *` presente

### Comandos de Verificación

```bash
# 1. Verificar permisos
ls -l ~/.ssh/config
# -rw------- 1 usuario usuario 1234 dic 10 10:30 /home/usuario/.ssh/config

# 2. Contar hosts configurados
grep -c "^Host " ~/.ssh/config
# 8 (o más)

# 3. Probar conexión con verbose
ssh -v mi-servidor 2>&1 | head -20

# 4. Verificar configuración de un host
ssh -G mi-servidor
```

---

## 🐛 Troubleshooting

### Error: "Bad owner or permissions"

```bash
# Problema: Permisos incorrectos
# Solución:
chmod 600 ~/.ssh/config
chmod 700 ~/.ssh
```

### Error: "Host key verification failed"

```bash
# Opción 1: Aceptar la nueva llave
ssh-keygen -R hostname  # Remover llave antigua
ssh hostname            # Aceptar nueva

# Opción 2: En desarrollo, menos estricto
Host dev-*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

### La Configuración No Aplica

```bash
# Verificar sintaxis
ssh -G hostname

# Verificar orden de bloques
# Recuerda: primera coincidencia gana para cada opción
# Host específico ANTES de Host *
```

---

## 🎯 Ejercicio Extra (Opcional)

Crea una configuración que:

1. Use `Include` para modularizar configs
2. Tenga diferentes archivos para trabajo/personal
3. Use variables de entorno

```bash
# Crear estructura modular
mkdir -p ~/.ssh/config.d

# ~/.ssh/config
Include ~/.ssh/config.d/*.conf

Host *
    ServerAliveInterval 60

# ~/.ssh/config.d/trabajo.conf
Host trabajo-*
    IdentityFile ~/.ssh/id_trabajo

# ~/.ssh/config.d/personal.conf
Host personal-*
    IdentityFile ~/.ssh/id_personal
```

---

## 🧭 Navegación

| ⬅️ Anterior         |       🏠 Índice        |                                        Siguiente ➡️ |
| :------------------ | :--------------------: | --------------------------------------------------: |
| [README](README.md) | [Prácticas](README.md) | [Práctica 02 - ProxyJump](practica-02-proxyjump.md) |

---

<div align="center">

**🏷️ Práctica 01: Aliases y Configuración Básica**

_Tu archivo ~/.ssh/config personal_

</div>
