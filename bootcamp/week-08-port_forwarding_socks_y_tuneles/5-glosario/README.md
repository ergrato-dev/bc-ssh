# Glosario — Semana 08

| Término | Definición |
|---------|------------|
| **`autossh`** | Programa que lanza `ssh` y lo vuelve a lanzar cada vez que sale con error. Con `-M 0`, delega la detección de cortes en `ServerAliveInterval` |
| **canal** | Conversación independiente dentro de una conexión SSH: `session`, `direct-tcpip` (`-L`, `-D`), `forwarded-tcpip` (`-R`) |
| **corte sin aviso** | Conexión que muere sin que llegue ningún paquete que lo diga (red caída, NAT que la olvida): el puerto sigue abierto y las conexiones esperan |
| **`DynamicForward` / `-D`** | Proxy SOCKS en tu equipo cuyas conexiones salen por el servidor, al destino que pida cada programa |
| **`ExitOnForwardFailure`** | Opción de cliente: `ssh` sale con error si no puede abrir un reenvío, en lugar de quedarse conectado sin él |
| **`GatewayPorts`** | En el servidor, si el puerto de un `-R` puede escuchar fuera de `localhost`. En el cliente, lo mismo para un `-L` sin dirección |
| **`LocalForward` / `-L`** | Un puerto de tu equipo cuyas conexiones abre el servidor hacia un destino que él resuelve |
| **`PermitOpen` / `permitopen`** | Lista de destinos permitidos para `-L` y `-D`, en `sshd_config` o en una línea de `authorized_keys` |
| **`PermitListen` / `permitlisten`** | Lista de puertos que un `-R` puede abrir en el servidor |
| **pidfile** | Archivo con el PID de un proceso en segundo plano, para encontrarlo después: `AUTOSSH_PIDFILE` |
| **`RemoteForward` / `-R`** | Un puerto del servidor cuyas conexiones abre tu equipo hacia un destino que tú resuelves |
| **`ServerAliveInterval`** | Cada cuántos segundos sin tráfico pregunta el cliente al servidor si sigue ahí; con `ServerAliveCountMax` sin respuesta, sale |
| **SOCKS** | Protocolo de proxy en el que el programa dice, en cada conexión, a qué host y puerto quiere ir. SOCKS5 permite mandar el nombre sin resolver |
| **`socks5h`** | En una URL de proxy, SOCKS5 resolviendo los nombres en el proxy (el servidor) y no en tu equipo |
| **túnel** | Conexión TCP que viaja dentro de una conexión SSH, cifrada entre los dos extremos de SSH |
| **`~/.pgpass`** | Archivo de contraseñas de PostgreSQL para `psql` y libpq: `host:puerto:base:usuario:contraseña`, con permisos 600 |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — web](../4-recursos/webgrafia/README.md) | — |

[↑ Semana 08](../README.md)
