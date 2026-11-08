# Lab 04 — Un servidor con algoritmos antiguos

⏱ Duración estimada: ~60 min

## Objetivo

Conectarte a un servidor que solo admite algoritmos con SHA-1, leyendo el error de negociación para saber qué activar, y activarlo **solo** para ese host en un `config`, sin rebajar la seguridad del resto.

## Contexto

- En la vida real te los encontrarás: switches, NAS, appliances o servidores sin actualizar desde hace años. OpenSSH moderno desactiva por defecto lo que ellos necesitan, y el error dice exactamente qué falta.
- Simularás ese servidor arrancando un **segundo** `sshd` dentro de `server`, en el puerto 2200, limitado a `diffie-hellman-group14-sha1` y a firmas `ssh-rsa`.
- La forma `+` y la regla "solo en el bloque `Host` que lo necesita" están en la [teoría 02](../../1-teoria/02-intercambio-de-llaves.md#cambiar-las-listas).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d
   docker compose exec server /usr/sbin/sshd -p 2200 -o KexAlgorithms=diffie-hellman-group14-sha1 -o HostKeyAlgorithms=ssh-rsa
   ```
   - `/usr/sbin/sshd` con ruta completa: `sshd` exige que se le llame así.
   - `-p 2200`: otro puerto, para no tocar el `sshd` normal del 22.
   - `-o`: opciones de `sshd_config` en la línea de comandos. Estas dejan una sola opción en cada lista.

   No imprime nada: el nuevo `sshd` se va a segundo plano. Abre el cliente en otra terminal:
   ```bash
   docker compose run --rm client
   ```
   **En el cliente**:
   ```bash
   cd bootcamp/week-02-protocolo_kex_y_known_hosts/2-practicas/lab-04-servidor-antiguo
   export SSHPASS=alumno
   ```

1. Intenta entrar:
   ```bash
   ssh -p 2200 server true
   ```
   ```
   Unable to negotiate with 172.20.0.3 port 2200: no matching key exchange method found. Their offer: diffie-hellman-group14-sha1,ext-info-s,kex-strict-s-v00@openssh.com
   ```
   Se corta en el primer paso: no hay ningún algoritmo de KEX en común. `Their offer` es la lista del servidor. `ext-info-s` y `kex-strict-s-v00@openssh.com` no son algoritmos, son extensiones ([teoría 01](../../1-teoria/01-capas-del-protocolo.md#extensiones-ext-info-y-kex-strict)). El único algoritmo real es `diffie-hellman-group14-sha1`.

2. ¿Lo soporta tu cliente?
   ```bash
   ssh -Q kex | grep group14-sha1
   ```
   ```
   diffie-hellman-group14-sha1
   ```
   Sí: está compilado, pero no en la oferta por defecto (lab-03). Añádelo al final con `+`:
   ```bash
   ssh -p 2200 -o KexAlgorithms=+diffie-hellman-group14-sha1 server true
   ```
   ```
   Unable to negotiate with 172.20.0.3 port 2200: no matching host key type found. Their offer: ssh-rsa
   ```
   El KEX ya pasa; ahora falla el siguiente: el servidor solo firma con `ssh-rsa`, es decir, RSA con SHA-1.

3. Añade los dos:
   ```bash
   ssh -p 2200 -o KexAlgorithms=+diffie-hellman-group14-sha1 -o HostKeyAlgorithms=+ssh-rsa server true
   ```
   ```
   The authenticity of host '[server]:2200 ([172.20.0.3]:2200)' can't be established.
   RSA key fingerprint is SHA256:SxDR3C2HCoPOpuoRGLdkDYX5uaQU2Mk/xaYI7uQaBUI.
   This key is not known by any other names.
   Are you sure you want to continue connecting (yes/no/[fingerprint])?
   ```
   - Fíjate en el nombre: `[server]:2200`. En `known_hosts` cada puerto es un host distinto.
   - Ahora la llave es **RSA**. Verifícala **en tu equipo**:
     ```bash
     docker compose exec server ssh-keygen -lf /etc/ssh/ssh_host_rsa_key.pub
     ```
     ```
     3072 SHA256:SxDR3C2HCoPOpuoRGLdkDYX5uaQU2Mk/xaYI7uQaBUI root@server (RSA)
     ```
   Si coincide, responde `yes` y escribe la contraseña.

4. **TODO.** Escribir esas dos opciones cada vez es incómodo, y ponerlas en `Host *` sería un error grave: **todos** tus servidores aceptarían SHA-1. Abre `starter/config`: tiene el bloque `Host legado` con un TODO. Añade:
   ```
       KexAlgorithms +diffie-hellman-group14-sha1
       HostKeyAlgorithms +ssh-rsa
   ```
   con un comentario Qué / Para qué / Impacto. Comprueba:
   ```bash
   ssh -G -F starter/config legado | grep -E '^(kexalgorithms|hostkeyalgorithms) ' | sed 's/,.*,/,...,/'
   ssh -G -F starter/config server | grep -E '^(kexalgorithms|hostkeyalgorithms) ' | sed 's/,.*,/,...,/'
   ```
   ```
   hostkeyalgorithms ssh-ed25519-cert-v01@openssh.com,...,ssh-rsa
   kexalgorithms sntrup761x25519-sha512@openssh.com,...,diffie-hellman-group14-sha1
   hostkeyalgorithms ssh-ed25519-cert-v01@openssh.com,...,rsa-sha2-256
   kexalgorithms sntrup761x25519-sha512@openssh.com,...,diffie-hellman-group14-sha256
   ```
   `sed 's/,.*,/,...,/'` recorta el centro de la lista para ver solo el primero y el último. `legado` termina en los algoritmos SHA-1; `server` no los tiene.

5. Entra con el alias:
   ```bash
   sshpass -e ssh -v -F starter/config legado true 2>&1 | grep -E 'kex: (algorithm|host key)'
   ```
   ```
   debug1: kex: algorithm: diffie-hellman-group14-sha1
   debug1: kex: host key algorithm: ssh-rsa
   ```
   Como están **al final** de la lista, solo se eligen porque el servidor no admite nada mejor. Si lo actualizan, tu cliente pasará solo a los modernos sin que cambies el `config`.

6. **¿Y `kex-strict`?** El servidor del puerto 2200 lo anuncia (`kex-strict-s-v00@openssh.com`, paso 1) porque es OpenSSH 9.6 con la lista recortada. Un servidor realmente antiguo (anterior a diciembre de 2023) no lo haría y la conexión quedaría expuesta a Terrapin. Compruébalo en un servidor real con `ssh -vv HOST true 2>&1 | grep -c kex-strict-s`: `0` significa que no lo soporta.

7. **`ssh-keyscan` tampoco entra:**
   ```bash
   ssh-keyscan -p 2200 server
   ```
   ```
   # server:2200 SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.20
   # server:2200 SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.20
   ...
   ```
   Solo los comentarios con el banner, sin llaves: `ssh-keyscan` usa la lista de KEX por defecto y no tiene `-o` para cambiarla. Ten en cuenta que el `bin/kh-add` del proyecto saldrá con código 3 para este host; ahí la llave se añade con la verificación manual del paso 3.

8. **Limpieza.** **En tu equipo**, detén el `sshd` del puerto 2200:
   ```bash
   docker compose exec server pkill -f 'sshd -p 2200'
   ```
   `pkill -f` busca el texto en la línea de comandos completa del proceso; así no tocas el `sshd` principal.

## Criterios de éxito

- [ ] Leíste en `Their offer` qué faltaba en cada error (pasos 1 y 2)
- [ ] Verificaste la huella RSA antes de aceptar (paso 3)
- [ ] `ssh -G` muestra los algoritmos SHA-1 en `legado` y no en `server` (paso 4)
- [ ] Explicas por qué `+` en un `Host` concreto y no en `Host *` (pasos 4 y 5)

## Reto extra

Cambia en tu `config` el `+` de `KexAlgorithms` por `^` y comprueba con `ssh -v` qué KEX se elige. Arranca otra vez el `sshd` del 2200 sin la opción `-o KexAlgorithms=...` (solo `-o HostKeyAlgorithms=ssh-rsa`) y conecta con cada versión del `config`. ¿Cuál de las dos versiones usa un KEX débil con un servidor que ya admite los modernos?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 03 — Negociación de algoritmos](../lab-03-negociacion-de-algoritmos/README.md) | [Lab 05 — Host keys y huellas](../lab-05-host-keys-y-huellas/README.md) → |

[↑ Semana 02](../../README.md)
