# Lab 01 — `scp`

⏱ Duración estimada: ~60 min

## Objetivo

Copiar archivos y carpetas con `scp` en los dos sentidos y entre dos servidores, conservar las fechas con `-p`, y ver por qué el protocolo antiguo de `scp` (`-O`) deja que el servidor interprete los nombres de archivo.

## Contexto

- `scp`, su sintaxis y sus dos protocolos: [teoría 01](../../1-teoria/01-scp-y-sftp.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d --build --force-recreate server bastion
   docker compose run --rm client
   ```
   `--build` reconstruye la imagen si cambió (esta semana añade `python3` para `rrsync`, lab 06). **En el cliente**, prepara `known_hosts` y una llave instalada en `server` y `bastion`, como en la semana 03, y una carpeta de trabajo:
   ```bash
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh
   ssh-keyscan -t ed25519 server bastion 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/id_ed25519
   for h in server bastion; do sshpass -e ssh-copy-id -f $h 2>&1 | grep 'Number of'; done
   mkdir -p ~/w && cd ~/w
   ```
   ```
   Number of key(s) added: 1
   Number of key(s) added: 1
   ```
   - La llave se llama `id_ed25519`, uno de los nombres que `ssh` prueba por defecto: `scp`, `sftp` y `rsync` la usan sin `-i` ni `config`.
   - No tiene frase (`-N ''`) para no escribirla en cada paso: **solo en el laboratorio**.
   - Trabajas en `~/w`, dentro del contenedor, y no en la carpeta del lab: así no llenas el repositorio de archivos de prueba.

1. **Subir un archivo.** `scp ORIGEN DESTINO`, como `cp`; lo remoto se escribe `host:ruta`:
   ```bash
   echo "notas del lab" > notas.txt
   scp notas.txt server:
   ssh server ls -l notas.txt
   ```
   ```
   -rw-r--r-- 1 alumno alumno 14 Nov  8 06:43 notas.txt
   ```
   `server:` sin ruta es tu home en `server`. Una ruta relativa (`server:docs/`) también parte del home.

2. **Bajar un archivo.** El remoto va primero:
   ```bash
   scp server:/etc/os-release .
   head -2 os-release
   ```
   ```
   PRETTY_NAME="Ubuntu 24.04.5 LTS"
   NAME="Ubuntu"
   ```

3. **Una carpeta necesita `-r`:**
   ```bash
   mkdir -p datos/sub; echo uno > datos/a.txt; echo dos > datos/sub/b.txt
   scp datos server:; echo "código: $?"
   scp -r datos server:
   ssh server find datos
   ```
   ```
   scp: local "datos" is not a regular file
   scp: failed to upload file datos to .
   código: 1
   datos
   datos/a.txt
   datos/sub
   datos/sub/b.txt
   ```

4. **Fechas con `-p`.** Pon a `notas.txt` una fecha antigua y súbelo con y sin `-p`:
   ```bash
   touch -d '2020-01-01 10:00' notas.txt
   scp notas.txt server:sinp.txt
   scp -p notas.txt server:conp.txt
   ssh server stat -c "'%y %n'" sinp.txt conp.txt
   ```
   ```
   2026-11-08 06:43:56.398828585 +0000 sinp.txt
   2020-01-01 10:00:00.000000000 +0000 conp.txt
   ```
   - Sin `-p`, el archivo copiado tiene la fecha de la copia. Con `-p` conserva la de modificación y los permisos.
   - `stat -c '%y %n'`: fecha de modificación y nombre. Las comillas dobles de fuera protegen las simples para la shell remota.

5. **El protocolo que usa `scp`.** `-v` muestra qué pide `scp` al servidor:
   ```bash
   scp -v notas.txt server: 2>&1 | grep -E 'Sending (subsystem|command)'
   scp -O -v notas.txt server: 2>&1 | grep -E 'Sending (subsystem|command)'
   ```
   ```
   debug1: Sending subsystem: sftp
   debug1: Sending command: scp -v -t .
   ```
   - Por defecto (OpenSSH 9.0+), `scp` habla SFTP con el subsistema `sftp` del servidor.
   - Con `-O`, el protocolo antiguo: ejecuta en el servidor el comando `scp -t .`, a través de la shell del usuario.

6. **Por qué importa la shell.** Pide un archivo cuyo nombre lleva `$(...)`:
   ```bash
   scp -O 'server:nada$(touch /tmp/ejecutado)' . ; echo "código: $?"
   ssh server ls -l /tmp/ejecutado
   scp 'server:nada$(touch /tmp/otra)' . ; echo "código: $?"
   ssh server ls /tmp/otra
   ```
   ```
   scp: nada: No such file or directory
   código: 1
   -rw-rw-r-- 1 alumno alumno 0 Nov  8 06:44 /tmp/ejecutado
   scp: nada$(touch /tmp/otra): No such file or directory
   código: 1
   ls: cannot access '/tmp/otra': No such file or directory
   ```
   - Con `-O`, la shell del servidor ejecutó el `touch` antes de buscar el archivo. Aquí lo escribiste tú, pero un nombre que llega de fuera (un script que copia lo que le pasan) ejecutaría cualquier orden.
   - Con SFTP, el nombre viaja como dato y nadie lo interpreta. Usa `-O` solo con servidores muy viejos que no tienen SFTP.

7. **De un servidor a otro.** Con dos remotos, `scp` pasa los datos por tu equipo:
   ```bash
   scp server:notas.txt bastion:; echo "código: $?"
   ssh bastion ls notas.txt
   ```
   ```
   código: 0
   notas.txt
   ```
   Tu equipo abre las dos conexiones con tus llaves y tu `known_hosts`; `server` y `bastion` no se hablan.

8. **Directo entre servidores, con `-R`:**
   ```bash
   scp -R server:notas.txt bastion:otra.txt; echo "código: $?"
   ```
   ```
   Host key verification failed.
   scp: Connection closed
   código: 1
   ```
   Con `-R`, es `server` quien conecta a `bastion`: con **sus** llaves y **su** `known_hosts`, que no conoce `bastion`. Va más rápido (los datos no pasan por ti), pero el servidor de origen necesita poder entrar en el de destino.

9. **Comodines remotos.** Entre comillas, para que tu shell no los expanda en local:
   ```bash
   scp 'server:datos/*.txt' .
   ls *.txt
   ```
   ```
   a.txt
   notas.txt
   ```
   Con SFTP, el propio `scp` expande `*` en el servidor; no hace falta shell remota.

## Criterios de éxito

- [ ] Subiste y bajaste archivos, y una carpeta con `-r` (pasos 1 a 3)
- [ ] Explicas qué conserva `-p` (paso 4)
- [ ] Explicas qué protocolo usa `scp` por defecto y qué riesgo tiene `-O` (pasos 5 y 6)
- [ ] Explicas por qué falla `-R` y por qué el paso 7 funciona (pasos 7 y 8)

## Reto extra

`scp` no tiene modo "solo lo que cambió". Sube `datos` dos veces seguidas con `time scp -r datos server:` y compáralo con `time rsync -a datos server:` (repetido). ¿Por qué la segunda vez de `rsync` es casi instantánea? Lo verás en el [lab 03](../lab-03-rsync/README.md).

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Índice de labs](../README.md) | [Lab 02 — `sftp`](../lab-02-sftp/README.md) → |

[↑ Semana 06](../../README.md)
