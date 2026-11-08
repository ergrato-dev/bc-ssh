# 📋 Ejemplos de Configuración

## Proyecto: Configuración SSH Multi-Entorno

![Ejemplos](https://img.shields.io/badge/Tipo-Referencia-green?style=for-the-badge)

---

## 📖 Tabla de Contenidos

1. [Configuración Completa](#-configuración-completa)
2. [Configuración Modular](#-configuración-modular)
3. [Variantes por Caso de Uso](#-variantes-por-caso-de-uso)
4. [Anti-patrones a Evitar](#-anti-patrones-a-evitar)

---

## 📄 Configuración Completa

### Archivo Único ~/.ssh/config

```ssh-config
# ============================================================
# CONFIGURACIÓN SSH MULTI-ENTORNO
# ============================================================
# Empresa: Acme Corporation
# Autor: DevOps Team
# Versión: 1.0
# Última actualización: 2024-01-15
#
# ESTRUCTURA:
#   1. Servicios externos (GitHub, GitLab)
#   2. Desarrollo (acceso directo)
#   3. Staging (vía bastion)
#   4. Producción (vía bastion, máxima seguridad)
#   5. Configuración global (Host *)
# ============================================================


# ============================================================
# SERVICIOS EXTERNOS
# ============================================================

# GitHub
Host github.com gh
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes

# GitLab
Host gitlab.com gl
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519_gitlab
    IdentitiesOnly yes


# ============================================================
# ENTORNO: DESARROLLO
# ============================================================
# Red: 192.168.10.0/24
# Acceso: Directo
# Seguridad: Baja (ambiente controlado)
# ============================================================

# Configuración común para desarrollo
Host dev-*
    User developer
    IdentityFile ~/.ssh/id_ed25519_dev
    IdentitiesOnly yes
    # Desarrollo = menos restricciones
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
    # Multiplexing corto
    ControlPersist 5m
    # Compresión desactivada (red local)
    Compression no

# Servidores de desarrollo
Host dev-web
    HostName 192.168.10.10

Host dev-api
    HostName 192.168.10.11

Host dev-db
    HostName 192.168.10.20
    User postgres
    # Forward local para pgAdmin
    LocalForward 54320 localhost:5432

Host dev-cache
    HostName 192.168.10.30
    # Forward para Redis
    LocalForward 63790 localhost:6379

Host dev-queue
    HostName 192.168.10.40


# ============================================================
# ENTORNO: STAGING
# ============================================================
# Red interna: 10.20.0.0/16
# Acceso: Vía bastion-stg
# Seguridad: Media
# ============================================================

# Bastion Staging
Host bastion-stg bstg
    HostName stg-bastion.empresa.com
    User security
    Port 22
    IdentityFile ~/.ssh/id_ed25519_stg_bastion
    IdentitiesOnly yes
    ForwardAgent no
    StrictHostKeyChecking accept-new
    # Multiplexing para bastion
    ControlPersist 20m

# Configuración común para staging interno
Host stg-*
    ProxyJump bastion-stg
    IdentityFile ~/.ssh/id_ed25519_stg
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    ControlPersist 15m

# Servidores staging
Host stg-web
    HostName 10.20.1.10
    User deploy

Host stg-api
    HostName 10.20.1.11
    User deploy

Host stg-db
    HostName 10.20.1.20
    User dba
    LocalForward 54321 localhost:5432

Host stg-cache
    HostName 10.20.1.30
    User deploy

Host stg-queue
    HostName 10.20.1.40
    User deploy


# ============================================================
# ENTORNO: PRODUCCIÓN
# ============================================================
# Red interna: 10.30.0.0/16
# Acceso: Vía bastion-prod (puerto 2222)
# Seguridad: MÁXIMA
# ============================================================

# Bastion Producción
Host bastion-prod bprod
    HostName prod-bastion.empresa.com
    User security
    Port 2222
    IdentityFile ~/.ssh/id_ed25519_prod
    IdentitiesOnly yes
    # NUNCA forward agent en producción
    ForwardAgent no
    # Verificación estricta
    StrictHostKeyChecking yes
    VisualHostKey yes
    # Multiplexing largo
    ControlPersist 30m

# Configuración común para producción
Host prod-*
    ProxyJump bastion-prod
    IdentityFile ~/.ssh/id_ed25519_prod
    IdentitiesOnly yes
    # MÁXIMA SEGURIDAD
    StrictHostKeyChecking yes
    ForwardAgent no
    ControlPersist 30m
    # Log para auditoría
    LogLevel VERBOSE

# Servidores producción
Host prod-web-1 prod-web
    HostName 10.30.1.10
    User deploy

Host prod-web-2
    HostName 10.30.1.11
    User deploy

Host prod-api-1 prod-api
    HostName 10.30.1.20
    User deploy

Host prod-api-2
    HostName 10.30.1.21
    User deploy

Host prod-db-master prod-db
    HostName 10.30.2.10
    User dba
    # SIN LocalForward por seguridad
    # Usar solo en emergencias con -L

Host prod-db-replica
    HostName 10.30.2.11
    User dba

Host prod-cache-1 prod-cache
    HostName 10.30.3.10
    User deploy

Host prod-cache-2
    HostName 10.30.3.11
    User deploy


# ============================================================
# CONFIGURACIÓN GLOBAL
# ============================================================
# Aplica a todos los hosts (opciones por defecto)
# ============================================================

Host *
    # --- Multiplexing ---
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%C
    ControlPersist 10m

    # --- Keep-Alive ---
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes

    # --- Timeouts ---
    ConnectTimeout 10
    ConnectionAttempts 2

    # --- Seguridad Base ---
    AddKeysToAgent yes
    HashKnownHosts yes

    # --- Algoritmos Seguros ---
    # Descomentar para forzar algoritmos modernos
    # KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
    # Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
    # MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
```

---

## 📁 Configuración Modular

### Estructura de Archivos

```
~/.ssh/
├── config                    # Archivo principal
├── config.d/
│   ├── 00-global.conf       # Configuración global
│   ├── 05-servicios.conf    # GitHub, GitLab, etc.
│   ├── 10-desarrollo.conf   # Entorno dev
│   ├── 20-staging.conf      # Entorno staging
│   └── 30-produccion.conf   # Entorno producción
└── sockets/                  # Directorio de sockets
```

### Archivo Principal (~/.ssh/config)

```ssh-config
# ~/.ssh/config
# Configuración SSH modular

# Incluir todos los archivos de configuración
Include ~/.ssh/config.d/*.conf
```

### 00-global.conf

```ssh-config
# ~/.ssh/config.d/00-global.conf
# Configuración global para todos los hosts

Host *
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%C
    ControlPersist 10m
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ConnectTimeout 10
    AddKeysToAgent yes
```

### 05-servicios.conf

```ssh-config
# ~/.ssh/config.d/05-servicios.conf
# Servicios externos

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes

Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519_gitlab
    IdentitiesOnly yes
```

### 10-desarrollo.conf

```ssh-config
# ~/.ssh/config.d/10-desarrollo.conf
# Entorno de desarrollo

Host dev-*
    User developer
    IdentityFile ~/.ssh/id_ed25519_dev
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ControlPersist 5m

Host dev-web
    HostName 192.168.10.10

Host dev-db
    HostName 192.168.10.20
```

### 20-staging.conf

```ssh-config
# ~/.ssh/config.d/20-staging.conf
# Entorno de staging

Host bastion-stg
    HostName stg-bastion.empresa.com
    User security
    IdentityFile ~/.ssh/id_ed25519_stg_bastion

Host stg-*
    ProxyJump bastion-stg
    IdentityFile ~/.ssh/id_ed25519_stg
    StrictHostKeyChecking accept-new

Host stg-web
    HostName 10.20.1.10
    User deploy

Host stg-db
    HostName 10.20.1.20
    User dba
```

### 30-produccion.conf

```ssh-config
# ~/.ssh/config.d/30-produccion.conf
# Entorno de producción - MÁXIMA SEGURIDAD

Host bastion-prod
    HostName prod-bastion.empresa.com
    User security
    Port 2222
    IdentityFile ~/.ssh/id_ed25519_prod
    ForwardAgent no
    StrictHostKeyChecking yes

Host prod-*
    ProxyJump bastion-prod
    IdentityFile ~/.ssh/id_ed25519_prod
    StrictHostKeyChecking yes
    ForwardAgent no
    LogLevel VERBOSE

Host prod-web
    HostName 10.30.1.10
    User deploy

Host prod-db
    HostName 10.30.2.10
    User dba
```

---

## 🔧 Variantes por Caso de Uso

### Variante 1: Con AWS/Cloud

```ssh-config
# AWS EC2 instances
Host aws-*
    User ec2-user
    IdentityFile ~/.ssh/aws-key.pem
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new

Host aws-bastion
    HostName 54.123.45.67

Host aws-web
    HostName 10.0.1.100
    ProxyJump aws-bastion

Host aws-db
    HostName 10.0.2.100
    ProxyJump aws-bastion
```

### Variante 2: Con Docker/Contenedores

```ssh-config
# Contenedores Docker locales
Host docker-*
    User root
    Port 2222
    IdentityFile ~/.ssh/id_ed25519_docker
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host docker-web
    HostName localhost
    Port 2222

Host docker-db
    HostName localhost
    Port 2223
```

### Variante 3: Trabajo Remoto con VPN

```ssh-config
# Cuando estás en VPN, conexión directa
# Cuando estás fuera, usa bastion
Match host *.internal exec "ip route | grep -q 10.0.0.0/8"
    ProxyJump none

Match host *.internal
    ProxyJump bastion

Host *.internal
    User developer
    IdentityFile ~/.ssh/id_work
```

---

## ❌ Anti-patrones a Evitar

### ❌ NO: Llave única para todo

```ssh-config
# MAL: Una llave para todos los entornos
Host *
    IdentityFile ~/.ssh/id_rsa  # ¡Riesgo de seguridad!
```

### ✅ SÍ: Llaves separadas por entorno

```ssh-config
Host dev-*
    IdentityFile ~/.ssh/id_ed25519_dev

Host prod-*
    IdentityFile ~/.ssh/id_ed25519_prod
```

---

### ❌ NO: ForwardAgent en producción

```ssh-config
# MAL: Forward agent a bastion de producción
Host bastion-prod
    ForwardAgent yes  # ¡El bastion puede usar tus llaves!
```

### ✅ SÍ: ForwardAgent desactivado

```ssh-config
Host bastion-prod
    ForwardAgent no
```

---

### ❌ NO: StrictHostKeyChecking no en producción

```ssh-config
# MAL: Ignorar verificación en producción
Host prod-*
    StrictHostKeyChecking no  # ¡Vulnerable a MITM!
```

### ✅ SÍ: Verificación estricta

```ssh-config
Host prod-*
    StrictHostKeyChecking yes
```

---

### ❌ NO: Permisos incorrectos

```bash
# MAL
chmod 644 ~/.ssh/config    # Muy permisivo
chmod 777 ~/.ssh/          # ¡Peligroso!
```

### ✅ SÍ: Permisos correctos

```bash
chmod 700 ~/.ssh/
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/*.pub
```

---

### ❌ NO: Host \* al inicio

```ssh-config
# MAL: Global antes de específicos
Host *
    User admin

Host prod-web
    # User admin ya aplicó, no se puede sobrescribir fácilmente
```

### ✅ SÍ: Host \* al final (o usar Match)

```ssh-config
# Específicos primero
Host prod-web
    User deploy

# Global después
Host *
    ServerAliveInterval 60
```

---

## 📊 Tabla Comparativa

| Aspecto               | Desarrollo | Staging    | Producción     |
| --------------------- | ---------- | ---------- | -------------- |
| Acceso                | Directo    | Bastion    | Bastion (2222) |
| StrictHostKeyChecking | no         | accept-new | yes            |
| ForwardAgent          | opcional   | no         | **NUNCA**      |
| LogLevel              | ERROR      | INFO       | VERBOSE        |
| ControlPersist        | 5m         | 15m        | 30m            |
| Llave                 | id_dev     | id_stg     | id_prod        |

---

## 🧭 Navegación

| ⬅️ Anterior                                      |       🏠 Índice       |                        Siguiente ➡️ |
| :----------------------------------------------- | :-------------------: | ----------------------------------: |
| [Guía de Implementación](GUIA-IMPLEMENTACION.md) | [Proyecto](README.md) | [Recursos](../4-recursos/README.md) |

---

<div align="center">

**📋 Ejemplos de Configuración**

_Referencias para tu implementación_

</div>
