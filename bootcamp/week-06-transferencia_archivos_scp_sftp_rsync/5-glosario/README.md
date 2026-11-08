# Glosario — Semana 06

| Término | Definición |
|---------|------------|
| **algoritmo de diferencias** | Método de `rsync` para enviar solo las partes de un archivo que cambiaron: el receptor envía sumas de sus bloques y el emisor busca esos bloques en la versión nueva |
| **`--backup-dir`** | Opción de `rsync` que mueve a otra carpeta lo que borraría o sobrescribiría, en lugar de perderlo |
| **barra final** | En el origen de `rsync`, `datos/` copia el contenido de la carpeta y `datos`, la carpeta misma |
| **`--delete`** | Opción de `rsync` que borra en el destino lo que ya no está en el origen; se ensaya siempre con `-n -i` |
| **dry run (`-n`)** | Ejecución de prueba: `rsync` hace todo menos escribir y, con `-i`, enseña cada cambio |
| **enlace duro** | Otro nombre para el mismo archivo en disco (inodo). No ocupa espacio; el archivo se libera al borrar su último nombre |
| **inodo** | El archivo en disco, con su contenido y permisos. `stat -c %i` da su número y `%h` cuántos nombres tiene |
| **`latest`** | Enlace simbólico que `bin/backup` apunta a la última copia completa; es la referencia de `--link-dest` |
| **`--link-dest`** | Opción de `rsync` que crea enlaces duros a una copia anterior para los archivos que no cambiaron |
| **`.parcial-NOMBRE`** | Carpeta oculta donde `bin/backup` escribe una copia en curso; solo al terminar bien se renombra |
| **`--partial`** | Opción de `rsync` que conserva lo ya transferido si la copia se corta, para reutilizarlo en la siguiente |
| **pull / push** | Tirar de los datos desde el equipo de copias (*pull*) o enviarlos desde el servidor (*push*). *Pull* deja en el servidor ninguna llave hacia las copias |
| **quick check** | Comparación por defecto de `rsync`: tamaño y fecha de modificación. `-c` la sustituye por un hash del contenido |
| **`restrict`** | Opción de `authorized_keys` que quita terminal, túneles y reenvío de agente y de X11 |
| **`rrsync`** | Script de `rsync` para `command=` en `authorized_keys`: solo permite `rsync`, encerrado en una carpeta, y con `-ro` solo lectura |
| **`RSYNC_RSH`** | Variable con la orden con la que `rsync` abre la conexión (como `-e`); los scripts del kit la fijan a `ssh -F config` |
| **`scp -O`** | `scp` con el protocolo antiguo: ejecuta `scp -t` por la shell del servidor, que interpreta los nombres de archivo |
| **SFTP** | *SSH File Transfer Protocol*: protocolo de operaciones sobre archivos dentro de un canal SSH. No es FTP |
| **`sftp -b`** | Modo lote de `sftp`: ejecuta las órdenes de un archivo y se para (con código 1) en la primera que falla, salvo las que llevan `-` delante |
| **`sftp-server`** | Programa del servidor que atiende SFTP; `sshd` lo arranca como subsistema |
| **`sshfs`** | Monta una carpeta remota como local usando SFTP; necesita FUSE |
| **subsistema** | Programa con nombre que `sshd` arranca sin la shell del usuario (`Subsystem sftp ...` en `sshd_config`) |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — web](../4-recursos/webgrafia/README.md) | — |

[↑ Semana 06](../README.md)
