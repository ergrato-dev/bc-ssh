# 📋 Ejemplos de Configuración

## Scripts de Referencia Adicionales

---

## 📋 Índice

1. [Script de Sincronización de Configuraciones](#script-de-sincronización-de-configuraciones)
2. [Script de Comparación Pre-Deploy](#script-de-comparación-pre-deploy)
3. [Script de Notificaciones](#script-de-notificaciones)
4. [Ejemplos de Cron Jobs](#ejemplos-de-cron-jobs)
5. [Configuraciones SSH Optimizadas](#configuraciones-ssh-optimizadas)

---

## 1. Script de Sincronización de Configuraciones

### sync-configs.sh

```bash
#!/bin/bash
#############################################
# Sincronizar Configuraciones por Entorno
# Copia la configuración correcta según destino
#############################################

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/config.sh"

ENTORNO="${1:-staging}"

echo "======================================"
echo "⚙️  SINCRONIZAR CONFIGURACIÓN"
echo "======================================"

case "$ENTORNO" in
    staging)
        SERVER="$STAGING_SERVER"
        DEST_PATH="$STAGING_PATH"
        CONFIG_FILE="staging.json"
        ;;
    production)
        SERVER="$PROD_SERVER"
        DEST_PATH="$PROD_PATH"
        CONFIG_FILE="production.json"
        ;;
    *)
        echo "Uso: $0 <staging|production>"
        exit 1
        ;;
esac

log "INFO" "Sincronizando configuración de $ENTORNO"

# Copiar archivo de configuración específico
CONFIG_SRC="${SOURCE_DIR}/config/${CONFIG_FILE}"

if [ ! -f "$CONFIG_SRC" ]; then
    log "ERROR" "Archivo de configuración no encontrado: $CONFIG_SRC"
    exit 1
fi

# Usar scp para archivo individual
scp "$CONFIG_SRC" "${SERVER}:${DEST_PATH}/config/config.json"

if [ $? -eq 0 ]; then
    log "OK" "Configuración sincronizada"
    echo ""
    echo "📋 Configuración en servidor:"
    ssh "$SERVER" "cat ${DEST_PATH}/config/config.json"
else
    log "ERROR" "Error al sincronizar configuración"
    exit 1
fi
```

---

## 2. Script de Comparación Pre-Deploy

### compare-files.sh

```bash
#!/bin/bash
#############################################
# Comparar archivos local vs remoto
# Muestra diferencias antes de deploy
#############################################

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/config.sh"

ENTORNO="${1:-staging}"
FILE="${2:-}"

case "$ENTORNO" in
    staging)
        SERVER="$STAGING_SERVER"
        REMOTE_PATH="$STAGING_PATH"
        ;;
    production)
        SERVER="$PROD_SERVER"
        REMOTE_PATH="$PROD_PATH"
        ;;
esac

echo "======================================"
echo "🔍 COMPARACIÓN DE ARCHIVOS"
echo "======================================"
echo "Entorno: $ENTORNO"
echo ""

if [ -n "$FILE" ]; then
    # Comparar archivo específico
    LOCAL_FILE="${SOURCE_DIR}/${FILE}"
    REMOTE_FILE="${REMOTE_PATH}/${FILE}"

    if [ ! -f "$LOCAL_FILE" ]; then
        echo "❌ Archivo local no existe: $LOCAL_FILE"
        exit 1
    fi

    echo "📄 Comparando: $FILE"
    echo ""

    # Obtener archivo remoto y comparar
    REMOTE_CONTENT=$(ssh "$SERVER" "cat $REMOTE_FILE 2>/dev/null")

    if [ -z "$REMOTE_CONTENT" ]; then
        echo "⚠️  Archivo no existe en remoto (se creará)"
    else
        diff <(cat "$LOCAL_FILE") <(echo "$REMOTE_CONTENT") && echo "✅ Archivos idénticos" || echo "⚠️  Hay diferencias"
    fi
else
    # Listar todos los archivos diferentes
    echo "📋 Archivos que serían modificados:"
    echo ""

    rsync -avzn --delete \
        --exclude-from="$DEPLOY_EXCLUDE" \
        "$SOURCE_DIR/" \
        "$SERVER:$REMOTE_PATH/" 2>/dev/null | grep -E "^[<>]|deleting" || echo "Sin cambios"
fi
```

---

## 3. Script de Notificaciones

### notify.sh

```bash
#!/bin/bash
#############################################
# Enviar Notificaciones
# Soporta: archivo local, webhook
#############################################

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOG_DIR="${SCRIPT_DIR}/../logs"

# Configuración (personalizar)
NOTIFICATION_FILE="${LOG_DIR}/notifications.log"
# WEBHOOK_URL="https://hooks.slack.com/services/XXX/YYY/ZZZ"  # Opcional

notify() {
    local tipo="$1"
    local mensaje="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Log local
    echo "[$tipo] $timestamp - $mensaje" >> "$NOTIFICATION_FILE"

    # Enviar a webhook (descomentar si se usa)
    # if [ -n "$WEBHOOK_URL" ]; then
    #     curl -s -X POST -H 'Content-type: application/json' \
    #         --data "{\"text\":\"[$tipo] $mensaje\"}" \
    #         "$WEBHOOK_URL"
    # fi

    # Mostrar en terminal
    case "$tipo" in
        SUCCESS) echo -e "\033[0;32m✅ $mensaje\033[0m" ;;
        ERROR)   echo -e "\033[0;31m❌ $mensaje\033[0m" ;;
        WARNING) echo -e "\033[1;33m⚠️  $mensaje\033[0m" ;;
        INFO)    echo -e "\033[0;34mℹ️  $mensaje\033[0m" ;;
    esac
}

# Uso desde otros scripts:
# source notify.sh
# notify "SUCCESS" "Deploy a staging completado"
# notify "ERROR" "Backup de producción falló"

# Si se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    notify "${1:-INFO}" "${2:-Notificación de prueba}"
fi
```

### Integrar en deploy-staging.sh

```bash
# Al final del script deploy-staging.sh, agregar:
source "${SCRIPT_DIR}/notify.sh"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    notify "SUCCESS" "Deploy a staging completado - $(date)"
else
    notify "ERROR" "Deploy a staging falló - $(date)"
fi
```

---

## 4. Ejemplos de Cron Jobs

### Backups Automáticos

```bash
# Editar crontab
crontab -e

# Agregar las siguientes líneas:

# Backup de staging cada 6 horas
0 */6 * * * /home/usuario/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/proyecto-sync/scripts/backup-incremental.sh staging >> /home/usuario/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/proyecto-sync/logs/cron-backup.log 2>&1

# Backup de producción diario a las 2 AM
0 2 * * * /home/usuario/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/proyecto-sync/scripts/backup-incremental.sh production >> /home/usuario/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/proyecto-sync/logs/cron-backup.log 2>&1

# Limpieza de logs viejos (más de 30 días) - semanal
0 3 * * 0 find /home/usuario/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/proyecto-sync/logs -name "*.log" -mtime +30 -delete
```

### Script Wrapper para Cron

```bash
#!/bin/bash
#############################################
# Wrapper para ejecución via cron
# Maneja ambiente y logging
#############################################

# Configurar PATH (cron tiene PATH limitado)
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

# Directorio del script
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOG_FILE="${SCRIPT_DIR}/../logs/cron-$(date +%Y%m%d).log"

# Función de log
log_cron() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Ejecutar comando
log_cron "Iniciando: $*"
"$@" >> "$LOG_FILE" 2>&1
EXIT_CODE=$?
log_cron "Finalizado con código: $EXIT_CODE"

exit $EXIT_CODE
```

---

## 5. Configuraciones SSH Optimizadas

### ~/.ssh/config para el proyecto

```ssh-config
# Configuración para proyecto de sincronización
# Agregar a ~/.ssh/config

# Configuración global para todos los hosts del proyecto
Host staging production
    # Autenticación
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

    # Rendimiento
    Compression yes

    # Conexiones persistentes (acelera rsync múltiple)
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600

    # Timeouts
    ConnectTimeout 10
    ServerAliveInterval 60
    ServerAliveCountMax 3

# Servidor de Staging
Host staging
    HostName tu-servidor.com
    User tu-usuario
    Port 22

# Servidor de Producción
Host production
    HostName tu-servidor.com
    User tu-usuario
    Port 22
```

### Crear directorio de sockets

```bash
mkdir -p ~/.ssh/sockets
chmod 700 ~/.ssh/sockets
```

---

## 📁 Estructura Final del Proyecto

```
proyecto-sync/
├── proyecto-web/
│   ├── src/
│   │   ├── index.html
│   │   ├── app.js
│   │   └── styles.css
│   ├── config/
│   │   ├── development.json
│   │   ├── staging.json
│   │   └── production.json
│   └── assets/
│       └── images/
│           └── logo.png
│
├── scripts/
│   ├── config.sh              # Variables comunes
│   ├── deploy-staging.sh      # Deploy a staging
│   ├── deploy-prod.sh         # Deploy a producción
│   ├── backup-incremental.sh  # Backups con --link-dest
│   ├── restore-backup.sh      # Restaurar backup
│   ├── sync-configs.sh        # Sincronizar configs
│   ├── compare-files.sh       # Comparar antes de deploy
│   └── notify.sh              # Notificaciones
│
├── exclude-files/
│   ├── deploy.exclude         # Exclusiones para deploy
│   └── backup.exclude         # Exclusiones para backup
│
├── logs/
│   ├── .gitkeep
│   ├── deploy-staging-*.log
│   ├── deploy-prod-*.log
│   ├── backup-*.log
│   └── notifications.log
│
└── README.md                  # Documentación del proyecto
```

---

## 📝 Plantilla de README para el Proyecto

````markdown
# 🔄 Sistema de Sincronización Multi-Entorno

## Descripción

Sistema automatizado para gestionar despliegues y backups entre
entornos de desarrollo, staging y producción usando rsync sobre SSH.

## Requisitos

- rsync instalado local y remotamente
- SSH configurado con autenticación por llaves
- Acceso a servidores de staging y producción

## Configuración

1. Editar `scripts/config.sh` con tus servidores
2. Configurar `~/.ssh/config` con los alias
3. Personalizar archivos de exclusión

## Uso

### Deploy a Staging

```bash
./scripts/deploy-staging.sh
```
````

### Deploy a Producción

```bash
./scripts/deploy-prod.sh
```

### Crear Backup

```bash
./scripts/backup-incremental.sh staging
./scripts/backup-incremental.sh production
```

### Restaurar Backup

```bash
./scripts/restore-backup.sh staging [nombre-backup]
```

## Logs

Todos los logs se guardan en `logs/`.

## Autor

[Tu nombre]

## Licencia

MIT

```

---

## 🧭 Navegación

| ⬅️ Anterior | 🏠 Índice | Siguiente ➡️ |
|:------------|:---------:|-------------:|
| [Guía](GUIA-IMPLEMENTACION.md) | [Proyecto](README.md) | [Recursos](../4-recursos/README.md) |

---

<div align="center">

**📋 Ejemplos de Configuración**

*Scripts y configuraciones de referencia*

</div>
```
