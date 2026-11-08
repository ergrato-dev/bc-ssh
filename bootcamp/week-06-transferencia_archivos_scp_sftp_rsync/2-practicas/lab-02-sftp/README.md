# Lab 02 — `sftp`

⏱ Duración estimada: ~60 min

## Objetivo

Moverte por el servidor y transferir archivos con `sftp` en modo interactivo, automatizarlo con un archivo de órdenes (`-b`), controlar qué errores detienen el lote y reanudar una subida cortada.

## Contexto

- SFTP, el subsistema `sftp-server` y las órdenes de `sftp`: [teoría 01](../../1-teoria/01-scp-y-sftp.md#sftp).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-scp/README.md). Después, unos archivos de prueba:
   ```bash
   mkdir -p datos/sub; echo uno > datos/a.txt; echo dos > datos/sub/b.txt; echo notas > notas.txt
   ```

1. **Sesión interactiva.** Abre `sftp server` y escribe las órdenes de después de cada `sftp>`:
   ```bash
   sftp server
   ```
   ```
   Connected to server.
   sftp> pwd
   Remote working directory: /home/alumno
   sftp> lpwd
   Local working directory: /home/alumno/w
   sftp> mkdir docs
   sftp> cd docs
   sftp> put notas.txt
   Uploading notas.txt to /home/alumno/docs/notas.txt
   sftp> ls -l
   -rw-r--r--    ? alumno   alumno          6 Nov  8 06:44 notas.txt
   sftp> df -h .
       Size     Used    Avail   (root)    %Capacity
     1007GB    323GB    632GB    684GB          32%
   sftp> !ls
   datos
   notas.txt
   sftp> bye
   ```
   - Cada orden tiene dos lados: `pwd`, `cd`, `ls` actúan en el servidor; `lpwd`, `lcd`, `lls`, en tu equipo (la `l` es de *local*).
   - `put` sube, `get` baja. `!orden` ejecuta una orden en tu equipo sin salir.
   - `help` lista todas las órdenes. Tus tamaños de `df` serán otros.

2. **Un lote de órdenes con `-b`.** Escribe las órdenes en un archivo:
   ```bash
   cat > subir.sftp <<'EOF'
   mkdir copia
   put -R datos copia
   ls copia/datos
   EOF
   sftp -b subir.sftp server; echo "código: $?"
   ```
   ```
   sftp> mkdir copia
   sftp> put -R datos copia
   Entering datos/
   Entering datos/sub
   sftp> ls copia/datos
   copia/datos/a.txt   copia/datos/sub
   código: 0
   ```
   - `cat > archivo <<'EOF' ... EOF` escribe en el archivo las líneas hasta `EOF` (un *heredoc*).
   - `-b` lee las órdenes del archivo y no pregunta nada: sirve para scripts y `cron`. Necesita autenticación sin teclado (llave o agente).
   - `put -R` sube una carpeta entera (`-r` también vale).

3. **El lote se para en el primer error.** Repite el mismo lote:
   ```bash
   sftp -b subir.sftp server; echo "código: $?"
   ```
   ```
   sftp> mkdir copia
   remote mkdir "/home/alumno/copia": Failure
   código: 1
   ```
   `copia` ya existe, `mkdir` falla y `sftp` termina con 1 sin ejecutar el resto. Un script que lo use sabe que algo fue mal.

4. **Un `-` delante ignora el error de esa orden:**
   ```bash
   sed -i 's/^mkdir/-mkdir/' subir.sftp
   sftp -b subir.sftp server; echo "código: $?"
   ```
   ```
   sftp> -mkdir copia
   remote mkdir "/home/alumno/copia": Failure
   sftp> put -R datos copia
   Entering datos/
   Entering datos/sub
   sftp> ls copia/datos
   copia/datos/a.txt   copia/datos/sub
   código: 0
   ```
   Úsalo solo en las órdenes que pueden fallar sin problema (crear algo que quizá ya existe). Un `-put` que falla y termina con 0 esconde un backup roto.

5. **Sin sesión: un archivo o una carpeta en una línea.** `sftp host:ruta` baja y termina:
   ```bash
   sftp -q server:docs/notas.txt bajado.txt; cat bajado.txt
   sftp -q -r server:copia/datos ./de-vuelta; find de-vuelta
   ```
   ```
   notas
   Retrieving /home/alumno/copia/datos
   Retrieving /home/alumno/copia/datos/sub
   de-vuelta
   de-vuelta/a.txt
   de-vuelta/sub
   de-vuelta/sub/b.txt
   ```
   `-q` quita el mensaje de conexión y la barra de progreso.

6. **Quién responde en el servidor.** `sftp` no ejecuta una shell: pide el subsistema `sftp`, que `sshd` asocia a un programa:
   ```bash
   ssh server grep -i subsystem /etc/ssh/sshd_config
   ```
   ```
   # override default of no subsystems
   Subsystem	sftp	/usr/lib/openssh/sftp-server
   ```
   `sftp-server` habla SFTP por la entrada y salida estándar del canal. Sin esa línea, `sftp` y el `scp` moderno fallan, y `scp -O` sigue funcionando.

7. **El lote desde la entrada estándar.** `-b -` lee las órdenes de la entrada, sin archivo:
   ```bash
   sftp -b - server <<'EOF'
   cd /etc
   get hostname
   EOF
   cat hostname
   ```
   ```
   sftp> cd /etc
   sftp> get hostname
   server
   ```
   `sftp` llega a todo lo que el usuario `alumno` puede leer, no solo a su home. Encerrarlo en una carpeta es cosa del servidor (`ChrootDirectory`, semana 07).

8. **Reanudar una subida.** Sube un archivo de 5 MB y simula un corte dejando solo su primer mega en el servidor:
   ```bash
   head -c 5M /dev/urandom > grande.bin
   echo put grande.bin | sftp -q -b - server
   ssh server 'truncate -s 1M grande.bin; ls -l grande.bin'
   echo reput grande.bin | sftp -b - server
   ssh server ls -l grande.bin
   cmp grande.bin <(ssh server cat grande.bin) && echo iguales
   ```
   ```
   sftp> put grande.bin
   -rw-r--r-- 1 alumno alumno 1048576 Nov  8 06:45 grande.bin
   sftp> reput grande.bin
   -rw-r--r-- 1 alumno alumno 5242880 Nov  8 06:45 grande.bin
   iguales
   ```
   - `head -c 5M /dev/urandom`: 5 MB aleatorios. `truncate -s 1M` corta el archivo a 1 MB.
   - `reput` (o `put -a`) sigue desde el tamaño que ya hay en el servidor; `reget` hace lo mismo al bajar. No comprueba que el trozo que ya está sea el correcto: `cmp` lo confirma. `rsync --partial` sí lo verifica ([lab 07](../lab-07-transferencias-grandes/README.md)).
   - `<(orden)` pasa la salida de `orden` como si fuera un archivo.

## Criterios de éxito

- [ ] Usaste las órdenes remotas y locales en una sesión interactiva (paso 1)
- [ ] Tu lote `-b` termina con 1 si falla y explicas cuándo usar `-` (pasos 2 a 4)
- [ ] Explicas qué programa atiende a `sftp` en el servidor y hasta dónde llega (pasos 6 y 7)
- [ ] Reanudaste una subida con `reput` y comprobaste el resultado (paso 8)

## Reto extra

Escribe `bajar-logs.sftp` que baje `/var/log/dpkg.log` de `server` a `~/w/logs/` (créala con `lmkdir`, sin fallar si existe) y que termine con 0. Ejecútalo dos veces seguidas: ¿qué pasa la segunda?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 01 — `scp`](../lab-01-scp/README.md) | [Lab 03 — `rsync` por SSH](../lab-03-rsync/README.md) → |

[↑ Semana 06](../../README.md)
