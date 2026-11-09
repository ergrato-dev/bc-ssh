# Lab 01 — Reenvío local: un servicio que solo escucha en el servidor

⏱ Duración estimada: ~60 min

## Objetivo

Llegar con `ssh -L` a una web que en `server` solo escucha en `127.0.0.1`. Ver dónde abre `ssh` el puerto, qué pasa si está ocupado, cómo publicarlo en tu red (y por qué no hacerlo), y cerrar el túnel.

## Contexto

- Cómo funciona `-L`: [teoría 01](../../1-teoria/01-reenvio-local-y-remoto.md#-l-un-puerto-de-tu-equipo-que-sale-por-el-servidor).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación.** En tu equipo, desde la raíz del repositorio:
   ```bash
   docker compose up -d --build --force-recreate server
   docker compose run --rm client
   ```
   `--build` reconstruye la imagen: esta semana añade `psql` (el cliente de PostgreSQL) y `autossh`, y `compose.yaml` añade el servicio `db`. `--force-recreate` deja `server` como recién instalado: cada lab empieza limpio. **En el cliente**, `known_hosts` y una llave instalada en `server`, como en la semana 03:
   ```bash
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh ~/w
   ssh-keyscan -t ed25519 server 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/id_ed25519
   sshpass -e ssh-copy-id -f server 2>&1 | grep 'Number of'
   ```
   ```
   Number of key(s) added: 1
   ```
   La llave no tiene frase (`-N ''`) para no escribirla en cada paso: **solo en el laboratorio**. Por último, arranca en `server` una web que solo escucha en su `127.0.0.1`. Los labs siguientes la usan: repite esta orden después de cada `--force-recreate`:
   ```bash
   ssh server 'mkdir -p ~/web; echo "hola desde server" > ~/web/index.html; nohup python3 -m http.server 8080 --bind 127.0.0.1 --directory ~/web >/dev/null 2>&1 &'
   ```
   - `python3 -m http.server 8080`: un servidor web mínimo que sirve la carpeta `--directory`. `--bind 127.0.0.1`: solo acepta conexiones del propio `server`, como una consola de administración o una base de datos bien configurada.
   - `nohup ... &`: sigue corriendo cuando la sesión SSH se cierra.

1. **Desde fuera no se llega.** Prueba desde el cliente y desde el propio `server`:
   ```bash
   curl -sS -m 3 http://server:8080; echo "código: $?"
   ssh server 'curl -s localhost:8080'
   ```
   ```
   curl: (7) Failed to connect to server port 8080 after 0 ms: Couldn't connect to server
   código: 7
   hola desde server
   ```
   - `curl`: descarga una URL y la escribe en la terminal. `-s` sin barra de progreso, `-S` sí muestra los errores, `-m 3` se rinde a los 3 s.
   - La web existe, pero solo para quien ya está dentro de `server`.

2. **El túnel.**
   ```bash
   ssh -f -N -L 8080:localhost:8080 server
   curl -s localhost:8080
   ```
   ```
   hola desde server
   ```
   - `-L 8080:localhost:8080`: abre el `8080` de **tu** equipo; cada conexión que llegue, `server` la conecta con `localhost:8080`, y `localhost` ahí es **`server`**.
   - `-N`: sin shell ni comando. `-f`: a segundo plano después de autenticarse. Te devuelve el prompt y el túnel sigue.

3. **Dónde escucha.** `ss` lista los puertos abiertos en tu equipo:
   ```bash
   ss -ltnp | grep 8080
   ```
   ```
   LISTEN 0      128        127.0.0.1:8080       0.0.0.0:*    users:(("ssh",pid=47,fd=5))
   LISTEN 0      128            [::1]:8080          [::]:*    users:(("ssh",pid=47,fd=4))
   ```
   - `-l` los que escuchan, `-t` TCP, `-n` números en lugar de nombres, `-p` qué proceso.
   - Es `ssh` quien escucha, y solo en `localhost` (IPv4 e IPv6). Otro equipo de tu red no puede usar tu túnel. Tu PID será otro.

4. **Cerrar el túnel.** `ssh -f` no tiene terminal a la que pulsar `Ctrl+C`: se cierra con `kill`.
   ```bash
   pgrep -a ssh
   kill $(pgrep -f 'ssh -f -N -L 8080')
   curl -sS localhost:8080; echo "código: $?"
   ```
   ```
   47 ssh -f -N -L 8080:localhost:8080 server
   curl: (7) Failed to connect to localhost port 8080 after 0 ms: Couldn't connect to server
   código: 7
   ```
   `pgrep -a` lista los procesos con su orden completa; `-f` busca el patrón en la orden completa, no solo en el nombre.

5. **Puerto ocupado.** Abre el mismo túnel dos veces:
   ```bash
   ssh -f -N -L 8080:localhost:8080 server
   ssh -f -N -L 8080:localhost:8080 server; echo "código: $?"
   pgrep -c -f 'ssh -f -N -L 8080'
   ```
   ```
   bind [127.0.0.1]:8080: Address already in use
   channel_setup_fwd_listener_tcpip: cannot listen to port: 8080
   Could not request local forwarding.
   código: 0
   2
   ```
   El segundo avisa, **sale con 0 y se queda conectado sin túnel**: un proceso inútil que un script daría por bueno. Con `ExitOnForwardFailure`:
   ```bash
   ssh -f -N -o ExitOnForwardFailure=yes -L 8080:localhost:8080 server; echo "código: $?"
   pkill -f 'ssh -f -N'
   ```
   ```
   bind [127.0.0.1]:8080: Address already in use
   channel_setup_fwd_listener_tcpip: cannot listen to port: 8080
   Could not request local forwarding.
   código: 255
   ```
   Ahora sale con error. Todos los túneles de tus scripts lo llevan (el kit, en el proyecto). `pkill -f` cierra los dos procesos que quedaban.

6. **Varios túneles y la dirección de escucha.** Una conexión puede llevar varios `-L`. Uno con dirección explícita `0.0.0.0` y otro sin ella:
   ```bash
   ssh -f -N -L 0.0.0.0:8081:localhost:8080 -L 8082:localhost:8080 server
   ss -ltn | grep -E ':808[12]'
   hostname -i
   ```
   ```
   LISTEN 0      128        127.0.0.1:8082       0.0.0.0:*
   LISTEN 0      128          0.0.0.0:8081       0.0.0.0:*
   LISTEN 0      128            [::1]:8082          [::]:*
   172.20.0.6
   ```
   - `8081` escucha en **todas** las interfaces: cualquiera que llegue a `172.20.0.6:8081` (tu IP en la red del laboratorio; la tuya será otra) entra en la web interna de `server` **sin autenticarse**, usando tu conexión.
   - En tu portátil, eso es cualquiera en la misma wifi. Escribe siempre `127.0.0.1:` delante, o nada.
   ```bash
   pkill -f 'ssh -f -N'
   ```

7. **El túnel por dentro.** Repite el túnel con `-v` y guarda el log en un archivo (`-E`), porque con `-f` la terminal ya no es suya:
   ```bash
   ssh -v -E ~/w/tun.log -f -N -L 8080:localhost:8080 server
   curl -s localhost:8080 >/dev/null
   grep -E 'forward|channel 2' ~/w/tun.log | cut -c1-110
   pkill -f 'ssh -v -E'
   ```
   ```
   debug1: Local connections to LOCALHOST:8080 forwarded to remote address localhost:8080
   debug1: Local forwarding listening on ::1 port 8080.
   debug1: Local forwarding listening on 127.0.0.1 port 8080.
   debug1: Connection to port 8080 forwarding to localhost port 8080 requested.
   debug1: channel 2: new direct-tcpip [direct-tcpip] (inactive timeout: 0)
   debug1: channel 2: free: direct-tcpip: listening port 8080 for localhost port 8080, connect from ::1 port 3
   ```
   - Los canales 0 y 1 son los dos puertos que escuchan; el `curl` abre el 2, de tipo `direct-tcpip`, y lo libera (`free`) al terminar. Cada conexión al túnel es un canal nuevo dentro de la misma conexión SSH ([teoría 01](../../1-teoria/01-reenvio-local-y-remoto.md#canales-lo-que-ya-viajaba-dentro-de-ssh)).
   - `curl` usó `::1` (IPv6) porque `localhost` resuelve primero a esa dirección.

## Criterios de éxito

- [ ] Explicas por qué `curl server:8080` falla y el túnel funciona, y quién resuelve `localhost` en `-L 8080:localhost:8080` (pasos 1 y 2)
- [ ] Encuentras y cierras un túnel en segundo plano (pasos 3 y 4)
- [ ] Explicas qué hace `ExitOnForwardFailure` y por qué un script lo necesita (paso 5)
- [ ] Explicas el riesgo de `-L 0.0.0.0:...` (paso 6)
- [ ] Ves en `ssh -v` un canal `direct-tcpip` por cada conexión al túnel (paso 7)

## Reto extra

Abre `ssh -f -N -L 8080:localhost:8080 server` y, sin cerrarlo, lanza tres `curl -s localhost:8080` a la vez (`for i in 1 2 3; do curl -s localhost:8080 & done; wait`). Con `-v` y `-E`, ¿cuántos canales `direct-tcpip` se abren? ¿Cuántas conexiones TCP hay entre tu equipo y `server` (`ss -tn | grep :22`)?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Índice de labs](../README.md) | [Lab 02 — PostgreSQL a través de `server`](../lab-02-postgres-por-tunel/README.md) → |

[↑ Semana 08](../../README.md)
