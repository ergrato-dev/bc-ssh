# Lab 04 — Postcuántico

⏱ Duración estimada: ~60 min

## Objetivo

Comprobar qué intercambio de llaves postcuántico usan tus conexiones, qué pasa cuando no lo usan, qué cuesta en tiempo y bytes, y cómo exigirlo en un servidor sin romperlo: ni para los clientes viejos sin avisar, ni para el propio `sshd` con un nombre que su versión no conoce.

## Contexto

- *Store now, decrypt later*, los híbridos y por qué las host keys aún no son postcuánticas: [teoría 02](../../1-teoria/02-algoritmos-y-postcuantico.md#postcuántico-guardar-hoy-descifrar-mañana).
- El laboratorio usa OpenSSH 9.6: tiene `sntrup761x25519-sha512`, no `mlkem768x25519-sha256` (9.9+). Lo que hagas aquí sirve igual con los dos.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-leer-ssh-v/README.md).

1. **Qué sabe hacer tu `ssh`.**
   ```bash
   ssh -Q kex | grep -E 'sntrup|mlkem'
   ```
   ```
   sntrup761x25519-sha512@openssh.com
   ```
   Un solo algoritmo postcuántico, y es **híbrido**: combina sntrup761 (resistente a un ordenador cuántico) con X25519 (el clásico de siempre). Para descifrar la sesión hay que romper los dos. Con OpenSSH 9.9 o posterior verás también `mlkem768x25519-sha256`, el mismo esquema con ML-KEM, el estándar del NIST (FIPS 203).

2. **Qué usan tus conexiones.**
   ```bash
   ssh -v server true 2>&1 | grep 'kex: algorithm'
   ```
   ```
   debug1: kex: algorithm: sntrup761x25519-sha512@openssh.com
   ```
   Es el primero de tu lista y el servidor lo admite: postcuántico sin haber hecho nada. OpenSSH lo tiene por defecto desde la 9.0 (2022). Si tu servidor tiene una versión anterior, o una configuración que lo quita, la sesión **no** lo es.

3. **Una conexión que no lo es.** Simula un servidor o un cliente sin postcuántico pidiendo solo X25519:
   ```bash
   ssh -v -o KexAlgorithms=curve25519-sha256 server true 2>&1 | grep 'kex: algorithm'
   ```
   ```
   debug1: kex: algorithm: curve25519-sha256
   ```
   Con OpenSSH 9.6 no hay ningún aviso. Desde la 10.1, el cliente avisa en cada conexión así:
   ```
   ** WARNING: connection is not using a post-quantum key exchange algorithm.
   ** This session may be vulnerable to "store now, decrypt later" attacks.
   ** The server may need to be upgraded. See https://openssh.com/pq.html
   ```
   El aviso se controla con `WarnWeakCrypto` en `ssh_config`. Apagarlo para un host concreto que no puedes actualizar (`Match host ...` y `WarnWeakCrypto no-pq-kex`) es aceptar el riesgo **por escrito**; apagarlo para todos es no enterarse. Tu `bin/doctor` del proyecto lo dice con cualquier versión: `(no postcuántico)`.

4. **Un servidor que lo exige.** Un segundo `sshd` en `server`, en el 2224, solo con el híbrido:
   ```bash
   ssh server 'sudo /usr/sbin/sshd -p 2224 -o KexAlgorithms=sntrup761x25519-sha512@openssh.com -o PidFile=/run/sshd-pq.pid'
   ssh -p 2224 -o HostKeyAlias=server server hostname
   ssh -p 2224 -o HostKeyAlias=server -o KexAlgorithms=curve25519-sha256 server true; echo "código: $?"
   ssh server 'sudo pkill -F /run/sshd-pq.pid'
   ```
   ```
   server
   Unable to negotiate with 172.20.0.2 port 2224: no matching key exchange method found. Their offer: sntrup761x25519-sha512@openssh.com,ext-info-s,kex-strict-s-v00@openssh.com
   código: 255
   ```
   - Tu cliente entra; un cliente sin postcuántico (anterior a 9.0, o PuTTY, una librería o un CI viejo) se queda fuera con el error del [lab 03](../lab-03-sin-algoritmo-en-comun/README.md), visto desde el otro lado.
   - Antes de exigirlo en un servidor de verdad, busca en su log quién entra con qué: con `LogLevel DEBUG1` (`40-salto.conf` del kit) aparece `kex: algorithm:` por conexión.

5. **La trampa: un nombre que tu `sshd` no conoce.** Quieres dejar escrito `mlkem768x25519-sha256` para cuando actualices. Prueba tres formas en `server` (con `sshd -t`, sin recargar):
   ```bash
   ssh server 'for l in "KexAlgorithms mlkem768x25519-sha256,sntrup761x25519-sha512@openssh.com,curve25519-sha256" "KexAlgorithms +mlkem768x25519-sha256" "KexAlgorithms -mlkem768x25519-sha256"; do
     echo "$l" | sudo tee /etc/ssh/sshd_config.d/05-prueba.conf >/dev/null
     sudo sshd -t; echo "código: $?"
   done
   sudo rm /etc/ssh/sshd_config.d/05-prueba.conf'
   ```
   ```
   Unsupported KEX algorithm "mlkem768x25519-sha256"
   /etc/ssh/sshd_config.d/05-prueba.conf line 1: Bad SSH2 KexAlgorithms 'mlkem768x25519-sha256,sntrup761x25519-sha512@openssh.com,curve25519-sha256'.
   código: 255
   Unsupported KEX algorithm "mlkem768x25519-sha256"
   /etc/ssh/sshd_config.d/05-prueba.conf line 1: Bad SSH2 KexAlgorithms '+mlkem768x25519-sha256'.
   código: 255
   código: 0
   ```
   - Una lista o un `+` con un nombre desconocido **rompen** la configuración: con un `kill -HUP` sin validar, ese `sshd` deja de escuchar.
   - Quitar (`-`) algo que no existe no molesta. Por eso `15-algoritmos.conf` del kit (semana 11) **quita** lo malo en lugar de escribir la lista buena: al actualizar OpenSSH, `mlkem768x25519-sha256` entra solo.
   - En una flota con versiones mezcladas, el mismo archivo tiene que valer en todas: otra razón para validar en cada servidor (el playbook de la [semana 12](../../../week-12-automatizacion_scripting_ci_cd_y_ansible/README.md) lo hace).

6. **Ponerlo primero sin escribir la lista.** `^` mueve algoritmos al **principio** de la lista por defecto:
   ```bash
   ssh server 'echo "KexAlgorithms ^sntrup761x25519-sha512@openssh.com" | sudo tee /etc/ssh/sshd_config.d/05-prueba.conf >/dev/null
   sudo sshd -t && sudo sshd -T | grep ^kexalgorithms | cut -c1-90
   sudo rm /etc/ssh/sshd_config.d/05-prueba.conf'
   ```
   ```
   kexalgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libss
   ```
   Aquí no cambia nada (ya era el primero), pero en una configuración heredada que alguien reordenó, `^` lo devuelve arriba. Recuerda que en el servidor el orden importa poco: gana el primero **del cliente** (lab 01, paso 3).

7. **Lo que cuesta.** Veinte conexiones con cada uno, y los bytes de una:
   ```bash
   TIMEFORMAT='%R s'
   for k in sntrup761x25519-sha512@openssh.com curve25519-sha256; do
     echo -n "$k "; time (for i in $(seq 20); do ssh -o KexAlgorithms=$k server true; done)
   done
   for k in sntrup761x25519-sha512@openssh.com curve25519-sha256; do ssh -v -o KexAlgorithms=$k server true 2>&1 | grep Transferred; done
   ```
   ```
   sntrup761x25519-sha512@openssh.com 3.807 s
   curve25519-sha256 2.734 s
   Transferred: sent 3364, received 4012 bytes, in 0.1 seconds
   Transferred: sent 2188, received 2972 bytes, in 0.1 seconds
   ```
   - Unos 50 ms y 2 KB más por conexión (tus tiempos dependen de tu equipo). Se pagan **una vez**, al conectar: después, el cifrado es el mismo.
   - Con multiplexing (tu kit), una vez por master. Para un script que abre cientos de conexiones sin master, sí se nota: el arreglo es el master, no quitar el postcuántico.

## Criterios de éxito

- [ ] Dices qué algoritmos postcuánticos tiene tu `ssh` y por qué son híbridos (paso 1)
- [ ] Compruebas qué intercambio usa una conexión y reconoces una que no es postcuántica (pasos 2 y 3)
- [ ] Explicas a quién deja fuera un servidor que exige postcuántico (paso 4)
- [ ] Explicas por qué `-` es seguro y una lista con un nombre desconocido no (paso 5)
- [ ] Mides el coste del postcuántico y dices cuándo importa (paso 7)

## Reto extra

Las host keys siguen siendo Ed25519 o RSA, que un ordenador cuántico sí podría romper. ¿Por qué eso es menos urgente que el intercambio de llaves? Piensa en qué puede hacer dentro de diez años alguien que grabó hoy tu sesión, y en qué necesitaría para hacerse pasar por tu servidor. Después busca `mldsa` en las notas de versión de OpenSSH 10.4 y 10.6.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 03 — Sin algoritmo en común](../lab-03-sin-algoritmo-en-comun/README.md) | [Lab 05 — Medir el rendimiento](../lab-05-medir-el-rendimiento/README.md) → |

[↑ Semana 13](../../README.md)
