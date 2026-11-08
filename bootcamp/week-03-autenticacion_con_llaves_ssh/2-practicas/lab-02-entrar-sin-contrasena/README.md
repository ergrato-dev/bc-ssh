# Lab 02 — Entrar sin contraseña

⏱ Duración estimada: ~60 min

## Objetivo

Instalar tu llave pública en `server` con `ssh-copy-id`, seguir en `ssh -v` los cuatro pasos de la autenticación con llave y ver qué queda en el `authorized_keys` del servidor.

## Contexto

- El intercambio paso a paso está en la [teoría 01](../../1-teoria/01-autenticacion-con-llave-publica.md#el-intercambio-paso-a-paso), con su diagrama.
- `ssh-copy-id` y `authorized_keys`: [teoría 03](../../1-teoria/03-authorized_keys-y-opciones.md#dónde-está-y-quién-lo-escribe).
- **La contraseña `alumno` es solo del laboratorio.** Hoy la usas por última vez para `server`.
- El cliente es nuevo en cada `docker compose run`: haz todo el lab en la misma sesión. En cambio, `server` **conserva** su `authorized_keys` mientras no se recree el contenedor.

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio. `--force-recreate server` recrea `server` desde cero, sin llaves de labs anteriores:
   ```bash
   docker compose up -d --force-recreate server
   docker compose run --rm client
   ```
   **En el cliente**, prepara `known_hosts` y una llave sin frase (la frase llega en el lab 03):
   ```bash
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh
   ssh-keyscan -t ed25519 server 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519
   ```
   Aquí `ssh-keyscan` sustituye a la verificación de huellas de la semana 02 para ir rápido; en un servidor real, verifícala.

1. **Antes de instalar nada:**
   ```bash
   ssh -o BatchMode=yes server true; echo "código: $?"
   ```
   ```
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   `BatchMode=yes` prohíbe a `ssh` preguntar nada: si la llave no basta, falla en lugar de pedir la contraseña. Útil para comprobar justo eso.

2. **Qué intentó:**
   ```bash
   ssh -v -o BatchMode=yes server true 2>&1 | grep -E 'Authentications that|Next authentication|Offering'
   ```
   ```
   debug1: Authentications that can continue: publickey,password
   debug1: Next authentication method: publickey
   debug1: Offering public key: /home/alumno/.ssh/id_ed25519 ED25519 SHA256:86qQFfxu5fSb1n21Hs3B5ISCaS9RcTrciqakBPxrZWI
   debug1: Authentications that can continue: publickey,password
   ```
   Paso 1 del diagrama: el cliente ofrece la llave. El servidor responde con otro `FAILURE` (la segunda línea `Authentications that can continue`): no la tiene. Sin `BatchMode`, el siguiente método sería `password`.

3. **El servidor no tiene `~/.ssh`:**
   ```bash
   sshpass -e ssh server 'ls -la ~/.ssh'
   ```
   ```
   ls: cannot access '/home/alumno/.ssh': No such file or directory
   ```
   `sshpass -e` escribe por ti la contraseña de la variable `SSHPASS` (solo laboratorio).

4. **Instala la llave:**
   ```bash
   ssh-copy-id server
   ```
   ```
   /usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/alumno/.ssh/id_ed25519.pub"
   /usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
   /usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
   alumno@server's password:

   Number of key(s) added: 1

   Now try logging into the machine, with:   "ssh 'server'"
   and check to make sure that only the key(s) you wanted were added.
   ```
   Escribe `alumno`. Sin `-i`, `ssh-copy-id` instala la llave por defecto más reciente de `~/.ssh`. Primero intenta entrar con ella (para no duplicarla) y después entra con contraseña para añadirla.

5. **Qué dejó en el servidor:**
   ```bash
   ssh server 'ls -l ~/.ssh; ssh-keygen -lf ~/.ssh/authorized_keys'
   ```
   ```
   total 4
   -rw------- 1 alumno alumno 95 Nov  8 05:26 authorized_keys
   256 SHA256:86qQFfxu5fSb1n21Hs3B5ISCaS9RcTrciqakBPxrZWI alumno@client (ED25519)
   ```
   Este `ssh` ya no pidió contraseña. `authorized_keys` tiene 95 bytes: exactamente tu `.pub`. La huella coincide con la de tu llave. Fíjate en lo que **no** hay: ninguna privada salió del cliente.

6. **Los cuatro pasos en `ssh -v`:**
   ```bash
   ssh -v server hostname 2>&1 | grep -E 'Offering|accepts|Authenticated|^server'
   ```
   ```
   debug1: Offering public key: /home/alumno/.ssh/id_ed25519 ED25519 SHA256:86qQFfxu5fSb1n21Hs3B5ISCaS9RcTrciqakBPxrZWI
   debug1: Server accepts key: /home/alumno/.ssh/id_ed25519 ED25519 SHA256:86qQFfxu5fSb1n21Hs3B5ISCaS9RcTrciqakBPxrZWI
   Authenticated to server ([172.20.0.3]:22) using "publickey".
   server
   ```
   Asocia cada línea con un paso del [diagrama](../../1-teoria/01-autenticacion-con-llave-publica.md#el-intercambio-paso-a-paso): `Offering` (1), `Server accepts key` (2, `PK_OK`), la firma (3) no tiene línea propia en `-v`, `Authenticated` (4).

7. **El servidor también lo registra.** **En tu equipo**:
   ```bash
   docker compose logs server | grep Accepted | tail -1
   ```
   ```
   server-1  | Accepted publickey for alumno from 172.20.0.6 port 51846 ssh2: ED25519 SHA256:86qQFfxu5fSb1n21Hs3B5ISCaS9RcTrciqakBPxrZWI
   ```
   El servidor sabe qué llave entró por su huella. Cuando hay varias llaves en una cuenta, esta línea dice cuál se usó.

8. **`ssh-copy-id` no duplica.** **En el cliente**:
   ```bash
   ssh-copy-id server
   ```
   ```
   /usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/alumno/.ssh/id_ed25519.pub"
   /usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed

   /usr/bin/ssh-copy-id: WARNING: All keys were skipped because they already exist on the remote system.
   		(if you think this is a mistake, you may want to use -f option)
   ```

9. **La contraseña sigue ahí.** Desactiva la llave en el cliente:
   ```bash
   ssh -o PubkeyAuthentication=no server hostname
   ```
   ```
   alumno@server's password:
   server
   ```
   El servidor sigue aceptando contraseñas: tu llave añade una forma de entrar, no quita la otra. Quien adivine `alumno` sigue entrando. Desactivar `PasswordAuthentication` en el servidor es la semana 07, **después** de comprobar que tu llave funciona (si no, te quedas fuera).

## Criterios de éxito

- [ ] `ssh -o BatchMode=yes server true` falla antes del paso 4 y funciona después
- [ ] Asociaste cada línea del paso 6 con un paso del diagrama
- [ ] Encontraste en el log del servidor la huella de tu llave (paso 7)
- [ ] Explicas por qué instalar una llave no impide entrar con contraseña (paso 9)

## Reto extra

Instala la llave a mano, sin `ssh-copy-id`, en `bastion`, con el comando de la [teoría 03](../../1-teoria/03-authorized_keys-y-opciones.md#ssh-copy-id). Antes, añade `bastion` a `known_hosts` como en el paso 0. Comprueba con `ssh -o BatchMode=yes bastion hostname`. ¿Qué pasa si lo ejecutas dos veces? ¿En qué se diferencia de `ssh-copy-id`?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 01 — Tu primer par de llaves](../lab-01-tu-primer-par-de-llaves/README.md) | [Lab 03 — La frase de paso](../lab-03-frase-de-paso/README.md) → |

[↑ Semana 03](../../README.md)
