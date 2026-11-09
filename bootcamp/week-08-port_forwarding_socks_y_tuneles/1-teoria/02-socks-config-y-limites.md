# SOCKS, túneles en `ssh_config` y lo que el servidor permite

⏱ Lectura: ~30 min

`-L` sirve para un destino fijo. Cuando no sabes de antemano a qué hosts vas a ir, o son muchos, `ssh` puede hacer de **proxy SOCKS**. Después, los túneles pasan de la línea de órdenes a `ssh_config`, y al final cambias de lado: qué deja hacer `sshd`.

## `-D`: un proxy SOCKS que sale por el servidor

```bash
ssh -D [DIRECCIÓN_LOCAL:]PUERTO server
```

`ssh` abre `PUERTO` en tu equipo y habla el protocolo **SOCKS** (versiones 4 y 5). Un programa que sabe usar SOCKS le dice, en cada conexión, a dónde quiere ir; `ssh` abre un canal `direct-tcpip` hacia ese destino y `server` conecta. Es un `-L` cuyo destino elige el programa en cada conexión.

**Qué:** un proxy para cualquier destino que alcance `server`. **Para qué:** navegar por las webs internas de una red, o salir a Internet desde `server` (otra IP, otro país) en una red que no es de fiar. **Impacto:** solo funciona con programas que hablen SOCKS: navegadores, `curl`, `git` (`http.proxy`), `nc -X 5`. `psql` no sabe: para una base de datos, `-L`.

### Quién resuelve los nombres: `socks5` y `socks5h`

SOCKS5 deja que el cliente mande al proxy **la IP** (resuelta en tu equipo) o **el nombre** (resuelto en el servidor). En `curl`:

| Opción | Resuelve el nombre | `db` (solo existe en la red de `server`) |
|---|---|---|
| `--socks5 localhost:1080` | Tu equipo | `curl: (97) Could not resolve host: db` |
| `--socks5-hostname localhost:1080` | `server` | Llega |

Con la variable `ALL_PROXY` la diferencia es la `h`: `socks5://` resuelve en tu equipo, `socks5h://` en el servidor. Usa siempre la `h`: un nombre resuelto en tu equipo le dice a tu DNS (el de la wifi del café) a qué hosts vas, aunque el tráfico vaya por el túnel. Los navegadores tienen la casilla equivalente: *Proxy DNS when using SOCKS v5*.

## Túneles en `ssh_config`

Cada opción de la línea de órdenes tiene su palabra en `ssh_config` (y en el `conf.d/` del kit, semana 05):

| Línea de órdenes | `ssh_config` | Notas |
|---|---|---|
| `-L 127.0.0.1:15432:db:5432` | `LocalForward 127.0.0.1:15432 db:5432` | Espacio, no `:`, entre el origen y el destino |
| `-R 9000:localhost:9000` | `RemoteForward 9000 localhost:9000` | |
| `-D 1080` | `DynamicForward 127.0.0.1:1080` | |
| `-N` | `SessionType none` | OpenSSH 8.7+ |
| `-f` | `ForkAfterAuthentication yes` | OpenSSH 8.7+ |
| — | `ExitOnForwardFailure yes` | Sal si un reenvío no se puede abrir |
| — | `ClearAllForwardings yes` | Ignora los reenvíos de la configuración (`-o` en la línea de órdenes, para entrar con shell en un host de túnel) |

Un host para cada túnel, y no los reenvíos en tu alias de siempre: si `lab-server` llevara `LocalForward`, cada `ssh lab-server` intentaría abrir el puerto, y el segundo fallaría (o, con `ExitOnForwardFailure`, no entraría). El kit usa `tun-pg` para el túnel y deja `lab-server` para la shell.

Compruébalo sin conectar, como siempre: `ssh -G tun-pg | grep forward`.

### Túneles y multiplexing

Con un master abierto (semana 05), un `ssh -L ... host` nuevo **no abre conexión**: pide el reenvío al master y sale. El túnel vive en el master, no en tu proceso. Eso tiene dos caras:

- Puedes añadir y quitar túneles a una conexión abierta, sin volver a autenticarte: `ssh -O forward -L 15432:db:5432 server` y `ssh -O cancel -L 15432:db:5432 server`.
- Un túnel persistente con multiplexing es un lío: el proceso que vigilas sale enseguida, y el túnel sigue en un master con su propio `ControlPersist`. Por eso el host de túnel del kit lleva `ControlMaster no` y `ControlPath none`.

### `~C`: túneles desde una sesión abierta

Dentro de una sesión interactiva, `Enter` seguido de `~C` abre la línea de órdenes de `ssh`, donde escribes `-L 8081:localhost:8080` o `-KL 8081` (cerrar). Desde OpenSSH 9.2 viene desactivada (`EnableEscapeCommandline no`), porque cualquier programa que escriba en tu terminal podía usarla; actívala solo para una conexión: `ssh -o EnableEscapeCommandline=yes server`.

## Lo que decide el servidor

Todo lo anterior lo pide el cliente; `sshd` decide si lo concede. El lab 06 lo prueba opción a opción:

| Opción (`sshd_config`) | Por defecto | Qué controla |
|---|---|---|
| `AllowTcpForwarding` | `yes` | `yes`, `local` (solo `-L` y `-D`), `remote` (solo `-R`) o `no` |
| `PermitOpen` | `any` | A qué `host:puerto` pueden ir los `-L` y `-D`: `PermitOpen db:5432` |
| `PermitListen` | `any` | Qué puertos pueden abrir los `-R` en el servidor |
| `GatewayPorts` | `no` | Si un `-R` puede escuchar fuera de `localhost` ([teoría 01](01-reenvio-local-y-remoto.md#gatewayports-del-servidor)) |
| `AllowStreamLocalForwarding` | `yes` | Lo mismo para sockets Unix (`-L /tmp/s:/run/postgresql/.s.PGSQL.5432`) |
| `DisableForwarding` | `no` | `yes` quita todos los reenvíos de golpe (semana 07, cuentas `sftp-only`) |

Cuando el servidor rechaza un reenvío, el cliente no lo sabe hasta que lo usa:

- Un `-R` prohibido: `Error: remote port forwarding failed for listen port 9000` (o `Warning:` sin `ExitOnForwardFailure`).
- Un `-L` a un destino prohibido: el puerto local se abre, pero cada conexión se corta. Con `ssh` en primer plano ves el motivo: `channel 2: open failed: administratively prohibited: open failed`. Con `-f`, nada: el programa que usa el túnel solo ve la conexión cerrada.

### Por llave: `permitopen` en `authorized_keys`

Las mismas limitaciones se ponen a **una llave** en `authorized_keys` (semana 03), sin tocar `sshd_config`. Una llave que solo sirve para el túnel a la base de datos:

```
restrict,port-forwarding,permitopen="db:5432",command="/usr/sbin/nologin" ssh-ed25519 AAAA... tunel@client
```

- `restrict`: quita todo; `port-forwarding` devuelve solo los túneles.
- `permitopen="db:5432"`: los `-L` solo van ahí. Para limitar también los `-R`, añade `permitlisten="localhost:9000"` con el único puerto que quieras permitir.
- `command="/usr/sbin/nologin"`: si alguien pide una shell o un comando, recibe `This account is currently not available.` Con `-N` no hay sesión, así que el túnel funciona.

### Lo que no es una barrera

Quitar los túneles a un usuario **que tiene shell** no le impide nada: con una shell puede montar sus propios reenvíos con `socat` o `nc`, o copiar un binario que lo haga. `AllowTcpForwarding no` solo protege de verdad cuando además el usuario no ejecuta lo que quiere: cuentas `sftp-only` (semana 07) o llaves con `command=` como la de arriba.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — Reenvío de puertos: `-L` y `-R`](01-reenvio-local-y-remoto.md) | [Teoría — Túneles que no se caen](03-tuneles-persistentes.md) → |

[↑ Semana 08](../README.md)
