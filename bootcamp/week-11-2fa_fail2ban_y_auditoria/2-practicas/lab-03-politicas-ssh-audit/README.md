# Lab 03 — Políticas de ssh-audit

⏱ Duración estimada: ~60 min

## Objetivo

Pasar de «leer un informe» a «cumple o no cumple»: probar una política integrada, generar una desde un servidor, escribir la tuya con `allow_algorithm_subset_and_reordering` y comprobar con ella varios servidores, también `interno`, al que solo llegas a través de `bastion`.

## Contexto

- Políticas y sus dos opciones clave: [teoría 01](../../1-teoria/01-auditar-algoritmos.md#políticas).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-leer-ssh-audit/README.md) y el paso 3 del [lab 02](../lab-02-quitar-algoritmos/README.md) (`15-algoritmos.conf` en `server`). `bastion` e `interno` se quedan como vienen.

1. **Las políticas integradas.**
   ```bash
   ssh-audit -L | grep -i ubuntu
   ssh-audit -n -P "Hardened Ubuntu Server 24.04 LTS (version 1)" server | cut -c1-110 | head -14; echo "código: ${PIPESTATUS[0]}"
   ```
   ```
     * "Hardened Ubuntu Server 24.04 LTS (version 1)"
     ...
   Host:   server
   Policy: Hardened Ubuntu Server 24.04 LTS (version 1)
   Result: ❌ Failed!

   Errors:
     * Ciphers did not match.
       - Expected: chacha20-poly1305@openssh.com, aes256-gcm@openssh.com, aes256-ctr, aes192-ctr, aes128-gcm@op
       - Actual:   chacha20-poly1305@openssh.com, aes128-ctr, aes192-ctr, aes256-ctr, aes128-gcm@openssh.com, aes
     * Host key (rsa-sha2-256) sizes did not match.
       - Expected: 4096
       - Actual:   3072
     ...
   código: 3
   ```
   `server` ya no tiene nada débil y aun así no cumple: esta política exige **el mismo orden** y host keys RSA de 4096 bits. Es la configuración de la guía de `ssh-audit`, al pie de la letra. Útil para comparar, no para tus servidores.

2. **Una política generada.** `-M` escribe lo que el servidor ofrece hoy:
   ```bash
   ssh-audit -n -M ~/w/server.txt server
   grep -vE '^(#|$)' ~/w/server.txt | cut -c1-100
   ```
   ```
   Wrote policy to /home/alumno/w/server.txt.  Customize as necessary, then run a policy scan with -P option.
   name = "Custom Policy (based on server on 2026/11/10)"
   version = 1
   allow_algorithm_subset_and_reordering = false
   allow_larger_keys = false
   host_key_sizes = {"rsa-sha2-256": {"hostkey_size": 3072}, "ssh-rsa": {"hostkey_size": 3072}, "rsa-sha2-5
   dh_modulus_sizes = {"diffie-hellman-group-exchange-sha256": 3072}
   host keys = rsa-sha2-512, rsa-sha2-256, ssh-ed25519
   key exchanges = sntrup761x25519-sha512@openssh.com, curve25519-sha256, curve25519-sha256@libssh.org, dif
   ciphers = chacha20-poly1305@openssh.com, aes128-ctr, aes192-ctr, aes256-ctr, aes128-gcm@openssh.com, aes
   macs = umac-128-etm@openssh.com, hmac-sha2-256-etm@openssh.com, hmac-sha2-512-etm@openssh.com
   ```
   Cada línea con `#` del archivo explica su opción: léelas.

3. **Comprobar dos servidores contra ella.**
   ```bash
   ssh-audit -n -P ~/w/server.txt server | head -3
   ssh-audit -n -P ~/w/server.txt bastion | grep -E '^Result|^  \*'; echo "código: ${PIPESTATUS[0]}"
   ```
   ```
   Host:   server
   Policy: Custom Policy (based on server on 2026/11/10) (version 1)
   Result: ✔ Passed
   Result: ❌ Failed!
     * Host keys did not match.
     * Key exchanges did not match.
     * MACs did not match.
   código: 3
   ```
   `bastion` sigue con los valores por defecto: la política dice qué le sobra sin que tengas que leer su informe entero.

4. **Exacta quiere decir exacta.** Cambia en `server` solo el **orden** y la cantidad de cifrados, nada inseguro:
   ```bash
   ssh server 'echo "Ciphers aes256-gcm@openssh.com,chacha20-poly1305@openssh.com" | sudo tee /etc/ssh/sshd_config.d/17-orden.conf; sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ssh-audit -n -P ~/w/server.txt server | grep -A3 '^Errors'
   ```
   ```
   Ciphers aes256-gcm@openssh.com,chacha20-poly1305@openssh.com
   Errors:
     * Ciphers did not match.
       - Expected: chacha20-poly1305@openssh.com, aes128-ctr, aes192-ctr, aes256-ctr, aes128-gcm@openssh.com, aes256-gcm@openssh.com
       - Actual:   aes256-gcm@openssh.com, chacha20-poly1305@openssh.com
   ```
   `server` es **más** estricto que antes y la política dice que no cumple. Una política generada sirve para detectar cualquier cambio; para decidir si un servidor es seguro, necesitas otra cosa.

5. **Tu política: lo permitido.** Escribe la del kit a mano:
   ```bash
   cat > ~/w/kit.txt <<'FIN'
   name = "ssh-infra-kit"
   version = 1
   allow_algorithm_subset_and_reordering = true
   allow_larger_keys = true
   host_key_sizes = {"rsa-sha2-512": {"hostkey_size": 3072}, "rsa-sha2-256": {"hostkey_size": 3072}, "ssh-ed25519": {"hostkey_size": 256}}
   dh_modulus_sizes = {"diffie-hellman-group-exchange-sha256": 3072}
   host keys = ssh-ed25519, rsa-sha2-512, rsa-sha2-256
   optional host keys = ssh-ed25519-cert-v01@openssh.com, rsa-sha2-512-cert-v01@openssh.com, rsa-sha2-256-cert-v01@openssh.com
   key exchanges = mlkem768x25519-sha256, sntrup761x25519-sha512@openssh.com, curve25519-sha256, curve25519-sha256@libssh.org, diffie-hellman-group-exchange-sha256, diffie-hellman-group16-sha512, diffie-hellman-group18-sha512, ext-info-s, kex-strict-s-v00@openssh.com
   ciphers = chacha20-poly1305@openssh.com, aes256-gcm@openssh.com, aes128-gcm@openssh.com, aes256-ctr, aes192-ctr, aes128-ctr
   macs = hmac-sha2-512-etm@openssh.com, hmac-sha2-256-etm@openssh.com, umac-128-etm@openssh.com
   FIN
   ssh-audit -n -P ~/w/kit.txt server | head -3
   ```
   ```
   Host:   server
   Policy: ssh-infra-kit (version 1)
   Result: ✔ Passed
   ```
   - `allow_algorithm_subset_and_reordering = true`: el servidor puede ofrecer **menos** (los dos cifrados del paso 4) o en otro orden; nunca algo que no esté en la lista.
   - `allow_larger_keys = true`: una RSA de 4096 bits también vale; una de 2048, no.
   - `mlkem768x25519-sha256` (**OpenSSH 9.9+**) está permitido aunque 9.6 no lo tenga: cuando actualices, la política seguirá cumpliéndose.
   - `optional host keys`: los certificados de host de la [semana 10](../../../week-10-certificados_ssh_ca_principals_krl_y_rotacion/README.md) pueden estar o no.
   - `ext-info-s` y `kex-strict-s-v00@openssh.com` no son algoritmos: son avisos de que el servidor admite extensiones y la defensa contra Terrapin. Si no los pones, la política falla.

   Deshaz el cambio del paso 4:
   ```bash
   ssh server 'sudo rm /etc/ssh/sshd_config.d/17-orden.conf; sudo kill -HUP $(cat /run/sshd.pid)'
   ```

6. **Toda la flota.** Con un bucle tienes, en tres líneas, lo que `bin/audit` hará en el proyecto:
   ```bash
   for h in server bastion; do
     ssh-audit -n -P ~/w/kit.txt $h > /dev/null; echo "$h: $?"
   done
   ```
   ```
   server: 0
   bastion: 3
   ```

7. **`interno`, a través del bastion.** `ssh-audit` no sabe usar `ProxyJump`, pero sí un puerto local. Un túnel de la [semana 08](../../../week-08-port_forwarding_socks_y_tuneles/README.md) basta:
   ```bash
   ssh -f -N -o ExitOnForwardFailure=yes -L 2222:interno:22 bastion
   ssh-audit -n -P ~/w/kit.txt -p 2222 127.0.0.1 | head -3; echo "código: ${PIPESTATUS[0]}"
   pkill -f '^ssh -f -N -o ExitOnForwardFailure=yes -L 2222'
   ```
   ```
   Host:   127.0.0.1:2222
   Policy: ssh-infra-kit (version 1)
   Result: ❌ Failed!
   código: 3
   ```
   La red privada no te libra de auditar: `interno` tiene los mismos algoritmos débiles que `bastion`.

8. **JSON.** Para un panel o un informe:
   ```bash
   ssh-audit -j -P ~/w/kit.txt bastion | jq -c '{passed, errors: [.errors[].mismatched_field]}'
   ```
   ```
   {"passed":false,"errors":["Host keys","Key exchanges","MACs"]}
   ```

## Criterios de éxito

- [ ] Explicas por qué `server` no cumple la política integrada de Ubuntu 24.04 (paso 1)
- [ ] Generas una política con `-M` y compruebas dos servidores (pasos 2 y 3)
- [ ] Explicas por qué una política exacta falla con un servidor más estricto (paso 4)
- [ ] Escribes una política con subconjunto y explicas cada opción, también `ext-info-s` (paso 5)
- [ ] Compruebas `server`, `bastion` e `interno` contra tu política (pasos 6 y 7)

## Reto extra

Quita `ext-info-s` de `~/w/kit.txt` y vuelve a comprobar `server`. ¿Qué error da? Ahora genera una política de **cliente** (`ssh-audit -M cliente.txt -c -p 2222` y conecta con `ssh -p 2222 localhost`). ¿Qué cambia en el archivo?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 02 — Quitar algoritmos débiles](../lab-02-quitar-algoritmos/README.md) | [Lab 04 — TOTP por dentro](../lab-04-totp-por-dentro/README.md) → |

[↑ Semana 11](../../README.md)
