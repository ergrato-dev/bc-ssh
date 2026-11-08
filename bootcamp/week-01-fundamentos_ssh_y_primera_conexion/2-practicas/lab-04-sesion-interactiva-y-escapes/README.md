# Lab 04 — Sesión interactiva y secuencias de escape

⏱ Duración estimada: ~60 min

## Objetivo

Ver qué procesos crea `sshd` por cada conexión, y recuperar el control de una sesión colgada con las secuencias de escape del cliente.

## Contexto

- Cuando te conectas, el proceso `sshd` principal (el que escucha en el 22) crea un proceso hijo **solo para tu conexión**. Si ese hijo muere, tu sesión cae, pero las de los demás siguen.
- El cliente `ssh` vigila lo que tecleas. Una línea que empieza por `~` (virgulilla) seguida de ciertos caracteres no se envía al servidor: es una orden **para el cliente**. Así puedes cortar una conexión aunque el servidor no responda.
- **Qué:** `~.` cierra la conexión desde tu lado. **Para qué:** salir de una sesión colgada sin cerrar la terminal. **Impacto:** el programa remoto recibe un corte de conexión, igual que si se cayera la red.
- En un teclado en español, `~` suele salir con **AltGr+4** (Windows/Linux) u **Option+ñ** (macOS). Prueba en la terminal antes de empezar.
- Necesitas **dos terminales**: **En tu equipo** y **En el cliente**.

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d
   ```
   En la otra terminal:
   ```bash
   docker compose run --rm client
   ```

1. **En el cliente**, abre una sesión interactiva en `server` (huella y contraseña `alumno` como en el lab-02):
   ```bash
   ssh server
   ```
   ```
   alumno@server:~$
   ```

2. **En tu equipo**, mira los procesos `sshd` de `server`:
   ```bash
   docker compose exec server ps -o pid,ppid,user,cmd -C sshd
   ```
   ```
       PID    PPID USER     CMD
         1       0 root     sshd: /usr/sbin/sshd -D -e [listener] 0 of 10-100 startups
       247       1 root     sshd: alumno [priv]
       258     247 alumno   sshd: alumno@pts/0
   ```
   - PID 1, `[listener]`: el servidor que escucha. `0 of 10-100 startups` cuenta las conexiones a medio autenticar (la semana 07 explica ese límite).
   - `[priv]`: el hijo creado para tu conexión. Corre como `root` y hace lo poco que necesita privilegios.
   - `alumno@pts/0`: su hijo, con **tus** permisos, que atiende tu sesión en la terminal `pts/0`. Si este proceso tiene un fallo, el atacante solo consigue los permisos de `alumno`. Eso se llama **separación de privilegios**.

   Los PID serán otros. Si abres una segunda sesión, aparece otro par `[priv]` y `alumno@pts/1`.

3. **En el cliente** (dentro de `server`), pide la ayuda de escapes. Pulsa **Enter** primero (los escapes solo se reconocen al principio de una línea) y escribe `~?`:
   ```
   Supported escape sequences:
    ~.   - terminate connection (and any multiplexed sessions)
    ~B   - send a BREAK to the remote system
    ~R   - request rekey
    ~V/v - decrease/increase verbosity (LogLevel)
    ~^Z  - suspend ssh
    ~#   - list forwarded connections
    ~&   - background ssh (when waiting for connections to terminate)
    ~?   - this message
    ~~   - send the escape character by typing it twice
   (Note that escapes are only recognized immediately after newline.)
   ```
   Los caracteres `~?` no aparecen en pantalla al escribirlos: el cliente se los quedó.

4. Suspende el cliente y vuelve. Pulsa **Enter**, luego `~` y después **Ctrl+Z**:
   ```
   [1]+  Stopped                 ssh server
   alumno@client:/bc-ssh$
   ```
   Estás en el cliente con la conexión en pausa. Vuelve:
   ```bash
   fg
   ```
   Pulsa **Enter** y vuelve a ver el prompt `alumno@server:~$`.

5. Simula un servidor colgado. **En tu equipo**, congela el contenedor:
   ```bash
   docker compose pause server
   ```
   **En el cliente**, escribe `hostname` y Enter. No pasa nada: el servidor no responde y no hay error, porque TCP sigue esperando. Así se ve una sesión colgada de verdad (Wi-Fi caída, VPN cortada, portátil que despierta de la suspensión).

6. Recupera la terminal. Pulsa **Enter**, luego `~.`:
   ```
   Connection to server closed.
   alumno@client:/bc-ssh$
   ```
   Sin esto, la única salida sería cerrar la terminal. **En tu equipo**, descongela:
   ```bash
   docker compose unpause server
   ```

7. Envía una `~` de verdad al servidor. Conéctate otra vez (`ssh server`) y escribe al principio de la línea `~~/` y Enter:
   ```
   alumno@server:~$ ~/
   -bash: /home/alumno/: Is a directory
   ```
   `~~` envía una sola `~`. La shell remota recibió `~/` y lo expandió a tu home.

8. Cierra con `exit` y sal del cliente con `exit`.

## Criterios de éxito

- [ ] Identificas los procesos `[listener]`, `[priv]` y `alumno@pts/N` y quién es el padre de cada uno (paso 2)
- [ ] `~?` muestra la ayuda de escapes (paso 3)
- [ ] Suspendiste y recuperaste la sesión con `~` Ctrl+Z y `fg` (paso 4)
- [ ] Saliste de la sesión colgada con `~.` (paso 6)

## Reto extra

Con `server` en pausa, conéctate con `ssh -o ServerAliveInterval=2 -o ServerAliveCountMax=2 server` justo **antes** de pausarlo. ¿Cuánto tarda en cortar solo? ¿Qué mensaje da? La semana 05 explica esas opciones.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 03 — Comandos remotos](../lab-03-comandos-remotos/README.md) | [Lab 05 — Leer una conexión con `ssh -v`](../lab-05-modo-verbose/README.md) → |

[↑ Semana 01](../../README.md)
