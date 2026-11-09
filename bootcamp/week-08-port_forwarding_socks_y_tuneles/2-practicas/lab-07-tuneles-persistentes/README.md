# Lab 07 — Túneles que vuelven solos

⏱ Duración estimada: ~60 min

## Objetivo

Romper un túnel de las dos formas en que se rompe de verdad: con aviso (el servidor se reinicia) y sin aviso (la conexión se congela). Detectar el segundo con `ServerAliveInterval` y hacer que el túnel vuelva solo con `autossh`.

## Contexto

- Las dos formas de morir, `ServerAliveInterval` y `autossh`: [teoría 03](../../1-teoria/03-tuneles-persistentes.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-reenvio-local/README.md) y el `~/.pgpass` del paso 5 del [lab 02](../lab-02-postgres-por-tunel/README.md). Ten **otra terminal en tu equipo**, en la raíz del repositorio: desde ella reinicias y congelas `server`. Define en el cliente una función corta para consultar la base de datos:
   ```bash
   echo '127.0.0.1:15432:tienda:alumno:alumno' > ~/.pgpass; chmod 600 ~/.pgpass
   export PGCONNECT_TIMEOUT=3
   q() { psql -h 127.0.0.1 -p 15432 -U alumno -w tienda -tAc 'select count(*) from productos' 2>&1 | head -1; }
   ```
   - `PGCONNECT_TIMEOUT=3`: `psql` se rinde a los 3 s si nadie contesta, en lugar de esperar para siempre.
   - `q` escribe `3` si el túnel funciona, o la primera línea del error.

1. **Corte con aviso.** Un túnel normal y un reinicio de `server`:
   ```bash
   ssh -f -N -L 15432:db:5432 server; q
   ```
   ```
   3
   ```
   **En tu equipo**: `docker compose restart server`. **En el cliente**, cuando termine:
   ```bash
   q; pgrep -a ssh
   ```
   ```
   psql: error: connection to server at "127.0.0.1", port 15432 failed: Connection refused
   ```
   `ssh` recibió el cierre de la conexión y salió; `pgrep` no encuentra nada. Nadie escucha en `15432`, y nadie lo vuelve a abrir. El reinicio no cambia la host key de `server` (`restart` no recrea el contenedor), así que podrías volver a conectar ya.

2. **Corte sin aviso.** Ahora congela la sesión en lugar de cerrarla, como cuando la wifi cae o un NAT olvida la conexión. Abre el túnel:
   ```bash
   ssh -f -N -L 15432:db:5432 server; q
   ```
   ```
   3
   ```
   **En tu equipo**: `docker compose exec server pkill -STOP -f 'sshd: alumno'`. `SIGSTOP` congela los procesos de `sshd` de tu sesión: no contestan, pero tampoco cierran nada. **En el cliente**:
   ```bash
   q; pgrep -a ssh
   ```
   ```
   psql: error: connection to server at "127.0.0.1", port 15432 failed: timeout expired
   59 ssh -f -N -L 15432:db:5432 server
   ```
   - `ssh` sigue vivo y el puerto sigue abierto, pero no llega nada. Sin `PGCONNECT_TIMEOUT`, `psql` (o tu aplicación) se quedaría esperando sin límite.
   - Así puede quedarse horas: TCP solo da por muerta una conexión cuando intenta mandar algo y nadie contesta, y un túnel parado no manda nada.
   **En tu equipo**: `docker compose exec server pkill -CONT -f 'sshd: alumno'` (descongela). **En el cliente**: `pkill -x ssh`.

3. **`ServerAliveInterval` lo detecta.** El mismo túnel, preguntando cada 2 s (en el kit, 15):
   ```bash
   ssh -E ~/w/b.log -o ServerAliveInterval=2 -o ServerAliveCountMax=2 -f -N -L 15432:db:5432 server; q
   ```
   ```
   3
   ```
   **En tu equipo**, congela otra vez: `docker compose exec server pkill -STOP -f 'sshd: alumno'`. **En el cliente**, cuenta cuánto tarda `ssh` en salir:
   ```bash
   t0=$(date +%s); while pgrep -x ssh >/dev/null; do sleep 0.5; done; echo "ssh salió tras $(( $(date +%s)-t0 )) s"; cat ~/w/b.log
   ```
   ```
   ssh salió tras 9 s
   Timeout, server server not responding.
   ```
   - Cada 2 s sin tráfico, `ssh` pregunta por dentro de la conexión cifrada; tras 2 preguntas sin respuesta, sale con 255. Unos 6-9 s, según cuándo llegue la primera pregunta.
   - Un corte sin aviso se ha convertido en uno con aviso. Falta que alguien vuelva a abrir el túnel.
   **En tu equipo**: `docker compose exec server pkill -CONT -f 'sshd: alumno'`.

4. **`autossh`.** Lanza el túnel con `autossh`, que vuelve a lanzar `ssh` cada vez que sale:
   ```bash
   export AUTOSSH_GATETIME=0 AUTOSSH_LOGFILE=~/w/autossh.log
   autossh -M 0 -f -N -o ServerAliveInterval=5 -o ServerAliveCountMax=2 -o ExitOnForwardFailure=yes -L 15432:db:5432 server
   sleep 1; q; pgrep -a autossh; pgrep -a -x ssh
   ```
   ```
   3
   111 /usr/lib/autossh/autossh -M 0    -N -o ServerAliveInterval=5 -o ServerAliveCountMax=2 -o ExitOnForwardFailure=yes -L 15432:db:5432 server
   112 /usr/bin/ssh -N -o ServerAliveInterval=5 -o ServerAliveCountMax=2 -o ExitOnForwardFailure=yes -L 15432:db:5432 server
   ```
   - `autossh` (el proceso 111) lanzó `ssh` (el 112) con tus opciones. `-f` es de `autossh`: es él quien se va a segundo plano, no `ssh`.
   - `-M 0`: sin puerto de vigilancia; la vigilancia es `ServerAliveInterval`. `AUTOSSH_GATETIME=0`: reintenta también si el primer intento falla. `AUTOSSH_LOGFILE`: dónde escribe lo que hace.

5. **Reinicia `server` con `autossh` vigilando.** **En tu equipo**: `docker compose restart server`. **En el cliente**, espera a que el túnel vuelva:
   ```bash
   t0=$(date +%s); until [ "$(q)" = 3 ]; do sleep 1; done; echo "vuelve tras $(( $(date +%s)-t0 )) s"
   pgrep -a -x ssh
   cut -d' ' -f3- ~/w/autossh.log
   ```
   ```
   vuelve tras 2 s
   138 /usr/bin/ssh -N -o ServerAliveInterval=5 -o ServerAliveCountMax=2 -o ExitOnForwardFailure=yes -L 15432:db:5432 server
   autossh[108]: port set to 0, monitoring disabled
   autossh[111]: starting ssh (count 1)
   autossh[111]: ssh child pid is 112
   autossh[111]: ssh exited with error status 255; restarting ssh
   autossh[111]: starting ssh (count 2)
   autossh[111]: ssh child pid is 120
   autossh[111]: ssh exited with error status 255; restarting ssh
   ...
   autossh[111]: starting ssh (count 7)
   autossh[111]: ssh child pid is 138
   ```
   - Mientras `server` arrancaba, cada intento falló con 255 y `autossh` lo repitió. Cuando `sshd` volvió, el túnel también: `ssh` es otro proceso (138), y `autossh` el mismo (111). Los números y el número de intentos serán otros.
   - `cut -d' ' -f3-` quita la fecha y la hora de cada línea del log.

6. **Cerrar un túnel de `autossh`.** Si matas solo `ssh`:
   ```bash
   pkill -x ssh; sleep 2
   pgrep -a autossh || echo "autossh terminó"
   tail -1 ~/w/autossh.log | cut -d' ' -f3-
   ```
   ```
   autossh terminó
   autossh[111]: ssh exited with status 0; autossh exiting
   ```
   - `pkill` manda `TERM`: `ssh` sale de forma ordenada, con 0, y `autossh` entiende que lo cerraste tú y sale también. Lo normal es mandar `TERM` al propio `autossh` (su PID, con `AUTOSSH_PIDFILE`), que cierra su `ssh` y sale: es lo que hace `bin/tunnel down` en el proyecto.
   - El paso 5 es el caso contrario: `ssh` salió con 255, y `autossh` lo relanzó.

7. **Lo que `autossh` no arregla.** Si la autenticación falla, `autossh` reintenta para siempre en silencio. Pruébalo con una llave que no existe y `BatchMode` (sin preguntas):
   ```bash
   : > ~/w/autossh.log
   autossh -M 0 -f -N -o BatchMode=yes -o IdentityFile=/no/existe -o IdentitiesOnly=yes -o ExitOnForwardFailure=yes -L 15432:db:5432 server
   sleep 5; q; grep -c 'restarting ssh' ~/w/autossh.log
   pkill -x autossh
   ```
   ```
   psql: error: connection to server at "127.0.0.1", port 15432 failed: Connection refused
   7
   ```
   Siete reintentos en 5 s (el número variará; tras muchos fallos seguidos, `autossh` los espacia más), y ninguno va a funcionar. Nadie te avisa: el túnel simplemente no está. `bin/tunnel up` del proyecto espera unos segundos a que el puerto abra y, si no, para `autossh` y sale con error.

## Criterios de éxito

- [ ] Explicas la diferencia entre un corte con aviso y uno sin aviso, y lo que ve `psql` en cada uno (pasos 1 y 2)
- [ ] Explicas qué hace `ServerAliveInterval` y por qué no basta solo (paso 3)
- [ ] Mantienes un túnel con `autossh -M 0` a través de un reinicio del servidor (pasos 4 y 5)
- [ ] Explicas cuándo `autossh` relanza `ssh` y cuándo sale (pasos 5 y 6)
- [ ] Explicas qué fallo de un túnel no arregla `autossh` y cómo detectarlo (paso 7)

## Reto extra

Repite el paso 5 **congelando** `server` (`pkill -STOP`) en lugar de reiniciarlo, y descongélalo pasados 20 s. ¿Cuánto tarda el túnel en volver? ¿Qué intervalo de `ServerAliveInterval` × `ServerAliveCountMax` pondrías para un túnel que usa una aplicación, y por qué no 1 × 1?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 06 — Lo que el servidor permite](../lab-06-limites-del-servidor/README.md) | [Proyecto — ssh-infra-kit: túneles persistentes a PostgreSQL](../../3-proyecto/README.md) → |

[↑ Semana 08](../../README.md)
