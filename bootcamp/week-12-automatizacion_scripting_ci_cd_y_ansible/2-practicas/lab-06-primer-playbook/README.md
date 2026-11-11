# Lab 06 — El primer playbook

⏱ Duración estimada: ~60 min

## Objetivo

Escribir un playbook que añade un aviso (`Banner`) a `sshd` en los dos servidores: dos tareas `copy`, una validación con `sshd -t` antes de instalar y un handler que recarga `sshd` solo si algo cambió. Ver la idempotencia (`changed=0` la segunda vez), `--check --diff` y qué pasa cuando la configuración no es válida.

## Contexto

- Idempotencia, handlers y cómo cambiar `sshd` sin quedarte fuera: [teoría 03](../../1-teoria/03-ansible.md#idempotencia-describir-el-estado-no-los-pasos).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-ssh-en-scripts/README.md) y los pasos 1 y 2 del [lab 05](../lab-05-ansible-ad-hoc/README.md) (`~/w/ansible` con `hosts.ini` y `ansible.cfg`). Abre una segunda terminal con `ssh server` y déjala abierta: vas a tocar `sshd`.

1. **El playbook.**
   ```bash
   cd ~/w/ansible
   cat > aviso.yml <<'FIN'
   - name: Aviso antes de entrar
     hosts: lab
     become: true
     tasks:
       - name: Texto del aviso
         ansible.builtin.copy:
           dest: /etc/issue.net
           content: |
             Solo personal autorizado. Las conexiones quedan registradas.
           mode: "0644"

       - name: sshd lo enseña
         ansible.builtin.copy:
           dest: /etc/ssh/sshd_config.d/90-aviso.conf
           content: |
             Banner /etc/issue.net
           mode: "0644"
           validate: /usr/sbin/sshd -t -f %s
         notify: Recargar sshd

     handlers:
       - name: Recargar sshd
         ansible.builtin.shell: kill -HUP "$(cat /run/sshd.pid)"
   FIN
   ```
   - Un *play*: para qué grupo (`hosts`), como root (`become`) y una lista de tareas, en orden.
   - `copy` con `content`: el archivo debe quedar **con este contenido y estos permisos**. No dice «copia»; dice cómo debe estar.
   - `validate`: antes de poner el archivo en su sitio, Ansible lo deja en un temporal y ejecuta `sshd -t -f TEMPORAL`. Si falla, no lo instala.
   - `notify`: si esta tarea cambia algo, al final se ejecuta el handler `Recargar sshd`. Una vez, aunque avisen varias tareas.

2. **La primera ejecución.**
   ```bash
   ansible-playbook aviso.yml
   ```
   ```
   PLAY [Aviso antes de entrar] ***************************************************
   TASK [Gathering Facts] *********************************************************
   ok: [server]
   ok: [bastion]
   TASK [Texto del aviso] *********************************************************
   changed: [server]
   changed: [bastion]
   TASK [sshd lo enseña] **********************************************************
   changed: [server]
   changed: [bastion]
   RUNNING HANDLER [Recargar sshd] ************************************************
   changed: [server]
   changed: [bastion]
   PLAY RECAP *********************************************************************
   bastion                    : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
   server                     : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
   ```
   ```bash
   ssh server true
   ```
   ```
   Solo personal autorizado. Las conexiones quedan registradas.
   ```

3. **La segunda: nada que hacer.**
   ```bash
   ansible-playbook aviso.yml | tail -3
   ```
   ```
   bastion                    : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
   server                     : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
   ```
   `changed=0` y el handler no se ejecuta: `sshd` no se recarga si su configuración no cambió. Es la **idempotencia**: el playbook se puede lanzar cuantas veces quieras (o en cada push, desde un CI).

4. **Qué cambiaría, sin cambiarlo.** Cambia el texto y pregunta antes de aplicar, solo en `server` (`-l`):
   ```bash
   sed -i "s/Solo personal autorizado./Solo personal autorizado de bc-ssh./" aviso.yml
   ansible-playbook aviso.yml --check --diff -l server | sed -n "/Texto del aviso/,/^changed/p"
   ssh server cat /etc/issue.net
   ```
   ```
   TASK [Texto del aviso] *********************************************************
   --- before: /etc/issue.net
   +++ after: /etc/issue.net
   @@ -1 +1 @@
   -Solo personal autorizado. Las conexiones quedan registradas.
   +Solo personal autorizado de bc-ssh. Las conexiones quedan registradas.

   changed: [server]
   Solo personal autorizado. Las conexiones quedan registradas.
   Solo personal autorizado. Las conexiones quedan registradas.
   ```
   `--check` no toca nada (el archivo sigue igual; sale dos veces porque `ssh server` también lo enseña como aviso); `--diff` enseña la diferencia. Antes de cualquier cambio en `sshd`: primero `--check --diff`.

5. **Una configuración rota.** Escribe mal la opción:
   ```bash
   sed -i "s#Banner /etc/issue.net#Banerr /etc/issue.net#" aviso.yml
   ansible-playbook aviso.yml -l server 2>&1 | grep -E "fatal|failed=" | cut -c1-120
   ssh server cat /etc/ssh/sshd_config.d/90-aviso.conf
   ```
   ```
   fatal: [server]: FAILED! => {"changed": false, "checksum": "93da08603e97b978ff63d133d6a4315539cdcc9f", "exit_s
   server                     : ok=2    changed=1    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
   Solo personal autorizado de bc-ssh. Las conexiones quedan registradas.
   Banner /etc/issue.net
   ```
   - El texto sí cambió (`changed=1`): esa tarea era válida.
   - `validate` falló (`failed to validate`, `Bad configuration option`) y el archivo de `sshd` siguió como estaba. Sin `validate`, el siguiente reinicio de `sshd` no arrancaría.
   - El handler no se ejecutó: un fallo para el play en ese servidor.

6. **Deja los servidores como estaban.**
   ```bash
   ansible lab -b -m command -a "rm /etc/ssh/sshd_config.d/90-aviso.conf /etc/issue.net"
   ansible lab -b -m shell -a 'kill -HUP $(cat /run/sshd.pid)'
   ```
   Lo de este paso no es idempotente (`rm` falla la segunda vez). La forma Ansible es otra tarea: `ansible.builtin.file` con `state: absent`.

## Criterios de éxito

- [ ] Explicas cada parte del playbook: play, tareas, `validate`, `notify` y handler (paso 1)
- [ ] Explicas por qué la segunda ejecución dice `changed=0` y no recarga `sshd` (paso 3)
- [ ] Usas `--check --diff` para ver un cambio antes de aplicarlo (paso 4)
- [ ] Explicas qué evitó `validate` y por qué el handler no se ejecutó (paso 5)

## Reto extra

`validate` comprueba el archivo **solo**, no la configuración completa. Instala con el playbook un `05-prueba.conf` con `PasswordAuthentication yes` en `server`: pasa `sshd -t`, pero ¿qué valor tiene después `sudo sshd -T | grep passwordauth`, si otro archivo dice `no`? (En `sshd`, el primer valor leído manda.) ¿Cómo prueba el playbook del proyecto la configuración entera ([teoría 03](../../1-teoria/03-ansible.md#cambiar-sshd-sin-quedarte-fuera))? Bórralo al terminar.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 05 — Ansible sin playbook](../lab-05-ansible-ad-hoc/README.md) | [Lab 07 — Ansible a través del bastion, y rápido](../lab-07-ansible-por-el-bastion/README.md) → |

[↑ Semana 12](../../README.md)
