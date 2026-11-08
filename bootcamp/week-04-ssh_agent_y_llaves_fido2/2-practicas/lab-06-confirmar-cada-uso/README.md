# Lab 06 — Confirmar cada uso con `ssh-add -c`

⏱ Duración estimada: ~60 min

## Objetivo

Cargar una llave que el agente solo usa después de preguntar, escribir en bash el programa que responde por ti (`SSH_ASKPASS`) y que deja un registro de cada firma, y ver en ese registro las firmas de un salto con agent forwarding.

## Contexto

- `ssh-add -c` y `SSH_ASKPASS`: [teoría 02](../../1-teoria/02-agent-forwarding-y-riesgos.md#ssh-add--c-confirmar-cada-firma).
- En un escritorio, el agente abre una ventana "¿Permitir?". El contenedor no tiene ventanas: tu script decide según exista o no el archivo `~/.ssh/permitir`. Es una simulación: en la vida real, quien responde eres tú.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d --force-recreate server bastion
   docker compose run --rm client
   ```
   **En el cliente**, la preparación del lab 05, todavía sin agente:
   ```bash
   cd bootcamp/week-04-ssh_agent_y_llaves_fido2/2-practicas/lab-06-confirmar-cada-uso
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh
   ssh-keyscan -t ed25519 server bastion 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/lab
   for h in server bastion; do sshpass -e ssh-copy-id -f -i ~/.ssh/lab.pub $h; done
   ssh -i ~/.ssh/lab server 'ssh-keyscan -t ed25519 bastion 2>/dev/null > ~/.ssh/known_hosts'
   ```

1. **Un agente que no puede preguntar:**
   ```bash
   eval "$(ssh-agent)"
   ssh-add -c ~/.ssh/lab
   ssh -o BatchMode=yes server hostname; echo "código: $?"
   ```
   ```
   Agent pid 12
   Identity added: /home/alumno/.ssh/lab (alumno@client)
   The user must confirm each use of the key
   sign_and_send_pubkey: signing failed for ED25519 "alumno@client" from agent: agent refused operation
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   El agente tenía que preguntar y no tenía cómo: ante la duda, no firma. Es el comportamiento seguro.

2. **Quién pregunta.** Para preguntar, el agente ejecuta el programa de **su** variable `SSH_ASKPASS` con la pregunta como primer argumento, y firma solo si sale con 0. Por eso la variable se le da al agente **al arrancarlo**, no a `ssh`. Detén este agente:
   ```bash
   eval "$(ssh-agent -k)"
   ```

3. **TODO de `starter/confirmar.sh`.** Lee la cabecera: ya tiene la ruta del registro (`$log`) y la pregunta en una línea (`$pregunta`). Completa el TODO: si existe `~/.ssh/permitir`, añade al registro `HORA SI  PREGUNTA` y sal con 0; si no, `HORA NO  PREGUNTA` y sal con 1. `>>` añade al final del archivo sin borrar lo anterior.

4. **El agente, con tu programa:**
   ```bash
   eval "$(SSH_ASKPASS=$PWD/starter/confirmar.sh SSH_ASKPASS_REQUIRE=force ssh-agent)"
   ssh-add -c ~/.ssh/lab
   ```
   - `VAR=valor comando` define la variable solo para ese comando: aquí, solo para el agente.
   - `SSH_ASKPASS_REQUIRE=force`: usa `SSH_ASKPASS` aunque no haya entorno gráfico.
   - `$PWD`: ruta absoluta. El agente no sabe en qué carpeta estabas.

5. **Sin permiso:**
   ```bash
   ssh -o BatchMode=yes server hostname; echo "código: $?"
   cat ~/.ssh/confirmaciones.log
   ```
   ```
   sign_and_send_pubkey: signing failed for ED25519 "alumno@client" from agent: agent refused operation
   alumno@server: Permission denied (publickey,password).
   código: 255
   05:46:59 NO  Allow use of key alumno@client? Key fingerprint SHA256:rVQkW8T3KNYujnQIc83LWgO3tIWA4pzq65z6hL/GWDk.
   ```
   La pregunta dice qué llave (comentario y huella) se quiere usar.

6. **Con permiso:**
   ```bash
   touch ~/.ssh/permitir
   ssh server hostname
   tail -1 ~/.ssh/confirmaciones.log
   ```
   ```
   server
   05:46:59 SI  Allow use of key alumno@client? Key fingerprint SHA256:rVQkW8T3KNYujnQIc83LWgO3tIWA4pzq65z6hL/GWDk.
   ```

7. **Las firmas de un salto.** Con forwarding, cuenta las preguntas:
   ```bash
   ssh -A server 'ssh bastion hostname'
   tail -2 ~/.ssh/confirmaciones.log
   ```
   ```
   bastion
   05:54:59 SI  Allow use of key alumno@client? Key fingerprint SHA256:bf9iyXK+24baQzVavrPYjAi1ln19gFk8waFqYQRgLW4.
   05:54:59 SI  Allow use of key alumno@client? Key fingerprint SHA256:bf9iyXK+24baQzVavrPYjAi1ln19gFk8waFqYQRgLW4.
   ```
   Dos firmas: una para entrar en `server` y otra, pedida **desde `server`** por el socket reenviado, para entrar en `bastion`. Cada uso de tu llave pasa por la pregunta, venga de donde venga.

8. **Responde en tus notas:** estás conectado con `ssh -A server` y aparece en tu registro una línea que no corresponde a nada que tú hayas hecho. ¿Qué significa? ¿Qué harías? ¿Qué ventaja tiene `-c` frente a `-h` (lab 05), y al revés?

9. **Al terminar**, retira el permiso para que no quede abierto:
   ```bash
   rm ~/.ssh/permitir
   ```

## Criterios de éxito

- [ ] Explicas por qué el agente se niega sin `SSH_ASKPASS` (paso 1) y por qué la variable se le da al agente (paso 2)
- [ ] `starter/confirmar.sh` anota y decide según `~/.ssh/permitir` (pasos 5 y 6)
- [ ] Viste en el registro las dos firmas de un salto con forwarding (paso 7)
- [ ] Respondiste las preguntas del paso 8

## Reto extra

Cambia el script para que, en lugar de un archivo fijo, permita solo durante 60 segundos después de `touch ~/.ssh/permitir` (pista: `find ~/.ssh/permitir -mmin -1`). Así un permiso olvidado caduca solo, igual que `ssh-add -t`.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 05 — Restringir destinos con `ssh-add -h`](../lab-05-restringir-destinos/README.md) | [Lab 07 — Llaves FIDO2](../lab-07-llaves-fido2/README.md) → |

[↑ Semana 04](../../README.md)
