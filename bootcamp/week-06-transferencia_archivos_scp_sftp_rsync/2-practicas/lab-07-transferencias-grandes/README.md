# Lab 07 — Transferencias grandes y muchas pequeñas

⏱ Duración estimada: ~60 min

## Objetivo

Reanudar una copia cortada con `--partial`, limitar el ancho de banda, ver el progreso de una transferencia larga y medir por qué copiar muchos archivos pequeños uno a uno es lento y cómo lo arreglan `rsync`, el multiplexing y `tar` por una tubería.

## Contexto

- `--partial`, `--bwlimit` y `--info=progress2`: [teoría 02](../../1-teoria/02-rsync.md#transferencias-largas).
- Multiplexing: [semana 05, teoría 03](../../../week-05-configuracion_avanzada_cliente_ssh/1-teoria/03-multiplexing.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-scp/README.md). Después, un archivo de 50 MB:
   ```bash
   head -c 50M /dev/urandom > grande.bin
   ```

1. **Una copia cortada, sin `--partial`.** `--bwlimit=5m` limita a 5 MB/s para que tarde unos 10 s; `timeout 3` la corta a los 3 s, como un corte de red:
   ```bash
   timeout 3 rsync -a --bwlimit=5m grande.bin server:; echo "código: $?"
   ssh server 'ls -la grande.bin .grande.bin.*'
   ```
   ```
   rsync error: unexplained error (code 255) at rsync.c(716) [sender=3.2.7]
   código: 124
   ls: cannot access 'grande.bin': No such file or directory
   ls: cannot access '.grande.bin.*': No such file or directory
   ```
   - `timeout 3 ORDEN` mata `ORDEN` a los 3 s y termina con 124.
   - `rsync` escribe en un temporal oculto (`.grande.bin.XXXXXX`) y lo borra si se corta. Los 15 MB ya enviados se pierden.

2. **La misma copia, con `--partial`:**
   ```bash
   timeout 3 rsync -a --partial --bwlimit=5m grande.bin server:; echo "código: $?"
   ssh server ls -l grande.bin
   ```
   ```
   rsync error: unexplained error (code 255) at rsync.c(716) [sender=3.2.7]
   código: 124
   -rw-r--r-- 1 alumno alumno 15040512 Jan  1  1970 grande.bin
   ```
   Se queda lo transferido, con su nombre definitivo y fecha de 1970: `rsync` todavía no le ha puesto la fecha real, y así la siguiente pasada sabe que no está terminado. Tu tamaño puede variar.

3. **Reanudar.** Repite sin límite: `rsync` usa el trozo que ya está en el servidor y envía el resto:
   ```bash
   rsync -a --partial -i --stats grande.bin server: | grep -E '^<|Literal|Matched'
   cmp grande.bin <(ssh server cat grande.bin) && echo iguales
   ```
   ```
   <f.st...... grande.bin
   Literal data: 37,389,952 bytes
   Matched data: 15,038,848 bytes
   iguales
   ```
   - `Matched data`: lo que ya estaba en el servidor y se reutilizó. A diferencia de `reput` (lab 02), `rsync` comprueba que ese trozo coincide antes de reutilizarlo.
   - `-P` es lo mismo que `--partial --progress`: la forma corta que verás en muchos tutoriales.

4. **El progreso de una copia larga.** `--info=progress2` da una línea para toda la transferencia, no una por archivo:
   ```bash
   ssh server rm grande.bin
   rsync -a --info=progress2 --bwlimit=20m grande.bin server: | tr '\r' '\n' | tail -1
   ```
   ```
        52,428,800 100%   20.20MB/s    0:00:02 (xfr#1, to-chk=0/1)
   ```
   - En tu terminal, sin `| tr ... | tail -1`, verás esa línea actualizarse sola. `rsync` la reescribe con `\r` (vuelta al principio de la línea); `tr` la parte en líneas para quedarte con la última.
   - `--bwlimit` evita que una copia de backup sature la red de la oficina o de un servidor en producción.

5. **Muchos archivos pequeños, uno a uno.** 200 archivos; copia 50 con un `scp` por archivo, y después todos con un solo `scp` y un solo `rsync`:
   ```bash
   mkdir -p muchos; for i in $(seq 200); do echo $i > muchos/f$i.txt; done
   time (for f in muchos/f{1..50}.txt; do scp -q $f server:; done)
   time (scp -q -r muchos server:)
   time (rsync -a muchos server:otro)
   ```
   ```
   real	0m13.500s
   ...
   real	0m0.416s
   ...
   real	0m0.267s
   ```
   - `f{1..50}`: la shell lo expande a `f1 f2 ... f50`.
   - Cada `scp` abre una conexión, negocia llaves y se autentica: unos 0,27 s cada vez, que se multiplican por 50. Una sola orden lo hace una vez para todo. Tus tiempos serán otros; compara las proporciones.

6. **Uno a uno, con multiplexing.** Cuando un script necesita lanzar muchas órdenes sueltas, el master de la semana 05 quita casi todo ese coste:
   ```bash
   mkdir -p -m 700 ~/.ssh/cm
   M='-o ControlMaster=auto -o ControlPath=~/.ssh/cm/%C -o ControlPersist=1m'
   time (for f in muchos/f{1..50}.txt; do scp -q $M $f server:; done)
   ```
   ```
   real	0m0.764s
   ```
   Unas 18 veces menos. Con tu kit no hace falta `$M`: `scp -F config`, `sftp -F config` y `rsync -e 'ssh -F config'` ya usan el multiplexing de `config`.

7. **`tar` por una tubería.** Sin `rsync` en el servidor y con muchos archivos, empaqueta en local y desempaqueta en remoto, sin archivo intermedio:
   ```bash
   tar czf - muchos | ssh server 'tar xzf - -C /tmp'; echo "código: $?"
   ssh server 'ls /tmp/muchos | wc -l'
   ```
   ```
   código: 0
   200
   ```
   - `tar czf -`: crea (`c`) un paquete comprimido (`z`) y lo escribe en la salida estándar (`f -`). `|` lo pasa como entrada a `ssh`, que lo entrega a `tar xzf -` en el servidor; `-C /tmp` desempaqueta allí.
   - Es una sola conexión y un solo flujo de datos, pero no reanuda ni compara: si se corta, empiezas de cero.

## Criterios de éxito

- [ ] Explicas qué pierde una copia cortada sin `--partial` y la reanudaste con él (pasos 1 a 3)
- [ ] Viste el progreso total y limitaste el ancho de banda (paso 4)
- [ ] Mediste el coste de una conexión por archivo y cómo lo reducen una sola orden y el multiplexing (pasos 5 y 6)
- [ ] Copiaste una carpeta con `tar` por `ssh` y explicas cuándo usarlo (paso 7)

## Reto extra

Repite el paso 2 con `--partial-dir=.rsync-partial` en lugar de `--partial`. ¿Dónde queda ahora el trozo cortado en el servidor? ¿Por qué es mejor que dejar un `grande.bin` incompleto con el nombre definitivo cuando otro programa lee esa carpeta (una web, un importador)?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 06 — Una llave que solo sirve para copiar](../lab-06-llave-solo-para-rsync/README.md) | [Proyecto — ssh-infra-kit: copias de seguridad y espejos con `rsync`](../../3-proyecto/README.md) → |

[↑ Semana 06](../../README.md)
