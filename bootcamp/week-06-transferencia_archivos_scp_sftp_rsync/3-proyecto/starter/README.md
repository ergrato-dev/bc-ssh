# ssh-infra-kit

Kit personal de acceso SSH, construido durante el bootcamp bc-ssh.

## Requisitos

- OpenSSH 9.6 o superior (`ssh -V`)
- bash, `nc` (netcat-openbsd), `getent`, `ssh-keyscan`, `ssh-keygen` y `ssh-copy-id`
- `rsync` 3.x en tu equipo y en cada servidor (`rsync --version`)

## Contenido

| Archivo | Qué hace | Ejemplo |
|---|---|---|
| `config` | Valores por defecto para todos los hosts: `ConnectTimeout 5`, `StrictHostKeyChecking yes`, `HashKnownHosts yes`, `IdentitiesOnly yes`, `AddKeysToAgent 1h`, `ForwardAgent no` y multiplexing (`ControlMaster auto`, `ControlPath ~/.ssh/cm/%C`, `ControlPersist 10m`). Incluye `conf.d/*.conf` a través de `~/.ssh/kit` | `ssh -F config lab-server` |
| `conf.d/00-perfiles.conf` | Perfil `sinmux`: una conexión sin master, que vuelve a autenticarse | `ssh -F config -P sinmux lab-server` |
| `conf.d/10-lab.conf` | Alias `lab-server` y `lab-bastion` (usuario `alumno`, llave `~/.ssh/lab`) | `ssh -G -F config lab-bastion` |
| `bin/kit-link` | Enlaza `~/.ssh/kit` a la carpeta del kit (el `Include` de `config` se busca desde `~/.ssh`) y deja `~/.ssh/cm` en 700. No toca un `~/.ssh/kit` que no sea un enlace. Sale con 0 si queda listo, 1 si `~/.ssh/kit` es otra cosa, 2 por uso incorrecto | `bin/kit-link` |
| `bin/mux` | `list`: los masters de `~/.ssh/cm`, activos o huérfanos. `stop`: los cierra y borra los huérfanos (`MUX_DIR` cambia la carpeta). Sale con 0, o 2 por uso incorrecto | `bin/mux stop` |
| `bin/backup` | TODO: qué hace, códigos de salida | TODO |
| `bin/mirror` | TODO: qué hace, códigos de salida | TODO |
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
| 06 | TODO |

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

TODO: cómo hacer una copia, qué hay en la carpeta de copias, cómo restaurar (primero en seco) y por qué el equipo de copias tira de los datos.

## Una llave solo para copias

TODO: llave propia, línea de `authorized_keys` con `rrsync -ro` y alias en `conf.d/`.

## Publicar una carpeta

TODO: `bin/mirror` primero sin `-y` y después con `-y`.

## Cuando cambias llaves

Un master abierto ya está autenticado: sigue entrando aunque quites la llave de `authorized_keys`.

1. Después de rotar o revocar una llave: `bin/mux stop`.
2. Para comprobar que una llave funciona de verdad: `ssh -F config -P sinmux HOST`.
