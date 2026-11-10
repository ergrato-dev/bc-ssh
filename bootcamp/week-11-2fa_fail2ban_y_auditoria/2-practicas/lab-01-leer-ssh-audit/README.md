# Lab 01 — Leer un informe de ssh-audit

⏱ Duración estimada: ~60 min

## Objetivo

Auditar `server` con `ssh-audit` y entender cada parte del informe: qué algoritmos anuncia, cuáles marca como `fail` o `warn` y por qué, qué recomienda quitar y qué significan los avisos de Terrapin y DHEat. Después, auditar tu propio cliente y sacar datos en JSON para un script.

## Contexto

- Qué negocian cliente y servidor y qué mira `ssh-audit`: [teoría 01](../../1-teoria/01-auditar-algoritmos.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación.** En tu equipo, desde la raíz del repositorio:
   ```bash
   docker compose up -d --force-recreate server bastion interno
   docker compose run --rm client
   ```
   `--force-recreate` deja los servidores como recién instalados: cada lab empieza limpio. **En el cliente**, `known_hosts` y una llave de administrador en `server` y `bastion`:
   ```bash
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh ~/w
   ssh-keyscan -t ed25519 server bastion 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -N '' -C admin@client -f ~/.ssh/id_ed25519
   sshpass -e ssh-copy-id -f server 2>&1 | grep 'Number of'
   sshpass -e ssh-copy-id -f bastion 2>&1 | grep 'Number of'
   ```
   ```
   Number of key(s) added: 1
   Number of key(s) added: 1
   ```
   Llave sin frase (`-N ''`) y la contraseña en `SSHPASS`: **solo en el laboratorio**.

1. **El primer informe.**
   ```bash
   ssh-audit server | less -R
   ```
   Lee las secciones en orden:

   | Sección | Qué hay |
   |---|---|
   | `# general` | Banner (`SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.20`), versión y compresión |
   | `# key exchange algorithms` | Cada `KexAlgorithms`, con su nivel |
   | `# host-key algorithms` | Las host keys que presenta el servidor |
   | `# encryption algorithms (ciphers)` | Los `Ciphers` |
   | `# message authentication code algorithms` | Los `MACs` |
   | `# fingerprints` | Huellas de las host keys: las mismas que verificaste en la [semana 02](../../../week-02-protocolo_kex_y_known_hosts/README.md) |
   | `# algorithm recommendations` | Qué quitar (`-`) o añadir (`+`) |
   | `# additional info` | Avisos que no son de un algoritmo: Terrapin, DHEat |

   - `ssh-audit` no entró en `server`: no usó tu llave ni la contraseña. Todo lo que ves lo anuncia el servidor a cualquiera.
   - Pulsa `q` para salir de `less`. `-R` deja pasar los colores.

2. **Solo lo que falla.** `-l warn` oculta los `info`; `-n` quita los colores.
   ```bash
   ssh-audit -n -l warn server; echo "código: $?"
   ```
   ```
   # key exchange algorithms
   (kex) ecdh-sha2-nistp256                    -- [fail] using elliptic curves that are suspected as being backdoored by the U.S. National Security Agency
   (kex) ecdh-sha2-nistp384                    -- [fail] using elliptic curves that are suspected as being backdoored by the U.S. National Security Agency
   (kex) ecdh-sha2-nistp521                    -- [fail] using elliptic curves that are suspected as being backdoored by the U.S. National Security Agency
   (kex) diffie-hellman-group14-sha256         -- [warn] 2048-bit modulus only provides 112-bits of symmetric strength
   # host-key algorithms
   (key) ecdsa-sha2-nistp256                   -- [fail] using elliptic curves that are suspected as being backdoored by the U.S. National Security Agency
                                               `- [warn] using weak random number generator could reveal the key
   # message authentication code algorithms
   (mac) umac-64-etm@openssh.com               -- [warn] using small 64-bit tag size
   (mac) hmac-sha1-etm@openssh.com             -- [fail] using broken SHA-1 hash algorithm
   (mac) umac-64@openssh.com                   -- [warn] using encrypt-and-MAC mode
                                               `- [warn] using small 64-bit tag size
   (mac) umac-128@openssh.com                  -- [warn] using encrypt-and-MAC mode
   (mac) hmac-sha2-256                         -- [warn] using encrypt-and-MAC mode
   (mac) hmac-sha2-512                         -- [warn] using encrypt-and-MAC mode
   (mac) hmac-sha1                             -- [fail] using broken SHA-1 hash algorithm
                                               `- [warn] using encrypt-and-MAC mode
   ...
   código: 3
   ```
   Tres familias de problemas:
   - **Curvas NIST** (`nistp256/384/521`): hay dudas sobre cómo se eligieron sus constantes. Afectan al intercambio de llaves y a la host key ECDSA.
   - **Tamaño**: el grupo 14 (2048 bits) y las etiquetas de 64 bits (`umac-64`) son cortos para los próximos años.
   - **Forma**: los MAC sin `-etm` (*encrypt-then-MAC*) calculan el MAC sobre el texto **sin cifrar**; los `-etm`, sobre el cifrado, que es lo seguro. SHA-1 está roto.

   El código **3** dice «hay algún `fail`»; con solo `warn` sería 2, y con 0 no habría ninguno.

3. **Lo que de verdad se usa.** Que el servidor ofrezca algo débil no quiere decir que tu conexión lo use: gana el primero de **tu** lista que también tenga el servidor.
   ```bash
   ssh -v server true 2>&1 | grep -E 'kex: (algorithm|host key|server->client)'
   ```
   ```
   debug1: kex: algorithm: sntrup761x25519-sha512@openssh.com
   debug1: kex: host key algorithm: ssh-ed25519
   debug1: kex: server->client cipher: chacha20-poly1305@openssh.com MAC: <implicit> compression: none
   ```
   - Tu OpenSSH 9.6 elige lo mejor. Lo débil está para **otros** clientes, y es lo que un atacante en medio intentará forzar.
   - `MAC: <implicit>`: `chacha20-poly1305` es un cifrado *AEAD*, que lleva su propia autenticación; no usa ninguno de los `MACs`.

4. **Las recomendaciones.**
   ```bash
   ssh-audit -n server | grep '(rec)'
   ```
   ```
   (rec) -diffie-hellman-group14-sha256        -- kex algorithm to remove
   (rec) -ecdh-sha2-nistp256                   -- kex algorithm to remove
   (rec) -ecdh-sha2-nistp384                   -- kex algorithm to remove
   (rec) -ecdh-sha2-nistp521                   -- kex algorithm to remove
   (rec) -ecdsa-sha2-nistp256                  -- key algorithm to remove
   (rec) -hmac-sha1                            -- mac algorithm to remove
   (rec) -hmac-sha1-etm@openssh.com            -- mac algorithm to remove
   (rec) -hmac-sha2-256                        -- mac algorithm to remove
   (rec) -hmac-sha2-512                        -- mac algorithm to remove
   (rec) -umac-128@openssh.com                 -- mac algorithm to remove
   (rec) -umac-64-etm@openssh.com              -- mac algorithm to remove
   (rec) -umac-64@openssh.com                  -- mac algorithm to remove
   ```
   Es la lista que convertirás en `15-algoritmos.conf` en el [lab 02](../lab-02-quitar-algoritmos/README.md). Apúntala.

5. **Los dos avisos.**
   ```bash
   ssh-audit -n server | grep '(nfo)' | cut -c1-160
   ```
   ```
   (nfo) For hardening guides on common OSes, please see: <https://www.ssh-audit.com/hardening_guides.html>
   (nfo) Be aware that, while this target properly supports the strict key exchange method (via the kex-strict-?-v00@openssh.com marker) needed to protect a
   (nfo) Potentially insufficient connection throttling detected, resulting in possible vulnerability to the DHEat DoS attack (CVE-2002-20001).  38 connectio
   ```
   - **Terrapin**: `server` tiene la defensa (*strict kex*), pero solo protege si el cliente también la tiene. No se arregla en el servidor quitando algoritmos, sino actualizando clientes.
   - **DHEat**: `ssh-audit` abrió unas 40 conexiones en una décima de segundo y el servidor las aceptó todas. Cada una obliga a `server` a un cálculo caro. Lo frenan `MaxStartups` (tu `10-acceso.conf`), fail2ban ([lab 06](../lab-06-fail2ban/README.md)) y, en **OpenSSH 9.8+**, `PerSourcePenalties`.
   - `--skip-rate-test` no hace esas 40 conexiones: úsalo cuando audites un servidor con fail2ban en modo `aggressive`, o te bloquea.

6. **Dos servidores, el mismo informe.** `bastion` usa la misma imagen:
   ```bash
   diff <(ssh-audit -n --skip-rate-test server | grep -E '^\((kex|key|enc|mac)\)') \
        <(ssh-audit -n --skip-rate-test bastion | grep -E '^\((kex|key|enc|mac)\)') && echo iguales
   ```
   ```
   iguales
   ```
   Algoritmos iguales, huellas distintas (cada contenedor genera sus host keys al arrancar). En una flota, un informe distinto en un servidor es la primera pista de que algo se configuró a mano.

7. **Auditar tu cliente.** Con `-c`, `ssh-audit` se hace pasar por servidor en un puerto y tú te conectas:
   ```bash
   timeout 8 ssh-audit -n -c -p 2222 > ~/w/cliente.txt &
   sleep 1; ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null localhost true
   sleep 1; grep -E '\[(fail|warn)\]' ~/w/cliente.txt | head -5
   ```
   ```
   Connection closed by ::1 port 2222
   (kex) ecdh-sha2-nistp256                           -- [fail] using elliptic curves that are suspected as being backdoored by the U.S. National Security Agency
   (kex) ecdh-sha2-nistp384                           -- [fail] using elliptic curves that are suspected as being backdoored by the U.S. National Security Agency
   (kex) ecdh-sha2-nistp521                           -- [fail] using elliptic curves that are suspected as being backdoored by the U.S. National Security Agency
   (kex) diffie-hellman-group14-sha256                -- [warn] 2048-bit modulus only provides 112-bits of symmetric strength
   (key) ecdsa-sha2-nistp256-cert-v01@openssh.com     -- [fail] using elliptic curves that are suspected as being backdoored by the U.S. National Security Agency
   ```
   - Tu cliente también acepta lo débil, por si un servidor viejo no tiene otra cosa. Endurecer el cliente es otra decisión: la [semana 13](../../../README.md) la retoma.
   - `StrictHostKeyChecking=no` y `UserKnownHostsFile=/dev/null` **solo** aquí: `ssh-audit -c` no es un servidor real y su host key cambia en cada ejecución. Nunca en un `config`.

8. **JSON para scripts.** `-j` da lo mismo en JSON; `jq` lo filtra:
   ```bash
   ssh-audit -j server | jq -r '.kex[] | select(.notes.fail) | .algorithm'
   ssh-audit -j server | jq -r '.fingerprints[] | "\(.hostkey) \(.hash_alg):\(.hash)"' | grep ed25519
   ```
   ```
   ecdh-sha2-nistp256
   ecdh-sha2-nistp384
   ecdh-sha2-nistp521
   ssh-ed25519 SHA256:d2JpqorlQsFHLr4zxI4/+jVmj4qc3zljK3yqmAQqkNY
   ```
   La huella será otra en tu laboratorio. `jq -r 'keys'` enseña todas las secciones del JSON.

## Criterios de éxito

- [ ] Explicas qué ve `ssh-audit` y por qué no necesita cuenta (paso 1)
- [ ] Clasificas los `fail` y `warn` de `server` en curvas NIST, tamaño y forma (paso 2)
- [ ] Distingues lo que el servidor ofrece de lo que tu conexión usa (paso 3)
- [ ] Tienes la lista de algoritmos a quitar (paso 4)
- [ ] Explicas Terrapin y DHEat y qué hace `--skip-rate-test` (paso 5)
- [ ] Auditas tu cliente con `-c` y sacas datos en JSON (pasos 7 y 8)

## Reto extra

`ssh-audit -n --lookup=hmac-sha1` y `ssh-audit -n --lookup=sntrup761x25519-sha512@openssh.com` dicen qué opina de un algoritmo suelto sin conectar a nadie. ¿Qué dice de `mlkem768x25519-sha256`, el intercambio postcuántico de OpenSSH 9.9+?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Índice de labs](../README.md) | [Lab 02 — Quitar algoritmos débiles](../lab-02-quitar-algoritmos/README.md) → |

[↑ Semana 11](../../README.md)
