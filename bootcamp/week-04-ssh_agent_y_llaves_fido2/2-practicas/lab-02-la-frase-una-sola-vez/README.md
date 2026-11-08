# Lab 02 — La frase una sola vez

⏱ Duración estimada: ~60 min

## Objetivo

Que la primera conexión cargue la llave en el agente (`AddKeysToAgent`), ponerle caducidad, bloquear el agente y conectarte sin usarlo cuando lo necesites.

## Contexto

- `AddKeysToAgent`, caducidad y bloqueo: [teoría 01](../../1-teoria/01-ssh-agent.md#addkeystoagent-cargar-al-usar).
- **La contraseña `alumno` es solo del laboratorio.**
- Trabajas con `starter/config`; `solucion/config` es la referencia.

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d --force-recreate server
   docker compose run --rm client
   ```
   **En el cliente**, una llave con frase instalada en `server` y un agente vacío (como en el lab 01):
   ```bash
   cd bootcamp/week-04-ssh_agent_y_llaves_fido2/2-practicas/lab-02-la-frase-una-sola-vez
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh
   ssh-keyscan -t ed25519 server 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -C alumno@client -f ~/.ssh/id_ed25519
   sshpass -e ssh-copy-id -f -i ~/.ssh/id_ed25519.pub server
   eval "$(ssh-agent)"
   ```

1. **Un agente que nadie llena:**
   ```bash
   ssh -F starter/config server hostname
   ssh-add -l
   ```
   ```
   Enter passphrase for key '/home/alumno/.ssh/id_ed25519':
   server
   The agent has no identities.
   ```
   Tener un agente no basta: `ssh` descifró la llave para esta conexión y la olvidó.

2. **TODO de `starter/config`:** añade `AddKeysToAgent 1h` en el bloque `server`. Comprueba cómo lo lee `ssh`:
   ```bash
   ssh -G -F starter/config server | grep addkeys
   ```
   ```
   addkeystoagent 3600
   ```
   `ssh -G` muestra la configuración final sin conectar. `1h` se guarda en segundos.

3. **La primera conexión carga la llave:**
   ```bash
   ssh -F starter/config server hostname
   ssh-add -l
   ssh -F starter/config server hostname
   ```
   ```
   Enter passphrase for key '/home/alumno/.ssh/id_ed25519':
   server
   256 SHA256:u1TusCd76hE/9mo7SUnXI8QCZ+nD9nq7xB1DCUz7X1E alumno@client (ED25519)
   server
   ```
   Frase en la primera conexión y nunca más, hasta que pase la hora.

4. **Caducidad a mano:**
   ```bash
   ssh-add -D
   ssh-add -t 30 ~/.ssh/id_ed25519
   ssh-add -l | wc -l
   sleep 31; ssh-add -l
   ```
   ```
   All identities removed.
   Enter passphrase for /home/alumno/.ssh/id_ed25519:
   Identity added: /home/alumno/.ssh/id_ed25519 (alumno@client)
   Lifetime set to 30 seconds
   1
   The agent has no identities.
   ```
   - `ssh-add -D` vacía el agente.
   - `-t 30`: el agente borra la llave a los 30 segundos. Acepta también `30m`, `1h` o `1d`.
   - `wc -l` cuenta líneas: una llave.

5. **Bloquear el agente.** Carga la llave otra vez con una conexión y bloquéalo:
   ```bash
   ssh -F starter/config server hostname
   ssh-add -x
   ssh-add -l
   ```
   ```
   Enter passphrase for key '/home/alumno/.ssh/id_ed25519':
   server
   Enter lock password:
   Again:
   Agent locked.
   The agent has no identities.
   ```
   La contraseña de bloqueo la eliges ahora; no tiene relación con la frase de la llave. Bloqueado, el agente no lista ni firma, pero conserva la llave. Desbloquéalo:
   ```bash
   ssh-add -X
   ssh-add -l
   ```
   ```
   Enter lock password:
   Agent unlocked.
   256 SHA256:u1TusCd76hE/9mo7SUnXI8QCZ+nD9nq7xB1DCUz7X1E alumno@client (ED25519)
   ```

6. **Una conexión sin agente:**
   ```bash
   ssh -F starter/config -o IdentityAgent=none server hostname
   ```
   ```
   Enter passphrase for key '/home/alumno/.ssh/id_ed25519':
   server
   ```
   El agente tiene la llave, pero esta conexión lo ignora. Útil para comprobar que una configuración funciona **sin** depender de lo que haya cargado.

7. **Caducidad para todas las llaves.** En lugar de recordar `-t` en cada `ssh-add`, se fija al arrancar el agente:
   ```bash
   eval "$(ssh-agent -k)"
   eval "$(ssh-agent -t 1h)"
   ```
   ```
   Agent pid 13 killed
   Agent pid 41
   ```
   Desde ahora, cada llave que entre (con `ssh-add` o con `AddKeysToAgent`) caduca en una hora como máximo. Tu `bin/agent-up` del proyecto arranca el agente así.

## Criterios de éxito

- [ ] `starter/config` con `AddKeysToAgent 1h` y `ssh -G` muestra `addkeystoagent 3600` (paso 2)
- [ ] La frase se pide en la primera conexión y no en la segunda (paso 3)
- [ ] Viste caducar una llave (paso 4) y bloqueaste y desbloqueaste el agente (paso 5)
- [ ] Explicas para qué sirve `IdentityAgent=none` (paso 6)

## Reto extra

Cambia `AddKeysToAgent 1h` por `AddKeysToAgent confirm`, vacía el agente con `ssh-add -D` y conéctate dos veces. La primera conexión funciona y carga la llave, pero marcada para confirmar cada uso. Lee lo que imprime `ssh` en la segunda y busca en la [teoría 02](../../1-teoria/02-agent-forwarding-y-riesgos.md#ssh-add--c-confirmar-cada-firma) qué le falta al agente para poder preguntarte. (Lo construirás en el lab 06.)

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 01 — Arrancar el agente](../lab-01-arrancar-el-agente/README.md) | [Lab 03 — Un agente para todas las terminales](../lab-03-un-agente-para-todas-las-terminales/README.md) → |

[↑ Semana 04](../../README.md)
