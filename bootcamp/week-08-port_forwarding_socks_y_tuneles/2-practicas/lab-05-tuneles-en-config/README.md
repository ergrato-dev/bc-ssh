# Lab 05 — Túneles en `ssh_config` y con el master

⏱ Duración estimada: ~60 min

## Objetivo

Llevar los túneles de la línea de órdenes a `~/.ssh/config`, en un host propio. Entrar con shell a ese host sin sus túneles, y añadir y quitar túneles a una conexión ya abierta con el master del multiplexing.

## Contexto

- Las opciones de `ssh_config`: [teoría 02](../../1-teoria/02-socks-config-y-limites.md#túneles-en-ssh_config).
- Multiplexing y `ssh -O`: semana 05, [teoría 03](../../../week-05-configuracion_avanzada_cliente_ssh/1-teoria/03-multiplexing.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-reenvio-local/README.md), con la web de `server` en marcha.

1. **Un host para el túnel.** Crea `~/.ssh/config` con `nano ~/.ssh/config` (o con `cat`, como aquí):
   ```bash
   cat > ~/.ssh/config <<'EOF'
   Host tunel-web
       HostName server
       LocalForward 127.0.0.1:8080 localhost:8080
       DynamicForward 127.0.0.1:1080
       ExitOnForwardFailure yes
       SessionType none
       ForkAfterAuthentication yes
   EOF
   ssh -G tunel-web | grep -E '^(localforward|dynamicforward|sessiontype|forkafterauthentication|exitonforwardfailure)'
   ```
   ```
   exitonforwardfailure yes
   sessiontype none
   forkafterauthentication yes
   dynamicforward [127.0.0.1]:1080
   localforward [127.0.0.1]:8080 [localhost]:8080
   ```
   - `LocalForward 127.0.0.1:8080 localhost:8080` es `-L 127.0.0.1:8080:localhost:8080`: entre el origen y el destino va un espacio. `DynamicForward` es `-D`.
   - `SessionType none` es `-N`; `ForkAfterAuthentication yes` es `-f` (las dos, OpenSSH 8.7+).
   - `ssh -G` lo comprueba sin conectar, como en la semana 05.

2. **Abrirlo con un nombre.**
   ```bash
   ssh tunel-web; echo "código: $?"
   curl -s localhost:8080
   pgrep -a ssh
   ```
   ```
   código: 0
   hola desde server
   51 ssh tunel-web
   ```
   Los dos túneles en una sola orden, que ya no tienes que recordar. `pgrep` dice qué túnel es cada proceso por su nombre.

3. **Otra vez el mismo.**
   ```bash
   ssh tunel-web; echo "código: $?"
   ```
   ```
   bind [127.0.0.1]:8080: Address already in use
   channel_setup_fwd_listener_tcpip: cannot listen to port: 8080
   bind [127.0.0.1]:1080: Address already in use
   channel_setup_fwd_listener_tcpip: cannot listen to port: 1080
   Could not request local forwarding.
   código: 255
   ```
   Con `ExitOnForwardFailure`, el segundo sale con error y no deja un proceso sin túneles. Por eso los túneles van en un host propio (`tunel-web`) y no en `server`: si `server` llevara `LocalForward`, tu segunda shell en `server` no podría entrar.

4. **Entrar con shell en un host de túnel.** A veces quieres la shell de ese mismo host, sin sus túneles:
   ```bash
   ssh -o ClearAllForwardings=yes -o SessionType=default -o ForkAfterAuthentication=no tunel-web hostname; echo "código: $?"
   pkill -x ssh
   ```
   ```
   server
   código: 0
   ```
   - `ClearAllForwardings yes`: olvida todos los `LocalForward`, `RemoteForward` y `DynamicForward` de la configuración. Así no choca con el túnel que ya está abierto.
   - La línea de órdenes gana a `~/.ssh/config` (el primer valor gana, semana 05): `-o SessionType=default` y `-o ForkAfterAuthentication=no` deshacen las otras dos.
   - `pkill -x ssh`: cierra todos los procesos que se llamen exactamente `ssh`.

5. **Túneles en un master abierto.** Abre un master (semana 05) y pídele túneles sin volver a autenticarte:
   ```bash
   M='-o ControlMaster=auto -o ControlPath=~/.ssh/cm-%C -o ControlPersist=5m'
   ssh $M server true
   ssh $M -O forward -L 15432:db:5432 server; echo "código: $?"
   PGPASSWORD=alumno psql -h 127.0.0.1 -p 15432 -U alumno tienda -tAc 'select count(*) from productos'
   ```
   ```
   código: 0
   3
   ```
   - `ssh $M server true` deja el master abierto 5 min. `-O forward -L`: le pide al master un reenvío nuevo y sale. El túnel **vive en el master**, no en este proceso.
   - `PGPASSWORD` delante de la orden: solo para esa orden. Contraseña **solo del laboratorio**.

6. **Quitarlo y cerrar el master.**
   ```bash
   ssh $M -O cancel -L 15432:db:5432 server; echo "código: $?"
   PGPASSWORD=alumno psql -h 127.0.0.1 -p 15432 -U alumno tienda -tAc 'select 1'
   ssh $M -O check server
   ssh $M -O exit server
   ```
   ```
   código: 0
   psql: error: connection to server at "127.0.0.1", port 15432 failed: Connection refused
   Master running (pid=60)
   Exit request sent.
   ```
   - `-O cancel` cierra solo ese túnel; el master sigue (`-O check`). `-O exit` lo cierra todo.
   - La otra cara: un `ssh -L ... server` normal con un master abierto **tampoco** abre conexión propia, y su túnel también se queda en el master hasta que este muere. Un túnel que quieras vigilar o cerrar por separado necesita `ControlMaster no` y `ControlPath none` ([teoría 02](../../1-teoria/02-socks-config-y-limites.md#túneles-y-multiplexing)). Lo usas en el proyecto.

7. **Túneles desde una sesión interactiva.** Entra con la línea de escape activada:
   ```bash
   ssh -o EnableEscapeCommandline=yes server
   ```
   Ya en `server`, pulsa `Enter`, después `~` y `C` (mayúscula). Aparece `ssh>`. Escribe:
   ```
   ssh> -L 8081:localhost:8080
   Forwarding port.
   ```
   Sal con `exit`. Mientras la sesión estaba abierta, `curl -s localhost:8081` desde otra terminal del cliente habría respondido. La línea `~C` está desactivada por defecto desde OpenSSH 9.2:
   ```bash
   ssh -G server | grep -i enableescape
   ```
   ```
   enableescapecommandline no
   ```
   Un programa que escriba en tu terminal (una salida maliciosa de `cat`) podía mandar esas teclas y abrir túneles por ti. Actívala solo cuando la necesites.

## Criterios de éxito

- [ ] Escribes un host de túnel con `LocalForward`, `DynamicForward`, `SessionType` y `ForkAfterAuthentication`, y lo compruebas con `ssh -G` (paso 1)
- [ ] Explicas por qué los túneles van en un host propio (paso 3)
- [ ] Entras con shell a un host de túnel sin sus túneles (paso 4)
- [ ] Añades y quitas túneles a un master con `-O forward` y `-O cancel`, y explicas qué problema da el master a un túnel persistente (pasos 5 y 6)
- [ ] Explicas por qué `~C` viene desactivada (paso 7)

## Reto extra

Añade a `tunel-web` la línea `RemoteForward 9000 localhost:9000` y abre el túnel sin tener nada escuchando en tu `9000`. ¿Falla al abrir? ¿Y al hacer `ssh server curl -s localhost:9000`? ¿Por qué `ExitOnForwardFailure` no lo detecta?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 04 — Un proxy SOCKS con `ssh -D`](../lab-04-socks/README.md) | [Lab 06 — Lo que el servidor permite](../lab-06-limites-del-servidor/README.md) → |

[↑ Semana 08](../../README.md)
