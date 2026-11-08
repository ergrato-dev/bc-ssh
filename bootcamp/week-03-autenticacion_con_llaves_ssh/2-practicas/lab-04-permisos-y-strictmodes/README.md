# Lab 04 — Permisos y `StrictModes`

⏱ Duración estimada: ~60 min

## Objetivo

Provocar los dos fallos de permisos más comunes (una privada legible en el cliente y una carpeta escribible en el servidor), encontrar la causa en el mensaje del cliente o en el log del servidor, y automatizar la revisión con un script que funciona en los dos lados.

## Contexto

- Permisos en el cliente: [teoría 02](../../1-teoria/02-tipos-de-llave-y-frase-de-paso.md#permisos-en-el-cliente). `StrictModes` en el servidor: [teoría 03](../../1-teoria/03-authorized_keys-y-opciones.md#qué-comprueba-sshd-antes-de-leerlo-strictmodes).
- Los modos se escriben en octal: `7` = leer + escribir + ejecutar, `6` = leer + escribir, `5` = leer + ejecutar, `0` = nada; tres cifras: dueño, grupo, otros. `chmod o+w` añade escritura a "otros"; `o-w` la quita.
- Necesitas dos terminales: **En tu equipo** (para leer el log del servidor) y **En el cliente**.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d
   docker compose run --rm client
   ```
   **En el cliente**:
   ```bash
   cd bootcamp/week-03-autenticacion_con_llaves_ssh/2-practicas/lab-04-permisos-y-strictmodes
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh
   ssh-keyscan -t ed25519 server 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519
   sshpass -e ssh-copy-id server
   ssh -o BatchMode=yes server echo dentro
   ```
   La última línea debe imprimir `dentro`: partes de una llave que funciona.

1. **Fallo en el cliente: privada legible.** Pasa con frecuencia al copiar llaves de otro equipo:
   ```bash
   chmod 644 ~/.ssh/id_ed25519
   ssh -o BatchMode=yes server true
   ```
   ```
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   @         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   Permissions 0644 for '/home/alumno/.ssh/id_ed25519' are too open.
   It is required that your private key files are NOT accessible by others.
   This private key will be ignored.
   Load key "/home/alumno/.ssh/id_ed25519": bad permissions
   alumno@server: Permission denied (publickey,password).
   ```
   Aquí el aviso es claro y sale en tu terminal. Corrígelo:
   ```bash
   chmod 600 ~/.ssh/id_ed25519
   ```

2. **Fallo en el servidor: carpeta personal escribible.**
   ```bash
   ssh server 'chmod o+w ~'
   ssh -o BatchMode=yes server true; echo "código: $?"
   ```
   ```
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   El mismo mensaje que si la llave no estuviera instalada. Aunque mires `ssh -v`, el cliente solo ve que el servidor no aceptó la llave: el motivo **no viaja** al cliente (daría pistas a un atacante).

3. **El motivo está en el log del servidor.** **En tu equipo**:
   ```bash
   docker compose logs server | grep -i refused | tail -1
   ```
   ```
   server-1  | Authentication refused: bad ownership or modes for directory /home/alumno
   ```
   Regla práctica: si una llave que **debería** funcionar no funciona, lee el log del servidor antes de tocar nada más. En un servidor real: `journalctl -u ssh`.

4. **Entra con contraseña para arreglarlo.** Con la llave rechazada, la contraseña es la única puerta. **En el cliente**:
   ```bash
   sshpass -e ssh -o PubkeyAuthentication=no server 'chmod o-w ~'
   ssh -o BatchMode=yes server echo dentro
   ```
   ```
   dentro
   ```
   Fíjate en la consecuencia para la semana 07: cuando desactives las contraseñas en el servidor, un error de permisos así te deja fuera. Por eso se desactivan solo con una segunda vía de entrada.

5. **Prueba los otros dos casos de `StrictModes`.** Para cada uno: provócalo, comprueba que la llave falla, busca la línea en el log **en tu equipo** y arréglalo con contraseña:

   | Provocar (en el servidor) | Arreglar |
   |---|---|
   | `chmod o+w ~/.ssh` | `chmod 700 ~/.ssh` |
   | `chmod 666 ~/.ssh/authorized_keys` | `chmod 600 ~/.ssh/authorized_keys` |

   Por ejemplo:
   ```bash
   sshpass -e ssh -o PubkeyAuthentication=no server 'chmod o+w ~/.ssh'
   ssh -o BatchMode=yes server true; echo "código: $?"
   sshpass -e ssh -o PubkeyAuthentication=no server 'chmod 700 ~/.ssh'
   ```
   Anota en tus notas el texto exacto del log para cada caso.

6. **La excepción de Ubuntu.** Prueba `chmod g+w ~/.ssh/authorized_keys` en el servidor. ¿Falla la llave? Explícalo con la [teoría 03](../../1-teoria/03-authorized_keys-y-opciones.md#qué-comprueba-sshd-antes-de-leerlo-strictmodes) (pista: `ssh server 'id; ls -l ~/.ssh'`). Déjalo en `600` al terminar.

7. **TODO de `starter/revisar-permisos.sh`.** El script revisa tu carpeta personal, `~/.ssh`, `authorized_keys` y cada privada, y dice `MAL` si el modo tiene algún bit prohibido. La función `revisar RUTA MASCARA MOTIVO` recibe en `MASCARA` los bits prohibidos (`002` = escritura de otros, `077` = cualquier permiso de grupo u otros). Falta la comparación: cambia `if false; then` por
   ```bash
   if (( 8#$modo & 8#$2 )); then
   ```
   - `(( ... ))` es aritmética de bash: verdadero si el resultado no es 0.
   - `8#644` lee `644` en octal (sin `8#`, bash lo leería en decimal).
   - `&` deja los bits que están en los dos números. `644 & 077` = `044`: el grupo y otros pueden leer, así que es `MAL`.

   ```bash
   chmod 644 ~/.ssh/id_ed25519
   ./starter/revisar-permisos.sh; echo "código: $?"
   chmod 600 ~/.ssh/id_ed25519
   ```
   ```
   ok   /home/alumno 750
   ok   /home/alumno/.ssh 700
   MAL  /home/alumno/.ssh/id_ed25519 644  (privada legible por otros)
   código: 1
   ```

8. **El mismo script en el servidor, sin copiarlo:**
   ```bash
   ssh server 'chmod o+w ~'
   sshpass -e ssh -o PubkeyAuthentication=no server bash -s < starter/revisar-permisos.sh; echo "código: $?"
   ```
   ```
   MAL  /home/alumno 752  (otros pueden escribir)
   ok   /home/alumno/.ssh 700
   ok   /home/alumno/.ssh/authorized_keys 600
   código: 1
   ```
   `bash -s` ejecuta lo que le llega por stdin; `< starter/revisar-permisos.sh` envía el script por la conexión. Se ejecuta en el servidor, con su `$HOME`. Arréglalo: `sshpass -e ssh -o PubkeyAuthentication=no server 'chmod o-w ~'`.

## Criterios de éxito

- [ ] Explicas por qué el cliente recibe `Permission denied` sin motivo en el paso 2
- [ ] Encontraste en el log del servidor la causa de los tres casos de `StrictModes` (pasos 3 y 5)
- [ ] Explicas la excepción de Ubuntu para el grupo (paso 6)
- [ ] `./starter/revisar-permisos.sh` detecta el fallo en el cliente y en el servidor (pasos 7 y 8)

## Reto extra

`StrictModes` también rechaza un `authorized_keys` cuyo **dueño** no es el usuario ni root. **En tu equipo**: `docker compose exec server chown nobody /home/alumno/.ssh/authorized_keys`. Comprueba que la llave falla y busca la línea del log. Devuélvelo con `docker compose exec server chown alumno /home/alumno/.ssh/authorized_keys`. Añade a `revisar-permisos.sh` la comprobación del dueño con `stat -c %U`.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 03 — La frase de paso](../lab-03-frase-de-paso/README.md) | [Lab 05 — Varias llaves, una por host](../lab-05-varias-llaves/README.md) → |

[↑ Semana 03](../../README.md)
