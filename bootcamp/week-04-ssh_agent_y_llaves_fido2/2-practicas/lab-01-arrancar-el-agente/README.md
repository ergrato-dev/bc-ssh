# Lab 01 — Arrancar el agente

⏱ Duración estimada: ~60 min

## Objetivo

Arrancar `ssh-agent`, entender qué hace `eval`, cargar una llave con frase de paso y comprobar que `ssh` ya no la pide. Al final, detener el agente y ver qué queda.

## Contexto

- Qué es el agente y cómo habla con `ssh`: [teoría 01](../../1-teoria/01-ssh-agent.md).
- **La contraseña `alumno` es solo del laboratorio.** La usas una vez, en el paso 0, para instalar tu llave.
- El cliente es un contenedor nuevo en cada `docker compose run`: haz todo el lab en la misma sesión.

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d --force-recreate server
   docker compose run --rm client
   ```
   **En el cliente**, una llave **con frase de paso** (inventa una y recuérdala durante el lab) instalada en `server`:
   ```bash
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh
   ssh-keyscan -t ed25519 server 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -C alumno@client -f ~/.ssh/id_ed25519
   sshpass -e ssh-copy-id -f -i ~/.ssh/id_ed25519.pub server
   ```
   - `ssh-keygen` pide la frase dos veces.
   - `ssh-copy-id -f` instala la pública sin probar antes la llave (así no te pide la frase todavía). `sshpass -e` escribe la contraseña de `SSHPASS`.

1. **Sin agente, la frase en cada conexión:**
   ```bash
   ssh server hostname
   ssh server hostname
   ```
   ```
   Enter passphrase for key '/home/alumno/.ssh/id_ed25519':
   server
   Enter passphrase for key '/home/alumno/.ssh/id_ed25519':
   server
   ```
   Cada `ssh` descifra la privada desde el archivo, y para eso necesita la frase.

2. **¿Hay agente?**
   ```bash
   echo "[$SSH_AUTH_SOCK]"
   ssh-add -l; echo "código: $?"
   ```
   ```
   []
   Could not open a connection to your authentication agent.
   código: 2
   ```
   `SSH_AUTH_SOCK` vacía: ningún agente. El código 2 de `ssh-add -l` significa exactamente eso ([teoría 01](../../1-teoria/01-ssh-agent.md#ssh-add-qué-tiene-el-agente)).

3. **Lo que imprime `ssh-agent`.** Ejecútalo dentro de `echo "$( )"` para ver su salida sin aplicarla:
   ```bash
   echo "$(ssh-agent)"
   ```
   ```
   SSH_AUTH_SOCK=/tmp/ssh-nVyZhZhHLF1W/agent.10; export SSH_AUTH_SOCK;
   SSH_AGENT_PID=11; export SSH_AGENT_PID;
   echo Agent pid 11;
   ```
   Es código de shell. Ese agente ya está corriendo, pero tu shell no sabe dónde: `echo "[$SSH_AUTH_SOCK]"` sigue vacía. Mátalo para no dejarlo huérfano: `pkill ssh-agent`.

4. **Arráncalo con `eval`:**
   ```bash
   eval "$(ssh-agent)"
   echo "$SSH_AUTH_SOCK $SSH_AGENT_PID"
   ```
   ```
   Agent pid 13
   /tmp/ssh-L7VziiXCbW0Y/agent.12 13
   ```
   `eval` ejecuta en tu shell las líneas del paso 3: define las dos variables y ejecuta el `echo Agent pid`.

5. **Quién puede usar el socket:**
   ```bash
   ls -ld "$(dirname "$SSH_AUTH_SOCK")"
   ls -l "$SSH_AUTH_SOCK"
   ```
   ```
   drwx------ 2 alumno alumno 4096 Nov  8 05:40 /tmp/ssh-L7VziiXCbW0Y
   srw------- 1 alumno alumno 0 Nov  8 05:40 /tmp/ssh-L7VziiXCbW0Y/agent.12
   ```
   `dirname` quita el último componente de la ruta. La `s` es de *socket*. Carpeta en 700 y socket en 600: solo `alumno` (y root) llega al agente.

6. **Un agente vacío, y tu llave dentro:**
   ```bash
   ssh-add -l; echo "código: $?"
   ssh-add
   ```
   ```
   The agent has no identities.
   código: 1
   Enter passphrase for /home/alumno/.ssh/id_ed25519:
   Identity added: /home/alumno/.ssh/id_ed25519 (alumno@client)
   ```
   Sin argumentos, `ssh-add` carga las llaves con nombre por defecto (`~/.ssh/id_ed25519`, `id_rsa`...). Pide la frase **una vez**, descifra la privada y se la pasa al agente.

7. **Qué tiene el agente:**
   ```bash
   ssh-add -l
   ssh-add -L | cut -c1-60
   cut -c1-60 ~/.ssh/id_ed25519.pub
   ```
   ```
   256 SHA256:fQpcN8p0y2xYkuNS4Xpd9+KMBUzgK88+13kYgO9Ej0c alumno@client (ED25519)
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHTtlySj2k1wTbSjjzHm6RBl
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHTtlySj2k1wTbSjjzHm6RBl
   ```
   `-l` muestra la huella y `-L` la pública completa, igual a tu `.pub`. No hay ningún `ssh-add` que muestre la privada.

8. **Entrar sin frase:**
   ```bash
   ssh server hostname
   ssh -v server true 2>&1 | grep -E 'Will attempt|Offering|accepts' | head -3
   ```
   ```
   server
   debug1: Will attempt key: /home/alumno/.ssh/id_ed25519 ED25519 SHA256:fQpcN8p0y2xYkuNS4Xpd9+KMBUzgK88+13kYgO9Ej0c agent
   debug1: Will attempt key: /home/alumno/.ssh/id_rsa
   debug1: Offering public key: /home/alumno/.ssh/id_ed25519 ED25519 SHA256:fQpcN8p0y2xYkuNS4Xpd9+KMBUzgK88+13kYgO9Ej0c agent
   ```
   La marca `agent` dice que esa llave la firma el agente: `ssh` no abrió el archivo. La llave del agente va primera.

9. **Quitar la llave y detener el agente:**
   ```bash
   ssh-add -d ~/.ssh/id_ed25519
   eval "$(ssh-agent -k)"
   ssh-add -l; echo "código: $?"
   ```
   ```
   Identity removed: /home/alumno/.ssh/id_ed25519 ED25519 (alumno@client)
   Agent pid 13 killed
   Could not open a connection to your authentication agent.
   código: 2
   ```
   - `ssh-add -d` quita la llave del agente; el archivo sigue en `~/.ssh`.
   - `ssh-agent -k` mata el agente de `SSH_AGENT_PID` e imprime `unset SSH_AUTH_SOCK; ...`: con `eval`, tu shell olvida las variables. Sin `eval`, quedarían apuntando a un socket que ya no existe.

## Criterios de éxito

- [ ] Explicas por qué `ssh-agent` sin `eval` no sirve (pasos 3 y 4)
- [ ] El socket está en 600 dentro de una carpeta 700 y sabes quién puede usarlo (paso 5)
- [ ] Distingues los códigos 0, 1 y 2 de `ssh-add -l` (pasos 2, 6 y 9)
- [ ] Con la llave cargada, `ssh` no pide la frase y `-v` marca la llave con `agent` (paso 8)

## Reto extra

Con el agente cargado, ejecuta `bash` (una shell hija) y comprueba que ahí también funciona `ssh server hostname`. Después ejecuta `env -u SSH_AUTH_SOCK bash` y repite. ¿Qué diferencia hay? ¿Qué te dice eso sobre una terminal nueva abierta desde tu escritorio? (Lo resolverás en el lab 03.)

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Índice de labs](../README.md) | [Lab 02 — La frase una sola vez](../lab-02-la-frase-una-sola-vez/README.md) → |

[↑ Semana 04](../../README.md)
