# 📖 Glosario - Semana 04

## Terminología de Transferencia de Archivos

![Glosario](https://img.shields.io/badge/Términos-40+-informational?style=for-the-badge)

---

## A

### Archive Mode

Modo de rsync (`-a`) que preserva permisos, timestamps, propietarios, grupos, enlaces simbólicos y dispositivos. Equivale a `-rlptgoD`.

```bash
rsync -a origen/ destino/
```

---

## B

### Bandwidth Limit

Limitación del ancho de banda usado durante la transferencia para no saturar la red.

```bash
# rsync: límite en KB/s
rsync --bwlimit=1000 origen/ destino/

# scp: límite en Kbit/s
scp -l 8000 archivo servidor:/destino/
```

### Batch Mode

Modo de ejecución automatizado de SFTP donde los comandos se leen de un archivo.

```bash
sftp -b comandos.txt servidor
```

### Block Size

Tamaño del bloque que rsync usa para calcular diferencias. Por defecto es dinámico según el tamaño del archivo.

---

## C

### Checksum

Suma de verificación que rsync usa para detectar cambios en archivos. Calcula un hash para cada bloque.

```bash
# Forzar verificación por checksum (más lento pero preciso)
rsync -c origen/ destino/
```

### Compression

Compresión de datos durante la transferencia para reducir uso de ancho de banda.

```bash
# rsync
rsync -z origen/ destino/

# scp
scp -C archivo servidor:/destino/
```

---

## D

### Delete

Opción de rsync para eliminar archivos en destino que no existen en origen, creando un espejo exacto.

```bash
rsync --delete origen/ destino/
```

### Delta Algorithm

Algoritmo de rsync que identifica diferencias entre archivos y transfiere solo los cambios, no el archivo completo.

### Dry Run

Simulación de la operación sin ejecutar cambios reales. Útil para verificar qué haría el comando.

```bash
rsync -avzn origen/ destino/
# -n es equivalente a --dry-run
```

---

## E

### Exclude

Patrón para excluir archivos o directorios de la transferencia.

```bash
rsync --exclude '*.log' origen/ destino/
rsync --exclude-from=exclusiones.txt origen/ destino/
```

---

## F

### FTP (File Transfer Protocol)

Protocolo de transferencia de archivos antiguo sin cifrado. SFTP lo reemplaza para transferencias seguras.

---

## G

### Get

Comando SFTP para descargar archivos del servidor remoto al sistema local.

```
sftp> get archivo.txt
sftp> get -r directorio/
```

---

## H

### Hard Link

Enlace a nivel de sistema de archivos donde múltiples nombres apuntan al mismo inodo. rsync los usa con `--link-dest` para backups eficientes.

```bash
rsync --link-dest=../backup-anterior origen/ backup-nuevo/
```

### Human Readable

Mostrar tamaños en formato legible (K, M, G) en lugar de bytes.

```bash
rsync -h origen/ destino/
```

---

## I

### Incremental

Transferencia que solo envía las diferencias respecto a una versión anterior, ahorrando tiempo y ancho de banda.

### Inode

Estructura de datos que almacena metadatos de un archivo en sistemas Unix. Los hard links comparten inodo.

---

## L

### Link-dest

Opción de rsync para crear hard links a archivos sin cambios de un backup anterior, ahorrando espacio.

```bash
rsync -avz --link-dest=../backup-anterior origen/ backup-nuevo/
```

### Local Port Forwarding

No confundir con transferencia de archivos - es tunelización SSH. Ver Semana 06.

---

## M

### Mget/Mput

Comandos SFTP para transferir múltiples archivos usando wildcards.

```
sftp> mget *.txt
sftp> mput documento-*.pdf
```

### Mirror

Sincronización que crea una copia exacta del origen en el destino, incluyendo eliminación de archivos.

```bash
rsync -avz --delete origen/ destino/
```

---

## N

### Numeric IDs

Opción de rsync para preservar IDs numéricos de usuario/grupo en lugar de resolver nombres.

```bash
rsync --numeric-ids origen/ destino/
```

---

## O

### OpenSSH

Implementación de código abierto de SSH que incluye scp, sftp, ssh, ssh-agent, etc.

---

## P

### Partial

Opción de rsync para mantener archivos parcialmente transferidos para poder reanudar.

```bash
rsync --partial origen/ destino/
rsync -P origen/ destino/  # -P = --partial --progress
```

### Perms

Preservar permisos de archivos durante la transferencia.

```bash
rsync -p origen/ destino/
scp -p archivo servidor:/destino/
```

### Progress

Mostrar progreso de la transferencia.

```bash
rsync --progress origen/ destino/
```

### Put

Comando SFTP para subir archivos del sistema local al servidor remoto.

```
sftp> put archivo.txt
sftp> put -r directorio/
```

---

## R

### Recursive

Transferir directorios y su contenido recursivamente.

```bash
scp -r directorio/ servidor:/destino/
rsync -r origen/ destino/
```

### Remote Shell

Shell remoto usado por rsync para conexiones. Por defecto usa SSH.

```bash
rsync -e "ssh -p 2222" origen/ destino/
```

### Resume

Capacidad de continuar una transferencia interrumpida.

```
sftp> reget archivo-grande.zip  # Reanudar descarga
sftp> reput subida.tar          # Reanudar subida
```

### Rolling Checksum

Técnica usada por rsync donde los checksums se calculan de forma que se pueden "deslizar" por el archivo eficientemente.

### rsync

Herramienta de sincronización remota que transfiere solo las diferencias entre archivos.

---

## S

### SCP (Secure Copy Protocol)

Protocolo basado en SSH para copiar archivos entre hosts. Simple pero sin soporte para reanudación.

### SFTP (SSH File Transfer Protocol)

Protocolo de transferencia de archivos que opera sobre SSH, con sesión interactiva y gestión de archivos remotos.

### SSH (Secure Shell)

Protocolo criptográfico para conexiones seguras. Base de scp, sftp y rsync sobre SSH.

### Stats

Estadísticas de la transferencia mostradas al finalizar.

```bash
rsync --stats origen/ destino/
```

### Symbolic Link (Symlink)

Enlace simbólico que apunta a otro archivo o directorio.

```bash
rsync -l origen/ destino/  # Copiar symlinks como symlinks
rsync -L origen/ destino/  # Seguir symlinks y copiar el contenido
```

---

## T

### Times

Preservar tiempos de modificación de archivos.

```bash
rsync -t origen/ destino/
scp -p archivo servidor:/destino/  # -p preserva tiempos y permisos
```

### Transfer Rate

Velocidad de transferencia de datos, generalmente medida en MB/s o Mbps.

---

## U

### Update

Opción de rsync que omite archivos que son más nuevos en el destino.

```bash
rsync -u origen/ destino/
```

---

## V

### Verbose

Modo detallado que muestra información adicional sobre la operación.

```bash
rsync -v origen/ destino/
rsync -vv origen/ destino/  # Más detallado
sftp -v servidor
scp -v archivo servidor:/destino/
```

---

## W

### Whole File

Opción de rsync para transferir archivos completos sin usar el algoritmo delta.

```bash
rsync --whole-file origen/ destino/
```

---

## Z

### Compress

Ver [Compression](#compression).

---

## 📊 Tabla de Opciones Comunes

### rsync

| Opción        | Significado                   |
| ------------- | ----------------------------- |
| `-a`          | Archive (preservar todo)      |
| `-v`          | Verbose                       |
| `-z`          | Compress                      |
| `-h`          | Human-readable                |
| `-n`          | Dry-run                       |
| `-P`          | Progress + Partial            |
| `--delete`    | Eliminar extras en destino    |
| `--exclude`   | Excluir patrón                |
| `--link-dest` | Hard links para incrementales |

### scp

| Opción | Significado            |
| ------ | ---------------------- |
| `-r`   | Recursive              |
| `-P`   | Port (nota: mayúscula) |
| `-p`   | Preserve times/perms   |
| `-C`   | Compression            |
| `-l`   | Bandwidth limit        |
| `-v`   | Verbose                |

### sftp

| Opción | Significado     |
| ------ | --------------- |
| `-b`   | Batch file      |
| `-P`   | Port            |
| `-v`   | Verbose         |
| `-l`   | Bandwidth limit |

---

## 🧭 Navegación

| ⬅️ Anterior                         |         🏠 Índice         |                           Siguiente ➡️ |
| :---------------------------------- | :-----------------------: | -------------------------------------: |
| [Recursos](../4-recursos/README.md) | [Semana 04](../README.md) | [Semana 05](../../week-05-configuracion_servidor_ssh/README.md) |

---

<div align="center">

**📖 Glosario - Semana 04**

_40+ términos técnicos de transferencia de archivos_

</div>
