# Lab 03 — Negociación de algoritmos

⏱ Duración estimada: ~60 min

## Objetivo

Ver las listas que ofrece cada lado, aplicar a mano la regla "gana el primero del cliente que el servidor soporte" y cambiar las listas con `+`, `-` y `^` comprobando el efecto antes de conectar.

## Contexto

- La regla y las cuatro formas de modificar una lista están en la [teoría 02](../../1-teoria/02-intercambio-de-llaves.md#la-regla-decide-el-orden-del-cliente).
- Tres comandos responden a tres preguntas distintas: `ssh -Q` (qué sabe hacer el binario), `ssh -G` (qué ofrecerá el cliente a ese host) y `sshd -T` (qué acepta el servidor). Confundirlos es el error más común al depurar algoritmos.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d
   docker compose run --rm client
   ```
   **En el cliente**:
   ```bash
   cd bootcamp/week-02-protocolo_kex_y_known_hosts/2-practicas/lab-03-negociacion-de-algoritmos
   export SSHPASS=alumno
   ssh server true
   ```
   Verifica la huella, responde `yes` y escribe la contraseña.

1. **Lo que sabe hacer el cliente:**
   ```bash
   ssh -Q kex
   ```
   ```
   diffie-hellman-group1-sha1
   diffie-hellman-group14-sha1
   diffie-hellman-group14-sha256
   diffie-hellman-group16-sha512
   diffie-hellman-group18-sha512
   diffie-hellman-group-exchange-sha1
   diffie-hellman-group-exchange-sha256
   ecdh-sha2-nistp256
   ecdh-sha2-nistp384
   ecdh-sha2-nistp521
   curve25519-sha256
   curve25519-sha256@libssh.org
   sntrup761x25519-sha512@openssh.com
   ```
   Trece algoritmos, en orden alfabético más o menos, **no** de preferencia. `group1-sha1` está aquí porque el binario lo soporta, aunque no lo ofrezca.

   Cuenta los de cada tipo:
   ```bash
   for t in kex cipher mac key; do echo "$t $(ssh -Q $t | wc -l)"; done
   ```
   ```
   kex 13
   cipher 10
   mac 16
   key 16
   ```

2. **Lo que ofrecerá a `server`:**
   ```bash
   ssh -G server | grep '^kexalgorithms' | tr ',' '\n'
   ```
   ```
   kexalgorithms sntrup761x25519-sha512@openssh.com
   curve25519-sha256
   curve25519-sha256@libssh.org
   ecdh-sha2-nistp256
   ecdh-sha2-nistp384
   ecdh-sha2-nistp521
   diffie-hellman-group-exchange-sha256
   diffie-hellman-group16-sha512
   diffie-hellman-group18-sha512
   diffie-hellman-group14-sha256
   ```
   `tr ',' '\n'` cambia cada coma por un salto de línea. Esta sí es la lista **ordenada por preferencia**, y no tiene ni `group1-sha1` ni `group14-sha1`.

3. **Lo que acepta el servidor.** **En tu equipo**:
   ```bash
   docker compose exec server sshd -T | grep -E '^(kexalgorithms|ciphers) '
   ```
   ```
   ciphers chacha20-poly1305@openssh.com,aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com
   kexalgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,ecdh-sha2-nistp256,...
   ```
   `sshd -T` imprime la configuración efectiva del servidor; necesita root, por eso va con `docker compose exec`. Los dos lados tienen OpenSSH 9.6 con valores por defecto: las listas coinciden.

4. **Las listas dentro de la conexión.** `ssh -vv` imprime el `KEXINIT` de cada lado:
   ```bash
   sshpass -e ssh -vv server true 2>&1 | grep -A3 'KEXINIT proposal' | cut -c1-90
   ```
   ```
   debug2: local client KEXINIT proposal
   debug2: KEX algorithms: sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sh
   debug2: host key algorithms: ssh-ed25519-cert-v01@openssh.com,ecdsa-sha2-nistp256-cert-v01
   debug2: ciphers ctos: chacha20-poly1305@openssh.com,aes128-ctr,aes192-ctr,aes256-ctr,aes12
   --
   debug2: peer server KEXINIT proposal
   debug2: KEX algorithms: sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sh
   debug2: host key algorithms: rsa-sha2-512,rsa-sha2-256,ecdsa-sha2-nistp256,ssh-ed25519
   debug2: ciphers ctos: chacha20-poly1305@openssh.com,aes128-ctr,aes192-ctr,aes256-ctr,aes12
   ```
   `grep -A3` imprime cada coincidencia y las 3 líneas siguientes. Fíjate en `host key algorithms` del servidor: **solo** los tipos de las host keys que tiene. El servidor anuncia `rsa-sha2-512` primero, pero gana `ssh-ed25519` porque decide el orden del cliente.

5. **TODO de `starter/elegido.sh`.** El script ya extrae las dos listas de cada función (`lista`) y al final imprime lo que eligió `ssh`. Falta `primero`, que aplica la regla:
   ```bash
   primero() {
     local alg
     for alg in ${1//,/ }; do
       [[ ",$2," == *",$alg,"* ]] && { echo "$alg"; return; }
     done
     echo "(ninguno)"
   }
   ```
   - `${1//,/ }` cambia todas las comas de la lista del cliente por espacios, para que `for` recorra un algoritmo cada vez.
   - `",$2,"` rodea la lista del servidor con comas, y `*",$alg,"*` busca el algoritmo entre comas. Sin ellas, `aes128-ctr` "estaría" dentro de `aes128-ctr-falso`.
   - `return` sale de la función al encontrar el primero.

   ```bash
   ./starter/elegido.sh server
   ```
   ```
   KEX algorithms:      sntrup761x25519-sha512@openssh.com
   host key algorithms: ssh-ed25519
   ciphers ctos:        chacha20-poly1305@openssh.com
   MACs ctos:           umac-64-etm@openssh.com
   --- ssh eligió:
   kex: algorithm: sntrup761x25519-sha512@openssh.com
   kex: host key algorithm: ssh-ed25519
   kex: client->server cipher: chacha20-poly1305@openssh.com MAC: <implicit> compression: none
   ```
   Tu cálculo y el de `ssh` coinciden. El MAC sale `umac-64-etm` en tu cálculo y `<implicit>` en `ssh`: con un cifrado AEAD la lista de MAC se negocia pero no se usa.

6. **Cambia el orden del cliente.** Pasa opciones extra al script (llegan a `ssh`):
   ```bash
   ./starter/elegido.sh server -o Ciphers=aes128-ctr,aes256-gcm@openssh.com -o MACs=hmac-sha2-512
   ```
   ```
   KEX algorithms:      sntrup761x25519-sha512@openssh.com
   host key algorithms: ssh-ed25519
   ciphers ctos:        aes128-ctr
   MACs ctos:           hmac-sha2-512
   --- ssh eligió:
   kex: algorithm: sntrup761x25519-sha512@openssh.com
   kex: host key algorithm: ssh-ed25519
   kex: client->server cipher: aes128-ctr MAC: hmac-sha2-512 compression: none
   ```
   `aes128-ctr` no es AEAD: ahora sí se usa un MAC aparte.

7. **Las cuatro formas de modificar una lista.** Compruébalas con `ssh -G`, sin conectar:
   ```bash
   ssh -G -o KexAlgorithms=-sntrup761x25519-sha512@openssh.com x | grep '^kexalgorithms' | cut -c1-80
   ssh -G -o 'KexAlgorithms=^curve25519-sha256' x | grep '^kexalgorithms' | cut -c1-80
   ssh -G -o KexAlgorithms=+diffie-hellman-group14-sha1 x | grep '^kexalgorithms' | tr ',' '\n' | tail -2
   ```
   ```
   kexalgorithms curve25519-sha256,curve25519-sha256@libssh.org,ecdh-sha2-nistp256,
   kexalgorithms curve25519-sha256,sntrup761x25519-sha512@openssh.com,curve25519-sha
   diffie-hellman-group14-sha256
   diffie-hellman-group14-sha1
   ```
   - `-` quitó `sntrup761x25519` de la cabeza.
   - `^` puso `curve25519-sha256` delante y dejó el resto igual.
   - `+` añadió `group14-sha1` **al final**: solo se usaría si el servidor no admite ninguno de los anteriores.

   El `^` va entre comillas simples porque en algunas shells tiene significado especial.

8. **Conecta con un algoritmo concreto:**
   ```bash
   sshpass -e ssh -v -o KexAlgorithms=curve25519-sha256 -o Ciphers=aes256-gcm@openssh.com server true 2>&1 | grep -E 'kex: (algorithm|server->client)'
   ```
   ```
   debug1: kex: algorithm: curve25519-sha256
   debug1: kex: server->client cipher: aes256-gcm@openssh.com MAC: <implicit> compression: none
   ```

9. **Errores.** Un nombre mal escrito lo detecta el cliente antes de conectar:
   ```bash
   ssh -o KexAlgorithms=curve25519 server true
   ```
   ```
   Unsupported KEX algorithm "curve25519"
   command-line line 0: Bad SSH2 KexAlgorithms 'curve25519'.
   ```
   Uno válido que el servidor no acepta llega hasta la negociación:
   ```bash
   ssh -o KexAlgorithms=diffie-hellman-group1-sha1 server true
   ```
   ```
   Unable to negotiate with 172.20.0.3 port 22: no matching key exchange method found. Their offer: sntrup761x25519-sha512@openssh.com,curve25519-sha256,...
   ```
   El primero es un error de **configuración**; el segundo, de **negociación**. `Their offer` es la lista del servidor.

## Criterios de éxito

- [ ] Explicas la diferencia entre `ssh -Q`, `ssh -G` y `sshd -T` (pasos 1 a 3)
- [ ] Explicas por qué gana `ssh-ed25519` aunque el servidor anuncie `rsa-sha2-512` primero (paso 4)
- [ ] `./starter/elegido.sh server` coincide con lo que eligió `ssh` (paso 5)
- [ ] Explicas el efecto de `+`, `-` y `^` (paso 7)
- [ ] Distingues un error de configuración de uno de negociación (paso 9)

## Reto extra

Ejecuta `./starter/elegido.sh server -o HostKeyAlgorithms=ecdsa-sha2-nistp256`. La conexión falla. Lee el error completo (quita el `2>&1 | ...` del script o ejecuta `ssh` a mano) y explícalo con la [teoría 03](../../1-teoria/03-host-keys-y-known_hosts.md#qué-tipo-elige-el-cliente). Lo verás en detalle en el lab-05.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 02 — Mensajes y capas en `ssh -vvv`](../lab-02-mensajes-y-capas/README.md) | [Lab 04 — Un servidor con algoritmos antiguos](../lab-04-servidor-antiguo/README.md) → |

[↑ Semana 02](../../README.md)
