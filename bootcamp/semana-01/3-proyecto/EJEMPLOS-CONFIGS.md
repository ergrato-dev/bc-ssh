# 📝 Ejemplos de Configuración SSH

![Referencia](https://img.shields.io/badge/Tipo-Referencia-green?style=flat-square)

---

## 📁 Plantillas de Archivo Config

Esta página contiene ejemplos de configuración que puedes usar como referencia para tu proyecto.

---

## Ejemplo 1: Configuración Básica

La configuración mínima para un servidor:

```ssh-config
Host mi-servidor
    HostName 192.168.1.100
    User root
    Port 22
```

**Uso:**
```bash
ssh mi-servidor
```

---

## Ejemplo 2: Configuración del Proyecto (4 Servidores)

```ssh-config
# ============================================
# SSH Configuration File
# Bootcamp SSH - Semana 01
# ============================================

# --- PRODUCCIÓN ---

Host web-prod
    HostName 134.122.15.92
    User root
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host db-prod
    HostName 10.0.1.20
    User dba
    Port 22
    ServerAliveInterval 60

# --- STAGING ---

Host web-staging
    HostName 10.0.1.10
    User deploy
    Port 22

# --- INFRAESTRUCTURA ---

Host monitoring
    HostName 10.0.1.30
    User monitor
    Port 2222
    ServerAliveInterval 120

# --- CONFIGURACIÓN GLOBAL ---

Host *
    AddKeysToAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

---

## Ejemplo 3: Configuración Empresarial Completa

```ssh-config
# ============================================
# SSH Configuration File
# Empresa: TechStartup S.A.
# Administrador: Juan Pérez
# Última actualización: 2025-11-28
# ============================================

# ============================================
# PRODUCCIÓN - CRÍTICO
# ============================================

# Servidor Web Principal
Host prod-web-1
    HostName web1.produccion.empresa.com
    User deploy
    Port 22
    IdentityFile ~/.ssh/id_ed25519_produccion
    ServerAliveInterval 30
    ServerAliveCountMax 5
    # Compresión para conexiones lentas
    Compression yes

# Servidor Web Secundario (Load Balancer)
Host prod-web-2
    HostName web2.produccion.empresa.com
    User deploy
    Port 22
    IdentityFile ~/.ssh/id_ed25519_produccion

# Base de Datos Principal
Host prod-db-master
    HostName db-master.produccion.empresa.com
    User dba
    Port 22
    IdentityFile ~/.ssh/id_ed25519_produccion
    # Conexión más estable para operaciones largas
    ServerAliveInterval 15
    ServerAliveCountMax 10

# Base de Datos Réplica
Host prod-db-replica
    HostName db-replica.produccion.empresa.com
    User dba
    Port 22
    IdentityFile ~/.ssh/id_ed25519_produccion

# Cache (Redis)
Host prod-cache
    HostName cache.produccion.empresa.com
    User admin
    Port 22

# ============================================
# STAGING - PRUEBAS
# ============================================

Host staging-web
    HostName web.staging.empresa.com
    User developer
    Port 22
    IdentityFile ~/.ssh/id_ed25519_staging

Host staging-db
    HostName db.staging.empresa.com
    User developer
    Port 22
    IdentityFile ~/.ssh/id_ed25519_staging

# ============================================
# DESARROLLO - LOCAL
# ============================================

Host dev-local
    HostName 192.168.1.100
    User developer
    Port 2222
    # Sin verificación de host para desarrollo
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# ============================================
# INFRAESTRUCTURA
# ============================================

# Servidor de Monitoreo (Prometheus/Grafana)
Host infra-monitoring
    HostName monitoring.empresa.com
    User monitor
    Port 22

# Servidor de Logs (ELK Stack)
Host infra-logs
    HostName logs.empresa.com
    User logadmin
    Port 22

# Servidor de CI/CD (Jenkins/GitLab Runner)
Host infra-cicd
    HostName cicd.empresa.com
    User jenkins
    Port 22

# ============================================
# SERVICIOS EXTERNOS
# ============================================

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    AddKeysToAgent yes

# GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519_gitlab
    AddKeysToAgent yes

# Bitbucket
Host bitbucket.org
    HostName bitbucket.org
    User git
    IdentityFile ~/.ssh/id_ed25519_bitbucket

# ============================================
# CONFIGURACIÓN GLOBAL (Aplica a todos)
# ============================================

Host *
    # Agregar llaves al agente automáticamente
    AddKeysToAgent yes
    
    # Mantener conexión activa
    ServerAliveInterval 60
    ServerAliveCountMax 3
    
    # Timeout de conexión
    ConnectTimeout 30
    
    # Usar IPv4 preferentemente
    AddressFamily inet
    
    # Algoritmos de cifrado modernos
    Ciphers aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
    
    # Verificar huella del servidor
    StrictHostKeyChecking ask
```

---

## Ejemplo 4: Configuración con Colores (Comentarios)

```ssh-config
# ╔════════════════════════════════════════════╗
# ║     SSH CONFIG - MI INFRAESTRUCTURA        ║
# ╚════════════════════════════════════════════╝

# ┌────────────────────────────────────────────┐
# │  🌐 SERVIDORES WEB                         │
# └────────────────────────────────────────────┘

Host web-1
    HostName 10.0.0.1
    User webadmin
    Port 22

# ┌────────────────────────────────────────────┐
# │  🗄️ BASES DE DATOS                         │
# └────────────────────────────────────────────┘

Host db-1
    HostName 10.0.0.10
    User dba
    Port 22

# ┌────────────────────────────────────────────┐
# │  📊 MONITOREO                              │
# └────────────────────────────────────────────┘

Host monitor
    HostName 10.0.0.20
    User admin
    Port 22

# ┌────────────────────────────────────────────┐
# │  ⚙️ CONFIGURACIÓN GLOBAL                   │
# └────────────────────────────────────────────┘

Host *
    ServerAliveInterval 60
```

---

## 📊 Referencia Rápida de Directivas

| Directiva | Descripción | Valor Común |
|-----------|-------------|-------------|
| `Host` | Alias del servidor | `mi-servidor` |
| `HostName` | IP o dominio real | `192.168.1.1` |
| `User` | Usuario SSH | `root`, `admin` |
| `Port` | Puerto SSH | `22`, `2222` |
| `IdentityFile` | Ruta a llave privada | `~/.ssh/id_ed25519` |
| `ServerAliveInterval` | Segundos entre keep-alive | `60` |
| `ServerAliveCountMax` | Máx intentos keep-alive | `3` |
| `ConnectTimeout` | Timeout de conexión | `30` |
| `Compression` | Habilitar compresión | `yes`, `no` |
| `StrictHostKeyChecking` | Verificar huella | `yes`, `no`, `ask` |
| `AddKeysToAgent` | Agregar llave al agent | `yes`, `no` |
| `ForwardAgent` | Reenviar agent SSH | `yes`, `no` |

---

## 🔗 Recursos

- [Manual oficial ssh_config](https://man.openbsd.org/ssh_config)
- [SSH Academy - Config File](https://www.ssh.com/academy/ssh/config)

---

<div align="center">

**Semana 01 • Ejemplos de Configuración**

[← Guía de Implementación](GUIA-IMPLEMENTACION.md) • [Volver al Proyecto](README.md)

</div>
