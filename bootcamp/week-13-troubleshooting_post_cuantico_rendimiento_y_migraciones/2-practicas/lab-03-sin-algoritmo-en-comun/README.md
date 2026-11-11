# Lab 03 — Sin algoritmo en común

⏱ Duración estimada: ~60 min

## Objetivo

Entrar en un "equipo viejo" que solo habla algoritmos con SHA-1: leer el `no matching ... Their offer`, ver que tu cliente aún sabe hablarlos aunque no los ofrezca, añadirlos con `+` solo para ese host y comprobar con `ssh -G` y `ssh-audit` que el resto de conexiones no cambia.

## Contexto

- Cómo se negocia cada lista y qué significa `+`, `-` y `^`: [teoría 02](../../1-teoria/02-algoritmos-y-postcuantico.md#cuando-no-hay-nada-en-común).
- El "equipo viejo" es un segundo `sshd` en `server`, en el puerto 2223, limitado a lo que ofrecía OpenSSH hacia 2015. Un switch o una cámara IP de verdad se comportan igual.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-leer-ssh-v/README.md).

1. **El equipo viejo.** En `server`, como root:
   ```bash
   ssh server 'sudo /usr/sbin/sshd -p 2223 -o KexAlgorithms=diffie-hellman-group14-sha1 -o HostKeyAlgorithms=ssh-rsa -o PidFile=/run/sshd-viejo.pid'
   ```
   Sin `-d`, este `sshd` pasa a segundo plano y atiende conexiones hasta que lo pares (paso 7). `PidFile` aparte, para no pisar el del `sshd` del puerto 22.

2. **El error.**
   ```bash
   ssh -p 2223 -o HostKeyAlias=server server true; echo "código: $?"
   ```
   ```
   Unable to negotiate with 172.20.0.2 port 2223: no matching key exchange method found. Their offer: diffie-hellman-group14-sha1,ext-info-s,kex-strict-s-v00@openssh.com
   código: 255
   ```
   - `key exchange method`: la lista que no casa es la de intercambio de llaves (`KexAlgorithms`). Otras veces dirá `host key type` (`HostKeyAlgorithms`), `cipher` (`Ciphers`) o `MAC` (`MACs`).
   - `Their offer`: todo lo que el servidor acepta. `ext-info-s` y `kex-strict-s-v00` no son algoritmos, sino avisos (extensiones y la defensa contra Terrapin, [semana 11](../../../week-11-2fa_fail2ban_y_auditoria/README.md)): el único de verdad es `diffie-hellman-group14-sha1`.
   - `HostKeyAlias=server`: mismas host keys que el 22, como en el [lab 02](../lab-02-el-lado-del-servidor/README.md).

3. **Tu cliente lo sabe hablar, pero no lo ofrece.**
   ```bash
   ssh -Q kex | grep -c group14-sha1
   ssh -G server | grep ^kexalgorithms | tr , '\n' | grep -c sha1
   ```
   ```
   1
   0
   ```
   - `ssh -Q kex`: lo que tu `ssh` **sabe** hacer (compilado dentro). Ahí está.
   - `ssh -G`: lo que **ofrece** para ese host. Ahí no: OpenSSH lo quitó de la lista por defecto. Quitar de la lista es el primer paso; quitar del programa, años después, el segundo (DSA: fuera de la lista en 7.0, fuera del programa en 10.0).

4. **Añadir, una cosa cada vez.** Con `+`, el algoritmo se **añade al final** de la lista por defecto:
   ```bash
   ssh -p 2223 -o HostKeyAlias=server -o KexAlgorithms=+diffie-hellman-group14-sha1 server true; echo "código: $?"
   ssh -p 2223 -o HostKeyAlias=server -o KexAlgorithms=+diffie-hellman-group14-sha1 -o HostKeyAlgorithms=+ssh-rsa server true; echo "código: $?"
   ```
   ```
   Unable to negotiate with 172.20.0.2 port 2223: no matching host key type found. Their offer: ssh-rsa
   código: 255
   código: 0
   ```
   - Arreglado el intercambio de llaves, aparece la siguiente lista: la host key. Los errores de algoritmos salen **de uno en uno**, en el orden en que se negocian.
   - `ssh-rsa` es una llave RSA firmando con SHA-1. La misma llave RSA firma con SHA-256 si se pide `rsa-sha2-256`; este equipo viejo no lo sabe pedir.
   - Entra sin preguntar por la host key: `known_hosts` ya tiene la llave RSA de `server`. La aprendió tu `ssh` sin avisar en el paso 0 (`UpdateHostKeys`, [lab 07](../lab-07-rotar-host-keys/README.md)).

5. **Solo para ese host.** En `~/.ssh/config` del cliente, un alias con nombre propio:
   ```bash
   cat >> ~/.ssh/config <<'EOF'
   Host viejo
       HostName server
       Port 2223
       HostKeyAlias server
       KexAlgorithms +diffie-hellman-group14-sha1
       HostKeyAlgorithms +ssh-rsa
   EOF
   ssh viejo hostname
   ssh -G viejo | grep ^kexalgorithms | tr , '\n' | tail -2
   ssh -G server | grep -E '^(kexalgorithms|hostkeyalgorithms)' | grep -c sha1
   ```
   ```
   server
   diffie-hellman-group14-sha256
   diffie-hellman-group14-sha1
   0
   ```
   - El `+` deja lo moderno delante: si mañana cambian el equipo por uno nuevo, `viejo` negociará lo mejor que tenga ese equipo sin tocar nada.
   - `server` sigue igual. Tu kit hace lo mismo con todos los alias que empiezan por `legado-` ([proyecto](../../3-proyecto/README.md)).

6. **¿Por qué no en `Host *`?** Con `+` al final, un servidor moderno seguiría eligiendo lo mejor: no empeoraría nada **que veas**. El problema es lo que no ves:
   - Cualquier servidor que solo ofrezca SHA-1 entraría sin un solo aviso, también uno que alguien dejó sin actualizar o un impostor que solo sabe hacer eso.
   - Cuando el último equipo viejo desaparezca, nadie se acordará de quitar la línea.
   - Con un alias, lo viejo tiene nombre: `grep -A3 '^Host' ~/.ssh/config` es la lista de lo que te queda por actualizar.

   Y mira lo que diría una auditoría del equipo viejo:
   ```bash
   ssh-audit -n -p 2223 server | grep -E '^.(gen|kex|key)' | grep -vE 'info|software'; echo "código: ${PIPESTATUS[0]}"
   ```
   ```
   (gen) compatibility: OpenSSH 9.6+, Dropbear SSH 2020.79+
   (kex) diffie-hellman-group14-sha1    -- [fail] using broken SHA-1 hash algorithm
   (key) ssh-rsa (3072-bit)             -- [fail] using broken SHA-1 hash algorithm
   código: 3
   ```
   Lo que pones en el alias es exactamente lo que `ssh-audit` marca como `[fail]`. El arreglo de verdad es actualizar el equipo; el alias es para mientras tanto.

7. **Parar el equipo viejo.**
   ```bash
   ssh server 'sudo pkill -F /run/sshd-viejo.pid'
   ssh viejo true; echo "código: $?"
   ```
   ```
   ssh: connect to host server port 2223: Connection refused
   código: 255
   ```

## Criterios de éxito

- [ ] Lees qué lista no casa y qué ofrece el servidor en un `no matching` (paso 2)
- [ ] Explicas la diferencia entre `ssh -Q` y `ssh -G` (paso 3)
- [ ] Entras añadiendo los algoritmos con `+`, uno por error (paso 4)
- [ ] Dejas los algoritmos viejos solo en un alias y compruebas que `server` no cambia (paso 5)
- [ ] Explicas por qué no se ponen en `Host *` (paso 6)

## Reto extra

Arranca el equipo viejo con `-o PubkeyAcceptedAlgorithms=ssh-rsa` (solo acepta firmas de usuario con SHA-1), crea una llave RSA de 3072 bits y añádela a `authorized_keys`. ¿Qué error ves con `ssh -i LLAVE viejo`? ¿Qué tercera línea necesita el alias? Compara con `conf.d/90-legado.conf` del kit.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 02 — El lado del servidor](../lab-02-el-lado-del-servidor/README.md) | [Lab 04 — Postcuántico](../lab-04-postcuantico/README.md) → |

[↑ Semana 13](../../README.md)
