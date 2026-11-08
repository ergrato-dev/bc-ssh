# Lab 04 — `Match`: reglas para unos pocos

⏱ Duración estimada: ~60 min

## Objetivo

Aplicar opciones distintas a un usuario, un grupo o una red con `Match`, comprobarlas sin conectar con `sshd -T -C`, y encontrar los cuatro errores que más se cometen con `Match`.

## Contexto

- `Match` y sus cinco reglas: [teoría 02](../../1-teoria/02-autenticacion-y-acceso.md#match-valores-distintos-para-conexiones-distintas).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-sshd-config/README.md), el paso 0 del [lab 03](../lab-03-quien-entra/README.md) (`ana`, `bot` y `ssh-users`), y además `alumno` en `ssh-users`:
   ```bash
   R='sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ssh server 'sudo usermod -aG ssh-users alumno'
   ```
   En este lab casi no hace falta recargar: `sshd -T -C` lee los archivos. Así pruebas un `Match` antes de que afecte a nadie.

1. **Una excepción para un usuario.** Sin contraseñas para todos, salvo para `ana`, que todavía no tiene llave:
   ```bash
   ssh server 'echo "PasswordAuthentication no" | sudo tee /etc/ssh/sshd_config.d/01-global.conf >/dev/null
   printf "Match User ana\n    PasswordAuthentication yes\n" | sudo tee /etc/ssh/sshd_config.d/05-ana.conf >/dev/null
   sudo sshd -T | grep ^passwordauth
   sudo sshd -T -C user=ana | grep ^passwordauth
   sudo sshd -T -C user=alumno | grep ^passwordauth'
   ```
   ```
   passwordauthentication no
   passwordauthentication yes
   passwordauthentication no
   ```
   - `-C user=ana`: aplica los `Match` como si se conectara `ana`. También admite `addr=`, `host=`, `laddr=` y `lport=`, separados por comas.
   - El valor global (`01-`) va antes que el `Match` (`05-`), y aun así el `Match` gana para `ana`: los `Match` se aplican encima de los valores globales al conectar.
   - Es una excepción temporal típica: la quitas en cuanto `ana` tiene su llave.

2. **Primera trampa: lo que va debajo de un `Match` es del `Match`.** Añade una opción global al final del mismo archivo, con una línea en blanco y sin sangría:
   ```bash
   ssh server 'printf "Match User ana\n    X11Forwarding yes\n\nMaxAuthTries 2\n" | sudo tee /etc/ssh/sshd_config.d/05-ana.conf >/dev/null
   sudo sshd -T | grep ^maxauth; sudo sshd -T -C user=ana | grep ^maxauth'
   ```
   ```
   maxauthtries 6
   maxauthtries 2
   ```
   `MaxAuthTries 2` solo se aplica a `ana`. Ni la línea en blanco ni la falta de sangría cierran el `Match`: solo otro `Match` o el final del archivo. Las opciones globales van en otro archivo, o antes del primer `Match`.

3. **El final de un archivo sí cierra el `Match`.** La misma opción, en un archivo aparte que se lee después:
   ```bash
   ssh server 'printf "Match User ana\n    X11Forwarding yes\n" | sudo tee /etc/ssh/sshd_config.d/05-ana.conf >/dev/null
   echo "MaxAuthTries 2" | sudo tee /etc/ssh/sshd_config.d/06-limites.conf >/dev/null
   sudo sshd -T | grep ^maxauth; sudo sshd -T -C user=ana | grep ^maxauth
   sudo rm /etc/ssh/sshd_config.d/06-limites.conf'
   ```
   ```
   maxauthtries 2
   maxauthtries 2
   ```
   Por eso en el kit cada `Match` vive en su propio archivo (`30-sftp.conf`).

4. **Segunda trampa: no todo vale dentro de un `Match`.**
   ```bash
   ssh server 'printf "Match User ana\n    Port 2222\n" | sudo tee /etc/ssh/sshd_config.d/05-ana.conf >/dev/null
   sudo sshd -t; echo "código: $?"'
   ```
   ```
   /etc/ssh/sshd_config.d/05-ana.conf line 2: Directive 'Port' is not allowed within a Match block
   código: 255
   ```
   El puerto lo abre el `listener` antes de saber quién se conecta. `man sshd_config`, en la sección `Match`, tiene la lista de opciones permitidas.

5. **Por red, y varias condiciones a la vez.** Contraseña solo desde una red interna (que no es la tuya), y 2 intentos para el grupo `ssh-users` menos `ana`:
   ```bash
   ssh server 'printf "Match Address 10.99.0.0/16\n    PasswordAuthentication yes\nMatch Group ssh-users User !ana\n    MaxAuthTries 2\n" | sudo tee /etc/ssh/sshd_config.d/05-ana.conf >/dev/null
   sudo sshd -t
   for c in user=alumno,addr=10.99.1.1 user=alumno,addr=172.20.0.4 user=ana user=bot; do
     echo "$c: $(sudo sshd -T -C $c | grep -E "^(passwordauth|maxauth)" | tr "\n" " ")"
   done'
   ```
   ```
   user=alumno,addr=10.99.1.1: maxauthtries 6 passwordauthentication yes 
   user=alumno,addr=172.20.0.4: maxauthtries 6 passwordauthentication no 
   user=ana: maxauthtries 6 passwordauthentication no 
   user=bot: maxauthtries 6 passwordauthentication no 
   ```
   - `tr "\n" " "`: junta las dos líneas en una.
   - El `Match Address` funciona: contraseña solo desde `10.99.x.x`.
   - **Tercera trampa:** `alumno` está en `ssh-users` y no es `ana`, pero tiene 6 intentos. El segundo `Match` no coincide con nadie.

6. **Una lista solo con negaciones no coincide nunca.** `User !ana` no significa "todos menos ana": significa "nadie, y además ana no". Hace falta un patrón positivo:
   ```bash
   ssh server 'printf "Match Group ssh-users User *,!ana\n    MaxAuthTries 2\n" | sudo tee /etc/ssh/sshd_config.d/05-ana.conf >/dev/null
   for c in user=alumno user=ana user=bot; do echo "$c: $(sudo sshd -T -C $c | grep ^maxauth)"; done'
   ```
   ```
   user=alumno: maxauthtries 2
   user=ana: maxauthtries 6
   user=bot: maxauthtries 6
   ```
   `alumno`: en `ssh-users` y no es `ana`. `ana`: excluida. `bot`: no está en `ssh-users`. Las dos condiciones de la línea se tienen que cumplir.

7. **Cuarta trampa: probar sin `-C`.** Sin `-C`, `sshd -T` no aplica ningún `Match` de usuario: lo que ves es lo que tendría alguien que no coincide con ninguno. Un `Match` mal escrito no da error; simplemente no coincide. **Pruébalo siempre con `-C` y con un usuario que debe coincidir y otro que no**, como en los pasos 5 y 6. Limpia al terminar:
   ```bash
   ssh server "sudo rm /etc/ssh/sshd_config.d/01-global.conf /etc/ssh/sshd_config.d/05-ana.conf; sudo sshd -t && $R"
   ```

## Criterios de éxito

- [ ] Aplicaste una excepción a un usuario y la comprobaste con `sshd -T -C` (paso 1)
- [ ] Explicas hasta dónde llega un `Match` y por qué el kit pone cada uno en su archivo (pasos 2 y 3)
- [ ] Encontraste una opción que no se admite en `Match` (paso 4)
- [ ] Combinaste condiciones y corregiste una lista solo con negaciones (pasos 5 y 6)
- [ ] Pruebas cada `Match` con un caso que coincide y otro que no (paso 7)

## Reto extra

Escribe un `Match LocalPort 2222` que solo permita entrar al grupo `ssh-users` con contraseña desde ese puerto. ¿Qué tienes que añadir **fuera** del `Match` para que `sshd` escuche también en el 2222? Compruébalo con `sshd -T -C user=alumno,lport=2222`.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 03 — Quién puede entrar: usuarios, grupos y shells](../lab-03-quien-entra/README.md) | [Lab 05 — Un usuario que solo sube archivos](../lab-05-sftp-chroot/README.md) → |

[↑ Semana 07](../../README.md)
