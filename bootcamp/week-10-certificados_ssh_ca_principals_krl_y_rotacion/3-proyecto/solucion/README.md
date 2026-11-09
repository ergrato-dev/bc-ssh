# ssh-infra-kit

Kit personal de acceso SSH, construido durante el bootcamp bc-ssh.

## Requisitos

- OpenSSH 9.6 o superior (`ssh -V`)
- bash, `nc` (netcat-openbsd), `getent`, `ssh-keyscan`, `ssh-keygen` y `ssh-copy-id`
- `git`, para que `ca/ca-init` compruebe que la CA no queda dentro de un repositorio
- `rsync` 3.x en tu equipo y en cada servidor (`rsync --version`)
- `autossh` para `bin/tunnel` (`sudo apt install autossh`, `brew install autossh`); `psql` para probar el túnel a PostgreSQL
- En el servidor de un túnel o de un salto: `AllowTcpForwarding` en `yes` o `local` (el valor por defecto)
- En cada servidor que endurezcas: OpenSSH 9.6 o superior, `sudo` y un `sshd_config` que incluya `/etc/ssh/sshd_config.d/*.conf` (Ubuntu 22.04+ y Debian 12+ ya lo traen)

## Contenido

| Archivo | Qué hace | Ejemplo |
|---|---|---|
| `config` | Valores por defecto para todos los hosts: `ConnectTimeout 5`, `StrictHostKeyChecking yes`, `HashKnownHosts yes`, `IdentitiesOnly yes`, `AddKeysToAgent 1h`, `ForwardAgent no` y multiplexing (`ControlMaster auto`, `ControlPath ~/.ssh/cm/%C`, `ControlPersist 10m`). Incluye `conf.d/*.conf` a través de `~/.ssh/kit` | `ssh -F config lab-server` |
| `conf.d/00-perfiles.conf` | Perfil `sinmux`: una conexión sin master, que vuelve a autenticarse | `ssh -F config -P sinmux lab-server` |
| `conf.d/10-lab.conf` | Alias `lab-server` y `lab-bastion` (usuario `alumno`, llave `~/.ssh/lab`) | `ssh -G -F config lab-bastion` |
| `bin/kit-link` | Enlaza `~/.ssh/kit` a la carpeta del kit (el `Include` de `config` se busca desde `~/.ssh`) y deja `~/.ssh/cm` en 700. No toca un `~/.ssh/kit` que no sea un enlace. Sale con 0 si queda listo, 1 si `~/.ssh/kit` es otra cosa, 2 por uso incorrecto | `bin/kit-link` |
| `bin/mux` | `list`: los masters de `~/.ssh/cm`, activos o huérfanos. `stop`: los cierra y borra los huérfanos (`MUX_DIR` cambia la carpeta). Sale con 0, o 2 por uso incorrecto | `bin/mux stop` |
| `conf.d/20-tuneles.conf` | Un host por túnel. `tun-pg`: `127.0.0.1:15432` de tu equipo llega a `db:5432` a través de `server`, sin sesión (`SessionType none`), sin multiplexing, con `ExitOnForwardFailure yes` y `ServerAliveInterval 15` × 3 | `ssh -G -F config tun-pg \| grep ^localforward` |
| `bin/tunnel` | `up NOMBRE`: abre el túnel con `autossh`, que lo relanza cada vez que cae, y espera a que el puerto escuche (`TUNNEL_TIMEOUT`, 10 s); si ya está activo, no abre otro. `status NOMBRE`: activo si el proceso vive y el puerto escucha. `down NOMBRE`: lo cierra. Guarda los PID en `TUNNEL_DIR` (`~/.ssh/tun`). Sale con 0 si queda activo, 1 si no abre o no está activo, 2 por uso incorrecto | `bin/tunnel up tun-pg` |
| `conf.d/30-bastion.conf` | La red privada: `lab-salto` (usuario `salto` en `bastion`, sin shell) y `lab-interno`, que entra en `interno` con `ProxyJump lab-salto` | `ssh -F config lab-interno` |
| `bin/backup` | Copia `ORIGEN` (local o `host:ruta`) en `DESTINO/AAAA-MM-DDTHHMMSS`, con `latest` apuntando a la última. Lo que no cambió son enlaces duros a la copia anterior (`--link-dest`); una copia cortada no se publica. Guarda las `BACKUP_KEEP` más recientes (7). Sale con 0 si la copia queda hecha, 1 si `rsync` falla, 2 por uso incorrecto | `bin/backup lab-server:datos ~/backups/server` |
| `bin/mirror` | Deja `DESTINO` igual que la carpeta local `ORIGEN`, con `--delete`. Sin `-y` solo enseña los cambios. Rechaza el home y la raíz como destino. Sale con 0, 1 si `rsync` falla, 2 por uso incorrecto o destino peligroso | `bin/mirror -y web/ lab-server:web` |
| `bin/sshd-deploy` | Aplica `server/sshd_config.d` en `HOST`: lo valida con `sshd -t`, recarga y prueba con una conexión nueva sin master (`ControlPath=none`). Si no entra, el servidor vuelve solo a la configuración anterior en `DEPLOY_TIMEOUT` segundos (60). Necesita `sudo` en el servidor. Sale con 0 si queda aplicada y confirmada, 1 si no se aplicó o no se pudo entrar después, 2 por uso incorrecto | `bin/sshd-deploy lab-server` |
| `server/sshd_config.d/` | Configuración de `sshd`: `10-acceso.conf` (solo llaves, sin root, `AllowGroups ssh-users sftp-only`, límites), `20-sesion.conf` (sin X11 ni agente, `ClientAlive`, `LogLevel VERBOSE`) `30-sftp.conf` (`Match Group sftp-only`: chroot en `/srv/sftp/USUARIO`, solo `internal-sftp`, sin reenvíos) `40-salto.conf` (`Match Group saltadores`: sin sesión ni terminal, solo `-L`/`-W` a `PermitOpen interno:22`, `LogLevel DEBUG1`) y `50-ca.conf` (`TrustedUserCAKeys`, `AuthorizedPrincipalsFile /etc/ssh/principals/%u`, `RevokedKeys` y `HostCertificate`) | `sudo sshd -T -C user=proveedor` |
| `server/sshd-apply` | La mitad de `bin/sshd-deploy` que corre en el servidor como root: guarda la carpeta actual, instala la nueva, valida, recarga y programa la vuelta atrás | `sudo sh sshd-apply CARPETA 60` |
| `bin/lab-check` | Comprueba DNS, puerto TCP y banner SSH de cada host. Sale con 0 si todos responden, 1 si falla alguno, 2 si no recibe hosts | `bin/lab-check server bastion` |
| `bin/key-new` | Crea un par Ed25519 (o Ed25519-SK con `KEY_TYPE=ed25519-sk` y una llave FIDO2 conectada) con 100 rondas de bcrypt, comentario `usuario@equipo-fecha` y permisos 600/700. No sobrescribe. Sale con 0 si la crea, 1 si ya existe o `ssh-keygen` falla, 2 por uso incorrecto o tipo no admitido | `bin/key-new lab` |
| `bin/agent-up` | Reutiliza el `ssh-agent` de `~/.ssh/agent.sock` o arranca uno con caducidad de 1 h por llave (`AGENT_SOCK`, `AGENT_LIFETIME`). Escribe la línea `export` para `eval`. Sale con 0 si el agente está listo, 1 si no arranca, 2 por uso incorrecto | `eval "$(bin/agent-up)"` |
| `bin/ak-line` | Escribe la línea de `authorized_keys` de una llave pública, empezando por `restrict`; `-t` pty, `-f` origen, `-c` comando forzado, `-e` caducidad. Sale con 1 si no es una llave pública (o es privada), 2 por uso incorrecto | `bin/ak-line -c uptime ~/.ssh/lab.pub` |
| `bin/kh-add` | Añade a `known_hosts` la host key de un servidor solo si su huella coincide con la esperada. Con `-J SALTO`, la lee a través de un bastion (`SSH_CMD` cambia el `ssh`, `ssh -F config` por defecto). Sale con 0 si la añade o ya estaba, 1 si la huella no coincide o hay otra llave, 2 por uso incorrecto, 3 si no lee la llave | `bin/kh-add -J lab-salto interno SHA256:kzu1...` |
| `ca/ca-init` | Crea en `CA_DIR` (`~/.ssh-ca`) la CA de usuarios y la de hosts (Ed25519, frase con 100 rondas), el contador `serial`, `emitidos/`, `emitidos.log` y una KRL vacía. No pisa una CA existente ni la crea dentro de un repositorio git. `CA_FRASE=` la deja sin frase (**solo pruebas y laboratorio**). Sale con 0 si la crea, 1 si ya existe, está en git o `ssh-keygen` falla, 2 por uso incorrecto | `ca/ca-init` |
| `ca/ca-sign` | Firma `LLAVE.pub` con el siguiente número de serie: de usuario (8 h) o de host con `-h` (52 semanas), siempre con 5 min de margen; `-V` y `-O` pasan a `ssh-keygen`. Si la llave privada de la CA no está en la carpeta, firma con la del agente (`-U`). Guarda una copia en `emitidos/SERIE-cert.pub` y una línea en `emitidos.log`. Sale con 0 si firma, 1 si falta la llave o la CA o `ssh-keygen` falla, 2 por uso incorrecto | `ca/ca-sign ~/.ssh/lab.pub alumno@client admins` |
| `ca/ca-revoke` | Añade a `revoked.krl` certificados por número de serie (`emitidos/SERIE-cert.pub`), certificados o llaves públicas (la llave y todos sus certificados). Trabaja sobre una copia y solo la sustituye si `ssh-keygen -Q` confirma que todo quedó revocado. Sale con 0, 1 si falta un archivo o la KRL o `ssh-keygen` falla, 2 por uso incorrecto | `ca/ca-revoke 12` |

## Bitácora

| Semana | Cambio |
|---|---|
| 01 | `config` mínimo y `bin/lab-check` |
| 02 | `StrictHostKeyChecking yes` y `HashKnownHosts yes` en `config`; `bin/kh-add` |
| 03 | `IdentityFile ~/.ssh/lab` e `IdentitiesOnly yes` en `config`; `bin/key-new` y `bin/ak-line` |
| 04 | `AddKeysToAgent 1h` y `ForwardAgent no` en `config`; `bin/agent-up`; `KEY_TYPE=ed25519-sk` en `bin/key-new` |
| 05 | Hosts en `conf.d/` con `Include`; multiplexing en `config`; perfil `sinmux`; `bin/kit-link` y `bin/mux` |
| 06 | `bin/backup` (copias con `--link-dest` y retención) y `bin/mirror` (espejo con vista previa) |
| 07 | `server/sshd_config.d/` endurecido (`10-acceso`, `20-sesion`, `30-sftp`), `server/sshd-apply` y `bin/sshd-deploy` con vuelta atrás automática |
| 08 | `conf.d/20-tuneles.conf` (`tun-pg`, PostgreSQL de `db` en `127.0.0.1:15432`) y `bin/tunnel` (túneles persistentes con `autossh`) |
| 09 | `conf.d/30-bastion.conf` (`lab-salto` y `lab-interno` con `ProxyJump`), `kh-add -J` y `server/sshd_config.d/40-salto.conf` (cuentas que solo saltan) |
| 10 | `ca/ca-init`, `ca/ca-sign` y `ca/ca-revoke` (CA de usuarios y de hosts, números de serie, registro y KRL) y `server/sshd_config.d/50-ca.conf` |

## Instalar el kit en un equipo

1. Clona o copia el kit donde quieras, por ejemplo `~/ssh-infra-kit`.
2. `bin/kit-link`: crea `~/.ssh/kit` (el `Include` de `config` lo necesita) y `~/.ssh/cm`.
3. `ssh -G -F config lab-server | grep '^hostname '` debe decir `hostname server`. Si dice `hostname lab-server`, el `Include` no encontró nada: repite el paso 2.
4. Opcional: para no escribir `-F config`, pon en `~/.ssh/config` la línea `Include kit/config`.

Un grupo nuevo de hosts es un archivo nuevo en `conf.d/` (`20-trabajo.conf`). Los valores por defecto siguen en `config`, que se lee después.

## Añadir un servidor nuevo

Con `StrictHostKeyChecking yes`, `ssh` no pregunta: un host que no está en `known_hosts` se rechaza. Para añadirlo:

1. Pide la huella al administrador del servidor, o léela tú por un canal que no sea SSH (consola, panel del proveedor): `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`.
2. `bin/kh-add HOST SHA256:...`
3. `ssh -F config HOST`

## Entrar con llave en un servidor nuevo

1. `bin/key-new lab` y elige una frase de paso.
2. Instala la pública con la contraseña, una sola vez: `ssh-copy-id -F config -i ~/.ssh/lab.pub HOST`.
3. `ssh -F config HOST`: pide la frase de la llave, no la contraseña del servidor.

Para una llave de uso limitado (un backup, un script), escribe su línea con `bin/ak-line` y añádela a mano al `~/.ssh/authorized_keys` del servidor en lugar de usar `ssh-copy-id`.

## Escribir la frase una vez por sesión

1. Al abrir la terminal: `eval "$(bin/agent-up)"`. La segunda terminal reutiliza el mismo agente.
2. `ssh -F config HOST`: la primera conexión pide la frase y deja la llave en el agente (`AddKeysToAgent 1h`); las siguientes no la piden.
3. `ssh-add -l` lista lo que tiene el agente; `ssh-add -D` lo vacía al terminar.

Para saltar de un servidor a otro, no actives `ForwardAgent`: carga la llave con `ssh-add -h ORIGEN -h "ORIGEN>DESTINO"`, que solo vale para ese camino.

## Copias de seguridad

1. `bin/backup lab-server:datos ~/backups/server`: la primera copia es completa; las siguientes solo ocupan lo que cambió.
2. `ls ~/backups/server` muestra una carpeta por copia y `latest`. Cada carpeta es una copia completa: puedes abrirla, comparar con `diff -r` o borrarla sin romper las demás.
3. Para restaurar, copia en sentido contrario desde la copia que quieras, primero en seco:
   ```bash
   rsync -a -n -i ~/backups/server/latest/ lab-server:datos/
   rsync -a ~/backups/server/latest/ lab-server:datos/
   ```
4. Una copia que no has restaurado nunca no es una copia: prueba la restauración en una carpeta aparte de vez en cuando.

`bin/backup` **tira** de los datos desde el equipo de copias: el servidor no tiene ninguna llave para entrar en tus copias, y si alguien lo toma, no puede borrarlas.

## Una llave solo para copias

Para un `bin/backup` desatendido (cron), usa una llave propia que solo pueda leer la carpeta de datos, con `rrsync` en el servidor:

1. `bin/key-new backup` (sin frase solo si el equipo de copias está protegido; mejor con frase y `bin/agent-up`).
2. La línea de `authorized_keys`, en el servidor: `bin/ak-line -c 'rrsync -ro /home/alumno/datos' ~/.ssh/backup.pub`.
3. Un alias con esa llave en `conf.d/` y `bin/backup ALIAS: ~/backups/server`: con `rrsync`, la ruta remota es relativa a la carpeta permitida.

## Publicar una carpeta

1. `bin/mirror web/ lab-server:web`: lee la lista; `*deleting` es lo que se borrará en el servidor.
2. Si es lo que quieres: `bin/mirror -y web/ lab-server:web`.

## Endurecer un servidor

Antes del primer despliegue, en el servidor:

1. Tu llave entra: `ssh -F config -P sinmux HOST true`. Con el kit, la contraseña deja de valer.
2. Los grupos existen y tú estás en `ssh-users`; si no, `AllowGroups` te deja fuera:
   ```bash
   ssh -F config HOST 'sudo groupadd -f ssh-users; sudo groupadd -f sftp-only; sudo usermod -aG ssh-users $USER'
   ```
3. Mira qué hay en `/etc/ssh/sshd_config.d/`: `sshd-deploy` sustituye la carpeta entera. Lo que necesites conservar, cópialo antes a `server/sshd_config.d/`.

Después, `bin/sshd-deploy HOST`. Con `0`, ya está. Con `1`:

- **`no se aplicó nada`**: el error de `sshd -t` va justo encima. El servidor no cambió.
- **`no se pudo entrar con la configuración nueva`**: no hagas nada; en `DEPLOY_TIMEOUT` segundos el servidor vuelve a la anterior. Mira por qué en el log del servidor (`journalctl -u ssh` o `docker compose logs server`).
- Si aun así no entras: una sesión abierta antes del cambio, o la consola del proveedor (`docker compose exec server` en el laboratorio). La configuración anterior está en `/etc/ssh/sshd_config.d.anterior`.

La confirmación es un archivo dentro de la carpeta que `mktemp -d` crea para cada despliegue, y no un nombre fijo en `/tmp`: cualquier usuario del servidor puede crear `/tmp/confirmado` y cancelar así la vuelta atrás de un cambio que te deja fuera. La carpeta de `mktemp -d` solo la puede escribir tu usuario.

Una cuenta que solo sube archivos, en el servidor:

```bash
sudo useradd -m -s /usr/sbin/nologin -G sftp-only proveedor
# su llave pública en /home/proveedor/.ssh/authorized_keys (de proveedor, 600)
sudo mkdir -p /srv/sftp/proveedor/subidas; sudo chown proveedor: /srv/sftp/proveedor/subidas
```

`/srv/sftp/proveedor` tiene que ser de root y sin escritura para nadie más, o `sshd` corta: `bad ownership or modes for chroot directory`.

## Túneles

1. `bin/tunnel up tun-pg`: abre `127.0.0.1:15432` en tu equipo.
2. `psql -h 127.0.0.1 -p 15432 -U alumno tienda`: hablas con PostgreSQL de `db` como si estuviera en tu equipo. En el laboratorio, la contraseña es `alumno` (**solo del laboratorio**); fuera, guárdala en `~/.pgpass` (600), nunca en el kit.
3. `bin/tunnel status tun-pg` para saber si sigue; `bin/tunnel down tun-pg` al terminar.

Si `bin/tunnel up` sale con 1:

- **`ya está ocupado por otro programa`**: algo escucha ya en `15432` (`ss -ltnp | grep 15432` dice qué). Ciérralo o cambia el puerto en `conf.d/20-tuneles.conf`.
- **`no abrió ... en 10 s`**: `ssh -F config -v tun-pg` enseña por qué: llave rechazada, host key desconocida o `administratively prohibited` (el servidor no permite túneles: `AllowTcpForwarding`).

Un túnel nuevo es un bloque `Host tun-NOMBRE` en `conf.d/20-tuneles.conf`, copiando las opciones de `tun-pg` y cambiando `HostName` y `LocalForward`. Escucha siempre en `127.0.0.1`: un `LocalForward` sin dirección, con `GatewayPorts yes` en tu equipo, deja la base de datos abierta a toda tu red.

El tramo de tu equipo a `server` va cifrado; el de `server` a `db`, no: el túnel protege el camino por la red pública, no la red interna.

## Red privada

`interno` no está en ninguna red de tu equipo: solo `bastion` llega a él. El kit entra saltando, sin copiar llaves al bastion ni reenviarle el agente.

1. En `bastion`, una cuenta por persona que solo salta (`salto` es la tuya; la creas con `lab-bastion`, que sí tiene shell y `sudo`):
   ```bash
   sudo groupadd -f saltadores
   sudo useradd -m -s /usr/sbin/nologin -G saltadores salto
   ```
   y tu llave pública en `/home/salto/.ssh/authorized_keys` (de `salto`, 600). Después, `bin/sshd-deploy lab-bastion` aplica `40-salto.conf`.
2. La host key de `interno`, verificada como cualquier otra (pide la huella por un canal que no sea SSH): `bin/kh-add -J lab-salto interno SHA256:...`. El bastion ya tiene que estar en `known_hosts`.
3. `ssh -F config lab-interno`. `scp`, `sftp` y `rsync` con `-F config lab-interno:...` saltan igual.

Un host interno nuevo es un bloque `Host` con `ProxyJump lab-salto` en `conf.d/30-bastion.conf` **y** su `HOST:22` en el `PermitOpen` de `40-salto.conf`; si falta lo segundo, `ssh` dice `channel 0: open failed: administratively prohibited`. Escribe el destino igual en los dos sitios: el bastion compara el texto, no la IP.

Para cortar el acceso de alguien a toda la red privada, quita su llave del bastion: es un solo sitio, aunque su llave siga en cada host interno. Un master abierto sigue vivo: `bin/mux stop` en su equipo, o `sudo pkill -u CUENTA` en el bastion (por eso una cuenta por persona: los logs y los cortes son de alguien).

## Autoridad de certificados

La CA vive en `CA_DIR` (`~/.ssh-ca`), **fuera del kit y de cualquier repositorio git**: `user_ca` entra como cualquiera en todos tus servidores. Ponle frase (`ca/ca-init` sin `CA_FRASE`) y, si firmas a menudo, cárgala en el agente con `ssh-add -t 15m` y guarda el archivo fuera del disco: `ca/ca-sign` firma con el agente si no lo encuentra. Nunca reenvíes ese agente.

**Preparar un servidor.** En este orden: si `revoked.krl` falta, `sshd` rechaza todas las llaves y `bin/sshd-deploy` deshace el cambio.

1. Firma su host key: `scp HOST:/etc/ssh/ssh_host_ed25519_key.pub` (por una conexión verificada) y `ca/ca-sign -h HOST.pub id-del-host NOMBRE[,NOMBRE...]`.
2. Instala con `sudo install -m 644` en `/etc/ssh/`: `user_ca.pub`, `revoked.krl` y el certificado como `ssh_host_ed25519_key-cert.pub`; y un archivo por cuenta en `/etc/ssh/principals/` (de root) con los roles que acepta.
3. `bin/sshd-deploy HOST`.

En cada cliente, una línea en `known_hosts`: `@cert-authority PATRONES CONTENIDO_DE_host_ca.pub`.

**Firmar a una persona.** Ella te manda su llave **pública**; tú, `ca/ca-sign SU.pub persona@equipo ROL`, y le devuelves `SU-cert.pub`, que deja junto a su llave. Ocho horas por defecto: mañana, otro.

**Revocar.** `ca/ca-revoke SERIE` (el número está en `emitidos.log`, y en el log del servidor: `serial N`), o la llave pública si se filtró. Después, `install -m 644` de `revoked.krl` en **cada** servidor; no hace falta recargar `sshd`. Las conexiones ya abiertas siguen: `sudo pkill -u CUENTA`.

**Rotar la CA.** Crea la nueva en otra carpeta (`ca/ca-init ~/.ssh-ca-2027`). Pon las dos en `user_ca.pub` de cada servidor (una por línea), firma con la nueva (`CA_DIR=~/.ssh-ca-2027 ca/ca-sign ...`) y, cuando caduque el último certificado de la vieja, deja solo la nueva. Para hosts, al revés: primero la nueva `@cert-authority` en los clientes, después los certificados nuevos en los servidores, y la vieja como `@revoked`. Si la vieja se filtró, revócala también en la KRL que distribuyes (`CA_DIR=~/.ssh-ca-2027 ca/ca-revoke ~/.ssh-ca/user_ca.pub`).

## Cuando cambias llaves

Un master abierto ya está autenticado: sigue entrando aunque quites la llave de `authorized_keys`.

1. Después de rotar o revocar una llave: `bin/mux stop`.
2. Para comprobar que una llave funciona de verdad: `ssh -F config -P sinmux HOST`.
