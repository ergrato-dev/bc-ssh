# ssh-infra-kit

Kit personal de acceso SSH, construido durante el bootcamp bc-ssh.

## Requisitos

- OpenSSH 9.6 o superior (`ssh -V`)
- bash, `nc` (netcat-openbsd), `getent`, `ssh-keyscan`, `ssh-keygen` y `ssh-copy-id`

## Contenido

| Archivo | Qué hace | Ejemplo |
|---|---|---|
| `config` | Alias `lab-server` y `lab-bastion` (usuario `alumno`, llave `~/.ssh/lab`); `ConnectTimeout 5`, `StrictHostKeyChecking yes`, `HashKnownHosts yes` e `IdentitiesOnly yes` para todos los hosts | `ssh -F config lab-server` |
| `bin/lab-check` | Comprueba DNS, puerto TCP y banner SSH de cada host. Sale con 0 si todos responden, 1 si falla alguno, 2 si no recibe hosts | `bin/lab-check server bastion` |
| `bin/key-new` | Crea un par Ed25519 con 100 rondas de bcrypt, comentario `usuario@equipo-fecha` y permisos 600/700. No sobrescribe. Sale con 0 si la crea, 1 si ya existe, 2 por uso incorrecto | `bin/key-new lab` |
| `bin/ak-line` | Escribe la línea de `authorized_keys` de una llave pública, empezando por `restrict`; `-t` pty, `-f` origen, `-c` comando forzado, `-e` caducidad. Sale con 1 si no es una llave pública (o es privada), 2 por uso incorrecto | `bin/ak-line -c uptime ~/.ssh/lab.pub` |
| `bin/kh-add` | Añade a `known_hosts` la host key de un servidor solo si su huella coincide con la esperada. Sale con 0 si la añade o ya estaba, 1 si la huella no coincide o hay otra llave, 2 por uso incorrecto, 3 si no lee la llave | `bin/kh-add server SHA256:GiOO...` |

## Bitácora

| Semana | Cambio |
|---|---|
| 01 | `config` mínimo y `bin/lab-check` |
| 02 | `StrictHostKeyChecking yes` y `HashKnownHosts yes` en `config`; `bin/kh-add` |
| 03 | `IdentityFile ~/.ssh/lab` e `IdentitiesOnly yes` en `config`; `bin/key-new` y `bin/ak-line` |

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
