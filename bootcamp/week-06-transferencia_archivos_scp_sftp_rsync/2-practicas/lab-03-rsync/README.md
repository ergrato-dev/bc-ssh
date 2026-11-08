# Lab 03 — `rsync` por SSH

⏱ Duración estimada: ~60 min

## Objetivo

Sincronizar una carpeta con `rsync -a`, entender la barra final del origen, leer la salida de `-i`, ver que solo viaja lo que cambió (y dentro de un archivo, solo el trozo cambiado) y saber cuándo hace falta `-c`.

## Contexto

- Cómo decide `rsync` qué copiar y el algoritmo de diferencias: [teoría 02](../../1-teoria/02-rsync.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-scp/README.md). Después:
   ```bash
   mkdir -p datos/sub; echo uno > datos/a.txt; echo dos > datos/sub/b.txt
   ```

1. **Primera copia.** `-a` (archivo: recursivo, con permisos, fechas y enlaces) y `-v` (cada archivo):
   ```bash
   rsync -av datos server:
   ```
   ```
   sending incremental file list
   datos/
   datos/a.txt
   datos/sub/
   datos/sub/b.txt

   sent 242 bytes  received 78 bytes  640.00 bytes/sec
   total size is 8  speedup is 0.03
   ```
   La sintaxis es la de `scp`: `host:ruta` para lo remoto. Por debajo, `rsync` abre una conexión con `ssh` y arranca otro `rsync` en el servidor.

2. **La segunda vez no copia nada:**
   ```bash
   rsync -av datos server:
   ```
   ```
   sending incremental file list

   sent 146 bytes  received 18 bytes  109.33 bytes/sec
   total size is 8  speedup is 0.05
   ```
   Ningún archivo en la lista: tamaño y fecha coinciden en los dos lados.

3. **La barra final del origen.** La misma orden, con y sin `/` al final de `datos`:
   ```bash
   rsync -a datos server:sin-barra
   rsync -a datos/ server:con-barra
   ssh server find sin-barra con-barra
   ```
   ```
   sin-barra
   sin-barra/datos
   sin-barra/datos/a.txt
   sin-barra/datos/sub
   sin-barra/datos/sub/b.txt
   con-barra
   con-barra/a.txt
   con-barra/sub
   con-barra/sub/b.txt
   ```
   - `datos`: copia **la carpeta** dentro del destino.
   - `datos/`: copia **su contenido**. Es lo que quieres para mantener dos carpetas iguales.
   - En el destino la barra da igual. Este es el error más común con `rsync`; con `--delete` (lab 04) puede borrar lo que no querías.

4. **Ensayo con `-n -i`.** Cambia un archivo y crea otro; `-n` (`--dry-run`) no copia nada y `-i` (`--itemize-changes`) dice qué haría:
   ```bash
   echo tres > datos/c.txt; echo uno-bis > datos/a.txt
   rsync -a -n -i datos/ server:con-barra
   ssh server ls con-barra
   ```
   ```
   .d..t...... ./
   <f.st...... a.txt
   <f+++++++++ c.txt
   a.txt
   sub
   ```
   Cada línea, de izquierda a derecha:
   - `<` se envía al remoto (`>` se recibe), `.` no se transfiere; `f` archivo, `d` carpeta.
   - `+++++++++`: es nuevo. `s`: cambió el tamaño. `t`: cambió la fecha. `c`: cambió el contenido (con `-c`).
   - `c.txt` no está en el servidor: `-n` no copió nada.

5. **Ahora sí:**
   ```bash
   rsync -a -i datos/ server:con-barra
   ```
   ```
   .d..t...... ./
   <f.st...... a.txt
   <f+++++++++ c.txt
   ```
   Costumbre para todo `rsync` que no has lanzado antes: primero con `-n -i`, después sin `-n`.

6. **Solo viaja lo que cambió dentro de un archivo.** Un archivo de 20 MB, copiado y después cambiado en un solo byte:
   ```bash
   head -c 20M /dev/urandom > datos/grande.bin
   rsync -a datos/ server:con-barra
   sleep 1
   printf X | dd of=datos/grande.bin bs=1 seek=1000 conv=notrunc 2>/dev/null
   rsync -a -i --stats datos/ server:con-barra | grep -E '^<|Literal|Matched|Total bytes sent'
   ```
   ```
   <f..t...... grande.bin
   Literal data: 4,576 bytes
   Matched data: 20,966,944 bytes
   Total bytes sent: 23,108
   ```
   - `dd ... seek=1000 conv=notrunc` escribe una `X` en el byte 1000 sin cambiar el resto.
   - `Literal data`: bytes enviados tal cual (el bloque que cambió). `Matched data`: lo que el servidor ya tenía y reutilizó. Se enviaron 23 KB, no 20 MB.
   - `sleep 1`: sin él, el cambio puede caer en el mismo segundo que la copia anterior, con el mismo tamaño y la misma fecha, y `rsync` no lo vería (paso 7).

7. **Lo que mira `rsync` para decidir.** Por defecto, solo tamaño y fecha de modificación (la *quick check*). Cambia `b.txt` en el servidor sin cambiar ni su tamaño ni su fecha:
   ```bash
   ssh server 'echo DOS > con-barra/sub/b.txt; touch -r con-barra/a.txt con-barra/sub/b.txt'
   touch -r datos/a.txt datos/sub/b.txt
   rsync -a -i datos/ server:con-barra
   echo "--- con -c"
   rsync -a -i -c datos/ server:con-barra
   ssh server cat con-barra/sub/b.txt
   ```
   ```
   --- con -c
   <fc........ sub/b.txt
   dos
   ```
   - `touch -r REF ARCHIVO`: pone a `ARCHIVO` la fecha de `REF`. Así los dos `b.txt` miden lo mismo y tienen la misma fecha.
   - Sin `-c`, `rsync` no ve la diferencia. Con `-c` (`--checksum`) calcula un hash de cada archivo en los dos lados: lo detecta, pero lee todos los archivos enteros. Úsalo para verificar una copia, no en cada sincronización.

8. **Lo que ejecuta en el servidor.** Con `-vv`, `rsync` enseña la orden `ssh` que lanza:
   ```bash
   rsync -a -vv datos/ server:con-barra 2>&1 | grep 'opening connection'
   ```
   ```
   opening connection using: ssh server rsync --server -vvlogDtpre.iLsfxCIvu . con-barra  (7 args)
   ```
   `rsync --server` en el otro lado: por eso el servidor necesita `rsync` instalado. Es también la orden que verá un `authorized_keys` con `command=` (lab 06).

9. **Cuando el otro lado no tiene `rsync`.** `--rsync-path` cambia el programa remoto; uno que no existe simula un servidor sin `rsync`:
   ```bash
   rsync -a --rsync-path=/no/existe datos/ server:con-barra; echo "código: $?"
   ```
   ```
   bash: line 1: /no/existe: No such file or directory
   rsync: connection unexpectedly closed (0 bytes received so far) [sender]
   rsync error: error in rsync protocol data stream (code 12) at io.c(232) [sender=3.2.7]
   código: 12
   ```
   Si ves `connection unexpectedly closed` nada más empezar, mira la primera línea: casi siempre es un `rsync` que falta o una shell remota que escribe algo al entrar.

10. **Opciones de `ssh` con `-e`.** `-e` fija la orden de conexión; aquí, un puerto y un tiempo de espera:
    ```bash
    rsync -a -v -e 'ssh -p 22 -o ConnectTimeout=5' datos/ server:con-barra | tail -1
    ```
    ```
    total size is 20,971,537  speedup is 105,384.61
    ```
    Con `-e 'ssh -F tu/config'` usa los alias, llaves y multiplexing de tu kit; es lo que harán `bin/backup` y `bin/mirror` en el proyecto (con la variable `RSYNC_RSH`, que hace lo mismo).

## Criterios de éxito

- [ ] La segunda sincronización no copió nada y explicas por qué (pasos 1 y 2)
- [ ] Explicas la diferencia entre `datos` y `datos/` (paso 3)
- [ ] Lees cada columna de una línea de `-i` (pasos 4 y 5)
- [ ] Mediste que un cambio de un byte envía unos KB, no el archivo (paso 6)
- [ ] Explicas cuándo `rsync` no ve un cambio y qué hace `-c` (paso 7)

## Reto extra

Repite el paso 6 con `-z` (comprime los datos en el camino) y compara `Total bytes sent`. Después hazlo con un archivo de texto repetitivo (`yes hola | head -c 20M > datos/texto.txt`). ¿Cuándo ayuda `-z` y cuándo solo gasta CPU?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 02 — `sftp`](../lab-02-sftp/README.md) | [Lab 04 — `--delete` y exclusiones](../lab-04-delete-y-exclude/README.md) → |

[↑ Semana 06](../../README.md)
