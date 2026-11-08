# Proyecto Semana 07 — ssh-infra-kit: el servidor endurecido y cómo aplicarlo

⏱ Duración estimada: ~3 h

## Contexto

Hasta ahora el kit solo tenía lado cliente. Esta semana gana su primera carpeta de servidor y la forma segura de aplicarla:

- **`server/sshd_config.d/`**: tres archivos con todo lo que endureciste en los labs. `10-acceso.conf` dice quién entra y cómo, `20-sesion.conf` qué puede hacer una sesión, y `30-sftp.conf` define las cuentas que solo suben archivos.
- **`bin/sshd-deploy HOST`**: copia esa carpeta al servidor, la valida, recarga `sshd` y comprueba con una conexión nueva que sigues entrando. Si no entras, el servidor vuelve solo a la configuración anterior ([lab 07](../2-practicas/lab-07-cambios-sin-quedarte-fuera/README.md)).
- **`server/sshd-apply`**: la mitad de `sshd-deploy` que se ejecuta en el servidor, como root.

## Estructura del proyecto

```
starter/                    ← aquí trabajas: tu ssh-infra-kit de la semana 06 + TODOs
├── README.md               ← documentación del kit (TODOs)
├── config, conf.d/         ← semana 05, terminados
├── bin/
│   ├── lab-check … backup, mirror   ← semanas 01-06
│   └── sshd-deploy         ← TODO 7
└── server/
    ├── sshd-apply          ← TODOs 6 y 8
    └── sshd_config.d/
        ├── 10-acceso.conf  ← TODOs 1, 2 y 3
        ├── 20-sesion.conf  ← TODO 4
        └── 30-sftp.conf    ← TODO 5
solucion/                   ← referencia: no la abras hasta terminar
```

## Lo que debes construir

### `server/sshd_config.d/`

| Archivo | Opciones |
|---|---|
| `10-acceso.conf` | `PasswordAuthentication no`, `KbdInteractiveAuthentication no`, `PermitRootLogin no`, `AllowGroups ssh-users sftp-only`, `MaxAuthTries 3`, `LoginGraceTime 20`, `MaxStartups 10:30:60` |
| `20-sesion.conf` | `X11Forwarding no`, `AllowAgentForwarding no`, `ClientAliveInterval 300`, `ClientAliveCountMax 2`, `LogLevel VERBOSE` |
| `30-sftp.conf` | `Match Group sftp-only` con `ChrootDirectory /srv/sftp/%u`, `ForceCommand internal-sftp -d /subidas`, `DisableForwarding yes`, `PermitTTY no` |

Cada opción lleva su **Qué / Para qué / Impacto** en un comentario. Ya los escribiste en los labs: aquí se quedan por escrito.

### `bin/sshd-deploy HOST`

1. Empaqueta `server/` con `tar`, lo envía por `ssh` a una carpeta temporal del servidor y ejecuta `sudo sh CARPETA/sshd-apply CARPETA SEGUNDOS`.
2. Prueba con una conexión **nueva**, `ssh -o ControlPath=none`, y crea `CARPETA/confirmado`.
3. Conecta con `ssh -F config` del kit (`SSH_CMD` lo cambia). `DEPLOY_TIMEOUT` fija los segundos (60).

| Código | Cuándo |
|---|---|
| 0 | Aplicada y confirmada |
| 1 | No se aplicó (configuración inválida, sin sudo, sin conexión), o no se pudo entrar después: el servidor la deshace solo |
| 2 | Uso incorrecto o `DEPLOY_TIMEOUT` no válido |

### `server/sshd-apply CARPETA SEGUNDOS`

En el servidor, como root: copia `/etc/ssh/sshd_config.d` a `.anterior`, la **sustituye** por `CARPETA/sshd_config.d`, valida con `sshd -t` (si falla, restaura y sale con 1), recarga y deja en segundo plano la vuelta atrás: si en `SEGUNDOS` no existe `CARPETA/confirmado`, restaura y recarga.

## Paso a paso

### Paso 0 — Preparar la terminal

Desde la raíz del repositorio en tu equipo:

```bash
docker compose up -d --build --force-recreate server
docker compose run --rm client
```

`--build`: esta semana la imagen añade `sudo` sin contraseña para `alumno`, **solo en el laboratorio**. Ya dentro del contenedor, enlaza el kit, prepara `known_hosts` y una llave sin frase (solo laboratorio) para `lab-server`, como en la semana 06:

```bash
cd bootcamp/week-07-servidor_sshd_config_y_hardening/3-proyecto/starter
mkdir -p -m 700 ~/.ssh ~/w
bin/kit-link
ls bin server server/sshd_config.d
export SSHPASS=alumno
ssh-keyscan -t ed25519 server 2>/dev/null > ~/.ssh/known_hosts
ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/lab
sshpass -e ssh-copy-id -F config -o ControlPath=none -i ~/.ssh/lab.pub lab-server 2>&1 | grep 'Number of'
```

```
kit-link: /home/alumno/.ssh/kit -> /bc-ssh/bootcamp/week-07-servidor_sshd_config_y_hardening/3-proyecto/starter
bin:
agent-up
ak-line
backup
key-new
kh-add
kit-link
lab-check
mirror
mux
sshd-deploy

server:
sshd-apply
sshd_config.d

server/sshd_config.d:
10-acceso.conf
20-sesion.conf
30-sftp.conf
Number of key(s) added: 1
```

La contraseña `alumno` (**solo del laboratorio**) es la última vez que la usas: al terminar, `server` ya no la acepta.

### Paso 1 — Lo que tiene `server` ahora

```bash
ssh -F config lab-server 'ls /etc/ssh/sshd_config.d; sudo sshd -T | grep -E "^(passwordauthentication|permitrootlogin|allowgroups|maxauthtries|x11forwarding|loglevel)"'
```

```
10-bc-ssh.conf
maxauthtries 6
permitrootlogin no
passwordauthentication yes
x11forwarding yes
loglevel INFO
```

Contraseñas, X11, 6 intentos y ningún `AllowGroups`: la configuración permisiva de la semana 01. Al final de este proyecto, `sshd-deploy` la sustituye.

### Paso 2 — Probar el kit sin tocar el servidor

El cliente tiene el mismo `sshd` que `server`. Puedes leer la configuración del kit con él, sin arrancarlo, haciendo una copia de `sshd_config` cuyo `Include` apunte a tu carpeta:

```bash
sudo ssh-keygen -A >/dev/null
sed "s|/etc/ssh/sshd_config.d|$PWD/server/sshd_config.d|" /etc/ssh/sshd_config > ~/w/main
T="sudo /usr/sbin/sshd -f $HOME/w/main"
$T -t; echo "código: $?"
$T -T | grep -E "^(passwordauthentication|permitrootlogin|allowgroups|maxauthtries)"
```

```
código: 0
maxauthtries 6
permitrootlogin without-password
passwordauthentication yes
```

- `ssh-keygen -A`: crea las host keys que falten en `/etc/ssh` del cliente. `sshd -t` y `-T` las necesitan, aunque no arranquen nada.
- `sed "s|A|B|"`: cambia la ruta del `Include` por la de tu kit. `-f`: `sshd` lee ese archivo en lugar de `/etc/ssh/sshd_config`.
- Con los `.conf` del kit casi vacíos, todo es el valor por defecto de OpenSSH: contraseñas y root con llave. Usa `$T -t` y `$T -T` después de cada paso.

### Paso 3 — TODO 1: solo llaves, y root no entra

En `server/sshd_config.d/10-acceso.conf`, `PasswordAuthentication`, `KbdInteractiveAuthentication` y `PermitRootLogin`, cada una con su Qué / Para qué / Impacto ([teoría 02](../1-teoria/02-autenticacion-y-acceso.md#con-qué-método), [lab 02](../2-practicas/lab-02-autenticacion/README.md)).

```bash
$T -T | grep -E "^(passwordauthentication|kbdinteractiveauthentication|permitrootlogin)"
```

```
permitrootlogin no
passwordauthentication no
kbdinteractiveauthentication no
```

En el **Impacto** de `PasswordAuthentication`, di qué compruebas antes de aplicarlo.

### Paso 4 — TODO 2: solo entran dos grupos

`AllowGroups ssh-users sftp-only` en `10-acceso.conf` ([lab 03](../2-practicas/lab-03-quien-entra/README.md)):

```bash
$T -T | grep -E "^allowgroups"
```

```
allowgroups ssh-users
allowgroups sftp-only
```

`sshd -T` escribe una línea por grupo. El **Impacto** tiene que avisar de lo que pasa si tu usuario no está en `ssh-users`. Lo vas a vivir en el paso 9.

### Paso 5 — TODO 3: límites antes de autenticar

`MaxAuthTries 3`, `LoginGraceTime 20` y `MaxStartups 10:30:60` ([teoría 02](../1-teoria/02-autenticacion-y-acceso.md#antes-de-autenticar-límites-a-quien-llega)):

```bash
$T -T | grep -E "^(maxauthtries|logingracetime|maxstartups)"
```

```
logingracetime 20
maxauthtries 3
maxstartups 10:30:60
```

### Paso 6 — TODO 4: qué puede hacer una sesión

En `20-sesion.conf`: `X11Forwarding no`, `AllowAgentForwarding no`, `ClientAliveInterval 300`, `ClientAliveCountMax 2` y `LogLevel VERBOSE` ([lab 06](../2-practicas/lab-06-sesion-y-reenvios/README.md)):

```bash
$T -T | grep -E "^(x11forwarding|allowagentforwarding|clientalive|loglevel)"
```

```
clientaliveinterval 300
clientalivecountmax 2
x11forwarding no
allowagentforwarding no
loglevel VERBOSE
```

Explica en el comentario por qué los túneles TCP **no** se quitan.

### Paso 7 — TODO 5: cuentas que solo suben archivos

En `30-sftp.conf`, el bloque `Match Group sftp-only` del [lab 05](../2-practicas/lab-05-sftp-chroot/README.md), con las cuatro opciones. Para probar un `Match Group` con `-C`, el usuario y el grupo tienen que existir en el equipo donde ejecutas `sshd -T`; créalos en el cliente (desaparecen con `exit`):

```bash
sudo groupadd -f sftp-only; sudo useradd -M -G sftp-only subidas
$T -t && for u in subidas alumno; do echo "== $u"; $T -T -C user=$u | grep -E "^(chrootdirectory|forcecommand|disableforwarding|permittty)"; done
```

```
== subidas
permittty no
disableforwarding yes
forcecommand internal-sftp -d /subidas
chrootdirectory /srv/sftp/%u
== alumno
permittty yes
disableforwarding no
forcecommand none
chrootdirectory none
```

Un caso que coincide y otro que no: si `alumno` saliera con `chrootdirectory /srv/sftp/%u`, tu `Match` estaría tragándose opciones globales ([lab 04, paso 2](../2-practicas/lab-04-match/README.md)).

### Paso 8 — TODO 6: nunca recargar una configuración rota

Abre `server/sshd-apply`. Ya copia la carpeta actual a `.anterior`, instala la nueva y recarga. Falta lo más importante: **antes** de recargar, `sshd -t`. Si falla: `restaurar`, borrar `$carpeta`, avisar por stderr y salir con 1. Sin esto, un error tumba `sshd` y el contenedor ([lab 07, paso 5](../2-practicas/lab-07-cambios-sin-quedarte-fuera/README.md)).

Pruébalo con una copia del kit que tiene un error:

```bash
rm -rf ~/w/roto; cp -r . ~/w/roto; echo 'NoExiste yes' >> ~/w/roto/server/sshd_config.d/20-sesion.conf
~/w/roto/bin/sshd-deploy lab-server; echo "código: $?"
ssh -F config lab-server ls /etc/ssh/sshd_config.d
```

```
/etc/ssh/sshd_config.d/20-sesion.conf: line 28: Bad configuration option: NoExiste
/etc/ssh/sshd_config.d/20-sesion.conf: terminating, 1 bad configuration options
sshd-apply: configuración inválida, no se aplicó nada
sshd-deploy: no se aplicó nada en lab-server
código: 1
10-bc-ssh.conf
```

- La copia (`~/w/roto`) evita meter el error en tu kit. Sus `bin/` usan su propia carpeta `server/`.
- `server` sigue con su `10-bc-ssh.conf`: nada cambió. Tu número de línea puede ser otro.

### Paso 9 — TODO 7: la prueba no puede ir por el master

Ahora una copia del kit que **te deja fuera** (`AllowUsers nadie`). Antes de arreglar nada, mira lo que hace `bin/sshd-deploy` tal como está. La primera orden abre un master, como pasa en tu día a día con el multiplexing del kit:

```bash
rm -rf ~/w/cierre; cp -r . ~/w/cierre; echo 'AllowUsers nadie' > ~/w/cierre/server/sshd_config.d/00-cierre.conf
ssh -F config lab-server true
~/w/cierre/bin/sshd-deploy lab-server; echo "código: $?"
ssh -F config -P sinmux -o BatchMode=yes lab-server true; echo "código: $?"
```

```
sshd-apply: aplicada; se deshace en 60 s si no se confirma
sshd-deploy: aplicada y confirmada en lab-server
código: 0
alumno@server: Permission denied (publickey).
código: 255
```

`sshd-deploy` dice que todo va bien y estás fuera: la prueba entró por el master, que se autenticó antes del cambio. Y el mensaje de `sshd-apply` miente: la vuelta atrás es el TODO 8, todavía no existe. Arréglalo desde el master, que sigue vivo:

```bash
ssh -F config lab-server 'sudo rm -rf /etc/ssh/sshd_config.d; sudo cp -a /etc/ssh/sshd_config.d.anterior /etc/ssh/sshd_config.d; sudo kill -HUP $(cat /run/sshd.pid); ls /etc/ssh/sshd_config.d'
sleep 1; ssh -F config -P sinmux lab-server echo dentro
```

```
10-bc-ssh.conf
dentro
```

Si cerraste el master, la consola: `docker compose exec server sh -c 'rm -rf /etc/ssh/sshd_config.d; cp -a /etc/ssh/sshd_config.d.anterior /etc/ssh/sshd_config.d; kill -HUP 1'`, **en tu equipo**.

El TODO 7 de `bin/sshd-deploy`: la prueba con una opción de `ssh` que no use el master. `-P sinmux` sirve con tu `config`, pero `SSH_CMD` puede traer otro; una opción en la línea de órdenes sirve siempre. Copia el arreglo a `~/w/cierre` y repite:

```bash
cp bin/sshd-deploy ~/w/cierre/bin/
~/w/cierre/bin/sshd-deploy lab-server; echo "código: $?"
```

```
sshd-apply: aplicada; se deshace en 60 s si no se confirma
alumno@server: Permission denied (publickey).
sshd-deploy: no se pudo entrar con la configuración nueva; lab-server vuelve a la anterior en 60 s
código: 1
```

Ahora detecta el problema. Pero sin el TODO 8 nadie lo deshace: vuelve a arreglarlo desde el master, con la orden de arriba.

### Paso 10 — TODO 8: la vuelta atrás automática

En `server/sshd-apply`, después de recargar: un proceso en segundo plano que espera `$espera` segundos y, si no existe `$carpeta/confirmado`, restaura y recarga. Al final borra `$carpeta`. Tiene que soltar la entrada y la salida (`</dev/null >/dev/null 2>&1`), o la conexión de `sshd-deploy` espera a que termine. Es el proceso del [lab 07, paso 3](../2-practicas/lab-07-cambios-sin-quedarte-fuera/README.md), con confirmación.

```bash
cp server/sshd-apply ~/w/cierre/server/
DEPLOY_TIMEOUT=10 ~/w/cierre/bin/sshd-deploy lab-server; echo "código: $?"
sleep 12; ssh -F config -P sinmux lab-server 'echo he vuelto; ls /etc/ssh/sshd_config.d'
```

```
sshd-apply: aplicada; se deshace en 10 s si no se confirma
alumno@server: Permission denied (publickey).
sshd-deploy: no se pudo entrar con la configuración nueva; lab-server vuelve a la anterior en 10 s
código: 1
he vuelto
10-bc-ssh.conf
```

Esta vez no tuviste que hacer nada. ¿Por qué `confirmado` va dentro de `$carpeta` (creada con `mktemp -d`) y no en un nombre fijo como `/tmp/confirmado`? Respóndelo en el README del kit.

### Paso 11 — Aplicar el kit en `lab-server`

`AllowGroups` exige que estés en `ssh-users`. Crea los dos grupos en `server`, entra en el tuyo, y despliega:

```bash
ssh -F config lab-server 'sudo groupadd -f ssh-users; sudo groupadd -f sftp-only; sudo usermod -aG ssh-users alumno; id -nG alumno'
bin/sshd-deploy lab-server; echo "código: $?"
sshpass -e ssh -F config -P sinmux -o PubkeyAuthentication=no lab-server true; echo "código: $?"
ssh -F config lab-server 'ls /etc/ssh/sshd_config.d; sudo sshd -T | grep -E "^(passwordauthentication|permitrootlogin|allowgroups|loglevel)"'
```

```
alumno adm dialout cdrom floppy sudo audio dip video plugdev ssh-users
sshd-apply: aplicada; se deshace en 60 s si no se confirma
sshd-deploy: aplicada y confirmada en lab-server
código: 0
alumno@server: Permission denied (publickey).
código: 255
10-acceso.conf
20-sesion.conf
30-sftp.conf
permitrootlogin no
passwordauthentication no
loglevel VERBOSE
allowgroups ssh-users
allowgroups sftp-only
```

- La contraseña `alumno` ya no entra. `10-bc-ssh.conf` desapareció: `sshd-apply` sustituye la carpeta entera ([teoría 03](../1-teoria/03-sftp-chroot-y-cambios-seguros.md#por-qué-el-kit-sustituye-la-carpeta-entera)).
- Si recreas `server` (`--force-recreate`), vuelve la configuración original y los grupos desaparecen: repite este paso.

Una cuenta de `sftp-only` en `server`, con tu llave, como en el lab 05:

```bash
ssh -F config lab-server 'sudo useradd -m -s /usr/sbin/nologin -G sftp-only proveedor
sudo mkdir -m 700 /home/proveedor/.ssh; sudo cp .ssh/authorized_keys /home/proveedor/.ssh/; sudo chown -R proveedor: /home/proveedor/.ssh
sudo mkdir -p /srv/sftp/proveedor/subidas; sudo chown proveedor: /srv/sftp/proveedor/subidas'
echo informe > ~/w/informe.txt
sftp -F config -o User=proveedor -b - lab-server <<<'put /home/alumno/w/informe.txt
ls'
ssh -F config -P sinmux -o User=proveedor lab-server id; echo "código: $?"
```

```
sftp> put /home/alumno/w/informe.txt
sftp> ls
informe.txt
This service allows sftp connections only.
código: 1
```

`/srv/sftp` y `/srv/sftp/proveedor` las crea `mkdir -p` como root y con 755: el chroot es válido sin más.

### Paso 12 — Calidad, README y git

1. `shellcheck bin/*` y `shellcheck -s sh server/sshd-apply` sin avisos, y ningún `TODO` en `config`, `conf.d/`, `bin/` ni `server/`.
2. Completa los TODOs de `starter/README.md`: la fila de `bin/sshd-deploy` y la de `server/`, la bitácora de la semana 07 y la sección "Endurecer un servidor" (qué hace falta en el servidor antes del primer despliegue, cómo se recupera si algo sale mal y la respuesta del paso 10).
3. Copia el kit a tu repositorio y haz el commit de la semana:
   ```bash
   cp -r config conf.d bin server README.md ~/ssh-infra-kit/
   cd ~/ssh-infra-kit && git add -A && git commit -m "semana 07: sshd_config.d endurecido y sshd-deploy"
   git log --stat -1
   ```
   En el commit deben aparecer `README.md`, `bin/sshd-deploy` y `server/`: ni llaves ni host keys.

### Paso 13 — Autograding

Desde la raíz del repositorio, **en tu equipo**:

```bash
./scripts/verificar-semana.sh 07
```

Los checks arrancan un `sshd` real como root dentro de un contenedor `client` nuevo, en el puerto 2207: crean allí los grupos, unos usuarios de prueba y las host keys, y despliegan tu kit sobre ese `sshd` con `sshd-deploy`. Solo se ejecutan dentro del laboratorio: nunca tocan el `sshd` de tu equipo ni el de `server`.

## ✅ Requisitos verificables

- sshd -t acepta la configuración del kit
- Sin contraseña: PasswordAuthentication y KbdInteractiveAuthentication en no
- root no entra por SSH, ni con llave (PermitRootLogin no)
- Solo entran los grupos ssh-users y sftp-only
- MaxAuthTries 3, LoginGraceTime 20 y MaxStartups 10:30:60
- Sin reenvío de X11 ni de agente, ClientAlive 300 x 2 y LogLevel VERBOSE
- Un usuario de sftp-only queda en chroot, solo con internal-sftp y sin reenvíos ni terminal
- El bloque Match no cambia nada a los demás usuarios
- Con el kit en un sshd real, alumno (de ssh-users) entra con llave
- Con el kit en un sshd real, la contraseña de alumno (solo laboratorio) se rechaza
- Un usuario con llave pero fuera de los grupos no entra
- Un usuario de sftp-only sube a /subidas y no puede leer fuera del chroot
- Un usuario de sftp-only no obtiene shell ni ejecuta órdenes
- bin/sshd-deploy aplica el kit: antes la contraseña entraba, después no
- Con un .conf inválido, bin/sshd-deploy sale con 1 y el servidor sigue como estaba
- Si la configuración nueva deja fuera, sshd-deploy lo detecta aunque haya un master y el servidor la deshace solo
- Los scripts de semanas anteriores siguen respondiendo
- Sin TODO en config, conf.d/, bin/ y server/, y shellcheck sin avisos

## Calidad

Lo que el autograding no ve se evalúa en la [rúbrica](../rubrica-evaluacion.md#-producto-30): los comentarios Qué / Para qué / Impacto de cada opción, el README del kit, los mensajes de `sshd-deploy` y el historial de git sin llaves.

## Entrega

- [ ] `./scripts/verificar-semana.sh 07` con las 18 comprobaciones en verde
- [ ] `starter/README.md` sin TODOs
- [ ] `~/ssh-infra-kit` con un commit nuevo para esta semana y ninguna llave en `git log --stat`

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 07 — Cambiar `sshd` sin quedarte fuera](../2-practicas/lab-07-cambios-sin-quedarte-fuera/README.md) | [Rúbrica de evaluación](../rubrica-evaluacion.md) → |

[↑ Semana 07](../README.md)
