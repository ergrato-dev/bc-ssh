# Proyecto Semana 12 — ssh-infra-kit: Ansible y despliegue desde CI

⏱ Duración estimada: ~3 h

## Contexto

Tu kit sabe endurecer un servidor (`bin/sshd-deploy`), pero de uno en uno y a mano. Con dos servidores es cómodo; con veinte, alguno se queda atrás. Esta semana el kit gana una forma de dejar **todos** los servidores como dice el repositorio, y de hacerlo sin ti delante:

- **`ansible/ansible.cfg` e `ansible/inventario.ini`**: Ansible con los alias, llaves y `known_hosts` del kit, y el grupo `servidores`.
- **`ansible/servidores.yml`**: el playbook. Lo que el kit da por hecho (grupos, KRL), `sshd_config.d` validado antes de instalarlo, el PAM y la jaula de fail2ban; recarga solo lo que cambió, de un servidor en un servidor, y comprueba al final con una conexión nueva.
- **`bin/ci-deploy`**: el playbook desde un CI, con la llave y el `known_hosts` en variables.
- **`ci/github-actions.yml`**: el workflow que lo llama en cada push.

## Estructura del proyecto

```
starter/                        ← aquí trabajas: tu ssh-infra-kit de la semana 11 + TODOs
├── README.md                   ← documentación del kit (TODOs)
├── config, conf.d/, ca/        ← semanas 05-10, terminados
├── server/                     ← semanas 07-11, terminado: lo que despliega el playbook
├── ansible/
│   ├── ansible.cfg             ← TODO 1
│   ├── inventario.ini          ← TODO 2
│   └── servidores.yml          ← TODOs 3 a 6
├── bin/
│   ├── ci-deploy               ← TODO 7
│   └── …                       ← semanas 01-11, terminados
└── ci/
    └── github-actions.yml      ← TODO 8
solucion/                       ← referencia: no la abras hasta terminar
```

## Lo que debes construir

| Archivo | Contenido | Lab |
|---|---|---|
| `ansible/ansible.cfg` | `inventory`, `interpreter_python`, `host_key_checking`; en `[ssh_connection]`, `ssh_args = -F ../config -o ControlPersist=60s` y `pipelining` | [05](../2-practicas/lab-05-ansible-ad-hoc/README.md), [07](../2-practicas/lab-07-ansible-por-el-bastion/README.md) |
| `ansible/inventario.ini` | Grupo `[servidores]`: `lab-server` y `lab-bastion` | [05](../2-practicas/lab-05-ansible-ad-hoc/README.md) |
| `ansible/servidores.yml` | Un play para `servidores`, con `become` y `serial: 1`: prerequisitos, validar e instalar `sshd_config.d`, borrar lo que sobra, PAM, jaula, handlers y comprobación final | [06](../2-practicas/lab-06-primer-playbook/README.md), [07](../2-practicas/lab-07-ansible-por-el-bastion/README.md) |
| `bin/ci-deploy` | `ci-deploy [ARGUMENTOS DE ansible-playbook]` con `KIT_SSH_KEY` y `KIT_KNOWN_HOSTS`: sale con 2 si falta una (nombrándola), si no, con el código de `ansible-playbook` | [04](../2-practicas/lab-04-un-ci-sin-nadie-delante/README.md) |
| `ci/github-actions.yml` | En push a `main` (rutas `server/**` y `ansible/**`) y a mano; `permissions: contents: read`; `concurrency`; checkout, `setup-uv`, `ansible-core==2.21.5` y `bin/ci-deploy` con los dos secretos | [04](../2-practicas/lab-04-un-ci-sin-nadie-delante/README.md) |

Cada opción lleva su **Qué / Para qué / Impacto** en un comentario.

## Paso a paso

### Paso 0 — Preparar la terminal

Desde la raíz del repositorio en tu equipo (si no lo hiciste esta semana, antes `docker compose build`):

```bash
docker compose up -d --force-recreate server bastion
docker compose run --rm client
```

Ya dentro del contenedor, enlaza el kit, `known_hosts` y una llave sin frase (**solo laboratorio**) instalada en `lab-server` y `lab-bastion`:

```bash
cd bootcamp/week-12-automatizacion_scripting_ci_cd_y_ansible/3-proyecto/starter
mkdir -p -m 700 ~/.ssh ~/w
bin/kit-link
export SSHPASS=alumno
ssh-keyscan -t ed25519 server bastion 2>/dev/null > ~/.ssh/known_hosts
ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/lab
for h in lab-server lab-bastion; do sshpass -e ssh-copy-id -F config -o ControlPath=none -i ~/.ssh/lab.pub $h 2>&1 | grep 'Number of'; done
```

```
kit-link: /home/alumno/.ssh/kit -> /bc-ssh/bootcamp/week-12-automatizacion_scripting_ci_cd_y_ansible/3-proyecto/starter
Number of key(s) added: 1
Number of key(s) added: 1
```

`SSHPASS=alumno` es la contraseña del laboratorio: **solo del laboratorio**. Desde aquí, todos los comandos de Ansible se ejecutan en `ansible/` (`cd ansible`): es donde Ansible busca `ansible.cfg`.

### Paso 1 — TODO 1: `ansible.cfg`

Las cinco opciones de la tabla, cada una con su Qué / Para qué / Impacto. En el de `ssh_args`, por qué `-F ../config` (Ansible y tu terminal usan los mismos alias, llaves y saltos) y por qué `ControlPersist` va aquí aunque el kit ya tenga multiplexing: con `ControlPersist` en `ssh_args`, Ansible pone su propio `ControlPath` y sabe cerrar el master (`reset_connection`, paso 5). Comprueba qué ha leído:

```bash
cd ansible
{ ansible-config dump --only-changed; ansible-config dump -t connection --only-changed | grep -E '^(ssh_args|pipelining)' | sort -u; } 2>/dev/null | grep -Ev '^(CONFIG_FILE|GALAXY|$)' | sed 's/(.*)//'
```

```
DEFAULT_HOST_LIST = ['/bc-ssh/bootcamp/week-12-automatizacion_scripting_ci_cd_y_ansible/3-proyecto/starter/ansible/inventario.ini']
HOST_KEY_CHECKING = True
INTERPRETER_PYTHON = /usr/bin/python3
pipelining = True
ssh_args = -F ../config -o ControlPersist=60s
```

### Paso 2 — TODO 2: el inventario

El grupo `[servidores]` con los dos alias de `conf.d/10-lab.conf`, y un comentario: cómo se añade un servidor (primero `conf.d/` y su host key, después aquí) y por qué `lab-interno` no está (su acceso es la cuenta de salto, sin shell).

```bash
ansible servidores -m ping
```

```
lab-bastion | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
lab-server | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Sin `-i`, sin `-u` y sin llave en la orden: todo sale de `ansible.cfg` y de `conf.d/`.

### Paso 3 — TODOs 3 y 4: prerequisitos, validar e instalar

**TODO 3.** El comentario de cabecera, `serial: 1` y tres tareas: los grupos de la configuración del kit (`ansible.builtin.group` con `loop`), quien despliega en `ssh-users` (`ansible.builtin.user` con `name: "{{ ansible_facts.env.SUDO_USER }}"`, `groups: ssh-users` y `append: true`) y la KRL (`ansible.builtin.file` con `state: touch` y `modification_time`/`access_time` en `preserve`, para que la segunda vez no cuente como cambio).

- Sin la segunda tarea, `AllowGroups ssh-users` de `10-acceso.conf` te dejaría fuera.
- En un servidor nuevo, `--check` no crea los grupos de verdad, y la tarea `user` fallaría: `ignore_errors: "{{ ansible_check_mode }}"`.

**TODO 4.** Probar antes de instalar. `validate` (lab 06) comprueba un archivo suelto; aquí hay que comprobar la configuración **completa** con la carpeta nueva:

1. `ansible.builtin.copy` de `../server/sshd_config.d/` a `/root/kit-sshd/sshd_config.d/`.
2. `ansible.builtin.shell` con `changed_when: false`: el `sshd_config` del servidor con la ruta cambiada, y `sshd -t` sobre él:
   ```yaml
   ansible.builtin.shell: >
     sed 's#/etc/ssh/sshd_config.d#/root/kit-sshd/sshd_config.d#'
     /etc/ssh/sshd_config > /root/kit-sshd/sshd_config &&
     sshd -t -f /root/kit-sshd/sshd_config
   ```
3. Solo entonces, `ansible.builtin.copy` a `/etc/ssh/sshd_config.d/` (`root`, `0644`) con `notify: Recargar sshd`.

Rompe a propósito un archivo del kit y comprueba que no llega a ningún servidor:

```bash
ansible-playbook --syntax-check servidores.yml
echo "NoExiste si" >> ../server/sshd_config.d/20-sesion.conf
ansible-playbook servidores.yml 2>&1 | grep -oE 'line [0-9]+: Bad configuration option: NoExiste|lab-[a-z]+ +: ok=[0-9]+ +changed=[0-9]+ +unreachable=0 +failed=1'
sed -i '$d' ../server/sshd_config.d/20-sesion.conf
ssh -F ../config lab-server ls /etc/ssh/sshd_config.d
```

```
playbook: servidores.yml
line 28: Bad configuration option: NoExiste
line 28: Bad configuration option: NoExiste
lab-server                 : ok=5    changed=4    unreachable=0    failed=1
10-bc-ssh.conf
```

- El error sale dos veces (el mensaje y su detalle) y solo para `lab-server`: con `serial: 1`, `lab-bastion` ni se toca.
- `sshd_config.d` del servidor sigue como venía (`10-bc-ssh.conf`, la del laboratorio).
- Hasta el TODO 5 no existe el handler `Recargar sshd`: con un kit válido, `Instalar sshd_config.d` cambia algo y Ansible para con `The requested handler 'Recargar sshd' was not found`. `--syntax-check` no lo detecta.

### Paso 4 — TODO 5: dejar el servidor como el kit

1. **Lo que sobra.** `copy` de una carpeta no borra. `ansible.builtin.find` en `/etc/ssh/sshd_config.d` (`register: actuales`) y `ansible.builtin.file` con `state: absent` en un `loop` sobre `actuales.files`, `when: item.path | basename not in kit_confs` y `notify: Recargar sshd`. `kit_confs` (la lista de archivos del kit) ya está en `vars`.
2. **El PAM**: `copy` de `../server/pam.d/sshd` con `backup: true` (deja `/etc/pam.d/sshd.FECHA~`). No hace falta recargar: `sshd` lo lee en cada conexión.
3. **La jaula**: `copy` de `../server/fail2ban/jail.d/` con `notify: Recargar fail2ban`.
4. **Los handlers**:
   - `Recargar sshd`: `kill -HUP "$(cat /run/sshd.pid)"`. Recargar, no reiniciar: las conexiones abiertas siguen.
   - `Recargar fail2ban`: `fail2ban-client -t` y después `reload`, o `start` si no estaba arrancado, con la entrada y las salidas a `/dev/null` (`fail2ban-client start` deja un proceso que las mantendría abiertas y Ansible esperaría para siempre).

Mira antes qué cambiaría en `lab-server`:

```bash
ansible-playbook servidores.yml --check --diff -l lab-server 2>&1 | grep -E '^TASK \[(Instalar|Quitar|PAM|Jaula)|^changed'
```

```
TASK [Instalar sshd_config.d] **************************************************
changed: [lab-server]
TASK [Quitar los que no son del kit] *******************************************
changed: [lab-server] => (item=10-bc-ssh.conf)
TASK [PAM de sshd (código TOTP para dosfa)] ************************************
changed: [lab-server]
TASK [Jaula de fail2ban] *******************************************************
changed: [lab-server]
```

### Paso 5 — TODO 6: comprobar al final

Con multiplexing, una conexión abierta no vuelve a autenticarse ([lab 07](../2-practicas/lab-07-ansible-por-el-bastion/README.md), paso 7): si el `sshd` nuevo te deja fuera, las tareas siguientes seguirían entrando por el master viejo. Al final de las tareas:

1. `ansible.builtin.meta: flush_handlers`: las recargas, ya, no al final del play.
2. `ansible.builtin.meta: reset_connection`: cierra el master (por eso `ControlPersist` en `ssh_args`, paso 1).
3. `ansible.builtin.ping`: una conexión nueva, con el `sshd` nuevo. Si falla, el play se para en este servidor y, con `serial: 1`, no pasa al siguiente.

Aplica, y vuelve a aplicar:

```bash
ansible-playbook servidores.yml | tail -3
ansible-playbook servidores.yml | tail -3
ssh -F ../config -P sinmux lab-server 'ls /etc/ssh/sshd_config.d | paste -sd" "; id -nG'
```

```
lab-bastion                : ok=14   changed=10   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
lab-server                 : ok=14   changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

lab-bastion                : ok=11   changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
lab-server                 : ok=11   changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0

10-acceso.conf 15-algoritmos.conf 20-sesion.conf 30-sftp.conf 40-salto.conf 50-ca.conf 60-2fa.conf
alumno adm dialout cdrom floppy sudo audio dip video plugdev ssh-users
```

- `lab-server` cambia menos que `lab-bastion`: los grupos y la KRL ya los creó el intento del paso 3.
- La segunda vez, `changed=0`: nada que hacer, ningún handler, ninguna recarga. Así se puede lanzar en cada push.
- `skipped=1`: `Quitar los que no son del kit` no tiene nada que quitar.

### Paso 6 — TODO 7: `bin/ci-deploy`

Los cuatro pasos del comentario: comprobar las dos variables (con `"${!v:-}"` recorres sus nombres en un bucle), `bin/kit-link` (en un runner no hay `~/.ssh/kit`), la carpeta temporal con `trap` y `umask 077`, y `ansible-playbook` con `--private-key`, `--ssh-common-args` y `"$@"`. `--ssh-common-args` se añade **después** de `ssh_args`: `-o` en la línea de órdenes gana a `config`, así que `UserKnownHostsFile` y `StrictHostKeyChecking=yes` mandan sobre los del kit.

Pruébalo como un runner, con un entorno vacío y `--check` (llega hasta `ansible-playbook`):

```bash
cd ..
KH=$(ssh-keygen -F server | grep -v '^#'; ssh-keygen -F bastion | grep -v '^#')
env -i PATH=$PATH HOME=$(mktemp -d) KIT_SSH_KEY="$(cat ~/.ssh/lab)" KIT_KNOWN_HOSTS="$KH" bin/ci-deploy --check | tail -3
env -i PATH=$PATH HOME=$(mktemp -d) KIT_KNOWN_HOSTS="$KH" bin/ci-deploy; echo "código: $?"
```

```
lab-bastion                : ok=10   changed=0    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0
lab-server                 : ok=10   changed=0    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0

ci-deploy: falta la variable KIT_SSH_KEY
código: 2
```

La llave `lab` es la tuya: en un CI de verdad, una solo para el CI (README del kit, «Desde un CI»).

### Paso 7 — TODO 8: el workflow

Los cinco puntos del TODO, con comentarios. Mira el ejemplo de la [teoría 02](../1-teoria/02-despliegue-desde-ci.md#un-workflow-de-github-actions). Sin `ssh-keyscan`, sin `StrictHostKeyChecking` y sin `accept-new` en el archivo: el `known_hosts` llega por el secreto. Comprueba que es YAML válido con el Python de Ansible, que trae `yaml`:

```bash
/opt/uv-tools/ansible-core/bin/python -c 'import yaml; w = yaml.safe_load(open("ci/github-actions.yml")); print(list(w[True]), list(w["jobs"]))'
```

```
['push', 'workflow_dispatch'] ['servidores']
```

`w[True]`: para YAML 1.1, la palabra `on` es el booleano verdadero. GitHub la entiende como `on`; un `yaml` de Python, como `True`.

### Paso 8 — Calidad, README y git

1. `shellcheck bin/* ca/*` y `shellcheck -s sh server/sshd-apply` sin avisos, y ningún `TODO` en `README.md`, `config`, `conf.d/`, `bin/`, `ca/`, `server/`, `ansible/` ni `ci/`.
2. Completa los TODOs de `starter/README.md`: los requisitos (`ansible-core`, y `python3` y `sudo` sin contraseña en los servidores), las cinco filas nuevas, la bitácora de la semana 12 y la sección "Automatización: Ansible y CI" (los tres comandos desde `ansible/`; qué no hace el playbook que sí hace `bin/sshd-deploy`; cómo preparar la llave del CI, `KIT_KNOWN_HOSTS` y la cuenta).
3. Copia el kit a tu repositorio y haz el commit de la semana:
   ```bash
   cp -r config conf.d bin ca server ansible ci README.md ~/ssh-infra-kit/
   cd ~/ssh-infra-kit && git add -A && git commit -m "semana 12: Ansible y despliegue desde CI"
   git log --stat -1
   ```
   En el commit: `ansible/`, `ci/` y `bin/ci-deploy`. **Ninguna llave privada ni `known_hosts`**: van como secretos del CI, nunca en el repositorio.

### Paso 9 — Autograding

Desde la raíz del repositorio, **en tu equipo**:

```bash
./scripts/verificar-semana.sh 12
```

Los checks del playbook arrancan un `sshd` como root en `127.0.0.1:2212` con la configuración del laboratorio y ejecutan tu `servidores.yml` contra él, con un inventario y una configuración SSH de prueba (`ANSIBLE_INVENTORY` y `ANSIBLE_SSH_ARGS`). Los de `ci-deploy`, lo mismo desde un entorno vacío. Solo funcionan dentro del laboratorio. Tardan unos minutos: cada uno ejecuta el playbook una o dos veces.

## ✅ Requisitos verificables

- ansible.cfg usa el inventario del kit, la configuración SSH del kit con ControlPersist, pipelining, python3 y comprobación de host keys
- El grupo servidores del inventario tiene lab-server y lab-bastion
- servidores.yml es un playbook válido para el grupo servidores, con become y de un servidor en un servidor (serial: 1)
- Con --check el playbook dice qué cambiaría sin tocar el servidor
- Si sshd_config.d del kit no pasa sshd -t, el playbook falla sin instalar nada y el servidor sigue aceptando conexiones
- El playbook deja sshd_config.d igual que el kit (borra lo que sobra), crea los grupos y la KRL, mantiene a quien despliega en ssh-users e instala PAM y jaula
- Recarga sshd solo si algo cambió, entra con una conexión nueva al terminar y la segunda ejecución no cambia nada
- ci-deploy sale con 2 y nombra la variable si falta KIT_SSH_KEY o KIT_KNOWN_HOSTS
- En un entorno vacío, ci-deploy aplica el playbook con la llave y el known_hosts de sus variables, no los escribe en la salida y no deja archivos
- Si la host key no es la de KIT_KNOWN_HOSTS, ci-deploy falla sin tocar el servidor ni aceptar la llave nueva
- ci/github-actions.yml se ejecuta en push, con permisos de solo lectura, y llama a bin/ci-deploy con los dos secretos, sin saltarse ni adivinar host keys
- Sin TODOs, shellcheck sin avisos y los scripts anteriores siguen respondiendo

## Calidad

Lo que el autograding no ve se evalúa en la [rúbrica](../rubrica-evaluacion.md#-producto-30): los comentarios Qué / Para qué / Impacto de cada archivo, los nombres de las tareas, el README del kit y el historial de git sin secretos.

## Entrega

- [ ] `./scripts/verificar-semana.sh 12` con las 12 comprobaciones en verde
- [ ] `starter/README.md` sin TODOs
- [ ] `~/ssh-infra-kit` con un commit nuevo para esta semana y ninguna llave ni `known_hosts` en `git log --stat`

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 07 — Ansible a través del bastion, y rápido](../2-practicas/lab-07-ansible-por-el-bastion/README.md) | [Rúbrica de evaluación](../rubrica-evaluacion.md) → |

[↑ Semana 12](../README.md)
