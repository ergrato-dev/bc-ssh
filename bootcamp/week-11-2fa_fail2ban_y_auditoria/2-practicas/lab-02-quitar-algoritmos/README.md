# Lab 02 — Quitar algoritmos débiles

⏱ Duración estimada: ~60 min

## Objetivo

Convertir las recomendaciones de `ssh-audit` en un `15-algoritmos.conf` con listas `-`, comprobar el resultado con `sshd -T` y con `ssh-audit`, y ver exactamente qué les pasa a los clientes que solo hablaban lo que quitaste.

## Contexto

- Las tres formas de una lista de algoritmos (`-`, `+` y completa): [teoría 01](../../1-teoria/01-auditar-algoritmos.md#quitar-sin-escribir-la-lista-entera).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-leer-ssh-audit/README.md). Ten a mano la lista de recomendaciones de su paso 4.

1. **Lo que hay ahora.** `sshd -T` imprime la configuración que usa `sshd`, con los valores por defecto incluidos:
   ```bash
   ssh server sudo sshd -T | grep -E '^(kexalgorithms|hostkeyalgorithms|macs) ' | tr , ' ' | fold -s -w 110
   ```
   ```
   macs umac-64-etm@openssh.com umac-128-etm@openssh.com hmac-sha2-256-etm@openssh.com hmac-sha2-512-etm@openssh.com
   hmac-sha1-etm@openssh.com umac-64@openssh.com umac-128@openssh.com hmac-sha2-256 hmac-sha2-512 hmac-sha1
   kexalgorithms sntrup761x25519-sha512@openssh.com curve25519-sha256 curve25519-sha256@libssh.org ecdh-sha2-nistp256
   ecdh-sha2-nistp384 ecdh-sha2-nistp521 diffie-hellman-group-exchange-sha256 diffie-hellman-group16-sha512
   diffie-hellman-group18-sha512 diffie-hellman-group14-sha256
   hostkeyalgorithms ssh-ed25519-cert-v01@openssh.com ecdsa-sha2-nistp256-cert-v01@openssh.com ...
   ```
   `tr` y `fold` solo parten las líneas para leerlas: `sshd -T` escribe cada lista en una sola línea separada por comas.

2. **De recomendaciones a tres líneas.** Agrupa la lista del lab 01 con comodines:

   | Recomendación | Línea |
   |---|---|
   | `-ecdh-sha2-nistp256/384/521`, `-diffie-hellman-group14-sha256` | `KexAlgorithms -ecdh-sha2-nistp*,diffie-hellman-group14-sha256` |
   | `-ecdsa-sha2-nistp256` | `HostKeyAlgorithms -ecdsa-sha2-*,sk-ecdsa-sha2-*` |
   | `-hmac-sha1`, `-hmac-sha1-etm`, `-umac-64`, `-umac-64-etm`, `-hmac-sha2-256`, `-hmac-sha2-512`, `-umac-128` | `MACs -*-sha1*,umac-64*,hmac-sha2-256,hmac-sha2-512,umac-128@openssh.com` |

   - `ecdsa-sha2-*` quita también las versiones con certificado (`ecdsa-sha2-nistp256-cert-v01@openssh.com`); `sk-ecdsa-sha2-*`, las de llaves FIDO2 con curva NIST, que `ssh-audit` no ve porque el servidor no tiene esa host key.
   - `hmac-sha2-256` sin comodín: `hmac-sha2-256*` quitaría también `hmac-sha2-256-etm@openssh.com`, que es bueno.

3. **Aplicarlo.**
   ```bash
   ssh server 'sudo tee /etc/ssh/sshd_config.d/15-algoritmos.conf' <<'FIN'
   KexAlgorithms -ecdh-sha2-nistp*,diffie-hellman-group14-sha256
   HostKeyAlgorithms -ecdsa-sha2-*,sk-ecdsa-sha2-*
   MACs -*-sha1*,umac-64*,hmac-sha2-256,hmac-sha2-512,umac-128@openssh.com
   FIN
   ssh server 'sudo sshd -t && sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ssh server sudo sshd -T | grep -E '^(kexalgorithms|macs) '
   ```
   ```
   KexAlgorithms -ecdh-sha2-nistp*,diffie-hellman-group14-sha256
   HostKeyAlgorithms -ecdsa-sha2-*,sk-ecdsa-sha2-*
   MACs -*-sha1*,umac-64*,hmac-sha2-256,hmac-sha2-512,umac-128@openssh.com
   macs umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
   kexalgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
   ```
   - `sudo tee` escribe como root lo que le llega por la entrada; las comillas de `'FIN'` impiden que tu shell toque los `*`.
   - `sshd -t` antes de recargar, siempre ([semana 07](../../../week-07-servidor_sshd_config_y_hardening/README.md)): un error aquí y `sshd` no vuelve a arrancar.
   - Tu conexión de ahora no notó nada: los algoritmos se eligen al conectar.

4. **Auditar otra vez.**
   ```bash
   ssh-audit -n -l warn --skip-rate-test server | cut -c1-100; echo "código: ${PIPESTATUS[0]}"
   ```
   ```
   # additional info
   (nfo) Be aware that, while this target properly supports the strict key exchange method (via the
   código: 0
   ```
   Ni `fail` ni `warn`: queda la nota de Terrapin, que depende de los clientes (lab 01, paso 5).

5. **Un cliente que solo habla lo que quitaste.** `-o` cambia las listas del cliente en una conexión; así simulas un cliente viejo:
   ```bash
   ssh -o KexAlgorithms=ecdh-sha2-nistp256 server true; echo "código: $?"
   ssh -o Ciphers=aes128-ctr -o MACs=hmac-sha1 server true; echo "código: $?"
   ssh -o HostKeyAlgorithms=ecdsa-sha2-nistp256 server true; echo "código: $?"
   ```
   ```
   Unable to negotiate with 172.20.0.2 port 22: no matching key exchange method found. Their offer: sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,ext-info-s,kex-strict-s-v00@openssh.com
   código: 255
   Unable to negotiate with 172.20.0.2 port 22: no matching MAC found. Their offer: umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
   código: 255
   Unable to negotiate with 172.20.0.2 port 22: no matching host key type found. Their offer: rsa-sha2-512,rsa-sha2-256,ssh-ed25519
   código: 255
   ```
   - Es el mensaje que verá quien use un cliente antiguo. `Their offer` es la lista del servidor: el cliente sabe qué le falta.
   - `-o Ciphers=aes128-ctr` en la segunda: con `chacha20-poly1305` o `aes-gcm` no se usa ningún MAC (son AEAD) y la conexión no fallaría.
   - Antes de quitar algo en un servidor de verdad, busca en su log qué algoritmos usan los clientes (con `LogLevel DEBUG1`, `kex: algorithm:`) o pregunta.

6. **La host key ECDSA ya no se presenta.**
   ```bash
   ssh-keyscan -t ecdsa server; echo "código: $?"
   ssh-keyscan -t ed25519 server 2>/dev/null | cut -c1-60
   ```
   ```
   # server:22 SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.20
   código: 1
   server ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAh4Vw9EzXIJkAU
   ```
   El archivo `/etc/ssh/ssh_host_ecdsa_key` sigue en el servidor, pero `sshd` ya no lo ofrece. Un cliente que solo tuviera guardada esa llave en `known_hosts` vería `no matching host key type`; por eso tu kit guarda la Ed25519 desde la [semana 02](../../../week-02-protocolo_kex_y_known_hosts/README.md).

7. **El `+` también existe.** Añadir es igual de fácil, y más peligroso:
   ```bash
   ssh server 'echo "Ciphers +aes256-cbc" | sudo tee /etc/ssh/sshd_config.d/16-prueba.conf; sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ssh-audit -n -l warn --skip-rate-test server | grep -E '^\((enc|rec)\)'; echo "código: ${PIPESTATUS[0]}"
   ssh server 'sudo rm /etc/ssh/sshd_config.d/16-prueba.conf; sudo kill -HUP $(cat /run/sshd.pid)'
   ```
   ```
   Ciphers +aes256-cbc
   (enc) aes256-cbc                            -- [warn] using weak cipher mode
   (rec) -aes256-cbc                           -- enc algorithm to remove
   código: 2
   ```
   Código **2**: hay `warn` pero ningún `fail`. Un `+` para «que conecte ese equipo viejo» se queda años: si lo necesitas, ponlo en un `Match Address` solo para la IP de ese equipo.

8. **Lo mismo vale para el cliente.** Tu `ssh` también tiene listas (`ssh -G server | grep ^kexalgorithms`) y sabe más de los que usa por defecto (`ssh -Q kex`, `ssh -Q mac`). No lo tocas esta semana: un cliente endurecido deja de entrar en servidores viejos que no controlas.

## Criterios de éxito

- [ ] Lees las listas reales con `sshd -T` (paso 1)
- [ ] Conviertes las recomendaciones en tres líneas con `-` y comodines, y explicas por qué `hmac-sha2-256` va sin `*` (paso 2)
- [ ] `ssh-audit -l warn` de `server` sale con 0 (paso 4)
- [ ] Reproduces los tres `Unable to negotiate` y explicas por qué el de MAC necesita `-o Ciphers=aes128-ctr` (paso 5)
- [ ] Explicas qué pasa con un cliente que solo conocía la host key ECDSA (paso 6)
- [ ] Explicas el código 2 y el riesgo de un `+` (paso 7)

## Reto extra

Pon `KexAlgorithms` con solo `sntrup761x25519-sha512@openssh.com` en un archivo de prueba y conecta con `ssh -o KexAlgorithms=curve25519-sha256 server`. ¿Cuántos clientes reales dejarías fuera con un servidor así? Busca desde qué versión de OpenSSH existe con `ssh-audit -n --lookup=sntrup761x25519-sha512@openssh.com`. Después borra el archivo.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 01 — Leer un informe de ssh-audit](../lab-01-leer-ssh-audit/README.md) | [Lab 03 — Políticas de ssh-audit](../lab-03-politicas-ssh-audit/README.md) → |

[↑ Semana 11](../../README.md)
