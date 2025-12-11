# ⚙️ Herramientas de Automatización

## Scripts y Utilidades para Transferencias

---

## Scripts de Backup con rsync

### rsnapshot

- **URL**: https://rsnapshot.org
- **Descripción**: Utilidad de backup basada en rsync
- **Características**:
  - Backups incrementales con hard links
  - Configuración sencilla
  - Rotación automática

```bash
# Instalar en Ubuntu/Debian
sudo apt install rsnapshot

# Configurar
sudo nano /etc/rsnapshot.conf

# Probar configuración
rsnapshot configtest

# Ejecutar backup
rsnapshot hourly
```

### Duplicity

- **URL**: https://duplicity.gitlab.io
- **Descripción**: Backups encriptados incrementales
- **Características**:
  - Encriptación GPG
  - Múltiples backends (SSH, S3, etc.)
  - Incrementales eficientes

```bash
# Backup encriptado via SSH
duplicity ~/documentos sftp://usuario@servidor/backups/documentos
```

### Borg Backup

- **URL**: https://www.borgbackup.org
- **Descripción**: Backup deduplicado y comprimido
- **Características**:
  - Deduplicación a nivel de bloque
  - Compresión
  - Encriptación
  - Muy eficiente

```bash
# Inicializar repositorio remoto
borg init --encryption=repokey ssh://user@server/backups/repo

# Crear backup
borg create ssh://user@server/backups/repo::backup-{now} ~/datos
```

---

## Herramientas de Sincronización

### Unison

- **URL**: https://www.cis.upenn.edu/~bcpierce/unison/
- **Descripción**: Sincronización bidireccional
- **Características**:
  - Sincronización en ambas direcciones
  - Detección de conflictos
  - Interfaz gráfica disponible

```bash
# Sincronizar local con remoto
unison ~/local ssh://servidor/remoto
```

### lsyncd

- **URL**: https://axkibe.github.io/lsyncd/
- **Descripción**: Sincronización en tiempo real
- **Características**:
  - Monitorea cambios con inotify
  - Sincroniza automáticamente
  - Usa rsync internamente

```lua
-- Configuración lsyncd.conf
sync {
    default.rsync,
    source = "/var/www/",
    target = "servidor:/var/www/",
    delay = 5
}
```

---

## Herramientas de Automatización General

### Ansible

- **URL**: https://www.ansible.com
- **Módulos relacionados**:
  - `synchronize` - Wrapper de rsync
  - `copy` - Copiar archivos
  - `fetch` - Descargar archivos

```yaml
# Playbook de sincronización
- name: Sync webapp
  hosts: webservers
  tasks:
    - name: Sync files with rsync
      synchronize:
        src: /local/app/
        dest: /var/www/app/
        delete: yes
        rsync_opts:
          - '--exclude=.git'
```

### Fabric (Python)

- **URL**: https://www.fabfile.org
- **Descripción**: Ejecución de comandos remotos vía SSH

```python
from fabric import Connection

def deploy():
    c = Connection('servidor')
    # Ejecutar rsync local
    local('rsync -avz ./app/ servidor:/var/www/app/')
    # O usar put
    c.put('config.json', '/var/www/app/')
```

---

## Monitores de Transferencia

### progress

- **URL**: https://github.com/Xfennec/progress
- **Descripción**: Ver progreso de cp, mv, dd, rsync, etc.

```bash
# Instalar
sudo apt install progress

# Mientras rsync corre en otra terminal
watch progress -w
```

### pv (Pipe Viewer)

- **URL**: https://www.ivarch.com/programs/pv.shtml
- **Descripción**: Monitor de progreso para pipes

```bash
# Ver progreso de transferencia
pv archivo.tar.gz | ssh servidor "cat > /destino/archivo.tar.gz"
```

---

## Scripts Útiles

### Script de Deploy Genérico

```bash
#!/bin/bash
# deploy.sh - Deploy genérico con rsync

SOURCE="${1:-.}"
TARGET="${2:-servidor:/var/www/app/}"
EXCLUDE_FILE="${3:-.deployignore}"

rsync -avz --delete \
    --exclude-from="$EXCLUDE_FILE" \
    "$SOURCE/" \
    "$TARGET"
```

### Script de Backup Rotativo

```bash
#!/bin/bash
# backup-rotate.sh

DEST="servidor:~/backups"
DATE=$(date +%A)  # Lunes, Martes, etc.

rsync -avz --delete \
    --link-dest=../latest \
    ~/datos/ \
    "$DEST/$DATE/"

ssh servidor "cd ~/backups && rm -f latest && ln -s $DATE latest"
```

---

## Cron y Systemd Timers

### Cron para Backups

```cron
# /etc/cron.d/backup
0 2 * * * root /usr/local/bin/backup-rsync.sh >> /var/log/backup.log 2>&1
```

### Systemd Timer

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Daily Backup

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

---

<div align="center">

**⚙️ Herramientas de Automatización**

</div>
