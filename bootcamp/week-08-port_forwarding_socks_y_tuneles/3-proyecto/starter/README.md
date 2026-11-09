# ssh-infra-kit

Kit personal de acceso SSH, construido durante el bootcamp bc-ssh.

## Requisitos

- OpenSSH 9.6 o superior (`ssh -V`)
- bash, `nc` (netcat-openbsd), `getent`, `ssh-keyscan`, `ssh-keygen` y `ssh-copy-id`
- `rsync` 3.x en tu equipo y en cada servidor (`rsync --version`)
- `autossh` para `bin/tunnel` (`sudo apt install autossh`, `brew install autossh`); `psql` para probar el túnel a PostgreSQL
- En el servidor de un túnel: `AllowTcpForwarding` en `yes` o `local` (el valor por defecto)
- En cada servidor que endurezcas: OpenSSH 9.6 o superior, `sudo` y un `sshd_config` que incluya `/etc/ssh/sshd_config.d/*.conf` (Ubuntu 22.04+ y Debian 12+ ya lo traen)

## Contenido

| Archivo | Qué hace | Ejemplo |
|---|---|---|
| `config` | Valores por defecto para todos los hosts: `ConnectTimeout 5`, `StrictHostKeyChecking yes`, `HashKnownHosts yes`, `IdentitiesOnly yes`, `AddKeysToAgent 1h`, `ForwardAgent no` y multiplexing (`ControlMaster auto`, `ControlPath ~/.ssh/cm/%C`, `ControlPersist 10m`). Incluye `conf.d/*.conf` a través de `~/.ssh/kit` | `ssh -F config lab-server` |
| `conf.d/00-perfiles.conf` | Perfil `sinmux`: una conexión sin master, que vuelve a autenticarse | `ssh -F config -P sinmux lab-server` |
| `conf.d/10-lab.conf` | Alias `lab-server` y `lab-bastion` (usuario `alumno`, llave `~/.ssh/lab`) | `ssh -G -F config lab-bastion` |
| `bin/kit-link` | Enlaza `~/.ssh/kit` a la carpeta del kit (el `Include` de `config` se busca desde `~/.ssh`) y deja `~/.ssh/cm` en 700. No toca un `~/.ssh/kit` que no sea un enlace. Sale con 0 si queda listo, 1 si `~/.ssh/kit` es otra cosa, 2 por uso incorrecto | `bin/kit-link` |
| `bin/mux` | `list`: los masters de `~/.ssh/cm`, activos o huérfanos. `stop`: los cierra y borra los huérfanos (`MUX_DIR` cambia la carpeta). Sale con 0, o 2 por uso incorrecto | `bin/mux stop` |
| `conf.d/20-tuneles.conf` | TODO: qué túnel define `tun-pg` y con qué opciones | TODO |
| `bin/tunnel` | TODO: qué hace cada orden, variables y códigos de salida | TODO |
| `bin/backup` | Copia `ORIGEN` (local o `host:ruta`) en `DESTINO/AAAA-MM-DDTHHMMSS`, con `latest` apuntando a la última. Lo que no cambió son enlaces duros a la copia anterior (`--link-dest`); una copia cortada no se publica. Guarda las `BACKUP_KEEP` más recientes (7). Sale con 0 si la copia queda hecha, 1 si `rsync` falla, 2 por uso incorrecto | `bin/backup lab-server:datos ~/backups/server` |
| `bin/mirror` | Deja `DESTINO` igual que la carpeta local `ORIGEN`, con `--delete`. Sin `-y` solo enseña los cambios. Rechaza el home y la raíz como destino. Sale con 0, 1 si `rsync` falla, 2 por uso incorrecto o destino peligroso | `bin/mirror -y web/ lab-server:web` |
| `bin/sshd-deploy` | Aplica `server/sshd_config.d` en `HOST`: lo valida con `sshd -t`, recarga y prueba con una conexión nueva sin master (`ControlPath=none`). Si no entra, el servidor vuelve solo a la configuración anterior en `DEPLOY_TIMEOUT` segundos (60). Necesita `sudo` en el servidor. Sale con 0 si queda aplicada y confirmada, 1 si no se aplicó o no se pudo entrar después, 2 por uso incorrecto | `bin/sshd-deploy lab-server` |
| `server/sshd_config.d/` | Configuración de `sshd`: `10-acceso.conf` (solo llaves, sin root, `AllowGroups ssh-users sftp-only`, límites), `20-sesion.conf` (sin X11 ni agente, `ClientAlive`, `LogLevel VERBOSE`) y `30-sftp.conf` (`Match Group sftp-only`: chroot en `/srv/sftp/USUARIO`, solo `internal-sftp`, sin reenvíos) | `sudo sshd -T -C user=proveedor` |
| `server/sshd-apply` | La mitad de `bin/sshd-deploy` que corre en el servidor como root: guarda la carpeta actual, instala la nueva, valida, recarga y programa la vuelta atrás | `sudo sh sshd-apply CARPETA 60` |
| `bin/lab-check` | Comprueba DNS, puerto TCP y banner SSH de cada host. Sale con 0 si todos responden, 1 si falla alguno, 2 si no recibe hosts | `bin/lab-check server bastion` |
| `bin/key-new` | Crea un par Ed25519 (o Ed25519-SK con `KEY_TYPE=ed25519-sk` y una llave FIDO2 conectada) con 100 rondas de bcrypt, comentario `usuario@equipo-fecha` y permisos 600/700. No sobrescribe. Sale con 0 si la crea, 1 si ya existe o `ssh-keygen` falla, 2 por uso incorrecto o tipo no admitido | `bin/key-new lab` |
| `bin/agent-up` | Reutiliza el `ssh-agent` de `~/.ssh/agent.sock` o arranca uno con caducidad de 1 h por llave (`AGENT_SOCK`, `AGENT_LIFETIME`). Escribe la línea `export` para `eval`. Sale con 0 si el agente está listo, 1 si no arranca, 2 por uso incorrecto | `eval "$(bin/agent-up)"` |
| `bin/ak-line` | Escribe la línea de `authorized_keys` de una llave pública, empezando por `restrict`; `-t` pty, `-f` origen, `-c` comando forzado, `-e` caducidad. Sale con 1 si no es una llave pública (o es privada), 2 por uso incorrecto | `bin/ak-line -c uptime ~/.ssh/lab.pub` |
| `bin/kh-add` | Añade a `known_hosts` la host key de un servidor solo si su huella coincide con la esperada. Sale con 0 si la añade o ya estaba, 1 si la huella no coincide o hay otra llave, 2 por uso incorrecto, 3 si no lee la llave | `bin/kh-add server SHA256:GiOO...` |

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
| 08 | TODO |

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

TODO: cómo abrir el túnel a PostgreSQL y conectarte con `psql`, qué hacer si `bin/tunnel up` sale con 1, cómo añadir un túnel nuevo y por qué escucha solo en `127.0.0.1`.

## Cuando cambias llaves

Un master abierto ya está autenticado: sigue entrando aunque quites la llave de `authorized_keys`.

1. Después de rotar o revocar una llave: `bin/mux stop`.
2. Para comprobar que una llave funciona de verdad: `ssh -F config -P sinmux HOST`.
