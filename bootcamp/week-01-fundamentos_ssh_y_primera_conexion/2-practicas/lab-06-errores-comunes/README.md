# Lab 06 — Los cinco errores más comunes

⏱ Duración estimada: ~60 min

## Objetivo

Provocar a propósito los cinco errores de conexión que más verás, reconocer cada uno por su mensaje y saber en qué capa está el problema y qué mirar primero.

## Contexto

- Casi todos los fallos de SSH caen en una de estas capas, de abajo arriba: **nombre** (DNS), **red** (TCP), **servidor** (identidad del host) y **usuario** (autenticación). El mensaje de error dice en cuál estás si sabes leerlo.
- Todos los errores de `ssh` salen con código **255**. El código no distingue el caso; el mensaje sí.
- Necesitas **dos terminales**: **En tu equipo** y **En el cliente**. La contraseña `alumno` es **solo del laboratorio**.

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d
   ```
   En la otra terminal:
   ```bash
   docker compose run --rm client
   ```
   **En el cliente**, verifica la huella de `server` como en el lab-02 y conéctate una vez (`ssh server true`).

1. **Nombre que no existe** (un error al escribir):
   ```bash
   ssh serve true; echo "código: $?"
   ```
   ```
   ssh: Could not resolve hostname serve: Name or service not known
   código: 255
   ```
   **Capa:** DNS. `ssh` ni siquiera intentó conectar. **Qué mirar:** el nombre, y `getent hosts NOMBRE` (lab-01).

2. **Nadie escucha en el puerto:**
   ```bash
   ssh -p 2222 server true
   ```
   ```
   ssh: connect to host server port 2222: Connection refused
   ```
   **Capa:** TCP. El host existe y respondió "aquí no hay nadie". **Qué mirar:** el puerto (¿el servidor usa otro?) y si `sshd` está corriendo (`nc -zv HOST PUERTO`).

3. **El host no responde:**
   ```bash
   ssh -o ConnectTimeout=3 10.255.255.1 true
   ```
   ```
   ssh: connect to host 10.255.255.1 port 22: Connection timed out
   ```
   **Capa:** red. Nadie contestó, ni siquiera para rechazar: host apagado, IP equivocada o un firewall que descarta paquetes en silencio. `-o` pasa una opción de configuración en la línea de comandos; sin `ConnectTimeout=3`, esperarías unos 2 minutos.

   Diferencia clave: **refused** es instantáneo (alguien respondió que no); **timed out** tarda (nadie respondió).

4. **Credenciales incorrectas.** Escribe una contraseña equivocada tres veces:
   ```bash
   ssh server true
   ```
   ```
   alumno@server's password:
   Permission denied, please try again.
   alumno@server's password:
   Permission denied, please try again.
   alumno@server's password:
   alumno@server: Permission denied (publickey,password).
   ```
   **Capa:** autenticación. La conexión y la verificación del servidor fueron bien. Entre paréntesis, los métodos que el servidor acepta. Ahora con un usuario al que el servidor no deja entrar:
   ```bash
   ssh root@server true
   ```
   Escribe cualquier cosa tres veces. El mensaje es **el mismo**, aunque aquí la causa sea que `root` tiene prohibido entrar (`PermitRootLogin no`, semana 07). El servidor no dice si falló el usuario o la contraseña: así no ayuda a quien intenta adivinar usuarios. La causa real solo la ve el administrador. **En tu equipo**:
   ```bash
   docker compose logs server --tail 5
   ```
   Busca líneas `Failed password for root` o `Failed password for alumno`.

5. **El servidor cambió de identidad.** **En tu equipo**, recrea `server` (nuevo contenedor, host keys nuevas):
   ```bash
   docker compose up -d --force-recreate server
   ```
   Espera unos segundos. **En el cliente**:
   ```bash
   ssh server true
   ```
   ```
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
   ...
   The fingerprint for the ED25519 key sent by the remote host is
   SHA256:NyfXgrgso987se+63BslXwUVKjkXJAVIAaWnYDXJEsw.
   ...
   Offending ED25519 key in /home/alumno/.ssh/known_hosts:1
     remove with:
     ssh-keygen -f '/home/alumno/.ssh/known_hosts' -R 'server'
   Host key for server has changed and you have requested strict checking.
   Host key verification failed.
   ```
   **Capa:** identidad del servidor. La llave no coincide con la guardada en el lab-02. Puede ser una reinstalación legítima (como ahora) o alguien en medio. `ssh` no puede saberlo y **se niega**, sin pedir contraseña.

   Si en el paso 5 ves `Connection refused`, el contenedor aún arrancaba: espera y repite.

6. **Arréglalo bien.** No borres la línea a ciegas. Primero confirma la nueva huella por el canal independiente. **En tu equipo**:
   ```bash
   docker compose exec server ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
   ```
   Si coincide con la del aviso, **en el cliente**:
   ```bash
   ssh-keygen -R server
   ```
   ```
   # Host server found: line 1
   /home/alumno/.ssh/known_hosts updated.
   Original contents retained as /home/alumno/.ssh/known_hosts.old
   ```
   `-R` borra las líneas de ese host. Conéctate (`ssh server true`): vuelve la pregunta de la primera vez. Compara la huella y responde `yes`.

7. **Tu tabla de diagnóstico.** Copia esta tabla en tus notas y complétala con tus palabras:

   | Mensaje | Capa | Primera comprobación |
   |---|---|---|
   | `Could not resolve hostname` | | |
   | `Connection refused` | | |
   | `Connection timed out` | | |
   | `Permission denied (...)` | | |
   | `REMOTE HOST IDENTIFICATION HAS CHANGED` | | |

   El proyecto de la semana automatiza las tres primeras filas en `bin/lab-check`.

## Criterios de éxito

- [ ] Reprodujiste los cinco errores (pasos 1 a 5)
- [ ] Explicas la diferencia entre `refused` y `timed out` (paso 3)
- [ ] Explicas por qué el servidor da el mismo mensaje para usuario y contraseña incorrectos (paso 4)
- [ ] Verificaste la nueva huella **antes** de `ssh-keygen -R` (paso 6)
- [ ] Tu tabla de diagnóstico está completa (paso 7)

## Reto extra

Hay quien "arregla" el paso 5 con `ssh -o StrictHostKeyChecking=no`. Pruébalo y lee con atención la salida: ¿se conecta?, ¿con qué contraseña? Escribe en dos líneas por qué esa opción anula la protección que viste en el lab-02.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 05 — Leer una conexión con `ssh -v`](../lab-05-modo-verbose/README.md) | [Lab 07 — `~/.ssh/config` y precedencia](../lab-07-config-y-precedencia/README.md) → |

[↑ Semana 01](../../README.md)
