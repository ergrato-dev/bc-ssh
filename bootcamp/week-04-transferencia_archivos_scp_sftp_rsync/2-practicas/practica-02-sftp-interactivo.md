# 📂 Práctica 02: Sesiones SFTP

## ⭐⭐ Nivel Intermedio - 30 minutos

![SFTP](https://img.shields.io/badge/SFTP-Interactivo-purple?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-30_min-green?style=for-the-badge)

---

## 🎯 Objetivos

Al completar esta práctica, serás capaz de:

- [ ] Conectar y navegar en sesiones SFTP
- [ ] Transferir archivos con get/put
- [ ] Gestionar archivos en el servidor remoto
- [ ] Automatizar transferencias con modo batch

---

## 📋 Prerequisitos

- [ ] Servidor SSH accesible
- [ ] Práctica 01 completada (archivos en el servidor)
- [ ] Archivos locales de prueba disponibles

---

## 🔧 Parte 1: Conexión y Navegación

### Ejercicio 1.1: Iniciar Sesión SFTP

```bash
# Conectar al servidor
sftp tu-servidor

# Verás el prompt:
# sftp>
```

### Ejercicio 1.2: Explorar Sistema Remoto

```
sftp> pwd
# Muestra directorio actual remoto

sftp> ls -la
# Lista archivos en directorio actual

sftp> cd lab-transferencias
sftp> pwd
# Ahora estás en ~/lab-transferencias

sftp> ls -la
# Ver archivos de práctica anterior
```

### Ejercicio 1.3: Explorar Sistema Local

```
sftp> lpwd
# Muestra directorio local actual

sftp> lls
# Lista archivos locales

sftp> lcd ~/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/archivos
sftp> lpwd
# Ahora tu directorio local es archivos/

sftp> lls
# Ver archivos locales
```

---

## 📤 Parte 2: Transferencias Básicas

### Ejercicio 2.1: Subir Archivo (put)

```
# Asegurarse de estar en directorios correctos
sftp> lcd ~/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/archivos
sftp> cd ~/lab-transferencias

# Subir un archivo
sftp> put app.log
# Uploading app.log to /home/usuario/lab-transferencias/app.log

# Verificar
sftp> ls -la app.log
```

### Ejercicio 2.2: Descargar Archivo (get)

```
sftp> lcd ~/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/downloads
sftp> cd ~/lab-transferencias

# Descargar un archivo
sftp> get config.txt
# Fetching /home/usuario/lab-transferencias/config.txt to config.txt

# Verificar localmente
sftp> lls config.txt
```

### Ejercicio 2.3: Transferir con Nombre Diferente

```
# Subir con otro nombre
sftp> put documento-1.txt doc-renombrado.txt

# Descargar con otro nombre
sftp> get config.txt config-downloaded.txt

# Verificar
sftp> ls doc-renombrado.txt
sftp> lls config-downloaded.txt
```

---

## 📁 Parte 3: Múltiples Archivos

### Ejercicio 3.1: Subir Múltiples (mput)

```
sftp> lcd ~/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/archivos
sftp> cd ~/lab-transferencias

# Subir todos los .txt
sftp> mput *.txt
# Confirmará cada archivo (y/n)
```

### Ejercicio 3.2: Descargar Múltiples (mget)

```
sftp> lcd ~/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/downloads
sftp> cd ~/lab-transferencias

# Descargar todos los .txt
sftp> mget *.txt
# Confirmará cada archivo
```

### Ejercicio 3.3: Transferir Directorio

```
sftp> lcd ~/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/archivos
sftp> cd ~/lab-transferencias

# Subir directorio recursivamente
sftp> put -r proyecto

# Verificar
sftp> ls proyecto
sftp> ls proyecto/src
```

---

## 🗂️ Parte 4: Gestión de Archivos Remotos

### Ejercicio 4.1: Crear Directorio

```
sftp> cd ~/lab-transferencias
sftp> mkdir backups
sftp> ls -la
# Verás el nuevo directorio backups/
```

### Ejercicio 4.2: Renombrar Archivo

```
sftp> rename config.txt configuracion.txt
sftp> ls *.txt
```

### Ejercicio 4.3: Cambiar Permisos

```
sftp> chmod 755 backups
sftp> ls -la
# Verás drwxr-xr-x para backups/
```

### Ejercicio 4.4: Eliminar Archivos

```
# Eliminar archivo
sftp> rm doc-renombrado.txt

# Verificar
sftp> ls doc-renombrado.txt
# Debería dar error: file not found
```

### Ejercicio 4.5: Ver Espacio Disponible

```
sftp> df
# Muestra espacio en disco del servidor
```

---

## 💻 Parte 5: Comandos Locales

### Ejercicio 5.1: Ejecutar Comandos Locales

```
# Prefijo ! para comandos locales
sftp> !pwd
sftp> !ls -la
sftp> !date

# Ver contenido de archivo local
sftp> !cat ~/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/archivos/config.txt
```

### Ejercicio 5.2: Crear Archivo Local

```
sftp> !echo "Creado desde SFTP" > /tmp/desde-sftp.txt
sftp> !cat /tmp/desde-sftp.txt
```

---

## 🤖 Parte 6: Modo Batch (Automatización)

### Ejercicio 6.1: Archivo de Comandos

```bash
# Primero, salir de SFTP
sftp> bye

# Crear archivo de comandos
cat > /tmp/sftp-batch.txt << 'EOF'
cd lab-transferencias
lcd /tmp
mkdir sftp-batch-test
cd sftp-batch-test
put desde-sftp.txt
ls -la
bye
EOF

# Ejecutar batch
sftp -b /tmp/sftp-batch.txt tu-servidor
```

### Ejercicio 6.2: Batch con Here-Document

```bash
# Ejecutar comandos inline
sftp tu-servidor << 'EOF'
cd lab-transferencias
ls -la
pwd
bye
EOF
```

### Ejercicio 6.3: Script de Backup Automatizado

```bash
# Crear script
cat > ~/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/sftp-backup.sh << 'EOF'
#!/bin/bash
# Script de backup via SFTP

FECHA=$(date +%Y%m%d-%H%M%S)
DESTINO=~/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/backups/sftp-$FECHA

mkdir -p "$DESTINO"
cd "$DESTINO"

sftp tu-servidor << COMMANDS
cd lab-transferencias
lcd $DESTINO
mget *.txt
get -r proyecto
bye
COMMANDS

echo "Backup completado en $DESTINO"
ls -la "$DESTINO"
EOF

chmod +x ~/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/sftp-backup.sh

# Ejecutar
~/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/sftp-backup.sh
```

---

## 🔍 Parte 7: Opciones Avanzadas

### Ejercicio 7.1: Limitar Ancho de Banda

```bash
# Conectar con límite de 100 Kbit/s
sftp -l 100 tu-servidor

sftp> put archivo-grande.bin
# Observar transferencia lenta
sftp> bye
```

### Ejercicio 7.2: Modo Verbose

```bash
# Ver detalles de conexión
sftp -v tu-servidor << 'EOF'
pwd
ls
bye
EOF
```

---

## 🏆 Desafío Final

### Escenario: Gestión de Logs

```bash
# 1. Conectar y crear estructura
sftp tu-servidor << 'EOF'
cd lab-transferencias
mkdir logs-app
cd logs-app
bye
EOF

# 2. Subir logs simulados
cd ~/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/archivos
for i in {1..5}; do
    echo "Log entry $i - $(date)" > log-$i.txt
done

sftp tu-servidor << 'EOF'
cd lab-transferencias/logs-app
lcd ~/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/archivos
mput log-*.txt
ls -la
bye
EOF

# 3. Descargar para análisis
mkdir -p ~/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/analisis
sftp tu-servidor << 'EOF'
cd lab-transferencias/logs-app
lcd ~/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/analisis
mget *.txt
bye
EOF

# 4. Verificar
ls -la ~/ssh-lab/week-04-transferencia_archivos_scp_sftp_rsync/analisis/
```

---

## 📝 Comandos SFTP - Referencia Rápida

### Navegación

| Comando   | Descripción               |
| --------- | ------------------------- |
| `pwd`     | Directorio remoto actual  |
| `lpwd`    | Directorio local actual   |
| `cd dir`  | Cambiar directorio remoto |
| `lcd dir` | Cambiar directorio local  |
| `ls`      | Listar remoto             |
| `lls`     | Listar local              |

### Transferencia

| Comando       | Descripción          |
| ------------- | -------------------- |
| `get archivo` | Descargar            |
| `put archivo` | Subir                |
| `mget *.ext`  | Descargar múltiples  |
| `mput *.ext`  | Subir múltiples      |
| `get -r dir`  | Descargar directorio |
| `put -r dir`  | Subir directorio     |

### Gestión

| Comando           | Descripción         |
| ----------------- | ------------------- |
| `mkdir dir`       | Crear directorio    |
| `rm archivo`      | Eliminar archivo    |
| `rmdir dir`       | Eliminar directorio |
| `rename old new`  | Renombrar           |
| `chmod mode file` | Cambiar permisos    |

---

## 📝 Verificación de Completación

| Tarea                          | Completada |
| ------------------------------ | :--------: |
| Conectar y navegar             |     ☐      |
| Subir archivo (put)            |     ☐      |
| Descargar archivo (get)        |     ☐      |
| Múltiples archivos (mput/mget) |     ☐      |
| Directorio recursivo           |     ☐      |
| Gestionar archivos remotos     |     ☐      |
| Modo batch funcional           |     ☐      |
| Script de backup               |     ☐      |

---

## ❓ Troubleshooting

### Error: Connection refused

```bash
# Verificar que SSH funciona
ssh tu-servidor "echo OK"
```

### Comandos batch fallan

```bash
# Verificar sintaxis sin ejecutar
cat tu-archivo-batch.txt

# Ejecutar con verbose
sftp -v -b batch.txt servidor
```

### mget/mput pide confirmación

```bash
# En modo interactivo, confirma con 'y'
# En batch, no hay confirmación
```

---

## 🧭 Navegación

| ⬅️ Anterior                              |       🏠 Índice        |                                Siguiente ➡️ |
| :--------------------------------------- | :--------------------: | ------------------------------------------: |
| [Práctica 01](practica-01-scp-basico.md) | [Prácticas](README.md) | [Práctica 03](practica-03-rsync-backups.md) |

---

<div align="center">

**📂 Práctica 02: Sesiones SFTP**

_Transferencia interactiva_

</div>
