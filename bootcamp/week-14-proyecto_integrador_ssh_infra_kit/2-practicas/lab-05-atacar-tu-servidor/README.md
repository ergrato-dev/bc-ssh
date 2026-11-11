# Lab 05 — Atacar tu servidor

⏱ Duración estimada: ~60 min

## Objetivo

Comprobar el modelo de amenazas del kit atacando tu propio `server`: contraseñas, root, una cuenta fuera de los grupos, tu agente, un algoritmo débil, un túnel y fuerza bruta. Cada control debe fallar **para el atacante**, con la línea del log que lo demuestra. Y apuntar lo que el kit **no** para.

## Contexto

- Qué es un modelo de amenazas y por qué se escribe lo que no se cubre: [teoría 02](../../1-teoria/02-documentar-para-operar.md#qué-protege-y-qué-no-el-modelo-de-amenazas).
- La configuración que pruebas: `server/sshd_config.d/` del kit, aplicada por el playbook en el [lab 02](../lab-02-un-servidor-nuevo/README.md).
- **Atacar solo tus servidores del laboratorio.** Las mismas pruebas contra una máquina ajena, sin permiso por escrito, son un delito.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 02](../lab-02-un-servidor-nuevo/README.md). Ten abierta otra terminal en tu equipo, en la raíz del repositorio: en el paso 7 te vas a bloquear a ti mismo. En el cliente:
   ```bash
   N="-o ControlPath=none -o BatchMode=yes"
   ```
   `N`: conexiones nuevas, sin master (el master ya está autenticado y lo saltaría todo) y sin preguntar nada.

1. **Con contraseña.**
   ```bash
   ssh $N -o PubkeyAuthentication=no lab-server true
   ```
   ```
   alumno@server: Permission denied (publickey).
   ```
   `(publickey)`: es lo único que el servidor ofrece. Ni siquiera llega a preguntar una contraseña: no hay nada que probar a fuerza bruta.

2. **Como root, y con una cuenta fuera de los grupos.** Prepara `pepe`, una cuenta con **tu** llave en su `authorized_keys`, pero sin grupo:
   ```bash
   ssh $N -o User=root lab-server true
   ssh lab-server 'sudo useradd -m -s /bin/bash pepe && sudo install -d -o pepe -m 700 ~pepe/.ssh &&
     sudo install -o pepe -m 600 .ssh/authorized_keys ~pepe/.ssh/authorized_keys'
   ssh $N -o User=pepe lab-server true
   ssh lab-server 'sudo grep -E "User (root|pepe)" /var/log/auth.log | tail -2'
   ```
   ```
   root@server: Permission denied (publickey).
   pepe@server: Permission denied (publickey).
   2026-11-11 01:13:48 server sshd: User root from 172.20.0.5 not allowed because none of user's groups are listed in AllowGroups
   2026-11-11 01:13:48 server sshd: User pepe from 172.20.0.5 not allowed because none of user's groups are listed in AllowGroups
   ```
   - `pepe` tiene una llave buena y aun así no entra: `AllowGroups` decide **antes** que la llave. Así queda fuera la cuenta de un servicio que alguien creó con `authorized_keys` y nadie revisó.
   - Al cliente, el mismo `Permission denied` que con una llave mala: el porqué solo está en el servidor.

3. **Tu agente, en el servidor.**
   ```bash
   ssh $N -A lab-server 'echo "SSH_AUTH_SOCK=[$SSH_AUTH_SOCK]"'
   ```
   ```
   SSH_AUTH_SOCK=[]
   ```
   Aunque el cliente lo pida (`-A`), `20-sesion.conf` no reenvía el agente (`AllowAgentForwarding no`). Root en `server` no puede usar tus llaves para saltar a otro sitio. Para saltar: `ProxyJump` (semana 09).

4. **Un algoritmo débil.**
   ```bash
   ssh $N -o KexAlgorithms=diffie-hellman-group14-sha1 lab-server true
   ```
   ```
   Unable to negotiate with 172.20.0.2 port 22: no matching key exchange method found. Their offer: sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,ext-info-s,kex-strict-s-v00@openssh.com
   ```
   Un cliente viejo, o uno que alguien fuerza a bajar de nivel, no negocia SHA-1 con `server`. `Their offer` es la lista que dejó `15-algoritmos.conf`: sin `group14` ni curvas NIST.

5. **Un túnel.** ¿Puede `alumno` llegar a la base de datos `db` a través de `server`?
   ```bash
   ssh $N -o ExitOnForwardFailure=yes -L 15432:db:5432 lab-server true; echo "código $?"
   ```
   ```
   código 0
   ```
   **Sí.** El kit solo limita los túneles de las cuentas de salto (`40-salto.conf`, grupo `saltadores`). Para quien está en `ssh-users`, los reenvíos son una herramienta de trabajo (el túnel a PostgreSQL de la semana 08). Es una decisión, no un descuido: va en la lista de lo que el kit **no** para. Si no la quieres, `AllowTcpForwarding no` en `10-acceso.conf` y un `Match` para quien sí.

6. **Lo que el kit no para, por escrito.** Apunta en tus notas (lo pasarás al README en el proyecto, paso 5) cada cosa que **sí** pudiste hacer en este lab o que sabes que el kit no cubre: el túnel del paso 5, un equipo tuyo comprometido, la llave de la CA o del CI robadas, lo que hace una cuenta una vez dentro.

7. **Fuerza bruta.** fail2ban (semana 11) bloquea una IP tras 5 fallos en 10 minutos. Primero cierra tus masters: el bloqueo también corta las conexiones abiertas y las deja colgadas.
   ```bash
   bin/mux stop >/dev/null
   hostname -i
   for i in 1 2 3 4 5 6; do timeout 8 ssh $N -o User=intruso$i lab-server true; done
   ssh -o ControlPath=none lab-server true
   bin/doctor lab-server | tail -2
   ```
   ```
   172.20.0.5
   intruso1@server: Permission denied (publickey).
   intruso2@server: Permission denied (publickey).
   intruso3@server: Permission denied (publickey).
   intruso4@server: Permission denied (publickey).
   intruso5@server: Permission denied (publickey).
   intruso6@server: Permission denied (publickey).
   ssh: connect to host server port 22: Connection refused
   error:    ssh: connect to host server port 22: Connection refused
   pista:    nadie escucha en ese puerto: ¿sshd está arrancado? ¿es el puerto correcto?
   ```
   - Cada `intruso` es un usuario que no existe: un fallo para fail2ban. Los de los pasos 1 y 2 también cuentan, así que el bloqueo puede llegarte antes del sexto (y el `timeout 8` corta el intento que se queda colgado).
   - Bloqueado, el servidor **rechaza** tu IP: `Connection refused`, el mismo error que si `sshd` estuviera parado.
   - La pista de `bin/doctor` (semana 13) solo piensa en `sshd` y el puerto: te mandaría a buscar donde no es. Lo mejoras en el [proyecto](../../3-proyecto/README.md), paso 2.

8. **Desbloquearte.** Por la consola, en tu equipo (con la IP del paso 7):
   ```bash
   docker compose exec server fail2ban-client status sshd | grep 'Banned IP'
   docker compose exec server fail2ban-client set sshd unbanip 172.20.0.5
   ```
   ```
      `- Banned IP list:	172.20.0.5
   1
   ```
   En el cliente, `bin/doctor lab-server` vuelve a entrar. En un servidor de verdad, la consola es la del proveedor: es tu única puerta cuando SSH te cierra la suya.

## Criterios de éxito

- [ ] Ni contraseñas, ni root, ni una cuenta fuera de `AllowGroups` entran, y encuentras la razón en el log (pasos 1 y 2)
- [ ] Compruebas que el agente no se reenvía y que SHA-1 no se negocia (pasos 3 y 4)
- [ ] Explicas por qué el túnel del paso 5 funciona y lo apuntas en "no protege contra" (pasos 5 y 6)
- [ ] Te bloquea fail2ban, explicas por qué la pista de `doctor` engaña y te desbloqueas por la consola (pasos 7 y 8)

## Reto extra

Prueba la cuenta de salto: crea `salto` en `bastion` en el grupo `saltadores` con tu llave (semana 09) y repite los pasos 3 y 5 contra `lab-salto`. ¿Puede abrir una sesión? ¿Un túnel a `db`? ¿Y a `interno:22`? ¿Qué línea de `40-salto.conf` decide cada respuesta?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 04 — Una llave perdida](../lab-04-una-llave-perdida/README.md) | [Lab 06 — Reconstruir un servidor](../lab-06-reconstruir-un-servidor/README.md) → |

[↑ Semana 14](../../README.md)
