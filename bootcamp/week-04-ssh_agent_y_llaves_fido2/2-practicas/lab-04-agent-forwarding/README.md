# Lab 04 — Agent forwarding

⏱ Duración estimada: ~60 min

## Objetivo

Saltar de `server` a `bastion` con tu llave sin copiarla a `server`, ver el socket que crea el forwarding y cuánto dura, activarlo solo para un host en `config` y comprobar que el servidor puede negarlo.

## Contexto

- Cómo funciona el forwarding y **su riesgo**: [teoría 02](../../1-teoria/02-agent-forwarding-y-riesgos.md). Léela antes del lab.
- **La contraseña `alumno` es solo del laboratorio.** La usas en el paso 0 para instalar la llave.
- Trabajas con `starter/config`; `solucion/config` es la referencia.

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d --force-recreate server bastion
   docker compose run --rm client
   ```
   **En el cliente**, la llave `~/.ssh/lab` instalada en los dos servidores, `bastion` en el `known_hosts` de `server` y la llave en el agente:
   ```bash
   cd bootcamp/week-04-ssh_agent_y_llaves_fido2/2-practicas/lab-04-agent-forwarding
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh
   ssh-keyscan -t ed25519 server bastion 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/lab
   for h in server bastion; do sshpass -e ssh-copy-id -f -i ~/.ssh/lab.pub $h; done
   ssh -i ~/.ssh/lab server 'ssh-keyscan -t ed25519 bastion 2>/dev/null > ~/.ssh/known_hosts'
   eval "$(ssh-agent)"
   ssh-add ~/.ssh/lab
   ```
   El `ssh-keyscan` que se ejecuta en `server` prepara el `known_hosts` **de `server`** (verificar huellas fue la semana 02).

1. **Sin forwarding, `server` no tiene tu llave:**
   ```bash
   ssh -F starter/config server 'ssh -o BatchMode=yes bastion hostname'; echo "código: $?"
   ```
   ```
   alumno@bastion: Permission denied (publickey,password).
   código: 255
   ```
   El segundo `ssh` corre **en `server`**, donde no hay ninguna llave. `BatchMode=yes` evita que pida la contraseña.

2. **Ni agente:**
   ```bash
   ssh -F starter/config server 'echo "SSH_AUTH_SOCK=[$SSH_AUTH_SOCK]"; ssh-add -l'
   ```
   ```
   SSH_AUTH_SOCK=[]
   Could not open a connection to your authentication agent.
   ```
   Las comillas simples hacen que `$SSH_AUTH_SOCK` se expanda en `server`, no en el cliente.

3. **Con `-A`:**
   ```bash
   ssh -F starter/config -A server 'echo "SSH_AUTH_SOCK=[$SSH_AUTH_SOCK]"; ssh-add -l; ls -ld $(dirname $SSH_AUTH_SOCK); ssh bastion hostname'
   ```
   ```
   SSH_AUTH_SOCK=[/tmp/ssh-X5a5UC12Cq/agent.81]
   256 SHA256:bf9iyXK+24baQzVavrPYjAi1ln19gFk8waFqYQRgLW4 alumno@client (ED25519)
   drwx------ 2 alumno alumno 4096 Nov  8 05:54 /tmp/ssh-X5a5UC12Cq
   bastion
   ```
   - `sshd` creó en `server` un socket y definió `SSH_AUTH_SOCK`.
   - `ssh-add -l` **en `server`** lista la llave de tu cliente: la pregunta viaja por la conexión hasta tu agente.
   - El salto a `bastion` funciona. `~/.ssh/lab` no está en `server`; compruébalo con `ssh server 'ls ~/.ssh'`.

4. **El socket dura lo que la conexión:**
   ```bash
   ssh -F starter/config server 'ls -d /tmp/ssh-*'
   ```
   ```
   ls: cannot access '/tmp/ssh-*': No such file or directory
   ```
   Al cerrarse la conexión del paso 3, `sshd` borró el socket. **Mientras está abierta**, cualquiera que llegue a ese socket en `server` (tu usuario o root de `server`) puede pedir firmas a tu agente. Repasa en la [teoría 02](../../1-teoria/02-agent-forwarding-y-riesgos.md#el-riesgo) qué puede hacer con ellas y qué no.

5. **TODO 1 y 2 de `starter/config`:** activa `ForwardAgent yes` solo en `Host server` y escribe `ForwardAgent no` en `Host *`. Compruébalo sin conectar:
   ```bash
   for h in server bastion; do ssh -G -F starter/config $h | grep forwardagent; done
   ssh -F starter/config server 'ssh bastion hostname'
   ```
   ```
   forwardagent yes
   forwardagent no
   bastion
   ```
   `ssh` usa el primer valor que encuentra para cada opción: el bloque `server` va antes que `Host *`. Ya no necesitas `-A`.

6. **El servidor también decide.** Añade `restrict,pty` delante de tu llave en el `authorized_keys` de `server` (semana 03):
   ```bash
   ssh -F starter/config server 'sed -i "s/^/restrict,pty /" ~/.ssh/authorized_keys'
   ssh -F starter/config server 'echo "SSH_AUTH_SOCK=[$SSH_AUTH_SOCK]"'
   ```
   ```
   SSH_AUTH_SOCK=[]
   ```
   - `sed -i "s/^/restrict,pty /"` escribe ese texto al principio de cada línea.
   - Tu `config` pide el forwarding, pero `restrict` lo desactiva para esa llave, sin error.

   Permítelo solo a esa llave con `agent-forwarding`:
   ```bash
   ssh -F starter/config server 'sed -i "s/^restrict,pty /restrict,pty,agent-forwarding /" ~/.ssh/authorized_keys'
   ssh -F starter/config server 'echo "SSH_AUTH_SOCK=[$SSH_AUTH_SOCK]"; ssh bastion hostname'
   ```
   ```
   SSH_AUTH_SOCK=[/tmp/ssh-66ImsmDCtJ/agent.153]
   bastion
   ```

7. **Responde en tus notas:**
   - Desde `server` saltaste a `bastion`. ¿Quién, además de ti, podía usar tu agente durante el paso 3?
   - ¿Por qué el valor por defecto de tu kit es `ForwardAgent no`?
   - ¿Qué dos medidas de la teoría 02 limitarían el daño si tuvieras que reenviar hacia un servidor en el que no confías del todo? (Las practicas en los labs 05 y 06.)

## Criterios de éxito

- [ ] Explicas por qué el salto falla sin `-A` y funciona con él (pasos 1 y 3)
- [ ] Viste el socket en `server` y comprobaste que desaparece al cerrar (pasos 3 y 4)
- [ ] `starter/config` reenvía solo a `server` (paso 5)
- [ ] Comprobaste que `restrict` niega el forwarding y `agent-forwarding` lo devuelve (paso 6)
- [ ] Respondiste las preguntas del paso 7

## Reto extra

Haz el mismo salto sin forwarding: `ssh -J server bastion hostname` (`-J` es `ProxyJump`). Compara con `ssh -v` en qué equipo se hace la firma para `bastion` en cada caso (busca `Offering public key` y quién la imprime). Lo verás a fondo en la semana 09.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 03 — Un agente para todas las terminales](../lab-03-un-agente-para-todas-las-terminales/README.md) | [Lab 05 — Restringir destinos con `ssh-add -h`](../lab-05-restringir-destinos/README.md) → |

[↑ Semana 04](../../README.md)
