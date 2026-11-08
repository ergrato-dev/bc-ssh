# Lab 02 — Patrones y tokens

⏱ Duración estimada: ~60 min

## Objetivo

Agrupar lo común de varios hosts en un bloque con patrón, excluir un host con `!` y usar tokens para que `ssh` calcule nombres de host y de archivo.

## Contexto

- Patrones de `Host` y tokens: [teoría 01](../../1-teoria/01-como-lee-ssh-su-configuracion.md#patrones-en-host).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-el-primer-valor-gana/README.md), con `cd` a esta carpeta.

1. **Lo que falta en `starter/config`.** Solo tiene un `HostName` por alias:
   ```bash
   ssh -G -F starter/config lab-server | grep '^identityfile '
   ```
   ```
   identityfile ~/.ssh/id_rsa
   identityfile ~/.ssh/id_ecdsa
   identityfile ~/.ssh/id_ecdsa_sk
   identityfile ~/.ssh/id_ed25519
   identityfile ~/.ssh/id_ed25519_sk
   identityfile ~/.ssh/id_xmss
   identityfile ~/.ssh/id_dsa
   ```
   Sin `IdentityFile`, `ssh` prueba los nombres por defecto, y `~/.ssh/lab` no está entre ellos.

2. **TODO 1: un bloque para el grupo.** Debajo de los dos alias, añade un bloque `Host lab-*` con `User alumno` e `IdentityFile ~/.ssh/lab`. Comprueba los dos alias:
   ```bash
   for h in lab-server lab-bastion; do ssh -G -F starter/config $h | grep -E '^(user|hostname|identityfile) ' | paste -sd' '; done
   ```
   ```
   user alumno hostname server identityfile ~/.ssh/lab
   user alumno hostname bastion identityfile ~/.ssh/lab
   ```
   `paste -sd' '` junta las líneas en una. Cada alias combina su bloque (`HostName`) y el del grupo. Conecta:
   ```bash
   ssh -F starter/config lab-server hostname
   ssh -F starter/config lab-bastion hostname
   ```
   ```
   server
   bastion
   ```
   `User alumno` no cambia nada aquí, porque tu usuario en el cliente también es `alumno`; en tu equipo, sí.

3. **TODO 2: todos menos uno.** Añade al final:
   ```
   Host * !lab-bastion
       ConnectTimeout 3
   ```
   y prueba cuatro nombres:
   ```bash
   for h in lab-server lab-bastion lab-x server; do printf '%-12s ' $h; ssh -G -F starter/config $h | grep -E '^(hostname|connecttimeout) ' | paste -sd' '; done
   ```
   ```
   lab-server   hostname server connecttimeout 3
   lab-bastion  hostname bastion connecttimeout none
   lab-x        hostname lab-x connecttimeout 3
   server       hostname server connecttimeout 3
   ```
   - `lab-bastion` queda fuera: `none` es el valor por defecto (el timeout de TCP del sistema).
   - `lab-x` coincide con `lab-*`, pero no tiene `HostName`: `ssh` intentaría resolver `lab-x` tal cual:
     ```bash
     ssh -F starter/config lab-x hostname; echo "código: $?"
     ```
     ```
     ssh: Could not resolve hostname lab-x: Name or service not known
     código: 255
     ```
   - `server` no es un alias: solo le aplica `Host * !lab-bastion`.

4. **Tokens en `HostName`.** Crea un archivo de prueba:
   ```bash
   cat > /tmp/tok.conf <<'EOF'
   Host *.lab
       HostName %h.example.com

   Host lab-server
       HostName server
       User alumno
       IdentityFile ~/.ssh/%r@%h
   EOF
   ssh -G -F /tmp/tok.conf web.lab | grep '^hostname '
   ```
   ```
   hostname web.lab.example.com
   ```
   Un bloque sirve para cualquier `*.lab`: un dominio corto para escribir menos.

5. **Tokens en `IdentityFile`.** `-G` los deja sin sustituir:
   ```bash
   ssh -G -F /tmp/tok.conf lab-server | grep '^identityfile '
   ```
   ```
   identityfile ~/.ssh/%r@%h
   ```
   Crea ese archivo (una copia de `lab`) y mira qué hace `ssh` al conectar:
   ```bash
   cp ~/.ssh/lab ~/.ssh/alumno@server
   cp ~/.ssh/lab.pub ~/.ssh/alumno@server.pub
   ssh -v -F /tmp/tok.conf lab-server true 2>&1 | grep -E 'identity file|Offering|Authenticated to'
   ```
   ```
   debug1: identity file /home/alumno/.ssh/alumno@server type 3
   debug1: identity file /home/alumno/.ssh/alumno@server-cert type -1
   debug1: Offering public key: /home/alumno/.ssh/alumno@server ED25519 SHA256:xzUk1ZLpNrSIQGxQj8dlMQh8V0yzUwUF/ce8Igb5c30 explicit
   Authenticated to server ([172.20.0.2]:22) using "publickey".
   ```
   - `%r@%h` se convirtió en `alumno@server`: usuario remoto y `HostName`.
   - `-cert type -1`: `ssh` busca también un certificado con el mismo nombre (semana 10); `-1` significa que no existe.
   - `explicit`: la llave viene de `IdentityFile`, no del agente ni de los nombres por defecto.

   Tu huella será otra: la llave es tuya.

## Criterios de éxito

- [ ] `starter/config` resuelve `lab-server` y `lab-bastion` con un bloque común (paso 2)
- [ ] Explicas por qué `lab-bastion` sale con `connecttimeout none` y qué le pasa a `lab-x` (paso 3)
- [ ] Viste un token sustituido en `HostName` y en `IdentityFile` (pasos 4 y 5)

## Reto extra

Escribe un bloque con `Host lab-?` y comprueba con `ssh -G` qué nombres coinciden: `lab-1`, `lab-12`, `lab-`. Después, explica por qué `Host !lab-bastion` sin un patrón positivo no se aplica ni siquiera a `server`.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 01 — El primer valor gana](../lab-01-el-primer-valor-gana/README.md) | [Lab 03 — `Include` y `conf.d/`](../lab-03-include-y-conf-d/README.md) → |

[↑ Semana 05](../../README.md)
