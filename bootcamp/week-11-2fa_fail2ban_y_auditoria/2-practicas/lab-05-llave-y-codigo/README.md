# Lab 05 — Llave y código

⏱ Duración estimada: ~60 min

## Objetivo

Exigir llave **y** código TOTP en `server`, solo a los usuarios del grupo `dosfa`: cambiar el PAM de `sshd`, añadir `AuthenticationMethods` en un `Match Group`, y comprobar qué pasa sin código, con un código malo, repetido o de emergencia, sin llave y con multiplexing.

## Contexto

- PAM, keyboard-interactive y `AuthenticationMethods`: [teoría 02](../../1-teoria/02-segundo-factor.md#cómo-pregunta-sshd-pam-y-keyboard-interactive).
- Vas a tocar cómo entra **tu** usuario. Si algo sale mal, la consola sigue ahí: en tu equipo, `docker compose exec server bash` (en un servidor real, la consola del proveedor). Nunca cierres tu última sesión hasta probar con una nueva.
- **La contraseña `alumno` y el secreto en `$S` son solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-leer-ssh-audit/README.md) y el paso 1 del [lab 04](../lab-04-totp-por-dentro/README.md) (el secreto en `server`). Guarda el secreto en el cliente **antes** de activar nada: después, leerlo por SSH pedirá un código.
   ```bash
   S=$(ssh server head -1 .google_authenticator); echo "$S"
   ```

1. **El PAM de ahora.**
   ```bash
   ssh server "grep -nE 'common-auth|google' /etc/pam.d/sshd"
   ```
   ```
   4:@include common-auth
   ```
   La parte `auth` de `sshd` es la contraseña de Unix (`common-auth`, que lleva a `pam_unix`).

2. **Código en lugar de contraseña.**
   ```bash
   ssh server "sudo cp /etc/pam.d/sshd /etc/pam.d/sshd.orig
   sudo sed -i 's/^@include common-auth/# @include common-auth\nauth required pam_google_authenticator.so/' /etc/pam.d/sshd
   grep -nE 'common-auth|google' /etc/pam.d/sshd"
   ```
   ```
   4:# @include common-auth
   5:auth required pam_google_authenticator.so
   ```
   - Copia antes de tocar (`sshd.orig`): con un PAM roto no entra nadie que use PAM.
   - `required`: si el módulo dice que no, PAM dice que no.
   - Aún no cambió nada: `KbdInteractiveAuthentication` sigue en `no` y nadie llega a esta parte de PAM. Compruébalo: `ssh server true` entra como siempre.

3. **La regla, solo para `dosfa`.**
   ```bash
   ssh server 'sudo groupadd dosfa
   printf "Match Group dosfa\n    KbdInteractiveAuthentication yes\n    AuthenticationMethods publickey,keyboard-interactive\n" | sudo tee /etc/ssh/sshd_config.d/60-2fa.conf
   sudo sshd -t && sudo kill -HUP $(cat /run/sshd.pid)'
   ssh server 'sudo sshd -T -C user=alumno | grep -iE "^(authenticationmethods|kbdinteractive)"'
   ```
   ```
   Match Group dosfa
       KbdInteractiveAuthentication yes
       AuthenticationMethods publickey,keyboard-interactive
   kbdinteractiveauthentication no
   authenticationmethods any
   ```
   `alumno` aún no está en el grupo: para él, nada cambia. `sshd -T -C user=...` evalúa los `Match` como si entrara ese usuario.

4. **Alta en el grupo.** El secreto ya existe (paso 0), así que el orden es el correcto:
   ```bash
   ssh server 'sudo usermod -aG dosfa alumno; sudo sshd -T -C user=alumno | grep -iE "^(authenticationmethods|kbdinteractive)"'
   ```
   ```
   kbdinteractiveauthentication yes
   authenticationmethods publickey,keyboard-interactive
   ```
   **No cierres esta terminal** hasta el paso 6.

5. **La llave sola ya no basta.**
   ```bash
   ssh -o BatchMode=yes server hostname; echo "código: $?"
   ```
   ```
   alumno@server: Permission denied (keyboard-interactive).
   código: 255
   ```
   El servidor aceptó la llave y dice qué **falta**: `keyboard-interactive`. Con `BatchMode` el cliente no puede preguntar nada, y se rinde. Así fallarán `cron`, los scripts y `bin/backup` con esta cuenta.

6. **Llave y código.** Calcula el código y conecta; escríbelo cuando te lo pida:
   ```bash
   oathtool --totp -b "$S"
   ssh server hostname
   ```
   ```
   406723
   (alumno@server) Verification code:
   server
   ```
   Tu código será otro. En el log de `server`, desde tu equipo (`docker compose logs --no-log-prefix server | tail -3`):
   ```
   Accepted keyboard-interactive/pam for alumno from 172.20.0.4 port 58864 ssh2
   ```
   Con `LogLevel VERBOSE` (tu `20-sesion.conf` del kit) verías antes `Partial publickey for alumno ... ED25519 SHA256:...`: la llave fue aceptada, pero solo como primera parte.

7. **Un código malo, un código repetido.**
   ```bash
   ssh server true      # escribe 000000 tres veces
   ssh server true      # escribe el código del paso 6, el mismo
   ```
   ```
   (alumno@server) Verification code:
   (alumno@server) Verification code:
   (alumno@server) Verification code:
   alumno@server: Permission denied (keyboard-interactive).
   (alumno@server) Verification code:
   ...
   alumno@server: Permission denied (keyboard-interactive).
   ```
   - El cliente pregunta hasta 3 veces (`NumberOfPasswordPrompts`).
   - El código del paso 6 ya se usó (`DISALLOW_REUSE`): no vale aunque siga en su periodo.
   - Y cuidado: con `RATE_LIMIT 3 30`, tras 3 intentos en 30 s **ni el código bueno entra**. Espera 30 s antes de seguir.
   - En el log, cada código malo es `PAM: Authentication failure for alumno from 172.20.0.4`: fail2ban los cuenta ([lab 06](../lab-06-fail2ban/README.md)).

8. **Un código de emergencia.** Usa uno de los que te dio el lab 04 (están en el archivo; aquí lo lees por la consola, en tu equipo: `docker compose exec server sed -n 6p /home/alumno/.google_authenticator`):
   ```bash
   ssh server "grep -cE '^[0-9]{8}$' .google_authenticator"
   ```
   Escribe el código de 8 cifras cuando te pida `Verification code:`.
   ```
   (alumno@server) Verification code:
   4
   ```
   Entró, y quedan 4: el que usaste se borró. Si intentas usarlo otra vez, `Permission denied`.

9. **El código sin la llave.**
   ```bash
   ssh -o PubkeyAuthentication=no server true; echo "código: $?"
   ```
   ```
   alumno@server: Permission denied (publickey).
   código: 255
   ```
   El orden de `AuthenticationMethods` importa: sin llave, el servidor ni siquiera pregunta el código. Quien solo vio tu código por encima del hombro no llega a usarlo.

10. **Multiplexing: el código una vez.**
    ```bash
    ssh -o ControlMaster=auto -o ControlPath=~/.ssh/cm-%C -o ControlPersist=5m server true
    ssh -o ControlPath=~/.ssh/cm-%C -o BatchMode=yes server 'echo sin código otra vez'
    ssh -o ControlPath=~/.ssh/cm-%C -O exit server
    ```
    ```
    (alumno@server) Verification code:
    sin código otra vez
    Exit request sent.
    ```
    Lo que va por un master no vuelve a autenticarse: ni llave ni código. Cómodo (tu kit usa multiplexing) y la razón de `bin/mux stop` al cambiar llaves o códigos.

11. **Quien no está en el grupo.**
    ```bash
    ssh server 'sudo gpasswd -d alumno dosfa'     # escribe un código: aún estás en el grupo
    ssh -o BatchMode=yes server 'id -nG'
    ```
    ```
    (alumno@server) Verification code:
    Removing user alumno from group dosfa
    alumno adm dialout cdrom floppy sudo audio dip video plugdev
    ```
    Fuera del grupo, la llave sola vuelve a bastar, sin recargar `sshd`: los grupos se miran en cada conexión.

## Criterios de éxito

- [ ] Cambias el PAM con copia previa y explicas por qué se comenta `common-auth` (paso 2)
- [ ] `sshd -T -C user=` muestra el cambio solo para quien está en `dosfa` (pasos 3 y 4)
- [ ] Entras con llave y código, y explicas el `Permission denied (keyboard-interactive)` (pasos 5 y 6)
- [ ] Explicas qué pasa con un código malo, repetido y tras 3 intentos (paso 7)
- [ ] Usas un código de emergencia y compruebas que se gasta (paso 8)
- [ ] Explicas por qué el código sin llave no sirve y qué hace el multiplexing (pasos 9 y 10)

## Reto extra

Añade `nullok` al final de la línea de `pam_google_authenticator.so`, mete en `dosfa` a una cuenta nueva sin `~/.google_authenticator` y entra con ella. ¿Qué pasa? ¿Por qué el kit no usa `nullok`? Deja el PAM como estaba con `sudo cp /etc/pam.d/sshd.orig /etc/pam.d/sshd`.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 04 — TOTP por dentro](../lab-04-totp-por-dentro/README.md) | [Lab 06 — fail2ban](../lab-06-fail2ban/README.md) → |

[↑ Semana 11](../../README.md)
