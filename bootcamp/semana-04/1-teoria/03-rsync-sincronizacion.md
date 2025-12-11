# 🔄 rsync: Sincronización Inteligente

## Módulo 03 - Sincronización y Backups

![Duración](https://img.shields.io/badge/Duración-20_min-blue?style=for-the-badge)
![Nivel](https://img.shields.io/badge/Nivel-Intermedio-yellow?style=for-the-badge)

---

## 🎯 Objetivos del Módulo

Al finalizar este módulo, serás capaz de:

- Entender cómo funciona la sincronización incremental de rsync
- Usar rsync sobre SSH para transferencias seguras
- Configurar opciones para backups eficientes
- Excluir archivos y directorios de la sincronización

---

## 📖 ¿Qué es rsync?

**rsync** es una herramienta de sincronización de archivos que transfiere solo las **diferencias** entre origen y destino, haciendo las transferencias extremadamente eficientes.

### Características Principales

- ✅ **Incremental**: Solo transfiere cambios (delta)
- ✅ **Eficiente**: Minimiza uso de red
- ✅ **Resume**: Continúa transferencias interrumpidas
- ✅ **Compresión**: Comprime durante transferencia
- ✅ **Preserva**: Permisos, timestamps, links, etc.
- ✅ **Exclusiones**: Filtros potentes para excluir archivos

---

## 📊 ¿Cómo Funciona el Delta?

![Flujo rsync](../0-assets/02-flujo-rsync.svg)

### Algoritmo rsync

1. **Checksum**: Calcula hash de bloques en destino
2. **Comparación**: Origen compara con sus bloques
3. **Delta**: Solo envía bloques diferentes
4. **Reconstrucción**: Destino reconstruye archivo

### Ejemplo Visual

```
Archivo original: [A][B][C][D][E]
Archivo modificado: [A][B][X][D][E]

SCP transferiría:  [A][B][X][D][E]  (todo)
rsync transfiere:  [X]              (solo el cambio)
```

---

## 🔧 Sintaxis Básica

### Formato General

```bash
rsync [opciones] origen destino
```

### Tipos de Rutas

```bash
# Local a local
rsync origen/ destino/

# Local a remoto (sobre SSH)
rsync origen/ usuario@servidor:/destino/

# Remoto a local
rsync usuario@servidor:/origen/ destino/
```

> ⚠️ **Importante**: La barra final `/` importa en rsync.

---

## 📁 La Barra Final: origen/ vs origen

### Con Barra: Contenido del Directorio

```bash
rsync -av proyecto/ servidor:/destino/
# Resultado: /destino/archivo1, /destino/archivo2
```

### Sin Barra: El Directorio Mismo

```bash
rsync -av proyecto servidor:/destino/
# Resultado: /destino/proyecto/archivo1, /destino/proyecto/archivo2
```

---

## ⚙️ Opciones Esenciales

### Las Más Usadas

| Opción      | Descripción                                          |
| ----------- | ---------------------------------------------------- |
| `-a`        | Archive: preserva todo (-rlptgoD)                    |
| `-v`        | Verbose: muestra progreso                            |
| `-z`        | Compress: comprime durante transferencia             |
| `-h`        | Human-readable: tamaños legibles                     |
| `-P`        | Progress + partial (resume)                          |
| `--delete`  | Elimina archivos en destino que no existen en origen |
| `--dry-run` | Simula sin hacer cambios                             |
| `-n`        | Igual que --dry-run                                  |

### Opciones de -a (Archive)

```bash
-a equivale a:
  -r  # recursivo
  -l  # preserva symlinks
  -p  # preserva permisos
  -t  # preserva timestamps
  -g  # preserva grupo
  -o  # preserva owner
  -D  # preserva devices y specials
```

### Comando Típico

```bash
# El combo más usado
rsync -avzP origen/ usuario@servidor:/destino/
```

---

## 🔐 rsync sobre SSH

Por defecto, rsync usa SSH para conexiones remotas. Puedes especificar opciones SSH:

### Uso Básico (SSH por defecto)

```bash
rsync -avz /local/ usuario@servidor:/remoto/
```

### Especificar Opciones SSH

```bash
# Puerto no estándar
rsync -avz -e "ssh -p 2222" /local/ usuario@servidor:/remoto/

# Llave específica
rsync -avz -e "ssh -i ~/.ssh/id_deploy" /local/ servidor:/remoto/

# Múltiples opciones
rsync -avz -e "ssh -p 2222 -i ~/.ssh/id_deploy" origen/ destino:/ruta/
```

### Usando ~/.ssh/config

Si tienes configurado tu `~/.ssh/config`, rsync lo usa automáticamente:

```bash
# ~/.ssh/config tiene:
# Host produccion
#     HostName 192.168.100.10
#     User deploy
#     Port 2222

rsync -avz ./app/ produccion:/var/www/app/
```

---

## 🚫 Exclusiones

### Excluir Archivos/Directorios

```bash
# Excluir un patrón
rsync -avz --exclude '*.log' origen/ destino/

# Excluir múltiples
rsync -avz --exclude '*.log' --exclude 'tmp/' --exclude '.git/' origen/ destino/

# Desde archivo
rsync -avz --exclude-from='exclude.txt' origen/ destino/
```

### Archivo de Exclusiones

```bash
# exclude.txt
*.log
*.tmp
.git/
node_modules/
__pycache__/
.DS_Store
*.pyc
.env
```

### Incluir y Excluir Combinados

```bash
# Incluir solo ciertos archivos
rsync -avz --include '*.php' --include '*.html' --exclude '*' origen/ destino/
```

---

## 🗑️ Opción --delete

### Sincronización Espejo

`--delete` elimina archivos en destino que ya no existen en origen:

```bash
# Sin --delete: archivos eliminados en origen persisten en destino
rsync -avz origen/ destino/

# Con --delete: destino es copia exacta de origen
rsync -avz --delete origen/ destino/
```

### Variantes de Delete

| Opción              | Comportamiento                |
| ------------------- | ----------------------------- |
| `--delete`          | Elimina durante transferencia |
| `--delete-before`   | Elimina antes de transferir   |
| `--delete-after`    | Elimina después de transferir |
| `--delete-excluded` | También elimina excluidos     |

> ⚠️ **Precaución**: Siempre usa `--dry-run` primero con `--delete`.

---

## 🧪 --dry-run: Simular Antes de Ejecutar

```bash
# Ver qué haría sin ejecutar
rsync -avzn --delete origen/ destino/

# O con --dry-run
rsync -avz --dry-run --delete origen/ destino/
```

### Salida de dry-run

```
sending incremental file list
deleting old-file.txt
new-file.txt
modified-file.txt

sent 1,234 bytes  received 56 bytes  2,580.00 bytes/sec
total size is 10,234,567  speedup is 7,934.45 (DRY RUN)
```

---

## 📊 Opciones de Progreso

### Mostrar Progreso

```bash
# Progreso por archivo
rsync -avz --progress origen/ destino/

# Progreso + permite resume (-P = --progress --partial)
rsync -avzP origen/ destino/

# Estadísticas al final
rsync -avz --stats origen/ destino/
```

### Limitar Ancho de Banda

```bash
# Limitar a 1 MB/s
rsync -avz --bwlimit=1000 origen/ destino/

# En KB/s
rsync -avz --bwlimit=500 origen/ destino/
```

---

## 💾 Backups con rsync

### Backup Simple

```bash
#!/bin/bash
# backup.sh
rsync -avz --delete \
    --exclude '.git/' \
    --exclude 'node_modules/' \
    /var/www/app/ \
    backup@storage:/backups/app/
```

### Backup con Rotación (Hard Links)

```bash
#!/bin/bash
# backup-incremental.sh
DATE=$(date +%Y-%m-%d)
LATEST="/backups/latest"
DEST="/backups/$DATE"

rsync -avz --delete \
    --link-dest="$LATEST" \
    /var/www/app/ \
    backup@storage:$DEST/

# Actualizar enlace a latest
ssh backup@storage "rm -f $LATEST && ln -s $DEST $LATEST"
```

### Explicación --link-dest

`--link-dest` crea **hard links** a archivos sin cambios:

```
/backups/2024-01-01/archivo.txt  (archivo real)
/backups/2024-01-02/archivo.txt  (hard link, no ocupa espacio extra)
/backups/2024-01-03/archivo.txt  (hard link)
```

Ahorra espacio dramáticamente en backups incrementales.

---

## 🔧 Opciones Avanzadas

### Preservar Más Atributos

```bash
# ACLs y atributos extendidos
rsync -avz --acls --xattrs origen/ destino/

# Hard links
rsync -avz --hard-links origen/ destino/

# Todo lo posible
rsync -avzAXH origen/ destino/
```

### Compresión Selectiva

```bash
# No comprimir archivos ya comprimidos
rsync -avz --compress-level=9 \
    --skip-compress=gz/zip/jpg/png/mp4 \
    origen/ destino/
```

### Checksum Forzado

```bash
# Usar checksum en vez de tamaño/fecha
rsync -avz --checksum origen/ destino/
```

---

## 📝 Ejemplos Prácticos

### Ejemplo 1: Sincronizar Proyecto Web

```bash
rsync -avzP \
    --exclude '.git/' \
    --exclude 'node_modules/' \
    --exclude '.env' \
    ./mi-proyecto/ \
    deploy@produccion:/var/www/mi-proyecto/
```

### Ejemplo 2: Backup de Home

```bash
rsync -avz --delete \
    --exclude-from="$HOME/.rsync-exclude" \
    $HOME/ \
    backup@nas:/backups/home/$(hostname)/
```

### Ejemplo 3: Mirror de Servidor

```bash
rsync -avz --delete \
    --exclude '/var/log/' \
    --exclude '/tmp/' \
    root@servidor1:/ \
    /mirror/servidor1/
```

---

## 📋 Resumen de Comandos

```bash
# Sincronización básica
rsync -avz origen/ destino/

# Sobre SSH con progreso
rsync -avzP origen/ usuario@servidor:/destino/

# Con exclusiones
rsync -avz --exclude '*.log' origen/ destino/

# Sincronización espejo
rsync -avz --delete origen/ destino/

# Simular antes de ejecutar
rsync -avzn --delete origen/ destino/

# Backup incremental
rsync -avz --link-dest=/backup/latest origen/ /backup/$(date +%Y%m%d)/
```

---

## 🎯 Resumen

| Concepto      | Descripción                     |
| ------------- | ------------------------------- |
| rsync         | Sincronización incremental      |
| `-avz`        | Archive, verbose, compress      |
| `-P`          | Progress + partial              |
| `--delete`    | Eliminar archivos no existentes |
| `--exclude`   | Excluir patrones                |
| `--dry-run`   | Simular sin ejecutar            |
| `--link-dest` | Hard links para backups         |
| `-e ssh`      | Especificar opciones SSH        |

---

## 🧭 Navegación

| ⬅️ Anterior                      |      🏠 Índice      |                          Siguiente ➡️ |
| :------------------------------- | :-----------------: | ------------------------------------: |
| [02 - SFTP](02-sftp-sesiones.md) | [Teoría](README.md) | [Prácticas](../2-practicas/README.md) |

---

<div align="center">

**🔄 rsync: Sincronización Inteligente**

_El rey de los backups_

</div>
