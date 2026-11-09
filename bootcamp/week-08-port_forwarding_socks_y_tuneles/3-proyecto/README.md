# Proyecto Semana 08 — ssh-infra-kit: túneles persistentes a PostgreSQL

⏱ Duración estimada: ~3 h

## Contexto

Tu kit ya entra, copia y endurece. Esta semana aprende a **llevarte a un servicio que no está publicado**: la base de datos PostgreSQL de `db`, que solo alcanza `server`. Dos piezas:

- **`conf.d/20-tuneles.conf`**: el host `tun-pg`, un túnel con todo lo que viste en los labs: escucha solo en `127.0.0.1`, sale si no puede abrir el puerto, detecta una conexión muerta, sin sesión y sin multiplexing.
- **`bin/tunnel up|status|down NOMBRE`**: abre ese túnel con `autossh` para que vuelva solo cuando se corta, dice si está vivo y lo cierra. No deja procesos colgados cuando algo falla ([lab 07](../2-practicas/lab-07-tuneles-persistentes/README.md), paso 7).

## Estructura del proyecto

```
starter/                    ← aquí trabajas: tu ssh-infra-kit de la semana 07 + TODOs
├── README.md               ← documentación del kit (TODOs)
├── config                  ← semana 05, terminado
├── conf.d/
│   ├── 00-perfiles.conf, 10-lab.conf   ← semana 05
│   └── 20-tuneles.conf     ← TODOs 1, 2 y 3
├── bin/
│   ├── lab-check … sshd-deploy         ← semanas 01-07
│   └── tunnel              ← TODOs 4 a 8
└── server/                 ← semana 07
solucion/                   ← referencia: no la abras hasta terminar
```

## Lo que debes construir

### `conf.d/20-tuneles.conf`: el host `tun-pg`

| Opción | Valor | Lab |
|---|---|---|
| `HostName`, `User`, `IdentityFile` | `server`, `alumno`, `~/.ssh/lab` | — |
| `LocalForward` | `127.0.0.1:15432 db:5432` | [01](../2-practicas/lab-01-reenvio-local/README.md), [02](../2-practicas/lab-02-postgres-por-tunel/README.md) |
| `ExitOnForwardFailure` | `yes` | 01 |
| `ServerAliveInterval`, `ServerAliveCountMax` | `15`, `3` | 07 |
| `SessionType` | `none` | 05 |
| `ControlMaster`, `ControlPath` | `no`, `none` | 05 |

Cada opción lleva su **Qué / Para qué / Impacto** en un comentario.

### `bin/tunnel`

| Orden | Hace | Código |
|---|---|---|
| `up NOMBRE [OPCIONES DE SSH...]` | Si ya está activo, nada. Si el puerto local está ocupado por otro programa, avisa. Si no, `autossh -M 0 -f -F config ... NOMBRE` y espera a que el puerto escuche | 0 activo; 1 ocupado o no abrió en `TUNNEL_TIMEOUT` s (10), y no deja procesos |
| `status NOMBRE` | Activo si `autossh` vive y el puerto escucha | 0 activo, 1 no |
| `down NOMBRE` | `TERM` a `autossh`, espera a que salga y borra su pidfile | 0 |

- El puerto lo saca del `LocalForward` del host, con `ssh -G` (sin `LocalForward`: código 1). Así un túnel nuevo es solo un bloque `Host` nuevo.
- Guarda el PID de `autossh` en `TUNNEL_DIR/NOMBRE.pid` (`~/.ssh/tun`). Uso incorrecto, o `TUNNEL_TIMEOUT` que no es un entero mayor que 0: código 2.

## Paso a paso

### Paso 0 — Preparar la terminal

Desde la raíz del repositorio en tu equipo:

```bash
docker compose up -d --build --force-recreate server
docker compose run --rm client
```

`--build`: la imagen añade `psql` y `autossh`, y arranca `db`. Ya dentro del contenedor, enlaza el kit, prepara `known_hosts` y una llave sin frase (solo laboratorio) para `lab-server`, como en la semana 07:

```bash
cd bootcamp/week-08-port_forwarding_socks_y_tuneles/3-proyecto/starter
mkdir -p -m 700 ~/.ssh ~/w
bin/kit-link
export SSHPASS=alumno
ssh-keyscan -t ed25519 server 2>/dev/null > ~/.ssh/known_hosts
ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/lab
sshpass -e ssh-copy-id -F config -o ControlPath=none -i ~/.ssh/lab.pub lab-server 2>&1 | grep 'Number of'
echo '127.0.0.1:15432:tienda:alumno:alumno' > ~/.pgpass; chmod 600 ~/.pgpass
```

```
kit-link: /home/alumno/.ssh/kit -> /bc-ssh/bootcamp/week-08-port_forwarding_socks_y_tuneles/3-proyecto/starter
Number of key(s) added: 1
```

`~/.pgpass` lleva la contraseña de PostgreSQL del laboratorio (`alumno`, **solo del laboratorio**), con permisos 600, como en el [lab 02](../2-practicas/lab-02-postgres-por-tunel/README.md). Va en tu `~`, nunca en el kit.

### Paso 1 — Lo que hay ahora

```bash
ssh -G -F config tun-pg | grep -E '^(hostname|localforward)'
bin/tunnel up tun-pg; echo "código: $?"
```

```
hostname tun-pg
tunnel: tun-pg no tiene LocalForward en el kit
código: 1
```

El host existe, pero vacío: sin `HostName`, `ssh` usaría el propio nombre `tun-pg`, que no existe. `bin/tunnel` ya sabe leer el puerto del host; te falta todo lo demás.

### Paso 2 — TODO 1: a dónde va el túnel

En `conf.d/20-tuneles.conf`, dentro de `Host tun-pg`: `HostName server`, `User alumno`, `IdentityFile ~/.ssh/lab` y el reenvío del [lab 02](../2-practicas/lab-02-postgres-por-tunel/README.md), escrito como en el [lab 05](../2-practicas/lab-05-tuneles-en-config/README.md):

```bash
ssh -G -F config tun-pg | grep -E '^(hostname|user |identityfile|localforward)'
```

```
user alumno
hostname server
localforward [127.0.0.1]:15432 [db]:5432
identityfile ~/.ssh/lab
```

`127.0.0.1` delante del puerto, aunque sin él `ssh` también escucharía en `localhost`: escrito así, no cambia si alguien activa `GatewayPorts` en el cliente ([teoría 01](../1-teoria/01-reenvio-local-y-remoto.md#dónde-escucha-el-puerto-local)). Pon en el comentario por qué.

### Paso 3 — TODO 2: fallar pronto y detectar el corte

`ExitOnForwardFailure yes`, `ServerAliveInterval 15` y `ServerAliveCountMax 3`:

```bash
ssh -G -F config tun-pg | grep -E '^(exitonforwardfailure|serveralive)'
```

```
exitonforwardfailure yes
serveralivecountmax 3
serveraliveinterval 15
```

- Sin `ExitOnForwardFailure`, con el puerto ocupado, `ssh` se queda conectado sin túnel y `autossh` cree que todo va bien ([lab 01](../2-practicas/lab-01-reenvio-local/README.md), paso 5).
- Sin `ServerAliveInterval`, una conexión congelada parece viva para siempre ([lab 07](../2-practicas/lab-07-tuneles-persistentes/README.md), paso 2). 15 × 3 = 45 s: lo bastante corto para que tu aplicación no espere mucho y lo bastante largo para que una red lenta no corte el túnel.

### Paso 4 — TODO 3: sin sesión y sin master

`SessionType none`, `ControlMaster no` y `ControlPath none`:

```bash
ssh -G -F config tun-pg | grep -E '^(sessiontype|controlmaster|controlpath)'
```

```
controlmaster false
sessiontype none
```

- `ssh -G` no escribe `controlpath` cuando vale `none`: que no salga es lo correcto.
- Sin `ControlMaster no`, el `ControlMaster auto` de `config` haría que el `ssh` de `autossh` le pidiera el túnel a un master y saliera al momento; `autossh` lo relanzaría sin parar ([teoría 03](../1-teoria/03-tuneles-persistentes.md#un-túnel-con-su-propia-conexión)).
- Pruébalo a mano antes de seguir. En primer plano, `ssh -F config tun-pg` se quedaría esperando sin prompt; con `&` lo dejas en segundo plano en la misma terminal:
  ```bash
  ssh -F config tun-pg & sleep 1
  psql -h 127.0.0.1 -p 15432 -U alumno tienda -tAc 'select 1'
  kill %1
  ```
  ```
  1
  ```
  `%1` es el primer trabajo en segundo plano de tu shell (`jobs` los lista).

### Paso 5 — TODO 4: uso correcto

En `bin/tunnel`, sustituye las tres líneas del TODO 4 por la validación: dos argumentos como mínimo, la orden es `up`, `status` o `down`, `status` y `down` no aceptan nada más, el nombre solo lleva letras, números, `.`, `_` o `-`, y `TUNNEL_TIMEOUT` es un entero mayor que 0. Todo lo demás, `uso` (código 2).

```bash
bin/tunnel; echo "código: $?"
bin/tunnel status tun-pg extra; echo "código: $?"
TUNNEL_TIMEOUT=0 bin/tunnel up tun-pg; echo "código: $?"
bin/tunnel up lab-server; echo "código: $?"
```

```
uso: tunnel up NOMBRE [OPCIONES DE SSH...] | tunnel status NOMBRE | tunnel down NOMBRE
código: 2
uso: tunnel up NOMBRE [OPCIONES DE SSH...] | tunnel status NOMBRE | tunnel down NOMBRE
código: 2
tunnel: TUNNEL_TIMEOUT debe ser un entero mayor que 0
código: 2
tunnel: lab-server no tiene LocalForward en el kit
código: 1
```

`[[ "$x" =~ ^[0-9]+$ ]]` comprueba un patrón, como en `sshd-deploy` (semana 07). Un nombre con `/` acabaría en una ruta fuera de `TUNNEL_DIR`: por eso se valida.

### Paso 6 — TODO 6: arrancar `autossh` y esperar al puerto

El corazón del script, después de los TODO 8 (déjalos para el paso 7):

1. Crea `TUNNEL_DIR` con permisos 700.
2. Lanza `autossh` como en el [lab 07](../2-practicas/lab-07-tuneles-persistentes/README.md), paso 4, pero con las variables delante de la orden y el host del kit:
   ```bash
   AUTOSSH_PIDFILE="$pidfile" AUTOSSH_GATETIME=0 autossh -M 0 -f -F "$kit/config" "$@" "$nombre"
   ```
   `"$@"` son las opciones extra de `up` (el `shift 2` ya quitó la orden y el nombre). El resto de opciones están en `tun-pg`.
3. Repite `escucha` cada medio segundo durante `TUNNEL_TIMEOUT` segundos. Si escucha: `tunnel: NOMBRE activo (pid N) en IP:PUERTO` y código 0.
4. Si no llega a escuchar: `parar` y código 1, con un mensaje que diga cómo ver el motivo (`ssh -F config -v NOMBRE`).

El paso 4 es lo que el lab 07 (paso 7) echaba de menos: sin él, un túnel con la llave equivocada deja un `autossh` reintentando para siempre. `parar` aún está vacío: para probar este paso, cierra a mano con `pkill -x autossh`.

```bash
bin/tunnel up tun-pg; echo "código: $?"
psql -h 127.0.0.1 -p 15432 -U alumno tienda -tAc 'select nombre from productos order by id'
pkill -x autossh
```

```
tunnel: tun-pg activo (pid 109) en 127.0.0.1:15432
código: 0
teclado
ratón
monitor
```

### Paso 7 — TODO 8: una sola vez, y el puerto de otro

Antes de lanzar `autossh`:

- Si `vivo` (el túnel ya está): `tunnel: NOMBRE ya estaba activo (pid N) en IP:PUERTO`, código 0. Dos `up` seguidos no pueden dejar dos `autossh`: el segundo chocaría con el puerto y reintentaría para siempre.
- Si no está vivo pero `escucha`: otro programa tiene el puerto. `tunnel: IP:PUERTO ya está ocupado por otro programa`, código 1.

```bash
bin/tunnel up tun-pg; bin/tunnel up tun-pg; pgrep -c autossh
pkill -x autossh
(nc -lk 127.0.0.1 15432 &); sleep 0.3
bin/tunnel up tun-pg; echo "código: $?"
pkill -f 'nc -lk 127.0.0.1 15432'
```

```
tunnel: tun-pg activo (pid 109) en 127.0.0.1:15432
tunnel: tun-pg ya estaba activo (pid 109) en 127.0.0.1:15432
1
tunnel: 127.0.0.1:15432 ya está ocupado por otro programa
código: 1
```

`nc -lk` escucha en un puerto y no hace nada más: es el "otro programa".

### Paso 8 — TODOs 5 y 7: `status` y `down`

- **`parar`** (TODO 7): lee el PID del pidfile, manda `kill` (TERM) y espera hasta 5 s (50 × 0,1 s) a que el proceso salga (`kill -0 PID` falla cuando ya no existe). Después, `rm -f` del pidfile. `autossh` con TERM cierra su `ssh` antes de salir ([lab 07](../2-practicas/lab-07-tuneles-persistentes/README.md), paso 6).
- **`status`** (TODO 5): `vivo && escucha`: código 0 y `tunnel: NOMBRE activo (pid N) en IP:PUERTO`; si no, `tunnel: NOMBRE no está activo` y código 1.

```bash
bin/tunnel up tun-pg >/dev/null
bin/tunnel status tun-pg; echo "código: $?"
bin/tunnel down tun-pg
bin/tunnel status tun-pg; echo "código: $?"
pgrep -c autossh
```

```
tunnel: tun-pg activo (pid 109) en 127.0.0.1:15432
código: 0
tunnel: tun-pg cerrado
tunnel: tun-pg no está activo
código: 1
0
```

Por qué `status` mira las dos cosas: un `autossh` vivo con el puerto cerrado es un túnel que está reintentando (servidor caído, llave rechazada). Para quien usa la base de datos, eso es "no está activo".

### Paso 9 — Probarlo de verdad: un reinicio de `server`

```bash
bin/tunnel up tun-pg
```

**En tu equipo**: `docker compose restart server`. **En el cliente**:

```bash
t0=$(date +%s); until bin/tunnel status tun-pg >/dev/null 2>&1 && psql -h 127.0.0.1 -p 15432 -U alumno -w tienda -tAc 'select 1' >/dev/null 2>&1; do sleep 1; done; echo "vuelve tras $(( $(date +%s)-t0 )) s"
bin/tunnel status tun-pg
bin/tunnel down tun-pg
```

```
vuelve tras 2 s
tunnel: tun-pg activo (pid 109) en 127.0.0.1:15432
tunnel: tun-pg cerrado
```

El mismo `autossh` (mismo PID) con un `ssh` nuevo dentro. Sin que hagas nada, `psql` vuelve a funcionar en cuanto `server` arranca. Prueba también a abrir el túnel con la llave equivocada: `TUNNEL_TIMEOUT=3 bin/tunnel up tun-pg -o IdentityFile=/no/existe -o BatchMode=yes` tiene que salir con 1 a los 3 s, y `pgrep -c autossh` dar `0`.

### Paso 10 — Calidad, README y git

1. `shellcheck bin/*` sin avisos, y ningún `TODO` en `config`, `conf.d/`, `bin/` ni `server/`.
2. Completa los TODOs de `starter/README.md`: las filas de `conf.d/20-tuneles.conf` y `bin/tunnel`, la bitácora de la semana 08 y la sección "Túneles" (cómo abrir el túnel y usar `psql`, qué hacer si `bin/tunnel up` sale con 1, cómo añadir un túnel y por qué escucha solo en `127.0.0.1`).
3. Copia el kit a tu repositorio y haz el commit de la semana:
   ```bash
   cp -r config conf.d bin server README.md ~/ssh-infra-kit/
   cd ~/ssh-infra-kit && git add -A && git commit -m "semana 08: túneles persistentes con tun-pg y bin/tunnel"
   git log --stat -1
   ```
   En el commit deben aparecer `README.md`, `conf.d/20-tuneles.conf` y `bin/tunnel`: ni llaves, ni `~/.pgpass`, ni pidfiles.

### Paso 11 — Autograding

Desde la raíz del repositorio, **en tu equipo**:

```bash
./scripts/verificar-semana.sh 08
```

Los checks no usan `server` ni `db`: arrancan un `sshd` propio en el puerto 2208 del contenedor `client`, apuntan el nombre `db` a ese mismo contenedor (en su `/etc/hosts`) con una web de prueba en el `5432`, y abren el túnel de tu kit hacia ellos con opciones extra de `up`. Para el corte, matan las sesiones de ese `sshd`. Solo se ejecutan dentro del laboratorio.

## ✅ Requisitos verificables

- tun-pg entra en server como alumno con la llave ~/.ssh/lab
- tun-pg reenvía 127.0.0.1:15432 de tu equipo a db:5432
- tun-pg sale con error si no puede abrir el puerto (ExitOnForwardFailure yes)
- tun-pg detecta una conexión muerta: ServerAliveInterval 15 y ServerAliveCountMax 3
- tun-pg no abre sesión (SessionType none) ni usa multiplexing
- bin/tunnel sale con 2 si el uso es incorrecto
- bin/tunnel up sale con 1 si el host no tiene LocalForward
- bin/tunnel up abre el túnel y los datos llegan al otro lado
- Un segundo bin/tunnel up no arranca otro autossh
- status sale con 0 con el túnel activo y con 1 tras down, que no deja procesos
- Si la conexión cae, autossh la vuelve a abrir y el túnel sigue funcionando
- bin/tunnel up sale con 1 si el puerto local está ocupado y no deja procesos
- bin/tunnel up sale con 1 en TUNNEL_TIMEOUT si no puede entrar, y no deja procesos
- Los scripts de las semanas anteriores siguen respondiendo
- Sin TODOs y shellcheck sin avisos

## Calidad

Lo que el autograding no ve se evalúa en la [rúbrica](../rubrica-evaluacion.md#-producto-30): los comentarios Qué / Para qué / Impacto de cada opción de `tun-pg`, los mensajes de `bin/tunnel`, el README del kit y el historial de git sin llaves ni contraseñas.

## Entrega

- [ ] `./scripts/verificar-semana.sh 08` con las 15 comprobaciones en verde
- [ ] `starter/README.md` sin TODOs
- [ ] `~/ssh-infra-kit` con un commit nuevo para esta semana y ninguna llave ni contraseña en `git log --stat`

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 07 — Túneles que vuelven solos](../2-practicas/lab-07-tuneles-persistentes/README.md) | [Rúbrica de evaluación](../rubrica-evaluacion.md) → |

[↑ Semana 08](../README.md)
