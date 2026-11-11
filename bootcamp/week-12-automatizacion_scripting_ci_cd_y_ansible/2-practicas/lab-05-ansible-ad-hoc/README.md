# Lab 05 — Ansible sin playbook

⏱ Duración estimada: ~60 min

## Objetivo

Dar los primeros pasos con Ansible: un inventario, un `ansible.cfg`, comandos sueltos (*ad hoc*) en un grupo de servidores, `become` para ejecutar como root, los *facts* de un servidor y el `ssh` exacto que Ansible lanza por debajo.

## Contexto

- Las piezas de Ansible y cómo usa SSH: [teoría 03](../../1-teoria/03-ansible.md).
- Ansible ya está en la imagen del laboratorio (`ansible --version`). En tu equipo se instala con `uv tool install ansible-core`.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-ssh-en-scripts/README.md). Ansible usa tu `ssh`: lo que no entre con `ssh -o BatchMode=yes HOST`, no entra con Ansible.

1. **Un inventario y el primer ping.**
   ```bash
   mkdir -p ~/w/ansible && cd ~/w/ansible
   printf "[lab]\nserver\nbastion\n" > hosts.ini
   ansible all -i hosts.ini -m ping
   ```
   ```
   [WARNING]: Host 'server' is using the discovered Python interpreter at '/usr/bin/python3.12', but future installation of another Python interpreter could cause a different interpreter to be discovered. ...
   server | SUCCESS => {
       "ansible_facts": {
           "discovered_interpreter_python": "/usr/bin/python3.12"
       },
       "changed": false,
       "ping": "pong"
   }
   ...
   ```
   - `[lab]` es un grupo; `all`, todos los servidores del inventario.
   - `-m ping` no es un ping de red: entra por SSH, ejecuta un módulo en Python y responde `pong`. Comprueba de una vez SSH, Python y permisos.
   - El aviso: Ansible ha buscado el Python del servidor. El paso siguiente lo fija.

2. **`ansible.cfg`.** Ansible lo lee de la carpeta desde la que lo ejecutas:
   ```bash
   printf "[defaults]\ninventory = hosts.ini\ninterpreter_python = /usr/bin/python3\n" > ansible.cfg
   ansible lab -m ping
   ansible-inventory --graph
   ```
   ```
   server | SUCCESS => {
       "changed": false,
       "ping": "pong"
   }
   bastion | SUCCESS => {
   ...
   @all:
     |--@ungrouped:
     |--@lab:
     |  |--server
     |  |--bastion
   ```
   Sin `-i` ni aviso. `ansible-config dump --only-changed` dice qué tomó de tu archivo.

3. **Comandos sueltos.**
   ```bash
   ansible lab -m command -a "uptime -p"
   ansible server -m shell -a 'echo $HOME | wc -c'
   ```
   ```
   bastion | CHANGED | rc=0 >>
   up 6 hours, 51 minutes
   server | CHANGED | rc=0 >>
   up 6 hours, 51 minutes
   server | CHANGED | rc=0 >>
   13
   ```
   - Los servidores van **en paralelo** (5 a la vez por defecto, `-f` lo cambia): el orden de las respuestas varía.
   - `command` ejecuta el programa sin shell: nada de `|`, `>` ni `$VAR`. `shell` pasa por `/bin/sh`. Usa `command` siempre que puedas: no hay comillas que interpretar dos veces.
   - `CHANGED`: Ansible no sabe qué hizo tu comando, así que supone que cambió algo. Los módulos de verdad (lab 06) sí lo saben.

4. **Como root: `become`.**
   ```bash
   ansible server -m command -a "id -un"
   ansible server -b -m command -a "id -un"
   ```
   ```
   server | CHANGED | rc=0 >>
   alumno
   server | CHANGED | rc=0 >>
   root
   ```
   `-b` (`become: true` en un playbook) usa `sudo` en el servidor. En el laboratorio, `alumno` tiene `sudo` sin contraseña (**solo laboratorio**); con contraseña, `-K` la pide.

5. **Lo que Ansible sabe de un servidor (*facts*).**
   ```bash
   ansible server -m setup -a "filter=ansible_distribution*" | head -8
   ```
   ```
   server | SUCCESS => {
       "ansible_facts": {
           "ansible_distribution": "Ubuntu",
           "ansible_distribution_file_parsed": true,
           "ansible_distribution_file_path": "/etc/os-release",
           "ansible_distribution_file_variety": "Debian",
           "ansible_distribution_major_version": "24",
           "ansible_distribution_release": "noble",
   ```
   Un playbook los recoge al empezar (`Gathering Facts`) y los usa como variables: `ansible_facts.distribution`, `ansible_facts.env.SUDO_USER` (lo usa el playbook del proyecto).

6. **El `ssh` de Ansible.**
   ```bash
   ansible server -m ping -vvv 2>&1 | grep -m1 "SSH: EXEC" | cut -c1-200
   ls ~/.ansible/cp
   ```
   ```
   <server> SSH: EXEC ssh -C -o ControlMaster=auto -o ControlPersist=60s -o KbdInteractiveAuthentication=no -o PreferredAuthentications=gssapi-with-mic,gssapi-keyex,hostbased,publickey -o Passwor
   cef052cad0
   f9e6445ae9
   ```
   - Es tu `ssh`, con multiplexing (`ControlMaster`, `ControlPersist=60s`) y masters en `~/.ansible/cp`: uno por servidor.
   - `PasswordAuthentication=no` y `KbdInteractiveAuthentication=no`: como `BatchMode`, nunca se queda esperando una contraseña.
   - Lee `~/.ssh/config` y `~/.ssh/known_hosts` como cualquier `ssh`.

7. **Un servidor al que no llegas.**
   ```bash
   printf "[lab]\nserver\nbastion\ninterno\n" > hosts.ini
   ansible lab -m ping 2>&1 | grep -A4 "^interno"; echo "código: ${PIPESTATUS[0]}"
   printf "[lab]\nserver\nbastion\n" > hosts.ini
   ```
   ```
   interno | UNREACHABLE! => {
       "changed": false,
       "msg": "Task failed: Failed to connect to the host via ssh: ssh: Could not resolve hostname interno: Name or service not known",
       "unreachable": true
   }
   código: 4
   ```
   El error es el de `ssh`, tal cual. Los demás servidores siguen; el código (4: alguno inalcanzable) avisa a un script o a un CI. En el [lab 07](../lab-07-ansible-por-el-bastion/README.md) llegas a `interno` a través de `bastion`.

## Criterios de éxito

- [ ] Explicas qué comprueba `-m ping` (paso 1)
- [ ] Tienes un `ansible.cfg` con inventario y Python, y sabes desde dónde se lee (paso 2)
- [ ] Explicas la diferencia entre `command` y `shell`, y por qué dicen `CHANGED` (paso 3)
- [ ] Ejecutas como root con `-b` y explicas qué usa por debajo (paso 4)
- [ ] Encuentras en `-vvv` el `ssh` de Ansible y explicas su multiplexing (paso 6)
- [ ] Explicas el `UNREACHABLE` y el código de salida (paso 7)

## Reto extra

`ansible-doc -l | wc -l` lista los módulos que trae `ansible-core`. Busca con `ansible-doc` los de `user`, `group` y `lineinfile`, y escribe el comando *ad hoc* que crearía el grupo `ssh-users` en los dos servidores. Ejecútalo dos veces: ¿qué dice la segunda?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 04 — Un CI sin nadie delante](../lab-04-un-ci-sin-nadie-delante/README.md) | [Lab 06 — El primer playbook](../lab-06-primer-playbook/README.md) → |

[↑ Semana 12](../../README.md)
