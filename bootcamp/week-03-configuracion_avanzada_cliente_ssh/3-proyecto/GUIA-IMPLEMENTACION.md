# 📘 Guía de Implementación

## Proyecto: Configuración SSH Multi-Entorno

![Guía](https://img.shields.io/badge/Tipo-Guía_Paso_a_Paso-blue?style=for-the-badge)

---

## 📋 Tabla de Contenidos

1. [Preparación del Entorno](#-fase-1-preparación-del-entorno)
2. [Configuración Global](#-fase-2-configuración-global)
3. [Entorno de Desarrollo](#-fase-3-entorno-de-desarrollo)
4. [Entorno de Staging](#-fase-4-entorno-de-staging)
5. [Entorno de Producción](#-fase-5-entorno-de-producción)
6. [Testing y Verificación](#-fase-6-testing-y-verificación)
7. [Documentación](#-fase-7-documentación)

---

## 🔧 Fase 1: Preparación del Entorno

### Paso 1.1: Crear Estructura de Directorios

```bash
# Crear directorios necesarios
mkdir -p ~/.ssh/sockets
mkdir -p ~/.ssh/config.d

# Establecer permisos seguros
chmod 700 ~/.ssh
chmod 700 ~/.ssh/sockets
chmod 700 ~/.ssh/config.d
```

### Paso 1.2: Generar Llaves por Entorno

```bash
# Llave para desarrollo
ssh-keygen -t ed25519 -C "dev@empresa.com" -f ~/.ssh/id_ed25519_dev

# Llave para bastion staging
ssh-keygen -t ed25519 -C "stg-bastion@empresa.com" -f ~/.ssh/id_ed25519_stg_bastion

# Llave para servidores staging
ssh-keygen -t ed25519 -C "stg@empresa.com" -f ~/.ssh/id_ed25519_stg

# Llave para producción (una llave para bastion e internos)
ssh-keygen -t ed25519 -C "prod@empresa.com" -f ~/.ssh/id_ed25519_prod
```

### Paso 1.3: Verificar Llaves Creadas

```bash
ls -la ~/.ssh/id_ed25519_*
# Debe mostrar 4 pares de llaves (8 archivos)
```

---

## 🌐 Fase 2: Configuración Global

### Paso 2.1: Crear Archivo Principal

```bash
# Crear/editar archivo principal
nano ~/.ssh/config
```

### Paso 2.2: Añadir Configuración Global

```ssh-config
# ~/.ssh/config
# ============================================================
# CONFIGURACIÓN SSH MULTI-ENTORNO
# Empresa: [Tu Empresa]
# Autor: [Tu Nombre]
# Última actualización: [Fecha]
# ============================================================

# Incluir configuraciones modulares (opcional)
# Include ~/.ssh/config.d/*.conf

# ============================================================
# CONFIGURACIÓN GLOBAL
# Aplica a TODOS los hosts (va al final conceptualmente,
# pero las opciones específicas tienen prioridad)
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
    IdentitiesOnly yes
    HashKnownHosts yes

    # --- Compresión (útil para conexiones lentas) ---
    # Compression yes
```

### Paso 2.3: Verificar Sintaxis

```bash
# Verificar que no hay errores de sintaxis
ssh -G localhost | head -5
```

---

## 💻 Fase 3: Entorno de Desarrollo

### Paso 3.1: Añadir Configuración de Desarrollo

```ssh-config
# ============================================================
# ENTORNO: DESARROLLO
# Red: 192.168.10.0/24
# Acceso: Directo (sin bastion)
# Seguridad: Baja (desarrollo)
# ============================================================

# Patrón para todos los servidores dev
Host dev-*
    User developer
    IdentityFile ~/.ssh/id_ed25519_dev
    # Desarrollo: menos estricto
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
    # Multiplexing corto
    ControlPersist 5m

# Servidores individuales
Host dev-web
    HostName 192.168.10.10

Host dev-db
    HostName 192.168.10.20

Host dev-cache
    HostName 192.168.10.30
```

### Paso 3.2: Probar Conexión de Desarrollo

```bash
# Verificar configuración
ssh -G dev-web | grep -E "^(hostname|user|identityfile|stricthostkeychecking)"

# Probar conexión (si tienes el servidor)
ssh dev-web hostname
```

---

## 🔶 Fase 4: Entorno de Staging

### Paso 4.1: Configurar Bastion de Staging

```ssh-config
# ============================================================
# ENTORNO: STAGING
# Red interna: 10.20.1.0/24
# Acceso: Vía bastion-stg
# Seguridad: Media
# ============================================================

# Bastion de Staging
Host bastion-stg
    HostName stg-bastion.empresa.com
    User security
    Port 22
    IdentityFile ~/.ssh/id_ed25519_stg_bastion
    # No forward agent por seguridad
    ForwardAgent no
    # Aceptar nuevas llaves automáticamente
    StrictHostKeyChecking accept-new
```

### Paso 4.2: Configurar Servidores Internos de Staging

```ssh-config
# Patrón para servidores internos de staging
Host stg-*
    ProxyJump bastion-stg
    IdentityFile ~/.ssh/id_ed25519_stg
    StrictHostKeyChecking accept-new
    ControlPersist 15m

# Servidor web staging
Host stg-web
    HostName 10.20.1.10
    User deploy

# Base de datos staging
Host stg-db
    HostName 10.20.1.20
    User dba
    # Forward local para conectar a MySQL
    LocalForward 33060 localhost:3306

# Cache staging
Host stg-cache
    HostName 10.20.1.30
    User deploy
```

### Paso 4.3: Probar ProxyJump de Staging

```bash
# Verificar configuración
ssh -G stg-web | grep -E "^(hostname|proxyjump|user)"

# Probar conexión (requiere bastion accesible)
ssh -v stg-web 2>&1 | grep -E "(ProxyJump|Connecting)"
```

---

## 🔴 Fase 5: Entorno de Producción

### Paso 5.1: Configurar Bastion de Producción

```ssh-config
# ============================================================
# ENTORNO: PRODUCCIÓN
# Red interna: 10.30.1.0/24
# Acceso: Vía bastion-prod (puerto 2222)
# Seguridad: MÁXIMA
# ============================================================

# Bastion de Producción (puerto no estándar)
Host bastion-prod
    HostName prod-bastion.empresa.com
    User security
    Port 2222
    IdentityFile ~/.ssh/id_ed25519_prod
    # NUNCA forward agent en producción
    ForwardAgent no
    # Verificar SIEMPRE la llave del host
    StrictHostKeyChecking yes
    # Verificar huella visual
    VisualHostKey yes
```

### Paso 5.2: Configurar Servidores Internos de Producción

```ssh-config
# Patrón para servidores de producción
Host prod-*
    ProxyJump bastion-prod
    IdentityFile ~/.ssh/id_ed25519_prod
    # Máxima seguridad
    StrictHostKeyChecking yes
    ForwardAgent no
    # Multiplexing largo (conexiones frecuentes)
    ControlPersist 30m
    # Log detallado para auditoría
    LogLevel VERBOSE

# Servidor web producción
Host prod-web
    HostName 10.30.1.10
    User deploy

# Base de datos producción
Host prod-db
    HostName 10.30.1.20
    User dba
    # CUIDADO: Es producción
    # LocalForward 33061 localhost:3306

# Cache producción
Host prod-cache
    HostName 10.30.1.30
    User deploy
```

### Paso 5.3: Verificar Configuración de Producción

```bash
# Verificar máxima seguridad
ssh -G prod-web | grep -E "^(stricthostkeychecking|forwardagent)"
# stricthostkeychecking yes
# forwardagent no

# Verificar ProxyJump
ssh -G prod-db | grep proxyjump
# proxyjump bastion-prod
```

---

## ✅ Fase 6: Testing y Verificación

### Paso 6.1: Verificar Permisos

```bash
# Verificar permisos de archivos SSH
ls -la ~/.ssh/

# Esperado:
# drwx------  ~/.ssh/
# -rw-------  ~/.ssh/config
# -rw-------  ~/.ssh/id_ed25519_*
# -rw-r--r--  ~/.ssh/id_ed25519_*.pub
# drwx------  ~/.ssh/sockets/

# Corregir si es necesario
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_ed25519_*
chmod 644 ~/.ssh/id_ed25519_*.pub
```

### Paso 6.2: Script de Verificación

```bash
#!/bin/bash
# test-ssh-config.sh

echo "=== Verificación de Configuración SSH ==="
echo

echo "1. Verificando permisos..."
stat -c "%a %n" ~/.ssh ~/.ssh/config ~/.ssh/sockets 2>/dev/null

echo
echo "2. Verificando hosts configurados..."
grep "^Host " ~/.ssh/config | grep -v "Host \*"

echo
echo "3. Verificando desarrollo (dev-web)..."
ssh -G dev-web | grep -E "^(hostname|user|stricthostkeychecking)"

echo
echo "4. Verificando staging (stg-web)..."
ssh -G stg-web | grep -E "^(hostname|user|proxyjump)"

echo
echo "5. Verificando producción (prod-web)..."
ssh -G prod-web | grep -E "^(hostname|user|proxyjump|stricthostkeychecking)"

echo
echo "6. Verificando multiplexing..."
ssh -G dev-web | grep -E "^(controlmaster|controlpath|controlpersist)"

echo
echo "=== Verificación completa ==="
```

### Paso 6.3: Probar Conexiones (si tienes los servidores)

```bash
# Desarrollo (directo)
ssh dev-web hostname

# Staging (vía bastion)
ssh stg-web hostname

# Producción (vía bastion puerto 2222)
ssh prod-web hostname

# Verificar multiplexing
ssh dev-web exit
ssh -O check dev-web  # Debe mostrar "Master running"
```

---

## 📝 Fase 7: Documentación

### Paso 7.1: Crear README del Proyecto

````bash
cat > ~/ssh-config-docs/README.md << 'EOF'
# Configuración SSH Multi-Entorno

## Descripción

Configuración SSH profesional para acceso a tres entornos:
- **Desarrollo**: Acceso directo, seguridad baja
- **Staging**: Vía bastion, seguridad media
- **Producción**: Vía bastion, seguridad máxima

## Uso Rápido

```bash
# Desarrollo
ssh dev-web
ssh dev-db

# Staging
ssh stg-web
ssh stg-db

# Producción
ssh prod-web
ssh prod-db
````

## Llaves Utilizadas

| Entorno         | Llave                           |
| --------------- | ------------------------------- |
| Desarrollo      | `~/.ssh/id_ed25519_dev`         |
| Staging Bastion | `~/.ssh/id_ed25519_stg_bastion` |
| Staging Interno | `~/.ssh/id_ed25519_stg`         |
| Producción      | `~/.ssh/id_ed25519_prod`        |

## Bastiones

| Entorno    | Host                       | Puerto |
| ---------- | -------------------------- | ------ |
| Staging    | `stg-bastion.empresa.com`  | 22     |
| Producción | `prod-bastion.empresa.com` | 2222   |

## Troubleshooting

Ver `troubleshooting.md` para problemas comunes.
EOF

````

### Paso 7.2: Crear Guía de Troubleshooting

```bash
cat > ~/ssh-config-docs/troubleshooting.md << 'EOF'
# Troubleshooting SSH Multi-Entorno

## Problema: "Permission denied"

### En bastion
```bash
# Verificar llave correcta
ssh -i ~/.ssh/id_ed25519_stg_bastion -v bastion-stg
````

### En servidor interno

```bash
# Probar desde el bastion
ssh bastion-stg
ssh deploy@10.20.1.10  # Desde dentro del bastion
```

## Problema: "Connection timed out"

```bash
# Verificar conectividad
ping stg-bastion.empresa.com

# Verificar puerto
nc -zv stg-bastion.empresa.com 22
```

## Problema: Multiplexing no funciona

```bash
# Verificar socket
ssh -O check dev-web

# Limpiar sockets huérfanos
rm ~/.ssh/sockets/*
```

## Problema: ProxyJump no salta

```bash
# Verificar configuración
ssh -G stg-web | grep proxyjump

# Probar manualmente
ssh -J bastion-stg deploy@10.20.1.10 -v
```

EOF

```

---

## 🎯 Checklist Final

- [ ] Estructura de directorios creada
- [ ] Llaves generadas por entorno
- [ ] Configuración global definida
- [ ] Desarrollo configurado (acceso directo)
- [ ] Staging configurado (ProxyJump)
- [ ] Producción configurado (máxima seguridad)
- [ ] Permisos verificados (600/700)
- [ ] Conexiones probadas
- [ ] Documentación creada

---

## 🧭 Navegación

| ⬅️ Anterior | 🏠 Índice | Siguiente ➡️ |
|:------------|:---------:|-------------:|
| [README](README.md) | [Proyecto](README.md) | [Ejemplos de Configuración](EJEMPLOS-CONFIGS.md) |

---

<div align="center">

**📘 Guía de Implementación**

*Paso a paso hacia una configuración profesional*

</div>
```
