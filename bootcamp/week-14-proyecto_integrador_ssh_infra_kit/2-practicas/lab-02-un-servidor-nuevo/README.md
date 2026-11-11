# Lab 02 — Un servidor nuevo

⏱ Duración estimada: ~60 min

## Objetivo

Llevar `server` y `bastion`, recién instalados, a la configuración del repositorio solo con el kit: el playbook en modo prueba, aplicado y repetido hasta que no cambia nada, y después `bin/audit` y `bin/doctor` para comprobar que el resultado es el que dice el repositorio.

## Contexto

- Es el procedimiento "Un servidor nuevo" del RUNBOOK del kit (lo escribes en el [proyecto](../../3-proyecto/README.md)); el alias, la host key y la llave ya los hiciste en el [lab 01](../lab-01-un-equipo-nuevo/README.md).
- El playbook `ansible/servidores.yml` es el de la [semana 12](../../../week-12-automatizacion_scripting_ci_cd_y_ansible/README.md); la configuración que instala, la de las semanas 07 a 13.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación.** Tu portátil del lab 01, en tu equipo:
   ```bash
   docker compose run --rm -v bc-ssh-portatil:/home/alumno client
   ```
   En el cliente: el agente de un contenedor anterior ya no existe, así que arranca otro y carga la llave (te pide la frase):
   ```bash
   cd ~/ssh-infra-kit
   eval "$(bin/agent-up)"
   ssh-add ~/.ssh/lab
   ```
   ```
   agent-up: agente nuevo en /home/alumno/.ssh/agent.sock
   Enter passphrase for /home/alumno/.ssh/lab:
   Identity added: /home/alumno/.ssh/lab (alumno@client-2026-11-11)
   ```
   Repite este paso 0 al principio de cada lab de esta semana.

1. **Cómo viene un servidor.** En otra terminal de tu equipo, la configuración efectiva de `interno`, que nadie ha tocado (es la misma imagen):
   ```bash
   docker compose exec interno sshd -T | grep -E '^(passwordauthentication|permitrootlogin|maxauthtries|allowgroups) '
   ```
   ```
   maxauthtries 6
   permitrootlogin no
   passwordauthentication yes
   ```
   Contraseñas aceptadas, 6 intentos por conexión y ningún `AllowGroups`: cualquier cuenta con contraseña entra. Así están ahora `server` y `bastion`.

2. **¿Entra Ansible?** Desde `ansible/`, donde Ansible lee `ansible.cfg`:
   ```bash
   cd ansible
   ansible servidores -m ping -o 2>/dev/null
   ```
   ```
   lab-server | SUCCESS => {"changed": false,"ping": "pong"}
   lab-bastion | SUCCESS => {"changed": false,"ping": "pong"}
   ```
   Ansible usa los mismos alias, la misma llave del agente y el mismo `known_hosts` que tú: lo que hiciste en el lab 01 es lo que necesita. `-o`, una línea por host; `2>/dev/null` esconde avisos de versiones futuras de Ansible.

3. **Qué cambiaría, sin tocar nada.**
   ```bash
   ansible-playbook servidores.yml --check --diff | grep -A3 'PLAY RECAP' | grep ^lab
   ```
   ```
   lab-bastion                : ok=11   changed=7    unreachable=0    failed=0    skipped=3    rescued=0    ignored=1
   lab-server                 : ok=11   changed=7    unreachable=0    failed=0    skipped=3    rescued=0    ignored=1
   ```
   - `changed=7`: siete tareas cambiarían algo en cada servidor. Quita el `grep` para ver los cambios (`--diff`).
   - `ignored=1`: en modo prueba el grupo `ssh-users` no se crea de verdad, así que la tarea que mete en él a quien despliega falla y se ignora (semana 12).
   - `skipped=3`: las recargas, que en modo prueba no se hacen.

4. **Aplicarlo, y otra vez.**
   ```bash
   ansible-playbook servidores.yml | grep -A3 'PLAY RECAP' | grep ^lab
   ansible-playbook servidores.yml | grep -A3 'PLAY RECAP' | grep ^lab
   ```
   ```
   lab-bastion                : ok=14   changed=10   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
   lab-server                 : ok=14   changed=10   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
   lab-bastion                : ok=11   changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
   lab-server                 : ok=11   changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
   ```
   - La primera vez cambia 10 cosas por servidor: grupos, `sshd_config.d`, PAM, fail2ban, la KRL y las recargas. Quita además `10-bc-ssh.conf`, la configuración de fábrica del laboratorio, porque no es del kit.
   - La segunda, **`changed=0`**: el servidor ya está como dice el repositorio. Es la prueba de que el playbook es idempotente, y de que nadie ha cambiado nada a mano después.

5. **Comprobar lo que quedó.**
   ```bash
   cd ..
   ssh lab-server 'sudo sshd -T | grep -E "^(passwordauthentication|permitrootlogin|maxauthtries|allowgroups) "'
   ssh lab-server id
   ```
   ```
   Could not load host certificate "/etc/ssh/ssh_host_ed25519_key-cert.pub": No such file or directory
   maxauthtries 3
   permitrootlogin no
   passwordauthentication no
   allowgroups ssh-users
   allowgroups sftp-only
   allowgroups saltadores
   uid=1000(alumno) gid=1000(alumno) groups=1000(alumno),4(adm),20(dialout),24(cdrom),25(floppy),27(sudo),29(audio),30(dip),44(video),46(plugdev),1001(ssh-users)
   ```
   - Solo llaves, 3 intentos y solo tres grupos. `alumno` entra porque el playbook lo metió en `ssh-users`: sin esa tarea, el propio despliegue te dejaría fuera.
   - El aviso del certificado de host: `50-ca.conf` lo nombra, pero la CA no ha firmado todavía la host key de `server`. Es lo primero del [lab 03](../lab-03-alta-con-certificado/README.md). No impide entrar.

6. **Auditar y diagnosticar.**
   ```bash
   bin/audit lab-server lab-bastion; echo "código $?"
   bin/mux stop >/dev/null
   bin/doctor lab-server | grep -E 'kex|entrada'
   ```
   ```
   lab-server: cumple
   lab-bastion: cumple
   código 0
   kex:      sntrup761x25519-sha512@openssh.com (postcuántico)
   entrada:  publickey
   ```
   `bin/audit` mira desde fuera lo que el servidor ofrece (semana 11), y `bin/doctor` una conexión real (semana 13). Las dos cosas dicen lo mismo que el repositorio.

## Criterios de éxito

- [ ] Explicas cómo viene un servidor sin el kit y qué cuentas pueden entrar (paso 1)
- [ ] Lees un `--check` y explicas `ignored=1` y `skipped=3` (paso 3)
- [ ] Aplicas el playbook y una segunda ejecución da `changed=0` en los dos servidores (paso 4)
- [ ] Compruebas el resultado con `sshd -T`, `bin/audit` (`cumple`) y `bin/doctor` (`postcuántico`) (pasos 5 y 6)

## Reto extra

Cambia algo a mano en `server` (`ssh lab-server 'echo "MaxAuthTries 6" | sudo tee /etc/ssh/sshd_config.d/99-mano.conf'`) y repite el playbook con `--check --diff`. ¿Lo detecta? ¿Lo deshace sin `--check`? ¿Qué tarea lo hace, y por qué es importante que la configuración de un servidor solo cambie desde el repositorio?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 01 — Un equipo nuevo](../lab-01-un-equipo-nuevo/README.md) | [Lab 03 — Alta con certificado](../lab-03-alta-con-certificado/README.md) → |

[↑ Semana 14](../../README.md)
