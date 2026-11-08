# Lab 03 — Un agente para todas las terminales

⏱ Duración estimada: ~60 min

## Objetivo

Ver por qué cada terminal nueva se queda sin agente, usar un socket con ruta fija para compartir uno solo, provocar el socket huérfano que deja un agente muerto y escribir `agente-vivo.sh`, que distingue los tres estados. Es la base de `bin/agent-up` del proyecto.

## Contexto

- Variables de entorno, `SSH_AUTH_SOCK` y los códigos de `ssh-add -l`: [teoría 01](../../1-teoria/01-ssh-agent.md#arrancarlo).
- Este lab no toca ningún servidor.
- "Otra terminal" se simula con `env -u SSH_AUTH_SOCK bash -c '...'`: una shell sin la variable, como la que abres desde tu escritorio. `env -u VAR` ejecuta un comando sin esa variable.

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose run --rm client
   ```
   **En el cliente:**
   ```bash
   cd bootcamp/week-04-ssh_agent_y_llaves_fido2/2-practicas/lab-03-un-agente-para-todas-las-terminales
   mkdir -p -m 700 ~/.ssh
   ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/id_ed25519
   ```
   Sin frase, para ir rápido: en este lab importa el agente, no la llave.

1. **Un agente en esta terminal:**
   ```bash
   eval "$(ssh-agent)"
   ssh-add
   ```
   ```
   Agent pid 10
   Identity added: /home/alumno/.ssh/id_ed25519 (alumno@client)
   ```

2. **La otra terminal no lo ve:**
   ```bash
   env -u SSH_AUTH_SOCK bash -c 'ssh-add -l'
   ```
   ```
   Could not open a connection to your authentication agent.
   ```
   El agente existe, pero su ruta (`/tmp/ssh-XXXX/agent.N`) es aleatoria y solo la conoce la shell que hizo `eval`. Si en cada terminal ejecutas `eval "$(ssh-agent)"`, acabas con varios agentes, cada uno con sus llaves, y ninguno se cierra solo.

3. **Un socket con ruta fija.** `ssh-agent -a RUTA` escucha donde le digas:
   ```bash
   eval "$(ssh-agent -k)"
   eval "$(ssh-agent -a ~/.ssh/agent.sock)"
   echo "$SSH_AUTH_SOCK"
   ssh-add
   ```
   ```
   Agent pid 10 killed
   Agent pid 15
   /home/alumno/.ssh/agent.sock
   Identity added: /home/alumno/.ssh/id_ed25519 (alumno@client)
   ```
   Dentro de `~/.ssh` (700): solo tu usuario llega al socket.

4. **La otra terminal, con la ruta conocida:**
   ```bash
   env -u SSH_AUTH_SOCK bash -c 'SSH_AUTH_SOCK=~/.ssh/agent.sock ssh-add -l'
   ```
   ```
   256 SHA256:YTMNqk1E2l8lAin3qdEZxtoUrlg20WMwafHbXUjsHGs alumno@client (ED25519)
   ```
   Con `export SSH_AUTH_SOCK=~/.ssh/agent.sock` en tu `~/.bashrc`, cada terminal nueva usa el mismo agente.

5. **TODO de `starter/agente-vivo.sh`.** El script ya ejecuta `ssh-add -l` contra el socket y guarda el código en `rc`. Completa el `case` siguiendo el comentario del TODO. Pruébalo con los tres estados:
   ```bash
   starter/agente-vivo.sh; echo "código: $?"
   ssh-add -D
   starter/agente-vivo.sh; echo "código: $?"
   starter/agente-vivo.sh /tmp/nada.sock; echo "código: $?"
   ```
   ```
   con llaves: /home/alumno/.ssh/agent.sock
   código: 0
   All identities removed.
   vacío: /home/alumno/.ssh/agent.sock
   código: 1
   sin agente: /tmp/nada.sock
   código: 2
   ```
   El script devuelve los mismos códigos que `ssh-add -l`: quien lo use en un `if` no necesita leer el texto.

6. **El socket huérfano.** Simula que el agente muere sin limpiar (un `kill -9`, un apagón):
   ```bash
   pkill -9 ssh-agent
   starter/agente-vivo.sh; echo "código: $?"
   ssh-agent -a ~/.ssh/agent.sock; echo "código: $?"
   ```
   ```
   sin agente: /home/alumno/.ssh/agent.sock (socket huérfano)
   código: 2
   unix_listener: cannot bind to path /home/alumno/.ssh/agent.sock: Address already in use
   código: 1
   ```
   - `kill -9` no deja al agente borrar su socket; con un `kill` normal (o `ssh-agent -k`) sí lo borra.
   - El archivo sigue ahí sin nadie detrás, y `ssh-agent -a` se niega a usar una ruta ocupada.

7. **Recuperarse:**
   ```bash
   rm ~/.ssh/agent.sock
   eval "$(ssh-agent -a ~/.ssh/agent.sock)"
   starter/agente-vivo.sh; echo "código: $?"
   ```
   ```
   Agent pid 32
   vacío: /home/alumno/.ssh/agent.sock
   código: 1
   ```
   Borrar el socket solo es seguro cuando `agente-vivo.sh` dice que no hay agente: si lo hubiera, lo dejarías sin nadie que pudiera llegar a él.

## Criterios de éxito

- [ ] Explicas por qué una terminal nueva no ve el agente (paso 2)
- [ ] Dos "terminales" usan el mismo agente por su ruta fija (paso 4)
- [ ] `starter/agente-vivo.sh` devuelve 0, 1 y 2 en los tres estados (paso 5) y detecta el socket huérfano (paso 6)
- [ ] Explicas cuándo es seguro borrar el socket (paso 7)

## Reto extra

Escribe en un archivo `agente.sh` los pasos 6 y 7 como una función: si `agente-vivo.sh ~/.ssh/agent.sock` sale con 0 o 1, solo exporta la variable; si sale con 2, borra el socket huérfano (si existe), arranca el agente y exporta la variable. Cárgala con `source agente.sh` y pruébala dos veces seguidas: la segunda no debe arrancar otro agente (`pgrep -c ssh-agent`). Es, casi línea por línea, el `bin/agent-up` del proyecto.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 02 — La frase una sola vez](../lab-02-la-frase-una-sola-vez/README.md) | [Lab 04 — Agent forwarding](../lab-04-agent-forwarding/README.md) → |

[↑ Semana 04](../../README.md)
