# Lab 05 — Agente reenviado frente a ProxyJump

⏱ Duración estimada: ~60 min

## Objetivo

Comprobar en el laboratorio el riesgo que la semana 04 contó en teoría: con `ssh -A`, `root` en el bastion entra con tus llaves donde quiera mientras estás conectado. Ver que con `-J` no hay nada que robar, limitar el agente con `ssh-add -h` cuando de verdad lo necesitas, y desactivarlo en el servidor.

## Contexto

- El agente y su reenvío: semana 04, [teoría 02](../../../week-04-ssh_agent_y_llaves_fido2/1-teoria/02-agent-forwarding-y-riesgos.md).
- Agente frente a `ProxyJump`: [teoría 03](../../1-teoria/03-endurecer-el-bastion.md#nunca-el-agente-reenviado).
- En el laboratorio, `alumno` tiene `sudo` sin contraseña en todos los servidores, así que **tú haces de `root` malicioso** en el bastion. **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-red-segmentada/README.md). Después, carga tu llave en un agente (semana 04):
   ```bash
   eval "$(ssh-agent)"
   ssh-add ~/.ssh/id_ed25519
   ```
   ```
   Agent pid 293
   Identity added: /home/alumno/.ssh/id_ed25519 (alumno@client)
   ```

1. **Lo que el agente reenviado permite.** Desde el bastion, intenta entrar en `interno` sin y con `-A`:
   ```bash
   ssh bastion 'echo "agente: ${SSH_AUTH_SOCK:-ninguno}"; ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new interno hostname'
   ssh -A bastion 'echo "agente: $SSH_AUTH_SOCK"; ssh-add -l; ssh interno hostname'
   ```
   ```
   agente: ninguno
   Warning: Permanently added 'interno' (ED25519) to the list of known hosts.
   alumno@interno: Permission denied (publickey,password).
   agente: /tmp/ssh-W8cVRNJU4R/agent.492
   256 SHA256:KvVs7zr36e/wM7pG/vWX6BgGZ3mJhXKZnHvhHeNGy68 alumno@client (ED25519)
   interno
   ```
   - Sin `-A`, el `ssh` del bastion no tiene llave: no entra.
   - Con `-A`, `sshd` crea en el bastion un socket (`SSH_AUTH_SOCK`) que lleva las peticiones de firma hasta **tu** agente. `ssh-add -l` en el bastion lista **tu** llave.
   - `accept-new` deja que el bastion guarde la host key de `interno` sin preguntar: es su `known_hosts`, no el tuyo (lab 01, paso 3).

2. **`root` en el bastion usa tu agente.** Deja una sesión con `-A` abierta en segundo plano y, desde otra conexión, haz de `root`:
   ```bash
   ssh -A bastion 'sleep 30' &
   sleep 2
   ssh bastion 'sudo sh -c "ls /tmp/ssh-*/agent.*"'
   ssh bastion 'for s in /tmp/ssh-*/agent.*; do sudo SSH_AUTH_SOCK=$s ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes alumno@server hostname; done'
   ```
   ```
   /tmp/ssh-stgllyGTGU/agent.506
   Warning: Permanently added 'server' (ED25519) to the list of known hosts.
   server
   ```
   - `&`: la primera orden sigue en segundo plano, como la sesión de alguien que trabaja en el bastion.
   - `root` encuentra el socket en `/tmp`, lo usa (`SSH_AUTH_SOCK=$s`) y **entra en `server` como tú**, con una llave que nunca salió de tu equipo. Podría ser cualquier servidor donde valga tu llave, o tu GitHub.
   - Dura lo que dure tu conexión. Ciérrala:
   ```bash
   kill %1
   ```

3. **Con `-J` no hay socket.**
   ```bash
   ssh -J bastion interno 'sleep 10' &
   sleep 2
   ssh bastion 'sudo sh -c "ls /tmp/ssh-*/agent.*"'
   wait
   ```
   ```
   ls: cannot access '/tmp/ssh-*/agent.*': No such file or directory
   ```
   Estás dentro de `interno` a través del bastion, y el bastion no tiene nada tuyo: la autenticación con `interno` la hizo tu equipo. `wait` espera a que termine la orden en segundo plano.

4. **Si necesitas el agente: limítalo.** A veces sí hace falta (un `git pull` con tu llave en un servidor). `ssh-add -h` (OpenSSH 8.9+) dice **por dónde** se puede usar cada llave:
   ```bash
   ssh-add -D
   ssh-add -h bastion -h 'bastion>interno' ~/.ssh/id_ed25519
   ssh -A bastion 'ssh interno hostname'
   ssh -A bastion 'sleep 20' &
   sleep 2
   ssh bastion 'for s in /tmp/ssh-*/agent.*; do sudo SSH_AUTH_SOCK=$s ssh -o BatchMode=yes alumno@server hostname; sudo SSH_AUTH_SOCK=$s ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes alumno@interno hostname; done'
   kill %1
   ```
   ```
   All identities removed.
   Identity added: /home/alumno/.ssh/id_ed25519 (alumno@client)
   interno
   alumno@server: Permission denied (publickey,password).
   Warning: Permanently added 'interno' (ED25519) to the list of known hosts.
   interno
   ```
   - `-h bastion`: la llave vale para entrar en el bastion desde tu equipo. `-h 'bastion>interno'`: y para entrar en `interno` **desde el bastion**. Nada más.
   - `root` ya no entra en `server`: tu agente se niega a firmar ese salto. Pero en `interno` **sí**: es un camino permitido. Limita el daño, no lo elimina.
   - `ssh-add -D` vacía el agente antes, para que la llave no esté dos veces (con y sin límites).

5. **Desactivarlo en el servidor.** El kit pone `AllowAgentForwarding no` en todos los servidores desde la semana 07. Pruébalo en el bastion:
   ```bash
   R='sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   echo 'AllowAgentForwarding no' | ssh bastion "sudo tee /etc/ssh/sshd_config.d/30-agente.conf >/dev/null; $R"
   ssh -A bastion 'echo "agente: ${SSH_AUTH_SOCK:-ninguno}"'
   ssh bastion "sudo rm /etc/ssh/sshd_config.d/30-agente.conf; $R"
   eval "$(ssh-agent -k)"
   ```
   ```
   agente: ninguno
   Agent pid 293 killed
   ```
   - `R` recarga `sshd` como en la semana 07: `HUP` le hace releer su configuración sin cortar las sesiones abiertas.
   - Con `AllowAgentForwarding no`, tu `-A` conecta pero no se crea el socket. Que el cliente no lo pida (`ForwardAgent no`) y que el servidor no lo dé son dos capas: cada una protege si la otra falla.
   - `ssh-agent -k` cierra el agente del paso 0; `eval` borra sus variables de tu shell.

## Criterios de éxito

- [ ] Explicas qué crea `-A` en el bastion y quién puede usarlo (paso 1)
- [ ] Demuestras que `root` en el bastion entra en otro servidor con tu agente (paso 2)
- [ ] Explicas por qué con `-J` no hay nada que robar (paso 3)
- [ ] Limitas una llave con `ssh-add -h` y explicas lo que sigue permitido (paso 4)
- [ ] Desactivas el reenvío del agente en el servidor y explicas por qué en los dos lados (paso 5)

## Reto extra

`ssh-add -c` pide confirmación en tu equipo cada vez que alguien usa la llave a través del agente. Necesita un programa `ssh-askpass` que el laboratorio no tiene: lee `man ssh-add` y explica cuándo te salvaría en el paso 2 y por qué no es tan buena idea como `-J`.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 04 — Saltos en `ssh_config`](../lab-04-saltos-en-config/README.md) | [Lab 06 — Un bastion que solo deja saltar](../lab-06-bastion-endurecido/README.md) → |

[↑ Semana 09](../../README.md)
