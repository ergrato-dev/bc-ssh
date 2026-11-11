# Lab 01 — Un equipo nuevo

⏱ Duración estimada: ~60 min

## Objetivo

Instalar tu kit en un equipo vacío, como lo haría otra persona: copiarlo, enlazarlo, crear una llave con frase, añadir las host keys comprobadas y entrar en `server` y `bastion`. Por el camino aparece la primera trampa de integración: un master abierto con contraseña que esconde que la llave no funciona.

## Contexto

- El mapa del kit y lo que cada pieza da por hecho: [teoría 01](../../1-teoria/01-el-kit-como-sistema.md#las-dependencias-entre-piezas).
- Esta semana el cliente es **tu portátil**: un volumen de Docker (`bc-ssh-portatil`) guarda su `/home/alumno` entre un lab y el siguiente. Los labs 02 a 07 siguen donde lo deja este.
- **La contraseña `alumno` y la frase de este lab son solo del laboratorio.**

## Instrucciones

0. **Preparación.** En tu equipo, desde la raíz del repositorio: servidores recién instalados y un portátil vacío.
   ```bash
   docker compose up -d --force-recreate server bastion interno
   docker volume rm -f bc-ssh-portatil
   docker compose run --rm -v bc-ssh-portatil:/home/alumno client
   ```
   - `-v bc-ssh-portatil:/home/alumno`: el home del cliente vive en un volumen con nombre. Al salir del contenedor (`--rm`) el volumen se queda: el siguiente `docker compose run` con el mismo `-v` encuentra tus llaves y tu kit.
   - `docker volume rm -f`: lo borra si existe, para empezar de cero.

1. **Copiar el kit y enlazarlo.** Tu kit es el `starter` de esta semana (o tu propio repositorio, si lo llevas aparte: clónalo en su lugar).
   ```bash
   cp -r /bc-ssh/bootcamp/week-14-proyecto_integrador_ssh_infra_kit/3-proyecto/starter ~/ssh-infra-kit
   cd ~/ssh-infra-kit
   bin/kit-link
   ssh -G -F config lab-server | grep '^hostname '
   ```
   ```
   kit-link: /home/alumno/.ssh/kit -> /home/alumno/ssh-infra-kit
   hostname server
   ```
   `hostname server` dice que el `Include kit/conf.d/*.conf` encontró los alias. Si dijera `hostname lab-server`, el enlace falta y ssh no avisa (teoría 01, la primera fila de la tabla).

2. **La primera conexión, sin nada.**
   ```bash
   ssh -F config lab-server true
   ```
   ```
   No ED25519 host key is known for server and you have requested strict checking.
   Host key verification failed.
   ```
   Es `StrictHostKeyChecking yes` haciendo su trabajo: el kit no acepta una host key que no comprobaste.

3. **Tu llave, con frase.**
   ```bash
   bin/key-new lab
   eval "$(bin/agent-up)"
   ```
   ```
   Enter passphrase (empty for no passphrase):
   Enter same passphrase again:
   /home/alumno/.ssh/lab creada
   256 SHA256:qsz1RGp6pFxgfB1c+yXv77etbjfMJ8rIo27W4HFL19Y alumno@client-2026-11-11 (ED25519)
   agent-up: agente nuevo en /home/alumno/.ssh/agent.sock
   ```
   Escribe una frase (en el laboratorio, la que quieras; en tu equipo, una larga de verdad). El agente queda listo, vacío: la llave entra en él la primera vez que la uses (`AddKeysToAgent 1h` de `config`).

4. **Las host keys, comprobadas.** La huella sale de la consola del servidor, **no** de la red. En **otra terminal de tu equipo**:
   ```bash
   docker compose exec server ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
   docker compose exec bastion ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
   ```
   ```
   256 SHA256:y13qRoFqGi/RTuf7J9ygDa2Gr00LPH/LBZfGDDfPbpU root@server (ED25519)
   256 SHA256:gjjY8i0REngZvNsQHXrQ7Gk7BSZahKFjLnK5vw75ohM root@bastion (ED25519)
   ```
   En el cliente, con **tus** huellas (las de arriba son de otro laboratorio):
   ```bash
   bin/kh-add server SHA256:y13qRoFqGi/RTuf7J9ygDa2Gr00LPH/LBZfGDDfPbpU
   bin/kh-add bastion SHA256:gjjY8i0REngZvNsQHXrQ7Gk7BSZahKFjLnK5vw75ohM
   ```
   ```
   server añadida SHA256:y13qRoFqGi/RTuf7J9ygDa2Gr00LPH/LBZfGDDfPbpU
   bastion añadida SHA256:gjjY8i0REngZvNsQHXrQ7Gk7BSZahKFjLnK5vw75ohM
   ```

5. **La trampa: un master con contraseña.** Instala tu llave en `server` con la configuración del kit:
   ```bash
   export SSHPASS=alumno
   sshpass -e ssh-copy-id -F config -i ~/.ssh/lab lab-server 2>&1 | grep 'Number of'
   bin/mux list
   ssh -F config lab-server hostname
   bin/doctor lab-server
   ```
   ```
   Number of key(s) added: 1
   activo    pid=92    /home/alumno/.ssh/cm/e02bc41ef904cf7479525f22b4660ffc0adc7c8c
   server
   destino:  alumno@server:22
   error:    alumno@server: Permission denied (publickey,password).
   pista:    el servidor no aceptó la llave: mira qué llaves se ofrecieron (ssh -v, 'Offering') y la razón en el log del servidor (sudo sshd -d en otro puerto)
   ```
   - `ssh-copy-id` usó `config`, y `config` tiene `ControlMaster auto` con `ControlPersist 10m`: dejó un **master abierto, autenticado con la contraseña**.
   - `ssh lab-server hostname` entró por ese master: **no probó tu llave** y ni siquiera te pidió la frase. Parece que todo funciona.
   - `bin/doctor` abre siempre una conexión nueva (`ControlPath=none`) con `BatchMode`: no puede escribir tu frase, y la llave no está en el agente. Por eso falla. Así fallarían también Ansible y el CI.
   - Dos piezas correctas (el multiplexing de la semana 05 y `ssh-copy-id` de la 03) que juntas engañan. Ciérralo:
   ```bash
   bin/mux stop
   ```
   ```
   cerrado   /home/alumno/.ssh/cm/e02bc41ef904cf7479525f22b4660ffc0adc7c8c
   ```

6. **Bien hecho: sin master.** En `bastion`, `-o ControlPath=none` evita el master:
   ```bash
   sshpass -e ssh-copy-id -F config -o ControlPath=none -i ~/.ssh/lab lab-bastion 2>&1 | grep 'Number of'
   unset SSHPASS
   ssh -F config lab-bastion hostname
   ssh -F config lab-server hostname
   ssh-add -l
   ```
   ```
   Number of key(s) added: 1
   Enter passphrase for key '/home/alumno/.ssh/lab':
   bastion
   server
   256 SHA256:qsz1RGp6pFxgfB1c+yXv77etbjfMJ8rIo27W4HFL19Y alumno@client-2026-11-11 (ED25519)
   ```
   La primera conexión pide la frase (es la prueba de que se usa la llave) y la deja en el agente durante 1 h; la segunda ya no la pide. `unset SSHPASS`: la contraseña no se queda en el entorno.

7. **El diagnóstico completo.**
   ```bash
   bin/doctor lab-server; echo "código $?"
   bin/doctor lab-bastion | grep -E 'kex|entrada'
   ```
   ```
   destino:  alumno@server:22
   kex:      sntrup761x25519-sha512@openssh.com (postcuántico)
   host key: ssh-ed25519 SHA256:y13qRoFqGi/RTuf7J9ygDa2Gr00LPH/LBZfGDDfPbpU
   cifrado:  chacha20-poly1305@openssh.com
   entrada:  publickey
   código 0
   kex:      sntrup761x25519-sha512@openssh.com (postcuántico)
   entrada:  publickey
   ```
   La `host key` es la huella que comprobaste en el paso 4, y la `entrada` es la llave. Este es el estado bueno de un equipo nuevo.

8. **Sin `-F config`.** Para que `ssh`, `scp` y `git` usen el kit sin escribirlo cada vez:
   ```bash
   echo 'Include kit/config' > ~/.ssh/config
   ssh lab-bastion hostname
   (cd ~/.ssh && stat -c '%A %N' *)
   ```
   ```
   bastion
   srw------- 'agent.sock'
   drwx------ 'cm'
   -rw-r--r-- 'config'
   lrwxrwxrwx 'kit' -> '/home/alumno/ssh-infra-kit'
   -rw------- 'known_hosts'
   -rw------- 'known_hosts.old'
   -rw------- 'lab'
   -rw-r--r-- 'lab.pub'
   ```
   `stat -c '%A %N'`: los permisos y el nombre (y a dónde apunta, si es un enlace).
   Lo privado (`lab`, `known_hosts`, el socket del agente, `cm/`) solo es tuyo; `kit` es el enlace al repositorio. Nada de esto está **dentro** del repositorio.

## Criterios de éxito

- [ ] El kit instalado en un home vacío, con `hostname server` en `ssh -G` (paso 1)
- [ ] Las host keys añadidas solo con la huella de la consola (paso 4)
- [ ] Explicas por qué `ssh lab-server` entraba y `bin/doctor` no, en el paso 5
- [ ] Tu llave con frase, en el agente, y `bin/doctor` con `entrada: publickey` en los dos servidores (pasos 6 y 7)
- [ ] `~/.ssh/config` con `Include kit/config` (paso 8)

## Reto extra

El paso 5 es un fallo de integración que nadie había visto en trece semanas. ¿Dónde lo arreglarías: en el README ("Instalar el kit en un equipo"), en el RUNBOOK, en `config` (un `Host` para `ssh-copy-id` no existe...) o en un script nuevo `bin/key-install` que llame a `ssh-copy-id` con `ControlPath=none`? Defiende tu opción con su Qué / Para qué / Impacto.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Índice de labs](../README.md) | [Lab 02 — Un servidor nuevo](../lab-02-un-servidor-nuevo/README.md) → |

[↑ Semana 14](../../README.md)
