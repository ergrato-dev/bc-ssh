# 🔄 Práctica 03: Backups con rsync

## ⭐⭐⭐ Nivel Avanzado - 30 minutos

![rsync](https://img.shields.io/badge/rsync-Sincronización-red?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-30_min-green?style=for-the-badge)

---

## 🎯 Objetivos

Al completar esta práctica, serás capaz de:

- [ ] Sincronizar directorios sobre SSH
- [ ] Usar exclusiones y filtros
- [ ] Ejecutar simulaciones con --dry-run
- [ ] Crear backups incrementales con --link-dest

---

## 📋 Prerequisitos

- [ ] Servidor SSH accesible
- [ ] rsync instalado local y remotamente
- [ ] Archivos de prácticas anteriores

### Verificar rsync

```bash
# Verificar rsync local
rsync --version | head -1

# Verificar rsync en servidor
ssh tu-servidor "rsync --version | head -1"
```

---

## 🔧 Parte 1: Sincronización Básica

### Ejercicio 1.1: Primera Sincronización (Local → Remoto)

```bash
cd ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/archivos

# Sincronizar directorio al servidor
rsync -avz proyecto/ tu-servidor:~/lab-transferencias/proyecto-sync/

# Observar salida:
# sending incremental file list
# created directory /home/usuario/lab-transferencias/proyecto-sync
# ./
# config/
# config/app.yml
# docs/
# docs/README.md
# src/
# src/index.php
```

### Ejercicio 1.2: Verificar Sincronización

```bash
# Ver estructura en servidor
ssh tu-servidor "ls -laR ~/lab-transferencias/proyecto-sync/"
```

### Ejercicio 1.3: Sincronización Inversa (Remoto → Local)

```bash
mkdir -p ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/sync-remoto

# Descargar del servidor
rsync -avz tu-servidor:~/lab-transferencias/proyecto-sync/ ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/sync-remoto/

# Verificar
ls -la ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/sync-remoto/
```

---

## 🔁 Parte 2: Sincronización Incremental

### Ejercicio 2.1: Modificar Archivos Locales

```bash
cd ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/archivos/proyecto

# Modificar un archivo
echo "Nueva línea añadida" >> src/index.php

# Añadir archivo nuevo
echo "Nuevo archivo" > src/nuevo.php

# Ver cambios
cat src/index.php
ls src/
```

### Ejercicio 2.2: Re-sincronizar (Solo Diferencias)

```bash
cd ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/archivos

# Sincronizar nuevamente
rsync -avz proyecto/ tu-servidor:~/lab-transferencias/proyecto-sync/

# Observar que solo se transfieren los cambios:
# sending incremental file list
# src/
# src/index.php
# src/nuevo.php
```

### Ejercicio 2.3: Verificar Transferencia Incremental

```bash
# Verificar que el archivo modificado está actualizado
ssh tu-servidor "cat ~/lab-transferencias/proyecto-sync/src/index.php"

# El nuevo archivo existe
ssh tu-servidor "ls ~/lab-transferencias/proyecto-sync/src/"
```

---

## 🧪 Parte 3: Simulación con --dry-run

### Ejercicio 3.1: Simular Sincronización

```bash
cd ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/archivos

# Ver qué haría sin ejecutar
rsync -avzn proyecto/ tu-servidor:~/lab-transferencias/proyecto-sync/

# -n es igual a --dry-run
# Debería mostrar (DRY RUN) al final
```

### Ejercicio 3.2: Simular con --delete

```bash
# Eliminar archivo local
rm proyecto/src/nuevo.php

# Ver qué eliminaría en servidor (SIN EJECUTAR)
rsync -avzn --delete proyecto/ tu-servidor:~/lab-transferencias/proyecto-sync/

# Observar:
# deleting src/nuevo.php
# (DRY RUN)
```

### Ejercicio 3.3: Ejecutar con --delete

```bash
# Ahora sí ejecutar
rsync -avz --delete proyecto/ tu-servidor:~/lab-transferencias/proyecto-sync/

# Verificar que se eliminó
ssh tu-servidor "ls ~/lab-transferencias/proyecto-sync/src/"
```

---

## 🚫 Parte 4: Exclusiones

### Ejercicio 4.1: Excluir Patrones

```bash
cd ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/archivos

# Crear archivos que queremos excluir
echo "Log de prueba" > proyecto/app.log
echo "Cache" > proyecto/.cache
mkdir -p proyecto/node_modules
echo "dependencia" > proyecto/node_modules/dep.js

# Sincronizar excluyendo
rsync -avz \
    --exclude '*.log' \
    --exclude '.cache' \
    --exclude 'node_modules/' \
    proyecto/ \
    tu-servidor:~/lab-transferencias/proyecto-clean/

# Verificar que no se copiaron los excluidos
ssh tu-servidor "ls -la ~/lab-transferencias/proyecto-clean/"
```

### Ejercicio 4.2: Archivo de Exclusiones

```bash
# Crear archivo de exclusiones
cat > ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/exclude.txt << 'EOF'
*.log
*.tmp
.cache
.git/
node_modules/
__pycache__/
.env
*.pyc
.DS_Store
EOF

# Usar archivo de exclusiones
rsync -avz \
    --exclude-from="$HOME/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/exclude.txt" \
    proyecto/ \
    tu-servidor:~/lab-transferencias/proyecto-filtered/
```

---

## 💾 Parte 5: Backups con rsync

### Ejercicio 5.1: Backup Simple

```bash
# Crear directorio de backups en servidor
ssh tu-servidor "mkdir -p ~/backups"

# Backup del proyecto
rsync -avz --delete \
    --exclude-from="$HOME/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/exclude.txt" \
    ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/archivos/proyecto/ \
    tu-servidor:~/backups/proyecto/

# Verificar
ssh tu-servidor "ls -la ~/backups/proyecto/"
```

### Ejercicio 5.2: Backup con Timestamp

```bash
# Backup con fecha
FECHA=$(date +%Y%m%d-%H%M%S)

rsync -avz \
    --exclude-from="$HOME/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/exclude.txt" \
    ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/archivos/proyecto/ \
    tu-servidor:~/backups/proyecto-$FECHA/

# Verificar
ssh tu-servidor "ls ~/backups/"
```

---

## 🔗 Parte 6: Backup Incremental con --link-dest

### Ejercicio 6.1: Configurar Estructura

```bash
# Crear estructura de backups incrementales
ssh tu-servidor "mkdir -p ~/backups-incremental"
```

### Ejercicio 6.2: Primer Backup (Full)

```bash
# Primer backup completo
FECHA=$(date +%Y%m%d-%H%M%S)

rsync -avz \
    ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/archivos/proyecto/ \
    tu-servidor:~/backups-incremental/$FECHA/

# Crear enlace simbólico a "latest"
ssh tu-servidor "cd ~/backups-incremental && rm -f latest && ln -s $FECHA latest"

# Verificar
ssh tu-servidor "ls -la ~/backups-incremental/"
```

### Ejercicio 6.3: Backup Incremental

```bash
# Modificar un archivo
echo "Cambio para backup incremental" >> ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/archivos/proyecto/docs/README.md

# Esperar unos segundos para diferenciar timestamp
sleep 2

# Backup incremental usando hard links
FECHA_NUEVA=$(date +%Y%m%d-%H%M%S)

rsync -avz \
    --link-dest=../latest \
    ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/archivos/proyecto/ \
    tu-servidor:~/backups-incremental/$FECHA_NUEVA/

# Actualizar latest
ssh tu-servidor "cd ~/backups-incremental && rm -f latest && ln -s $FECHA_NUEVA latest"
```

### Ejercicio 6.4: Verificar Hard Links

```bash
# Ver backups
ssh tu-servidor "ls ~/backups-incremental/"

# Comparar inodes (archivos sin cambios comparten inodo)
ssh tu-servidor "ls -li ~/backups-incremental/*/src/index.php"
# Los inodos iguales = hard links (no ocupan espacio adicional)

# Ver tamaño real
ssh tu-servidor "du -sh ~/backups-incremental/*"
```

---

## 📊 Parte 7: Opciones Avanzadas

### Ejercicio 7.1: Limitar Ancho de Banda

```bash
# Limitar a 1 MB/s (1000 KB/s)
rsync -avz --bwlimit=1000 \
    ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/archivos/archivo-grande.bin \
    tu-servidor:~/lab-transferencias/
```

### Ejercicio 7.2: Con Estadísticas

```bash
rsync -avz --stats \
    ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/archivos/proyecto/ \
    tu-servidor:~/lab-transferencias/proyecto-stats/

# Observar estadísticas al final:
# Number of files: X
# Number of files transferred: Y
# Total file size: Z bytes
# Total transferred file size: W bytes
```

### Ejercicio 7.3: SSH con Puerto No Estándar

```bash
# Si tu servidor usa puerto diferente
# rsync -avz -e "ssh -p 2222" origen/ servidor:/destino/

# Con llave específica
# rsync -avz -e "ssh -i ~/.ssh/id_especial" origen/ servidor:/destino/
```

---

## 🏆 Desafío Final: Script de Backup Completo

### Crear Script Profesional

```bash
cat > ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/backup-rsync.sh << 'EOF'
#!/bin/bash
#############################################
# Script de Backup con rsync
# Uso: ./backup-rsync.sh /ruta/origen servidor
#############################################

set -e  # Salir si hay error

# Configuración
ORIGEN="${1:-$HOME/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/archivos/proyecto}"
SERVIDOR="${2:-tu-servidor}"
BACKUP_DIR="~/backups-auto"
FECHA=$(date +%Y%m%d-%H%M%S)
EXCLUDE_FILE="$HOME/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/exclude.txt"
LOG_FILE="/tmp/backup-$FECHA.log"

echo "======================================"
echo "Backup rsync - $FECHA"
echo "======================================"
echo "Origen:  $ORIGEN"
echo "Destino: $SERVIDOR:$BACKUP_DIR/$FECHA"
echo ""

# Crear directorio de backup
ssh "$SERVIDOR" "mkdir -p $BACKUP_DIR"

# Verificar si existe backup anterior
if ssh "$SERVIDOR" "test -L $BACKUP_DIR/latest"; then
    echo "📁 Backup incremental (usando latest como base)"
    LINK_DEST="--link-dest=../latest"
else
    echo "📁 Primer backup (full)"
    LINK_DEST=""
fi

# Ejecutar rsync
echo ""
echo "🔄 Iniciando sincronización..."
rsync -avzh --stats \
    $LINK_DEST \
    --exclude-from="$EXCLUDE_FILE" \
    "$ORIGEN/" \
    "$SERVIDOR:$BACKUP_DIR/$FECHA/" 2>&1 | tee "$LOG_FILE"

# Actualizar enlace latest
ssh "$SERVIDOR" "cd $BACKUP_DIR && rm -f latest && ln -s $FECHA latest"

echo ""
echo "======================================"
echo "✅ Backup completado exitosamente"
echo "======================================"
echo "Log guardado en: $LOG_FILE"

# Mostrar backups existentes
echo ""
echo "📊 Backups disponibles:"
ssh "$SERVIDOR" "ls -la $BACKUP_DIR/"
echo ""
echo "💾 Espacio utilizado:"
ssh "$SERVIDOR" "du -sh $BACKUP_DIR/*"
EOF

chmod +x ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/backup-rsync.sh
```

### Ejecutar Script

```bash
# Ejecutar backup
~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/backup-rsync.sh

# Modificar algo y ejecutar de nuevo
echo "Otro cambio" >> ~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/archivos/proyecto/config/app.yml
~/ssh-lab/week-06-transferencia_archivos_scp_sftp_rsync/backup-rsync.sh
```

---

## 📝 Resumen de Comandos rsync

```bash
# Sincronización básica
rsync -avz origen/ servidor:/destino/

# Con exclusiones
rsync -avz --exclude '*.log' origen/ servidor:/destino/

# Simular (dry-run)
rsync -avzn origen/ servidor:/destino/

# Sincronización espejo
rsync -avz --delete origen/ servidor:/destino/

# Backup incremental
rsync -avz --link-dest=../latest origen/ servidor:/destino/

# Con límite de ancho de banda
rsync -avz --bwlimit=1000 origen/ servidor:/destino/
```

---

## 📝 Verificación de Completación

| Tarea                            | Completada |
| -------------------------------- | :--------: |
| Sincronización básica            |     ☐      |
| Sincronización incremental       |     ☐      |
| Usar --dry-run                   |     ☐      |
| Usar --delete                    |     ☐      |
| Exclusiones con --exclude        |     ☐      |
| Archivo de exclusiones           |     ☐      |
| Backup con timestamp             |     ☐      |
| Backup incremental (--link-dest) |     ☐      |
| Script de backup funcional       |     ☐      |

---

## ❓ Troubleshooting

### rsync: command not found (en servidor)

```bash
# Instalar rsync en servidor
ssh tu-servidor "sudo apt update && sudo apt install -y rsync"
```

### Permission denied

```bash
# Verificar permisos de directorio destino
ssh tu-servidor "ls -la ~ && mkdir -p ~/backups"
```

### --link-dest no funciona

```bash
# Debe ser ruta relativa desde el nuevo backup
# ✅ Correcto: --link-dest=../latest
# ❌ Incorrecto: --link-dest=/ruta/absoluta/latest
```

---

## 🧭 Navegación

| ⬅️ Anterior                                    |       🏠 Índice        |                        Siguiente ➡️ |
| :--------------------------------------------- | :--------------------: | ----------------------------------: |
| [Práctica 02](practica-02-sftp-interactivo.md) | [Prácticas](README.md) | [Proyecto](../3-proyecto/README.md) |

---

<div align="center">

**🔄 Práctica 03: Backups con rsync**

_El rey de la sincronización_

</div>
