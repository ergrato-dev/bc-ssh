# Lab 03 — Reenvío remoto: enseñar al servidor algo de tu equipo

⏱ Duración estimada: ~60 min

## Objetivo

Con `ssh -R`, que `server` llegue a una web que corre en tu equipo. Ver dónde abre `sshd` ese puerto, cómo `GatewayPorts` decide si se puede publicar fuera de `server`, y qué pasa si el puerto remoto ya está ocupado.

## Contexto

- Cómo funciona `-R` y `GatewayPorts`: [teoría 01](../../1-teoria/01-reenvio-local-y-remoto.md#-r-un-puerto-del-servidor-que-entra-a-tu-equipo).
- Recargar `sshd` después de cambiar su configuración: semana 07, [lab 02](../../../week-07-servidor_sshd_config_y_hardening/2-practicas/lab-02-autenticacion/README.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-reenvio-local/README.md), y la variable `R` de la semana 07, que recarga `sshd`:
   ```bash
   R='sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ```

1. **Una web en tu equipo.** En el cliente, solo en su `127.0.0.1`:
   ```bash
   mkdir -p ~/w/pub; echo "hola desde client" > ~/w/pub/index.html
   (python3 -m http.server 9000 --bind 127.0.0.1 --directory ~/w/pub >/dev/null 2>&1 &)
   curl -s localhost:9000
   ssh server 'curl -sS -m 2 client:9000'; echo "código: $?"
   ```
   ```
   hola desde client
   curl: (7) Failed to connect to client port 9000 after 11 ms: Couldn't connect to server
   código: 7
   ```
   Los paréntesis lanzan el servidor web en segundo plano sin que la shell te avise cuando termine. `server` no llega: tu web escucha solo en tu `localhost`. En la vida real, además, tu portátil está detrás de un NAT y nadie de fuera podría conectarse a él.

2. **El túnel al revés.**
   ```bash
   ssh -f -N -R 9000:localhost:9000 server
   ssh server 'curl -s localhost:9000; ss -ltn | grep 9000'
   ```
   ```
   hola desde client
   LISTEN 0      128        127.0.0.1:9000       0.0.0.0:*          
   LISTEN 0      128            [::1]:9000          [::]:*          
   ```
   - `-R 9000:localhost:9000`: **`sshd` en `server`** abre su `9000`; lo que llegue ahí, tu `ssh` lo conecta con `localhost:9000`, y ahora `localhost` es **tu equipo**.
   - La conexión SSH la abriste tú, hacia fuera: por eso funciona aunque estés detrás de un NAT. Es la forma de dar acceso temporal a algo de tu equipo, o de entrar a un equipo que solo puede salir.
   - Mientras dure, **cualquier usuario de `server`** puede conectar a ese `9000` y llegar a tu web.

3. **Pedir que escuche fuera.** Pide `0.0.0.0` y mira desde el cliente, que está en la red `publica` como `server`:
   ```bash
   ssh -f -N -R 0.0.0.0:9001:localhost:9000 server
   ssh server 'ss -ltn | grep 9001; sudo sshd -T | grep ^gatewayports'
   curl -sS -m 2 server:9001; echo "código: $?"
   ```
   ```
   LISTEN 0      128        127.0.0.1:9001       0.0.0.0:*          
   LISTEN 0      128            [::1]:9001          [::]:*          
   gatewayports no
   curl: (7) Failed to connect to server port 9001 after 1 ms: Couldn't connect to server
   código: 7
   ```
   Pediste todas las interfaces y `sshd` abrió solo `localhost`, sin avisar: con `GatewayPorts no` (por defecto), el cliente no decide.

4. **`GatewayPorts clientspecified`.** Que el cliente decida, y vuelve a pedirlo:
   ```bash
   echo 'GatewayPorts clientspecified' | ssh server "sudo tee /etc/ssh/sshd_config.d/30-tuneles.conf >/dev/null; sudo sshd -t && $R"
   pkill -f 'R 0.0.0.0:9001'
   ssh -f -N -R 0.0.0.0:9001:localhost:9000 server
   ssh server 'ss -ltn | grep 9001'
   curl -s -m 2 server:9001
   ```
   ```
   LISTEN 0      128          0.0.0.0:9001       0.0.0.0:*          
   hola desde client
   ```
   - Ahora el `9001` de `server` está abierto a toda su red, y cualquiera que llegue a `server` llega a la web de tu equipo. Es lo que quieres para publicar una demo; nunca para algo con datos.
   - Hace falta cerrar el túnel anterior y abrirlo de nuevo: la opción se aplica cuando el cliente pide el reenvío.
   - Vuelve al valor seguro:
   ```bash
   ssh server "sudo rm /etc/ssh/sshd_config.d/30-tuneles.conf; $R"
   ```

5. **Puerto remoto ocupado.** El `9000` de `server` sigue abierto por el túnel del paso 2. Pide otro igual:
   ```bash
   ssh -o ExitOnForwardFailure=yes -f -N -R 9000:localhost:9000 server; echo "código: $?"
   ```
   ```
   Error: remote port forwarding failed for listen port 9000
   código: 255
   ```
   Sin `ExitOnForwardFailure` el mensaje empieza por `Warning:` y `ssh` se queda conectado sin túnel, igual que con `-L` en el lab 01. Con `-R` es más fácil que pase: el puerto está en una máquina que compartes.

6. **El servidor usa tu red como proxy.** Con `-R` y solo un puerto, OpenSSH 7.6+ abre en `server` un proxy SOCKS que sale por **tu** equipo (el `-D` del lab 04, pero al revés):
   ```bash
   ssh -f -N -R 1081 server
   ssh server 'curl -s --socks5-hostname localhost:1081 http://localhost:9000'
   pkill -f 'ssh -f -N'
   ```
   ```
   hola desde client
   ```
   `server` pidió `localhost:9000`, y ese `localhost` lo resolvió tu equipo. Es útil para un servidor sin salida a Internet que necesita descargar algo. Pero piensa en el impacto: mientras dure, **cualquiera en `server` navega por tu red**, la de tu casa o tu oficina.

## Criterios de éxito

- [ ] Explicas quién abre el puerto y quién resuelve `localhost` en `-R 9000:localhost:9000` (paso 2)
- [ ] Explicas por qué un `-R 0.0.0.0:...` no publicó nada hasta cambiar `GatewayPorts`, y volviste al valor seguro (pasos 3 y 4)
- [ ] Explicas qué hace `ExitOnForwardFailure` con `-R` (paso 5)
- [ ] Explicas el riesgo de un `-R` dinámico (paso 6)

## Reto extra

Con `-R 0:localhost:9000` (puerto `0`), `sshd` elige un puerto libre. Abre así el túnel **sin** `-f` (en primer plano, con `-N`) y busca en la salida qué puerto te asignó. ¿Cómo lo sabría un script?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 02 — PostgreSQL a través de `server`](../lab-02-postgres-por-tunel/README.md) | [Lab 04 — Un proxy SOCKS con `ssh -D`](../lab-04-socks/README.md) → |

[↑ Semana 08](../../README.md)
