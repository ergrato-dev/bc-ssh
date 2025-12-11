# 📘 Guía de Implementación

## Sistema de Sincronización Multi-Entorno

---

## 📋 Índice

1. [Preparación del Entorno](#preparación-del-entorno)
2. [Crear Estructura del Proyecto](#crear-estructura-del-proyecto)
3. [Implementar Scripts](#implementar-scripts)
4. [Configurar Exclusiones](#configurar-exclusiones)
5. [Pruebas y Validación](#pruebas-y-validación)

---

## 1. Preparación del Entorno

### 1.1 Configurar Alias SSH

Asegúrate de tener configurados los servidores en `~/.ssh/config`:

```ssh-config
# Servidor de staging (puedes usar el mismo servidor con directorios diferentes)
Host staging
    HostName tu-servidor.com
    User tu-usuario
    IdentityFile ~/.ssh/id_ed25519

# Servidor de producción (puede ser el mismo para práctica)
Host production
    HostName tu-servidor.com
    User tu-usuario
    IdentityFile ~/.ssh/id_ed25519
```

> **Nota**: Para esta práctica, puedes usar el mismo servidor con directorios diferentes para simular staging y producción.

### 1.2 Crear Directorios Remotos

```bash
# Crear estructura en servidor
ssh staging "mkdir -p ~/staging/{app,config,backups} ~/production/{app,config,backups} ~/backups/{staging,production}"

# Verificar
ssh staging "tree ~/ -L 2 2>/dev/null || ls -laR ~/"
```

---

## 2. Crear Estructura del Proyecto

### 2.1 Estructura Local

```bash
# Crear directorio base
mkdir -p ~/ssh-lab/semana-04/proyecto-sync
cd ~/ssh-lab/semana-04/proyecto-sync

# Crear estructura completa
mkdir -p {proyecto-web/{src,config,assets/images},scripts,exclude-files,logs}

# Crear archivos de proyecto web (simulado)
cat > proyecto-web/src/index.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mi Aplicación Web</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <header>
        <h1>Mi Aplicación Web</h1>
        <p>Versión: 1.0.0</p>
    </header>
    <main id="app">
        <p>Cargando...</p>
    </main>
    <script src="app.js"></script>
</body>
</html>
EOF

cat > proyecto-web/src/styles.css << 'EOF'
/* Estilos de la aplicación */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    line-height: 1.6;
    background-color: #f4f4f4;
    color: #333;
}

header {
    background: #35424a;
    color: #ffffff;
    padding: 20px;
    text-align: center;
}

main {
    padding: 20px;
    max-width: 1200px;
    margin: 0 auto;
}
EOF

cat > proyecto-web/src/app.js << 'EOF'
/**
 * Aplicación principal
 */
document.addEventListener('DOMContentLoaded', function() {
    const app = document.getElementById('app');

    app.innerHTML = `
        <h2>Bienvenido</h2>
        <p>Fecha de despliegue: ${new Date().toLocaleString()}</p>
        <p>Entorno: ${window.location.hostname}</p>
    `;

    console.log('Aplicación iniciada correctamente');
});
EOF

# Configuraciones por entorno
cat > proyecto-web/config/development.json << 'EOF'
{
    "environment": "development",
    "debug": true,
    "api_url": "http://localhost:3000/api",
    "database": {
        "host": "localhost",
        "port": 5432,
        "name": "app_dev"
    }
}
EOF

cat > proyecto-web/config/staging.json << 'EOF'
{
    "environment": "staging",
    "debug": true,
    "api_url": "https://staging.ejemplo.com/api",
    "database": {
        "host": "db-staging.interno",
        "port": 5432,
        "name": "app_staging"
    }
}
EOF

cat > proyecto-web/config/production.json << 'EOF'
{
    "environment": "production",
    "debug": false,
    "api_url": "https://api.ejemplo.com",
    "database": {
        "host": "db-prod.interno",
        "port": 5432,
        "name": "app_prod"
    }
}
EOF

# Crear algunos archivos que deben excluirse
echo "DB_PASSWORD=secret123" > proyecto-web/.env
echo "node_modules content" > proyecto-web/node_modules_placeholder
mkdir -p proyecto-web/.git proyecto-web/tmp
echo "git data" > proyecto-web/.git/config
echo "temp file" > proyecto-web/tmp/cache.tmp

# Crear imagen de ejemplo
echo "PNG_IMAGE_DATA" > proyecto-web/assets/images/logo.png

echo "✅ Estructura del proyecto creada"
tree ~/ssh-lab/semana-04/proyecto-sync/ 2>/dev/null || ls -laR ~/ssh-lab/semana-04/proyecto-sync/
```

---

## 3. Implementar Scripts

### 3.1 Variables Comunes (Archivo de Configuración)

```bash
cat > scripts/config.sh << 'EOF'
#!/bin/bash
#############################################
# Configuración común para scripts de sync
#############################################

# Servidores
STAGING_SERVER="staging"
PROD_SERVER="production"  # Puede ser el mismo para pruebas

# Rutas remotas
STAGING_PATH="~/staging/app"
PROD_PATH="~/production/app"
BACKUP_PATH="~/backups"

# Rutas locales
PROJECT_ROOT="$(dirname "$(dirname "$(readlink -f "$0")")")"
SOURCE_DIR="${PROJECT_ROOT}/proyecto-web"
EXCLUDE_DIR="${PROJECT_ROOT}/exclude-files"
LOG_DIR="${PROJECT_ROOT}/logs"

# Archivos de exclusión
DEPLOY_EXCLUDE="${EXCLUDE_DIR}/deploy.exclude"
BACKUP_EXCLUDE="${EXCLUDE_DIR}/backup.exclude"

# Opciones rsync
RSYNC_OPTS="-avzh --stats --progress"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función de logging
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        INFO)  echo -e "${BLUE}[INFO]${NC} $timestamp - $message" ;;
        OK)    echo -e "${GREEN}[OK]${NC} $timestamp - $message" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} $timestamp - $message" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $timestamp - $message" ;;
    esac

    # Guardar en archivo de log
    echo "[$level] $timestamp - $message" >> "${LOG_DIR}/sync-$(date +%Y%m%d).log"
}

# Verificar conectividad
check_connection() {
    local server="$1"
    if ssh -q -o ConnectTimeout=5 "$server" exit 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Confirmar acción
confirm() {
    local message="$1"
    read -p "$message [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}
EOF

chmod +x scripts/config.sh
```

### 3.2 Script de Deploy a Staging

```bash
cat > scripts/deploy-staging.sh << 'EOF'
#!/bin/bash
#############################################
# Deploy a Staging
# Sincroniza código local con servidor staging
#############################################

# Cargar configuración
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/config.sh"

echo "======================================"
echo "🚀 DEPLOY A STAGING"
echo "======================================"
echo ""

log "INFO" "Iniciando deploy a staging"

# Verificar conectividad
log "INFO" "Verificando conexión con $STAGING_SERVER..."
if ! check_connection "$STAGING_SERVER"; then
    log "ERROR" "No se puede conectar a $STAGING_SERVER"
    exit 1
fi
log "OK" "Conexión establecida"

# Verificar que existe el directorio fuente
if [ ! -d "$SOURCE_DIR" ]; then
    log "ERROR" "Directorio fuente no encontrado: $SOURCE_DIR"
    exit 1
fi

# Mostrar lo que se va a hacer
echo ""
echo "📂 Origen:  $SOURCE_DIR"
echo "📍 Destino: $STAGING_SERVER:$STAGING_PATH"
echo ""

# Dry-run primero
log "INFO" "Ejecutando simulación (dry-run)..."
rsync $RSYNC_OPTS --dry-run \
    --exclude-from="$DEPLOY_EXCLUDE" \
    "$SOURCE_DIR/" \
    "$STAGING_SERVER:$STAGING_PATH/"

echo ""
if ! confirm "¿Deseas continuar con el deploy?"; then
    log "WARN" "Deploy cancelado por el usuario"
    exit 0
fi

# Ejecutar deploy real
log "INFO" "Ejecutando sincronización..."
rsync $RSYNC_OPTS \
    --exclude-from="$DEPLOY_EXCLUDE" \
    --delete \
    "$SOURCE_DIR/" \
    "$STAGING_SERVER:$STAGING_PATH/" 2>&1 | tee -a "${LOG_DIR}/deploy-staging-$(date +%Y%m%d-%H%M%S).log"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    log "OK" "Deploy a staging completado exitosamente"

    # Verificar archivos en destino
    echo ""
    echo "📋 Archivos en staging:"
    ssh "$STAGING_SERVER" "ls -la $STAGING_PATH/"
else
    log "ERROR" "Deploy falló"
    exit 1
fi

echo ""
echo "======================================"
echo "✅ DEPLOY COMPLETADO"
echo "======================================"
EOF

chmod +x scripts/deploy-staging.sh
```

### 3.3 Script de Deploy a Producción

```bash
cat > scripts/deploy-prod.sh << 'EOF'
#!/bin/bash
#############################################
# Deploy a Producción
# PRECAUCIÓN: Este script afecta producción
#############################################

# Cargar configuración
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/config.sh"

echo "======================================"
echo "🔴 DEPLOY A PRODUCCIÓN"
echo "======================================"
echo ""
echo "⚠️  ADVERTENCIA: Estás desplegando a PRODUCCIÓN"
echo ""

log "INFO" "Iniciando deploy a producción"

# Verificar conectividad
log "INFO" "Verificando conexión con $PROD_SERVER..."
if ! check_connection "$PROD_SERVER"; then
    log "ERROR" "No se puede conectar a $PROD_SERVER"
    exit 1
fi
log "OK" "Conexión establecida"

# Doble confirmación para producción
echo ""
if ! confirm "⚠️  ¿Estás seguro de desplegar a PRODUCCIÓN?"; then
    log "WARN" "Deploy cancelado"
    exit 0
fi

# Crear backup antes de deploy
log "INFO" "Creando backup pre-deploy..."
BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="pre-deploy-$BACKUP_DATE"

ssh "$PROD_SERVER" "mkdir -p $BACKUP_PATH/production/$BACKUP_NAME"
ssh "$PROD_SERVER" "cp -a $PROD_PATH/. $BACKUP_PATH/production/$BACKUP_NAME/ 2>/dev/null || echo 'No había archivos previos'"

log "OK" "Backup creado: $BACKUP_NAME"

# Mostrar cambios
echo ""
echo "📂 Origen:  $SOURCE_DIR"
echo "📍 Destino: $PROD_SERVER:$PROD_PATH"
echo "💾 Backup:  $BACKUP_PATH/production/$BACKUP_NAME"
echo ""

# Dry-run
log "INFO" "Simulando cambios..."
rsync $RSYNC_OPTS --dry-run \
    --exclude-from="$DEPLOY_EXCLUDE" \
    "$SOURCE_DIR/" \
    "$PROD_SERVER:$PROD_PATH/"

echo ""
if ! confirm "📋 ¿Los cambios son correctos? ¿Proceder?"; then
    log "WARN" "Deploy cancelado por el usuario"
    exit 0
fi

# Deploy real
log "INFO" "Ejecutando deploy a producción..."
rsync $RSYNC_OPTS \
    --exclude-from="$DEPLOY_EXCLUDE" \
    --delete \
    "$SOURCE_DIR/" \
    "$PROD_SERVER:$PROD_PATH/" 2>&1 | tee -a "${LOG_DIR}/deploy-prod-$(date +%Y%m%d-%H%M%S).log"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    log "OK" "Deploy a producción completado"

    # Verificación post-deploy
    echo ""
    echo "🔍 Verificación post-deploy:"
    ssh "$PROD_SERVER" "ls -la $PROD_PATH/"

    # Verificar integridad básica
    LOCAL_COUNT=$(find "$SOURCE_DIR/src" -type f | wc -l)
    REMOTE_COUNT=$(ssh "$PROD_SERVER" "find $PROD_PATH/src -type f 2>/dev/null | wc -l")

    echo ""
    echo "📊 Archivos en src: Local=$LOCAL_COUNT, Remoto=$REMOTE_COUNT"

    if [ "$LOCAL_COUNT" == "$REMOTE_COUNT" ]; then
        log "OK" "Verificación de integridad: OK"
    else
        log "WARN" "Diferencia en conteo de archivos - verificar manualmente"
    fi
else
    log "ERROR" "Deploy falló - considera restaurar desde backup: $BACKUP_NAME"
    exit 1
fi

echo ""
echo "======================================"
echo "✅ DEPLOY A PRODUCCIÓN COMPLETADO"
echo "======================================"
echo "💾 Backup disponible: $BACKUP_NAME"
echo "======================================"
EOF

chmod +x scripts/deploy-prod.sh
```

### 3.4 Script de Backup Incremental

```bash
cat > scripts/backup-incremental.sh << 'EOF'
#!/bin/bash
#############################################
# Backup Incremental
# Usa --link-dest para eficiencia
#############################################

# Cargar configuración
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/config.sh"

# Parámetros
ENTORNO="${1:-staging}"  # staging o production
MAX_BACKUPS=7            # Mantener últimos 7 backups

echo "======================================"
echo "💾 BACKUP INCREMENTAL"
echo "======================================"
echo ""

# Determinar servidor y paths según entorno
case "$ENTORNO" in
    staging)
        SERVER="$STAGING_SERVER"
        APP_PATH="$STAGING_PATH"
        BACKUP_DEST="$BACKUP_PATH/staging"
        ;;
    production)
        SERVER="$PROD_SERVER"
        APP_PATH="$PROD_PATH"
        BACKUP_DEST="$BACKUP_PATH/production"
        ;;
    *)
        log "ERROR" "Entorno no válido: $ENTORNO (usa 'staging' o 'production')"
        exit 1
        ;;
esac

log "INFO" "Iniciando backup de $ENTORNO"

# Verificar conectividad
if ! check_connection "$SERVER"; then
    log "ERROR" "No se puede conectar a $SERVER"
    exit 1
fi

# Crear directorio de backups si no existe
ssh "$SERVER" "mkdir -p $BACKUP_DEST"

# Determinar nombre del nuevo backup
FECHA=$(date +%Y%m%d-%H%M%S)
NEW_BACKUP="backup-$FECHA"

# Verificar si hay backup anterior
LATEST_LINK="$BACKUP_DEST/latest"
HAS_PREVIOUS=$(ssh "$SERVER" "test -L $LATEST_LINK && echo 'yes' || echo 'no'")

if [ "$HAS_PREVIOUS" == "yes" ]; then
    log "INFO" "Backup incremental (basado en latest)"
    LINK_DEST_OPT="--link-dest=../latest"
else
    log "INFO" "Primer backup (completo)"
    LINK_DEST_OPT=""
fi

echo ""
echo "📂 Origen:  $SERVER:$APP_PATH"
echo "💾 Destino: $SERVER:$BACKUP_DEST/$NEW_BACKUP"
echo ""

# Ejecutar backup (remoto a remoto en el mismo servidor)
log "INFO" "Ejecutando backup..."
ssh "$SERVER" "rsync -avh --stats $LINK_DEST_OPT \
    $APP_PATH/ \
    $BACKUP_DEST/$NEW_BACKUP/" 2>&1 | tee -a "${LOG_DIR}/backup-$ENTORNO-$FECHA.log"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    # Actualizar enlace latest
    ssh "$SERVER" "cd $BACKUP_DEST && rm -f latest && ln -s $NEW_BACKUP latest"
    log "OK" "Backup completado: $NEW_BACKUP"

    # Mostrar backups existentes
    echo ""
    echo "📋 Backups disponibles:"
    ssh "$SERVER" "ls -la $BACKUP_DEST/"

    # Mostrar espacio usado (con hard links)
    echo ""
    echo "💿 Espacio utilizado:"
    ssh "$SERVER" "du -sh $BACKUP_DEST/*"

    # Rotación de backups antiguos
    log "INFO" "Verificando rotación de backups..."
    BACKUP_COUNT=$(ssh "$SERVER" "ls -d $BACKUP_DEST/backup-* 2>/dev/null | wc -l")

    if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
        EXCESS=$((BACKUP_COUNT - MAX_BACKUPS))
        log "INFO" "Eliminando $EXCESS backups antiguos..."

        # Eliminar los más antiguos
        ssh "$SERVER" "ls -d $BACKUP_DEST/backup-* | head -$EXCESS | xargs rm -rf"
        log "OK" "Rotación completada"
    fi
else
    log "ERROR" "Backup falló"
    exit 1
fi

echo ""
echo "======================================"
echo "✅ BACKUP COMPLETADO"
echo "======================================"
EOF

chmod +x scripts/backup-incremental.sh
```

### 3.5 Script de Restauración

```bash
cat > scripts/restore-backup.sh << 'EOF'
#!/bin/bash
#############################################
# Restaurar desde Backup
# Recupera una versión anterior
#############################################

# Cargar configuración
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/config.sh"

# Parámetros
ENTORNO="${1:-staging}"
BACKUP_NAME="$2"

echo "======================================"
echo "🔄 RESTAURAR BACKUP"
echo "======================================"
echo ""

# Determinar servidor y paths
case "$ENTORNO" in
    staging)
        SERVER="$STAGING_SERVER"
        APP_PATH="$STAGING_PATH"
        BACKUP_DEST="$BACKUP_PATH/staging"
        ;;
    production)
        SERVER="$PROD_SERVER"
        APP_PATH="$PROD_PATH"
        BACKUP_DEST="$BACKUP_PATH/production"
        ;;
    *)
        log "ERROR" "Entorno no válido: $ENTORNO"
        echo "Uso: $0 <staging|production> [nombre-backup]"
        exit 1
        ;;
esac

# Verificar conectividad
if ! check_connection "$SERVER"; then
    log "ERROR" "No se puede conectar a $SERVER"
    exit 1
fi

# Listar backups disponibles
echo "📋 Backups disponibles en $ENTORNO:"
echo ""
ssh "$SERVER" "ls -la $BACKUP_DEST/ | grep -E 'backup-|latest'"
echo ""

# Si no se especificó backup, pedir selección
if [ -z "$BACKUP_NAME" ]; then
    echo "Backups:"
    ssh "$SERVER" "ls -d $BACKUP_DEST/backup-* 2>/dev/null | xargs -n1 basename"
    echo ""
    read -p "Ingresa el nombre del backup a restaurar: " BACKUP_NAME
fi

# Verificar que existe el backup
if ! ssh "$SERVER" "test -d $BACKUP_DEST/$BACKUP_NAME"; then
    log "ERROR" "Backup no encontrado: $BACKUP_NAME"
    exit 1
fi

echo ""
echo "⚠️  VAS A RESTAURAR:"
echo "📂 Backup:  $BACKUP_DEST/$BACKUP_NAME"
echo "📍 Destino: $APP_PATH"
echo ""

# Confirmación
if ! confirm "¿Estás seguro de restaurar? (Esto sobrescribirá los archivos actuales)"; then
    log "WARN" "Restauración cancelada"
    exit 0
fi

# Crear backup de estado actual antes de restaurar
CURRENT_BACKUP="pre-restore-$(date +%Y%m%d-%H%M%S)"
log "INFO" "Creando backup del estado actual: $CURRENT_BACKUP"
ssh "$SERVER" "mkdir -p $BACKUP_DEST/$CURRENT_BACKUP && cp -a $APP_PATH/. $BACKUP_DEST/$CURRENT_BACKUP/ 2>/dev/null || true"

# Restaurar
log "INFO" "Restaurando desde $BACKUP_NAME..."
ssh "$SERVER" "rsync -avh --delete $BACKUP_DEST/$BACKUP_NAME/ $APP_PATH/"

if [ $? -eq 0 ]; then
    log "OK" "Restauración completada"

    echo ""
    echo "📋 Estado actual de $APP_PATH:"
    ssh "$SERVER" "ls -la $APP_PATH/"
else
    log "ERROR" "Restauración falló"
    exit 1
fi

echo ""
echo "======================================"
echo "✅ RESTAURACIÓN COMPLETADA"
echo "======================================"
echo "💾 Backup pre-restauración: $CURRENT_BACKUP"
echo "======================================"
EOF

chmod +x scripts/restore-backup.sh
```

---

## 4. Configurar Exclusiones

### 4.1 Exclusiones para Deploy

```bash
cat > exclude-files/deploy.exclude << 'EOF'
# Archivos sensibles
.env
.env.*
*.pem
*.key
secrets/
credentials/

# Control de versiones
.git/
.gitignore
.svn/

# Dependencias (se instalan en destino)
node_modules/
vendor/
__pycache__/
*.pyc

# Archivos temporales
tmp/
temp/
.tmp
*.tmp
*.log
*.cache

# IDE y editores
.idea/
.vscode/
*.swp
*.swo
*~

# Sistema operativo
.DS_Store
Thumbs.db

# Archivos de desarrollo
*.test.js
*.spec.js
tests/
__tests__/

# Configuración local
config/development.json
*.local.json
EOF
```

### 4.2 Exclusiones para Backup

```bash
cat > exclude-files/backup.exclude << 'EOF'
# Logs (pueden ser muy grandes)
*.log
logs/

# Cache
*.cache
cache/
.cache/

# Temporales
tmp/
temp/
*.tmp
EOF
```

---

## 5. Pruebas y Validación

### 5.1 Probar Deploy a Staging

```bash
cd ~/ssh-lab/semana-04/proyecto-sync

# Ejecutar deploy
./scripts/deploy-staging.sh

# Verificar en servidor
ssh staging "ls -la ~/staging/app/"
ssh staging "cat ~/staging/app/src/index.html"
```

### 5.2 Probar Backup

```bash
# Crear backup de staging
./scripts/backup-incremental.sh staging

# Modificar algo y crear otro backup
ssh staging "echo 'cambio' >> ~/staging/app/src/app.js"
./scripts/backup-incremental.sh staging

# Ver backups
ssh staging "ls ~/backups/staging/"
```

### 5.3 Probar Restauración

```bash
# Listar backups
./scripts/restore-backup.sh staging

# Restaurar backup específico
./scripts/restore-backup.sh staging backup-YYYYMMDD-HHMMSS
```

---

## 📝 Checklist de Implementación

| Componente                | Estado |
| ------------------------- | :----: |
| Estructura de directorios |   ☐    |
| config.sh                 |   ☐    |
| deploy-staging.sh         |   ☐    |
| deploy-prod.sh            |   ☐    |
| backup-incremental.sh     |   ☐    |
| restore-backup.sh         |   ☐    |
| deploy.exclude            |   ☐    |
| backup.exclude            |   ☐    |
| README.md del proyecto    |   ☐    |
| Pruebas completadas       |   ☐    |

---

## 🧭 Navegación

| ⬅️ Anterior                  |       🏠 Índice       |                    Siguiente ➡️ |
| :--------------------------- | :-------------------: | ------------------------------: |
| [README Proyecto](README.md) | [Proyecto](README.md) | [Ejemplos](EJEMPLOS-CONFIGS.md) |

---

<div align="center">

**📘 Guía de Implementación**

_Sistema de Sincronización Multi-Entorno_

</div>
