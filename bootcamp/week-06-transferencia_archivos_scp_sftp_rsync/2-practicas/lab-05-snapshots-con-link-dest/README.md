# Lab 05 — Copias completas que ocupan poco: `--link-dest`

⏱ Duración estimada: ~60 min

## Objetivo

Hacer copias de seguridad sucesivas de una carpeta de `server`, cada una completa, en las que los archivos que no cambiaron no ocupan espacio otra vez. Ver los enlaces duros con `stat` y `du`, el error de ruta más común con `--link-dest` y por qué nunca se edita un archivo dentro de una copia.

## Contexto

- Enlaces duros y `--link-dest`: [teoría 02](../../1-teoria/02-rsync.md#copias-con---link-dest).
- Es lo que automatiza `bin/backup` en el [proyecto](../../3-proyecto/README.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-scp/README.md). Después, unos datos en `server`: una "foto" de 10 MB que no cambia y unas notas que sí:
   ```bash
   ssh server 'mkdir -p datos; head -c 10M /dev/urandom > datos/fotos.bin; echo v1 > datos/notas.txt'
   ```

1. **Primera copia, completa.** `rsync` **tira** de `server` hacia tu equipo:
   ```bash
   mkdir -p ~/snaps
   rsync -a server:datos/ ~/snaps/s1/
   ls ~/snaps/s1
   ```
   ```
   fotos.bin
   notas.txt
   ```

2. **Segunda copia, enlazada a la primera.** `--link-dest=DIR`: si un archivo es igual al de `DIR`, en lugar de copiarlo crea un **enlace duro** a él:
   ```bash
   rsync -a -i --link-dest=../s1 server:datos/ ~/snaps/s2/
   stat -c '%h %i %n' ~/snaps/s1/fotos.bin ~/snaps/s2/fotos.bin
   ```
   ```
   created directory /home/alumno/snaps/s2
   2 9245125 /home/alumno/snaps/s1/fotos.bin
   2 9245125 /home/alumno/snaps/s2/fotos.bin
   ```
   - Ninguna línea de `-i`: no se transfirió nada.
   - `stat -c '%h %i %n'`: número de enlaces, inodo y nombre. El **inodo** es el archivo en disco; los dos nombres apuntan al mismo, y ese archivo tiene 2 nombres. Tus números de inodo serán otros.
   - `../s1` es relativa a la carpeta de **destino** (`~/snaps/s2/`), no a la carpeta donde estás (paso 6).

3. **Cuánto ocupa cada copia:**
   ```bash
   du -sh ~/snaps/s1 ~/snaps/s2
   du -sh ~/snaps/s2
   ```
   ```
   11M	/home/alumno/snaps/s1
   8.0K	/home/alumno/snaps/s2
   11M	/home/alumno/snaps/s2
   ```
   - En una sola orden, `du` cuenta cada inodo una vez: `s2` solo añade 8 KB (sus carpetas).
   - Sola, `s2` mide 11 MB: es una copia completa. Puedes abrirla, copiarla o restaurarla sin `s1`.

4. **Un archivo que cambia.** Cambia las notas en el servidor y haz la tercera copia enlazada a la segunda:
   ```bash
   ssh server 'echo v2 > datos/notas.txt'
   rsync -a -i --link-dest=../s2 server:datos/ ~/snaps/s3/
   stat -c '%h %i %n' ~/snaps/s*/notas.txt ~/snaps/s3/fotos.bin
   cat ~/snaps/s*/notas.txt
   ```
   ```
   created directory /home/alumno/snaps/s3
   >f..t...... notas.txt
   2 9245126 /home/alumno/snaps/s1/notas.txt
   2 9245126 /home/alumno/snaps/s2/notas.txt
   1 9245132 /home/alumno/snaps/s3/notas.txt
   3 9245125 /home/alumno/snaps/s3/fotos.bin
   v1
   v1
   v2
   ```
   - `notas.txt` cambió: se transfiere y es un inodo nuevo, con un solo nombre. Las copias anteriores conservan `v1`.
   - `fotos.bin` tiene ya 3 nombres, uno por copia, y sigue ocupando 10 MB una sola vez.

5. **Borrar una copia vieja.** El archivo sigue mientras le quede un nombre:
   ```bash
   rm -rf ~/snaps/s1
   stat -c '%h %n' ~/snaps/s2/fotos.bin
   du -sh ~/snaps
   ```
   ```
   2 /home/alumno/snaps/s2/fotos.bin
   11M	/home/alumno/snaps
   ```
   Así funciona la retención de `bin/backup`: borrar la copia más antigua es seguro y solo libera lo que ninguna otra copia comparte.

6. **El error de la ruta.** Con una ruta relativa al lugar donde estás, y no al destino:
   ```bash
   rsync -a -i --link-dest=s3 server:datos/ ~/snaps/s4/
   du -sh ~/snaps/s4; stat -c '%h' ~/snaps/s4/fotos.bin
   ```
   ```
   created directory /home/alumno/snaps/s4
   --link-dest arg does not exist: s3
   cd+++++++++ ./
   >f+++++++++ fotos.bin
   >f+++++++++ notas.txt
   11M	/home/alumno/snaps/s4
   1
   ```
   `rsync` busca `~/snaps/s4/s3`, no la encuentra, avisa y **sigue**: copia todo entero. Sin mirar la salida, cada copia ocuparía el total y el disco se llenaría en pocos días. Por eso `bin/backup` pasa una ruta absoluta.

7. **Un enlace `latest` y una ruta absoluta.** Así no hay que recordar cuál fue la última copia:
   ```bash
   rm -rf ~/snaps/s4
   ln -sfn s3 ~/snaps/latest
   rsync -a --link-dest=$HOME/snaps/latest server:datos/ ~/snaps/s4/
   ls -l ~/snaps | tail -n +2
   stat -c '%h' ~/snaps/s4/fotos.bin
   ```
   ```
   lrwxrwxrwx 1 alumno alumno    2 Nov  8 06:48 latest -> s3
   drwxr-xr-x 2 alumno alumno 4096 Nov  8 06:48 s2
   drwxr-xr-x 2 alumno alumno 4096 Nov  8 06:48 s3
   drwxr-xr-x 2 alumno alumno 4096 Nov  8 06:48 s4
   3
   ```
   - `ln -sfn s3 latest`: el mismo `ln -sfn` de `bin/kit-link` (semana 05). Tras cada copia buena, `latest` pasa a apuntar a la nueva.
   - `tail -n +2` quita la línea `total` de `ls -l`.

8. **Nunca edites dentro de una copia.** Un enlace duro es el **mismo** archivo:
   ```bash
   stat -c '%h' ~/snaps/s4/notas.txt
   echo cambio >> ~/snaps/s4/notas.txt
   cat ~/snaps/s3/notas.txt
   ```
   ```
   2
   v2
   cambio
   ```
   Cambiaste `s4` y también cambió `s3`. `rsync` no tiene este problema: escribe cada archivo nuevo en un temporal y lo renombra, así que crea un inodo nuevo. Restaura **desde** una copia, nunca trabajes **dentro** de ella.

## Criterios de éxito

- [ ] Tienes varias copias completas y `du` muestra que las siguientes casi no ocupan (pasos 1 a 3)
- [ ] Explicas con `stat` qué pasa con un archivo que cambia y con uno que no (paso 4)
- [ ] Explicas por qué borrar la copia más antigua no rompe las demás (paso 5)
- [ ] Encontraste el aviso de `--link-dest` mal escrito y lo corregiste con una ruta absoluta (pasos 6 y 7)
- [ ] Explicas por qué editar un archivo en una copia cambia las otras (paso 8)

## Reto extra

Restaura `notas.txt` de `s2` en el servidor, primero en seco: `rsync -a -n -i ~/snaps/s2/notas.txt server:datos/`. ¿Qué marca `-i` indica que va a cambiar el archivo remoto? Y si en vez de un archivo restauras la carpeta entera con `--delete`, ¿qué archivos del servidor se borrarían?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 04 — `--delete` y exclusiones](../lab-04-delete-y-exclude/README.md) | [Lab 06 — Una llave que solo sirve para copiar](../lab-06-llave-solo-para-rsync/README.md) → |

[↑ Semana 06](../../README.md)
