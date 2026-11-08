# Lab 07 — Rotar una llave

⏱ Duración estimada: ~60 min

## Objetivo

Sustituir la llave con la que entras en un servidor por una nueva sin quedarte fuera en ningún momento, identificar cada línea de `authorized_keys` por su huella y retirar la vieja con un script que no puede borrar más de la cuenta.

## Contexto

- El orden de la rotación y por qué: [teoría 03](../../1-teoria/03-authorized_keys-y-opciones.md#varias-llaves-y-rotación).
- Se rota una llave cuando se sospecha que se filtró, cuando un equipo se pierde o cambia de manos, cuando alguien deja el equipo de trabajo, o simplemente cada cierto tiempo (una política habitual es una vez al año).
- **La contraseña `alumno` es solo del laboratorio.** En este lab no la usas después del paso 0: si te quedas fuera, entrar con contraseña es la red de seguridad del laboratorio, no la de un servidor real.

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d --force-recreate server
   docker compose run --rm client
   ```
   **En el cliente**, la llave "vieja" instalada:
   ```bash
   cd bootcamp/week-03-autenticacion_con_llaves_ssh/2-practicas/lab-07-rotar-una-llave
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh
   ssh-keyscan -t ed25519 server 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -N '' -C alumno -f ~/.ssh/id_ed25519
   sshpass -e ssh-copy-id server
   ```

1. **Genera la nueva**, con un comentario que diga desde cuándo es válida:
   ```bash
   ssh-keygen -q -t ed25519 -N '' -C alumno-2026-11 -f ~/.ssh/nueva
   ```
   En un caso real, con frase de paso (o con `bin/key-new` de tu kit).

2. **Añádela sin quitar la vieja.** `ssh-copy-id` entra con la vieja, que todavía funciona:
   ```bash
   ssh-copy-id -i ~/.ssh/nueva.pub server
   ssh server 'ssh-keygen -lf ~/.ssh/authorized_keys'
   ```
   ```
   Number of key(s) added: 1
   ...
   256 SHA256:aifRNcmdPjJgb6FaG8O+QpHa6OduPvKIaFP8HE7oRi4 alumno (ED25519)
   256 SHA256:T9vj77Cca/QBnMU+DhNjzsOscNmy1u3ZoiHE18TY/T8 alumno-2026-11 (ED25519)
   ```
   Dos llaves válidas a la vez: es el momento seguro de la rotación. Si la nueva no funcionara, la vieja sigue ahí.

3. **Comprueba la nueva, y solo la nueva:**
   ```bash
   ssh -o IdentitiesOnly=yes -i ~/.ssh/nueva server hostname
   ```
   ```
   server
   ```
   Sin `IdentitiesOnly`, `ssh` también probaría `id_ed25519` (nombre por defecto), y si la nueva fallara entrarías igual con la vieja sin enterarte. La prueba no demostraría nada.

4. **Identifica la línea de la vieja.** Compara huellas:
   ```bash
   ssh-keygen -lf ~/.ssh/id_ed25519.pub
   ```
   ```
   256 SHA256:aifRNcmdPjJgb6FaG8O+QpHa6OduPvKIaFP8HE7oRi4 alumno (ED25519)
   ```
   Es la primera línea del paso 2. Aquí el comentario también lo dice, pero no te fíes solo del comentario: es texto libre, cualquiera lo cambia, y dos llaves pueden tener el mismo. La huella identifica la llave.

5. **TODO de `starter/quitar-llave.sh`.** El script borra de `authorized_keys` las líneas que contienen una llave (el campo en base64). Lee la cabecera y la validación: sin ella, una llave vacía coincidiría con **todas** las líneas. Completa el TODO cambiando `cp "$archivo" "$archivo.nuevo"` (que de momento no quita nada) por:
   ```bash
   grep -vF -- "$llave" "$archivo" > "$archivo.nuevo" || true
   ```
   - `-v` deja pasar las líneas que **no** coinciden; `-F` trata la llave como texto literal (`+` y `/` del base64 no son expresiones regulares).
   - `--` marca el fin de las opciones: nada de lo que venga después se lee como opción.
   - `|| true`: `grep` sale con 1 si no deja ninguna línea, y `set -e` pararía el script.

   El resto ya está escrito: cuenta líneas antes y después, y solo si quitó alguna sustituye el archivo con `mv` (con `chmod 600` antes, para que `StrictModes` no lo rechace).

6. **Retira la vieja, entrando con la nueva:**
   ```bash
   vieja=$(cut -d' ' -f2 ~/.ssh/id_ed25519.pub)
   ssh -o IdentitiesOnly=yes -i ~/.ssh/nueva server bash -s -- "$vieja" < starter/quitar-llave.sh; echo "código: $?"
   ```
   ```
   quitadas: 1
   código: 0
   ```
   - `cut -d' ' -f2` toma el segundo campo de la `.pub`: la llave en base64.
   - `bash -s -- "$vieja"` ejecuta el script que llega por stdin y le pasa `$vieja` como primer argumento.
   - Entras con la **nueva**: si algo saliera mal y borrara la nueva, lo sabrías ahora, con la vieja todavía en tu equipo.

7. **Los casos que no deben hacer nada:**
   ```bash
   ssh -o IdentitiesOnly=yes -i ~/.ssh/nueva server bash -s -- "$vieja" < starter/quitar-llave.sh; echo "código: $?"
   ssh -o IdentitiesOnly=yes -i ~/.ssh/nueva server bash -s -- "" < starter/quitar-llave.sh; echo "código: $?"
   ```
   ```
   quitadas: 0
   código: 1
   uso: quitar-llave.sh LLAVE_BASE64 [ARCHIVO]
   código: 2
   ```
   Ya no estaba (1), y la llave vacía ni siquiera llega a `grep` (2).

8. **Resultado:**
   ```bash
   ssh -o IdentitiesOnly=yes -i ~/.ssh/nueva server 'ssh-keygen -lf ~/.ssh/authorized_keys; ls -l ~/.ssh/authorized_keys'
   ssh -o BatchMode=yes -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 server true; echo "código: $?"
   ```
   ```
   256 SHA256:T9vj77Cca/QBnMU+DhNjzsOscNmy1u3ZoiHE18TY/T8 alumno-2026-11 (ED25519)
   -rw------- 1 alumno alumno 96 Nov  8 05:29 /home/alumno/.ssh/authorized_keys
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   Solo queda la nueva, con permisos 600, y la vieja ya no entra. Ahora sí puedes borrar la vieja de tu equipo: `rm ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub`.

9. **Responde en tus notas:** si la llave vieja se hubiera **filtrado**, ¿bastaría con quitarla de `server`? ¿Dónde más tendrías que buscarla? ¿Qué te diría el log del servidor (lab 02, paso 7) sobre si alguien la usó?

## Criterios de éxito

- [ ] Hubo dos llaves válidas a la vez y probaste la nueva con `IdentitiesOnly` (pasos 2 y 3)
- [ ] Identificaste la línea de la vieja por su huella (paso 4)
- [ ] `starter/quitar-llave.sh` quita la vieja y no hace nada con una llave ausente o vacía (pasos 6 y 7)
- [ ] La vieja ya no entra y `authorized_keys` sigue en 600 (paso 8)
- [ ] Respondiste las preguntas del paso 9

## Reto extra

Rota a la vez en `server` y `bastion` con un bucle `for h in server bastion; do ...; done` que siga los pasos 2, 3 y 6 y **se detenga** en cuanto un host falle la comprobación del paso 3 (pista: `|| break`). ¿Por qué no debe seguir con el siguiente host si uno falla?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 06 — Opciones de `authorized_keys`](../lab-06-opciones-de-authorized-keys/README.md) | [Proyecto — ssh-infra-kit: llaves propias y authorized_keys restringido](../../3-proyecto/README.md) → |

[↑ Semana 03](../../README.md)
