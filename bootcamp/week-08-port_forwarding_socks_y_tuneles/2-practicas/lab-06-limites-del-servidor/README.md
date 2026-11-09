# Lab 06 — Lo que el servidor permite

⏱ Duración estimada: ~60 min

## Objetivo

Cambiar de lado: limitar en `sshd` qué túneles se pueden abrir (`AllowTcpForwarding`, `PermitOpen`) y ver qué error recibe el cliente en cada caso. Crear una llave que solo sirve para el túnel a la base de datos, con `permitopen` en `authorized_keys`.

## Contexto

- Las opciones de servidor y de `authorized_keys`: [teoría 02](../../1-teoria/02-socks-config-y-limites.md#lo-que-decide-el-servidor).
- Opciones de `authorized_keys` y `restrict`: semana 03.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-reenvio-local/README.md), con la web de `server` en marcha, y la variable `R` del [lab 03](../lab-03-reenvio-remoto/README.md). Para la web de tu equipo en `9000`, el paso 1 del lab 03.

1. **Lo que `server` permite ahora.**
   ```bash
   ssh server 'sudo sshd -T | grep -E "^(allowtcpforwarding|gatewayports|permitopen|permitlisten|allowstreamlocalforwarding|disableforwarding)"'
   ```
   ```
   gatewayports no
   allowtcpforwarding yes
   disableforwarding no
   allowstreamlocalforwarding yes
   permitopen any
   permitlisten any
   ```
   Todo permitido, a cualquier destino (`any`). Es el valor por defecto de OpenSSH, y el que deja tu kit de la semana 07 para las cuentas normales.

2. **Solo túneles locales.** `AllowTcpForwarding local` permite `-L` y `-D`, y no `-R`:
   ```bash
   echo 'AllowTcpForwarding local' | ssh server "sudo tee /etc/ssh/sshd_config.d/30-tuneles.conf >/dev/null; sudo sshd -t && $R"
   ssh -o ExitOnForwardFailure=yes -f -N -R 9000:localhost:9000 server; echo "código: $?"
   ssh -f -N -L 15432:db:5432 server; echo "código: $?"
   PGPASSWORD=alumno psql -h 127.0.0.1 -p 15432 -U alumno tienda -tAc 'select 1'
   pkill -x ssh
   ```
   ```
   Error: remote port forwarding failed for listen port 9000
   código: 255
   código: 0
   1
   ```
   El `-R` es el que mete tu red en el servidor (lab 03). En un servidor que solo usas para llegar a sus servicios, no hace falta.

3. **Solo a la base de datos.** `PermitOpen` limita a dónde van los `-L` y `-D`:
   ```bash
   printf 'AllowTcpForwarding local\nPermitOpen db:5432\n' | ssh server "sudo tee /etc/ssh/sshd_config.d/30-tuneles.conf >/dev/null; sudo sshd -t && $R"
   ssh -f -N -L 15432:db:5432 -L 8080:localhost:8080 server; echo "código: $?"
   PGPASSWORD=alumno psql -h 127.0.0.1 -p 15432 -U alumno tienda -tAc 'select 1'
   curl -sS -m 3 localhost:8080; echo "código: $?"
   ```
   ```
   código: 0
   1
   curl: (56) Recv failure: Connection reset by peer
   código: 56
   ```
   - Los dos túneles se abren: `ssh` no sabe que uno está prohibido hasta que lo usas. Al conectar, `sshd` rechaza el canal y `ssh` corta la conexión de `curl`.
   - El motivo no lo ves porque, con `-f`, `ssh` ya no escribe en tu terminal. Un túnel en primer plano (`ssh -N -L 8080:localhost:8080 server`, y el `curl` desde otra terminal) escribe `channel 2: open failed: administratively prohibited: open failed`.
   - `ExitOnForwardFailure` **no** lo detecta: el puerto local sí se pudo abrir. Pruébalo:
   ```bash
   pkill -x ssh
   ssh -o ExitOnForwardFailure=yes -f -N -L 8080:localhost:8080 server; echo "código: $?"
   pkill -x ssh
   ```
   ```
   código: 0
   ```
   Un script que abra un túnel tiene que comprobar que llega, no solo que se abre.

4. **El SOCKS también.** `PermitOpen` se aplica a cada destino de `-D`:
   ```bash
   ssh -f -N -D 1080 server
   curl -sS -m 3 --socks5-hostname localhost:1080 http://localhost:8080; echo "código: $?"
   pkill -x ssh
   ssh server "sudo rm /etc/ssh/sshd_config.d/30-tuneles.conf; $R"
   ```
   ```
   curl: (97) connection to proxy closed
   código: 97
   ```
   Has vuelto a dejar `server` como estaba.

5. **Una llave que solo abre el túnel.** Para un túnel desatendido (lab 07), no quieres que su llave sirva para todo. Crea una y ponle límites en `authorized_keys`:
   ```bash
   ssh-keygen -q -t ed25519 -N '' -C tunel@client -f ~/.ssh/tunel
   echo "restrict,port-forwarding,permitopen=\"db:5432\",command=\"/usr/sbin/nologin\" $(cat ~/.ssh/tunel.pub)" | ssh server 'cat >> ~/.ssh/authorized_keys; tail -1 ~/.ssh/authorized_keys | cut -c1-90'
   ```
   ```
   restrict,port-forwarding,permitopen="db:5432",command="/usr/sbin/nologin" ssh-ed25519 AAAA
   ```
   - `restrict` quita todo (semana 03); `port-forwarding` devuelve solo los túneles; `permitopen="db:5432"` los limita a la base de datos; `command="/usr/sbin/nologin"`: cualquier sesión ejecuta eso y sale.
   - Sin frase de paso para que un túnel desatendido la use sin ti: **solo en el laboratorio**, o en un equipo protegido y siempre con estos límites.

6. **Probar la llave.** `T` elige esa llave y ninguna otra:
   ```bash
   T='-o IdentitiesOnly=yes -i ~/.ssh/tunel'
   ssh $T server 'cat /etc/passwd'; echo "código: $?"
   ssh $T -f -N -L 15432:db:5432 -L 8080:localhost:8080 server
   PGPASSWORD=alumno psql -h 127.0.0.1 -p 15432 -U alumno tienda -tAc 'select count(*) from productos'
   curl -sS -m 3 localhost:8080; echo "código: $?"
   pkill -x ssh
   ```
   ```
   This account is currently not available.
   código: 1
   3
   curl: (56) Recv failure: Connection reset by peer
   código: 56
   ```
   - Ningún comando: `nologin` contesta siempre. Con `-N` no hay sesión, así que el túnel a `db` funciona; a cualquier otro sitio, el canal se rechaza (`administratively prohibited`).
   - Si te roban esta llave, solo tienen el túnel a la base de datos (y su contraseña, que es otra barrera). Ni shell, ni archivos, ni el resto de la red.

7. **Lo que la llave aún permite.** `permitopen` limita los `-L`, no los `-R`:
   ```bash
   ssh $T -o ExitOnForwardFailure=yes -f -N -R 9000:localhost:9000 server; echo "código: $?"
   pkill -x ssh
   ```
   ```
   código: 0
   ```
   `port-forwarding` devuelve los dos sentidos. Para limitar también los `-R`, añade `permitlisten="localhost:9000"` con el único puerto que quieras, o quita la opción `port-forwarding` y no uses `-R`.

## Criterios de éxito

- [ ] Limitas los túneles con `AllowTcpForwarding local` y `PermitOpen`, y reconoces el error del cliente en cada caso (pasos 2, 3 y 4)
- [ ] Explicas por qué `ExitOnForwardFailure` no detecta un destino prohibido (paso 3)
- [ ] Creas una llave que solo abre el túnel a `db:5432` y lo compruebas (pasos 5 y 6)
- [ ] Explicas qué deja abierto `port-forwarding` y cómo cerrarlo (paso 7)
- [ ] Explicas por qué quitar los túneles a un usuario con shell no lo frena ([teoría 02](../../1-teoria/02-socks-config-y-limites.md#lo-que-no-es-una-barrera))

## Reto extra

Pon los límites del paso 3 solo para un usuario, dentro de `Match User` (semana 07, lab 04), y comprueba con `sudo sshd -T -C user=alumno` y con otro usuario que solo se aplican a él.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 05 — Túneles en `ssh_config` y con el master](../lab-05-tuneles-en-config/README.md) | [Lab 07 — Túneles que vuelven solos](../lab-07-tuneles-persistentes/README.md) → |

[↑ Semana 08](../../README.md)
