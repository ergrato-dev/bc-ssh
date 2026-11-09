# Proyecto Semana 09 — ssh-infra-kit: acceso a `interno` vía `bastion`

⏱ Duración estimada: ~3 h

## Contexto

Tu kit ya entra en `server`, copia, endurece y abre túneles. Esta semana aprende a **entrar en una red privada**: `interno` solo está en la red `privada`, y la única puerta es `bastion`. Tres piezas:

- **`conf.d/30-bastion.conf`**: `lab-salto`, una cuenta del bastion que solo sirve para saltar, y `lab-interno`, que entra en `interno` con `ProxyJump lab-salto`. Una sola orden, sin copiar llaves al bastion ni reenviarle el agente ([lab 05](../2-practicas/lab-05-agente-reenviado/README.md)).
- **`bin/kh-add -J SALTO`**: la host key de `interno`, verificada por su huella como la de cualquier otro servidor, aunque `ssh-keyscan` no llegue a él.
- **`server/sshd_config.d/40-salto.conf`**: lo que el bastion deja hacer a esa cuenta: ni shell ni terminal, solo saltar a `interno:22`, y un log que dice a dónde salta cada uno.

## Estructura del proyecto

```
starter/                    ← aquí trabajas: tu ssh-infra-kit de la semana 08 + TODOs
├── README.md               ← documentación del kit (TODOs)
├── config                  ← semana 05, terminado
├── conf.d/
│   ├── 00-perfiles.conf, 10-lab.conf, 20-tuneles.conf   ← semanas 05 y 08
│   └── 30-bastion.conf     ← TODOs 1 y 2
├── bin/
│   ├── kh-add              ← TODOs 3 y 4
│   └── lab-check … tunnel  ← semanas 01-08
└── server/sshd_config.d/
    ├── 10-acceso.conf      ← TODO 8
    ├── 20-sesion.conf, 30-sftp.conf   ← semana 07
    └── 40-salto.conf       ← TODOs 5, 6 y 7
solucion/                   ← referencia: no la abras hasta terminar
```

## Lo que debes construir

### `conf.d/30-bastion.conf`

| Host | `HostName` | `User` | `IdentityFile` | Salto |
|---|---|---|---|---|
| `lab-salto` | `bastion` | `salto` | `~/.ssh/lab` | — |
| `lab-interno` | `interno` | `alumno` | `~/.ssh/lab` | `ProxyJump lab-salto` ([lab 04](../2-practicas/lab-04-saltos-en-config/README.md)) |

### `bin/kh-add -J SALTO HOST[:PUERTO] HUELLA`

| Caso | Código |
|---|---|
| La llave leída a través de `SALTO` tiene esa huella: la añade (o ya estaba) | 0 |
| Huella distinta, u otra llave del mismo tipo ya en `known_hosts`: no escribe nada | 1 |
| `-J` sin salto, salto vacío o faltan argumentos | 2 |
| No llega a `HOST` a través de `SALTO` | 3 |

El `ssh` de `-J` es `SSH_CMD`, o `ssh -F config` del kit si no existe. Sin `-J`, `kh-add` sigue usando `ssh-keyscan`.

### `server/sshd_config.d/40-salto.conf`: `Match Group saltadores`

| Opción | Valor | Lab |
|---|---|---|
| `ForceCommand`, `PermitTTY` | `/usr/sbin/nologin`, `no` | [06](../2-practicas/lab-06-bastion-endurecido/README.md) |
| `AllowTcpForwarding`, `PermitOpen` | `local`, `interno:22` | 06 |
| `AllowAgentForwarding`, `AllowStreamLocalForwarding`, `X11Forwarding`, `PermitTunnel` | `no` | 06 |
| `LogLevel` | `DEBUG1` | [07](../2-practicas/lab-07-auditoria-y-cortes/README.md) |

Y `saltadores` en el `AllowGroups` de `10-acceso.conf`. Cada opción lleva su **Qué / Para qué / Impacto** en un comentario.

## Paso a paso

### Paso 0 — Preparar la terminal

Desde la raíz del repositorio en tu equipo:

```bash
docker compose up -d --force-recreate bastion interno
docker compose run --rm client
```

`--force-recreate` deja `bastion` e `interno` como recién instalados, con host keys nuevas. Ya dentro del contenedor, enlaza el kit, prepara `known_hosts` y una llave sin frase (**solo laboratorio**) para `lab-bastion`:

```bash
cd bootcamp/week-09-bastion_hosts_y_arquitecturas_segmentadas/3-proyecto/starter
mkdir -p -m 700 ~/.ssh ~/w
bin/kit-link
export SSHPASS=alumno
ssh-keyscan -t ed25519 bastion 2>/dev/null > ~/.ssh/known_hosts
ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/lab
sshpass -e ssh-copy-id -F config -o ControlPath=none -i ~/.ssh/lab.pub lab-bastion 2>&1 | grep 'Number of'
```

```
kit-link: /home/alumno/.ssh/kit -> /bc-ssh/bootcamp/week-09-bastion_hosts_y_arquitecturas_segmentadas/3-proyecto/starter
Number of key(s) added: 1
```

`SSHPASS=alumno` es la contraseña del laboratorio: **solo del laboratorio**. Abre además **una segunda terminal en tu equipo** (no en el contenedor) y pide la huella de `interno` por un canal que no es SSH, como en la semana 02. La necesitas en el paso 3:

```bash
docker compose exec interno ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

```
256 SHA256:UL7DsJUMENYjyk9M2qZqUlk4L7LK21q6O8Ru8fiH+f4 root@interno (ED25519)
```

La tuya será otra: cambia con cada `--force-recreate`.

### Paso 1 — Lo que hay ahora

```bash
ssh -G -F config lab-salto | grep -E '^(hostname|user) '
ssh -F config lab-interno hostname; echo "código: $?"
bin/kh-add -J lab-bastion interno SHA256:UL7DsJUMENYjyk9M2qZqUlk4L7LK21q6O8Ru8fiH+f4; echo "código: $?"
```

```
user alumno
hostname lab-salto
ssh: Could not resolve hostname interno: Name or service not known
código: 255
uso: kh-add HOST[:PUERTO] HUELLA   (HUELLA = SHA256:...)
código: 2
```

`lab-salto` está vacío: `ssh` usaría el propio nombre y tu usuario. `lab-interno` intenta ir directo, y tu equipo ni siquiera resuelve `interno`. `kh-add` no conoce `-J`.

### Paso 2 — TODOs 1 y 2: los dos hosts

En `conf.d/30-bastion.conf`, completa `lab-salto` con la tabla de arriba y añade a `lab-interno` el salto **por su alias**:

```
    ProxyJump lab-salto
```

Con el alias, el salto usa el `HostName`, `User`, `IdentityFile` y multiplexing de su propio bloque `Host`; con `ProxyJump salto@bastion`, solo lo que escribas en esa línea más `Host *`. Compruébalo sin conectar:

```bash
ssh -G -F config lab-interno | grep -E '^(hostname|user|proxyjump) '
```

```
user alumno
hostname interno
proxyjump lab-salto
```

Pon a cada bloque su comentario **Qué / Para qué / Impacto**: por qué una cuenta sin shell, y qué ve el bastion de tu conexión con `interno` ([teoría 02](../1-teoria/02-proxyjump-y-proxycommand.md#qué-ve-el-bastion)).

### Paso 3 — TODOs 3 y 4: `kh-add -J`

`ssh-keyscan` no sabe saltar. Pero una conexión SSH de verdad a través del salto recibe la host key **antes** de autenticarse, y con un `known_hosts` temporal la puedes leer sin tocar el tuyo ([lab 02](../2-practicas/lab-02-proxyjump/README.md), paso 4).

**TODO 3**, en `bin/kh-add`: si el primer argumento es `-J`, guarda el siguiente en `salto` y quita los dos con `shift 2`. Sin segundo argumento, o vacío: `uso`. Actualiza también el mensaje de `uso` y la cabecera.

**TODO 4**, en `por_salto`:

```bash
  kit="$(cd "$(dirname "$0")/.." && pwd)"
  ssh_cmd="${SSH_CMD:-ssh -F $kit/config}"
  tmp=$(mktemp)
  # shellcheck disable=SC2086
  $ssh_cmd -J "$salto" -p "$puerto" -o UserKnownHostsFile="$tmp" \
    -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=accept-new \
    -o HashKnownHosts=yes -o BatchMode=yes -o ControlPath=none \
    "$host" true </dev/null >/dev/null 2>&1 || true
  head -n 1 "$tmp"
  rm -f "$tmp"
```

- `-J "$salto"` en la línea de órdenes gana a cualquier `ProxyJump` de la configuración (el primer valor gana).
- `UserKnownHostsFile="$tmp"` + `accept-new`: la llave nueva va a ese archivo vacío, sin preguntar. `GlobalKnownHostsFile=/dev/null`: que no la encuentre en `/etc/ssh/ssh_known_hosts`.
- `BatchMode=yes`: nunca pide contraseña ni frase. Si la autenticación falla, da igual: la llave ya llegó. Si entra, ejecuta `true`.
- `ControlPath=none`: sin master, para no dejar una conexión abierta con un host que aún no has verificado.
- `$ssh_cmd` sin comillas: `ssh -F ruta` son tres palabras. `SC2086` es el aviso de `shellcheck` por eso.

El resto de `kh-add` ya compara la huella y escribe la línea. El salto **tiene que estar ya** en `known_hosts`: la confianza va de un host al siguiente. De momento salta con `lab-bastion` (`alumno`), porque `salto` aún no existe:

```bash
bin/kh-add -J lab-bastion interno SHA256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA; echo "código: $?"
bin/kh-add -J lab-bastion interno SHA256:UL7DsJUMENYjyk9M2qZqUlk4L7LK21q6O8Ru8fiH+f4; echo "código: $?"
```

```
interno: HUELLA DISTINTA, esperada SHA256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA, recibida SHA256:UL7DsJUMENYjyk9M2qZqUlk4L7LK21q6O8Ru8fiH+f4
código: 1
interno añadida SHA256:UL7DsJUMENYjyk9M2qZqUlk4L7LK21q6O8Ru8fiH+f4
código: 0
```

Con la huella mala no escribe nada: así se ve un intermediario.

### Paso 4 — La primera entrada en `interno`

Tu llave en `interno`, saltando con `alumno` (`-o ProxyJump=lab-bastion` gana al `lab-salto` de la configuración):

```bash
sshpass -e ssh-copy-id -F config -o ControlPath=none -o ProxyJump=lab-bastion -i ~/.ssh/lab.pub lab-interno 2>&1 | grep 'Number of'
ssh -F config -J lab-bastion lab-interno hostname
```

```
Number of key(s) added: 1
interno
```

`sshpass` responde a la contraseña de `interno` (**solo del laboratorio**); en `bastion` ya entras con llave. La llave privada no salió de tu equipo.

### Paso 5 — TODOs 5 a 8: la cuenta que solo salta

En `server/sshd_config.d/40-salto.conf`, dentro de `Match Group saltadores`, con la tabla de arriba:

- **TODO 5**: `ForceCommand /usr/sbin/nologin` y `PermitTTY no`. Cualquier sesión ejecuta `nologin`, que sale con 1.
- **TODO 6**: `AllowTcpForwarding local` y `PermitOpen interno:22`, y en `no` el agente, los sockets Unix, X11 y `PermitTunnel`. `ProxyJump` es un canal `direct-tcpip`, como un `-L`: con esto, el único que se abre es a `interno:22`.
- **TODO 7**: `LogLevel DEBUG1`. `VERBOSE` no dice a dónde salta nadie; `DEBUG1` sí, y solo para este grupo.

**TODO 8**, en `10-acceso.conf`: `saltadores` en `AllowGroups`, o la cuenta no entra. Compruébalo en `bastion` antes de desplegar, con la carpeta del kit:

```bash
tar -cf - server | ssh -F config lab-bastion 'd=$(mktemp -d); tar -xf - -C $d; sed "s|/etc/ssh/sshd_config.d|$d/server/sshd_config.d|" /etc/ssh/sshd_config > $d/main; sudo groupadd -f saltadores; sudo sshd -t -f $d/main && echo válida; rm -rf $d'
```

```
válida
```

### Paso 6 — Desplegar en `bastion`

En `bastion`, el grupo `ssh-users` con `alumno` dentro (lo exige `AllowGroups`, como en la semana 07) y la cuenta `salto` sin shell, con tu llave:

```bash
ssh -F config lab-bastion 'sudo groupadd -f ssh-users; sudo groupadd -f saltadores; sudo usermod -aG ssh-users alumno
sudo useradd -m -s /usr/sbin/nologin -G saltadores salto
sudo install -d -m 700 -o salto -g salto ~salto/.ssh
sudo install -m 600 -o salto -g salto ~/.ssh/authorized_keys ~salto/.ssh/
id salto'
bin/sshd-deploy lab-bastion
```

```
uid=1001(salto) gid=1003(salto) groups=1003(salto),1002(saltadores)
sshd-apply: aplicada; se deshace en 60 s si no se confirma
sshd-deploy: aplicada y confirmada en lab-bastion
```

- `-s /usr/sbin/nologin`: la cuenta no tiene shell ni aunque falle el `Match`. `-G saltadores`: entra en el `Match` de `40-salto.conf`.
- `install`: crea la carpeta y copia el archivo con dueño y permisos en un solo paso. Copia **tu** `authorized_keys` de `alumno`: en la vida real, cada persona tiene su cuenta de salto con su llave.
- `bin/sshd-deploy` prueba con una conexión nueva y deshace el cambio si te deja fuera (semana 07).

### Paso 7 — Probarlo de verdad

```bash
bin/mux stop >/dev/null
ssh -F config lab-interno hostname
ssh -F config lab-salto; echo "código: $?"
ssh -F config -J lab-salto lab-server hostname; echo "código: $?"
```

```
interno
This account is currently not available.
código: 1
Connection closed by UNKNOWN port 65535
código: 255
```

- `lab-interno` entra con una sola orden. `lab-salto` no tiene sesión.
- `server` no está en `PermitOpen`: el bastion lo rechaza. El `channel 0: open failed: administratively prohibited` no aparece porque el salto fue por el master de `lab-salto`, abierto por la orden anterior. El porqué está en el log del bastion. En tu equipo:

```bash
docker compose logs --no-log-prefix bastion | grep -E 'target|denied' | tail -3
```

```
debug1: server_request_direct_tcpip: originator 127.0.0.1 port 65535, target interno port 22
debug1: server_request_direct_tcpip: originator 127.0.0.1 port 65535, target server port 22
Received request from 172.20.0.6 port 48432 to connect to host server port 22, but the request was denied.
```

Cada salto deja su `target`, y cada rechazo su `denied` ([lab 07](../2-practicas/lab-07-auditoria-y-cortes/README.md)).

### Paso 8 — Masters y archivos a través del salto

```bash
bin/mux list | cut -c1-30
echo hola > ~/w/nota.txt
scp -F config ~/w/nota.txt lab-interno:
rsync -a -e 'ssh -F config' ~/w/nota.txt lab-interno:copia.txt
ssh -F config lab-interno ls
```

```
activo    pid=195   /home/alum
activo    pid=198   /home/alum
copia.txt
nota.txt
```

Dos masters: el de `lab-salto` (el `ssh -W` del salto también es una conexión multiplexada) y el de `lab-interno`. `scp` y `rsync` leen el mismo `config`: saltan sin escribir nada más.

### Paso 9 — Calidad, README y git

1. `shellcheck bin/*` sin avisos, y ningún `TODO` en `config`, `conf.d/`, `bin/` ni `server/`.
2. Completa los TODOs de `starter/README.md`: las filas de `conf.d/30-bastion.conf`, `kh-add -J` y `40-salto.conf`, la bitácora de la semana 09 y la sección "Red privada" (preparar la cuenta de salto, añadir la host key de `interno`, entrar, añadir un host interno nuevo y cortar el acceso de alguien).
3. Copia el kit a tu repositorio y haz el commit de la semana:
   ```bash
   cp -r config conf.d bin server README.md ~/ssh-infra-kit/
   cd ~/ssh-infra-kit && git add -A && git commit -m "semana 09: acceso a interno vía bastion con ProxyJump"
   git log --stat -1
   ```
   En el commit deben aparecer `README.md`, `conf.d/30-bastion.conf`, `bin/kh-add` y `server/sshd_config.d/`: ni llaves ni `known_hosts`.

### Paso 10 — Autograding

Desde la raíz del repositorio, **en tu equipo**:

```bash
./scripts/verificar-semana.sh 09
```

Los checks no usan `bastion` ni `interno`: arrancan dos `sshd` propios en `127.0.0.1:2209` (el salto) y `127.0.0.1:2210` (el destino) del contenedor `client`, y una configuración de prueba que redirige `lab-salto` y `lab-interno` a ellos antes de incluir tu `config`. Para ver si de verdad saltas, apagan el primero. La configuración del servidor la comprueban con `sudo sshd -T -C user=salto` contra tu `server/sshd_config.d`. Solo se ejecutan dentro del laboratorio.

## ✅ Requisitos verificables

- lab-salto entra en bastion como salto con la llave ~/.ssh/lab
- lab-interno entra en interno como alumno con la llave ~/.ssh/lab
- lab-interno salta por lab-salto (ProxyJump)
- ssh lab-interno entra a través del salto, y sin el salto no entra
- bin/kh-add sale con 2 si -J no lleva salto o faltan argumentos
- bin/kh-add -J lee la host key a través del salto y la añade si la huella coincide
- bin/kh-add -J sale con 1 y no escribe nada si la huella no coincide
- bin/kh-add -J sale con 3 si no llega a través del salto
- bin/kh-add sin -J sigue leyendo la llave directamente
- sshd deja entrar a los grupos ssh-users, sftp-only y saltadores
- Un usuario de saltadores no tiene shell, comandos ni terminal
- Un usuario de saltadores solo reenvía a interno:22, sin -R, agente, sockets, X11 ni tun
- Los saltos quedan en el log (DEBUG1 para saltadores, VERBOSE para el resto)
- El Match de saltadores no limita a los demás usuarios
- Los scripts de las semanas anteriores siguen respondiendo
- Sin TODOs y shellcheck sin avisos

## Calidad

Lo que el autograding no ve se evalúa en la [rúbrica](../rubrica-evaluacion.md#-producto-30): los comentarios Qué / Para qué / Impacto de cada host y cada opción de `40-salto.conf`, los mensajes de `kh-add`, el README del kit y el historial de git sin llaves.

## Entrega

- [ ] `./scripts/verificar-semana.sh 09` con las 16 comprobaciones en verde
- [ ] `starter/README.md` sin TODOs
- [ ] `~/ssh-infra-kit` con un commit nuevo para esta semana y ninguna llave en `git log --stat`

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 07 — Quién salta a dónde, y cómo cortarlo](../2-practicas/lab-07-auditoria-y-cortes/README.md) | [Rúbrica de evaluación](../rubrica-evaluacion.md) → |

[↑ Semana 09](../README.md)
