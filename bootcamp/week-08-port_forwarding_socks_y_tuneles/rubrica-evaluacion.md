# Rúbrica de Evaluación — Semana 08

> Port forwarding, SOCKS y túneles. Se evalúan tres evidencias por separado y hace falta **70% en cada una**. No basta con que el túnel funcione: tienes que saber quién escucha y quién conecta, qué tramo va cifrado, qué permite el servidor y cómo se comporta el túnel cuando se corta.

---

## 📊 Distribución de Evidencias

| Evidencia | Peso | Instrumento |
|---|:--:|---|
| 🧠 Conocimiento | 30% | Las 10 preguntas de esta rúbrica, respondidas por escrito |
| 💪 Desempeño | 40% | Los 7 labs, con sus criterios de éxito comprobados en el laboratorio |
| 📦 Producto | 30% | `ssh-infra-kit` con `conf.d/20-tuneles.conf` y `bin/tunnel`: 60 pts de autograding + 40 de calidad |

| Calificación | Rango |
|---|:--:|
| Sobresaliente | 90-100% |
| Notable | 80-89% |
| Aprobado | 70-79% |
| No aprobado | < 70% |

---

## 🧠 Conocimiento (30%)

Diez preguntas, 3 puntos cada una.

| # | Pregunta |
|:--:|---|
| 1 | En `ssh -L 8080:localhost:8080 server`, ¿quién abre el puerto 8080, quién resuelve `localhost` y a qué máquina llega la conexión? ¿Y en `ssh -R 9000:localhost:9000 server`? |
| 2 | Abres `ssh -L 15432:db:5432 server` y consultas PostgreSQL. ¿Desde qué IP ve la conexión la base de datos? ¿Qué tramo va cifrado y cuál no, y cómo protegerías el que no? |
| 3 | ¿Qué riesgo tiene `-L 0.0.0.0:8080:...`? ¿Por qué el kit escribe `127.0.0.1:` delante aunque sin él `ssh` también escuche en `localhost`? |
| 4 | Pides `ssh -R 0.0.0.0:9001:localhost:9000 server` y desde fuera no llegas al 9001. ¿Por qué? ¿Qué opción del servidor lo cambia y qué valores tiene? |
| 5 | ¿Qué diferencia hay entre `curl --socks5` y `curl --socks5-hostname` (o `socks5://` y `socks5h://`)? ¿Por qué importa fuera del laboratorio? ¿Por qué no puedes usar `-D` con `psql`? |
| 6 | ¿Qué hace `ExitOnForwardFailure yes`? Da un caso que detecta y uno que no. |
| 7 | ¿Por qué un host de túnel lleva `ControlMaster no` y `ControlPath none` cuando el resto del kit usa multiplexing? ¿Qué hace `ssh -O forward`? |
| 8 | ¿Qué limitan `AllowTcpForwarding local` y `PermitOpen db:5432`? ¿Qué ve el cliente cuando el servidor rechaza un `-R` y cuando rechaza un destino de `-L`? ¿Por qué quitar los túneles a un usuario con shell no lo frena? |
| 9 | Explica las dos formas en que se corta un túnel y qué ve `psql` en cada una. ¿Qué hace `ServerAliveInterval 15` con `ServerAliveCountMax 3`, y en qué se diferencia de `TCPKeepAlive`? |
| 10 | ¿Qué hacen `autossh -M 0` y `AUTOSSH_GATETIME=0`? ¿Cuándo relanza `ssh` y cuándo sale? ¿Qué fallo no arregla, y cómo lo resuelve `bin/tunnel up`? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Con `-L`, el 8080 lo abre `ssh` en **tu equipo**; `localhost` lo resuelve `server`, así que la conexión llega a un servicio del propio `server`. Con `-R`, el 9000 lo abre `sshd` en **`server`**; `localhost` lo resuelve tu equipo, y la conexión llega a un servicio tuyo. En los dos casos el tramo entre equipos va por un canal dentro de la conexión SSH.

**2.** Desde la IP de `server` en la red de la base de datos (`inet_client_addr()`), no desde la tuya: sus reglas de acceso (`pg_hba.conf`, firewall) tienen que permitir a `server`. Va cifrado de tu equipo a `server`; de `server` a `db`, en claro si PostgreSQL no usa TLS (con `tcpdump` se leen las consultas). Se protege con TLS en PostgreSQL, con una red que solo vean ellos dos, o con el túnel hasta el propio servidor de base de datos (`-L ...:localhost:5432 db-host`).

**3.** Cualquiera que llegue a tu equipo (la misma wifi) usa tu túnel sin autenticarse y entra en la red del servidor. Sin dirección, `ssh` escucha en `localhost` solo mientras `GatewayPorts` del cliente sea `no`: con `127.0.0.1:` explícito, el túnel no cambia aunque alguien active esa opción.

**4.** Porque `GatewayPorts no` (por defecto) en el servidor hace que el puerto de un `-R` escuche solo en su `localhost`, pidas lo que pidas, sin avisar. `GatewayPorts clientspecified` deja que el cliente elija; `yes`, todas las interfaces siempre. Se cambia en `sshd_config`, y hay que volver a abrir el túnel.

**5.** `--socks5` resuelve el nombre en tu equipo y manda la IP; `--socks5-hostname` manda el nombre y lo resuelve el servidor. Fuera del laboratorio, la primera pregunta a tu DNS (el de la red en la que estás) por cada host al que vas, aunque el tráfico vaya cifrado; y un nombre interno (`db`) no se resuelve. `psql` no sabe hablar SOCKS: para un servicio concreto con cualquier programa, `-L`.

**6.** Hace que `ssh` salga con error (255) si no puede abrir un reenvío, en lugar de seguir conectado sin él. Detecta un puerto local ocupado (o uno remoto, con `-R`). No detecta un destino prohibido por el servidor (`PermitOpen`) ni un destino caído: el puerto local se abre bien y el fallo llega cuando lo usas.

**7.** Con un master abierto, `ssh` le pediría el reenvío y saldría: el túnel viviría en el master (con su `ControlPersist`), `autossh` vería salir a su hijo y lo relanzaría sin parar, y `bin/tunnel down` no lo cerraría. `ssh -O forward -L ...` añade un túnel a un master ya abierto, sin volver a autenticar; `-O cancel` lo quita.

**8.** `local` permite `-L` y `-D` y no `-R`; `PermitOpen db:5432` limita a ese destino los `-L` y `-D`. Un `-R` rechazado: `Error: remote port forwarding failed for listen port 9000` (o `Warning:`). Un destino de `-L` rechazado: el puerto se abre, la conexión se corta, y en primer plano `channel N: open failed: administratively prohibited`. Con shell, el usuario monta sus reenvíos con `socat`, `nc` o un binario propio; solo protege junto con cuentas sin shell o llaves con `command=`.

**9.** Con aviso (reinicio, `sshd` cae): `ssh` sale y nadie escucha: `Connection refused`. Sin aviso (red caída, NAT): `ssh` sigue vivo, el puerto abierto, y `psql` espera hasta su *timeout* (`timeout expired`). `ServerAliveInterval 15` pregunta cada 15 s sin tráfico por dentro de la conexión cifrada, y tras 3 sin respuesta `ssh` sale: corte detectado en 45 s. `TCPKeepAlive` usa paquetes TCP que se pueden falsificar y que el sistema manda cada ~2 h.

**10.** `-M 0`: sin puerto de vigilancia, confía en `ServerAliveInterval`. `AUTOSSH_GATETIME=0`: reintenta aunque el primer intento falle. Relanza cuando `ssh` sale con error (255); sale cuando `ssh` sale con 0 o cuando él recibe `TERM`. No arregla una autenticación que falla: reintenta para siempre en silencio. `bin/tunnel up` espera `TUNNEL_TIMEOUT` segundos a que el puerto escuche y, si no, para `autossh` y sale con 1.

</details>

---

## 💪 Desempeño (40%)

Dentro de cada lab: 10 puntos si se cumplen todos los criterios y explicas con tus palabras por qué funciona; 8 si se cumplen todos; 7 si falla uno; menos de 7 si fallan dos o más.

| Lab | Criterio | Puntos |
|---|---|:--:|
| [01 — Reenvío local](2-practicas/lab-01-reenvio-local/README.md) | Web interna alcanzada; túnel encontrado y cerrado; `ExitOnForwardFailure` con puerto ocupado; riesgo de `0.0.0.0`; canales en `ssh -v` | 10 |
| [02 — PostgreSQL por túnel](2-practicas/lab-02-postgres-por-tunel/README.md) | `db` solo alcanzable por `server`; IP de origen explicada; consulta en claro vista con `tcpdump`; `~/.pgpass` con 600; error de túnel caído | 10 |
| [03 — Reenvío remoto](2-practicas/lab-03-reenvio-remoto/README.md) | `-R` funcionando; `GatewayPorts` probado y devuelto a `no`; puerto remoto ocupado; riesgo del SOCKS remoto | 10 |
| [04 — SOCKS](2-practicas/lab-04-socks/README.md) | Proxy usado con `curl`; `socks5` frente a `socks5h`; `nc -X 5` y `ALL_PROXY`; alcance del proxy; elección entre `-L` y `-D` | 10 |
| [05 — Túneles en config](2-practicas/lab-05-tuneles-en-config/README.md) | Host de túnel comprobado con `-G`; por qué un host propio; `ClearAllForwardings`; `-O forward` y `-O cancel`; `~C` explicado | 10 |
| [06 — Límites del servidor](2-practicas/lab-06-limites-del-servidor/README.md) | `AllowTcpForwarding` y `PermitOpen` con su error en el cliente; llave limitada a `db:5432` probada; qué deja abierto `port-forwarding` | 10 |
| [07 — Túneles persistentes](2-practicas/lab-07-tuneles-persistentes/README.md) | Los dos cortes vistos; `ServerAliveInterval` detectando el congelado; `autossh` a través de un reinicio; cuándo relanza y cuándo no | 10 |

La nota de Desempeño es la media de los siete labs.

---

## 📦 Producto (30%)

### Verificable por el autograding — 60 puntos

Lo ejecuta `./scripts/verificar-semana.sh 08`. Es binario: pasa o no pasa.

| Comprobación | Puntos |
|---|:--:|
| `tun-alias` — tun-pg entra en server como alumno con la llave ~/.ssh/lab | 2 |
| `tun-forward` — tun-pg reenvía 127.0.0.1:15432 de tu equipo a db:5432 | 4 |
| `tun-exit-on-failure` — tun-pg sale con error si no puede abrir el puerto (ExitOnForwardFailure yes) | 2 |
| `tun-keepalive` — tun-pg detecta una conexión muerta: ServerAliveInterval 15 y ServerAliveCountMax 3 | 3 |
| `tun-sin-sesion-ni-master` — tun-pg no abre sesión (SessionType none) ni usa multiplexing | 3 |
| `tunnel-uso` — bin/tunnel sale con 2 si el uso es incorrecto | 2 |
| `tunnel-sin-forward` — bin/tunnel up sale con 1 si el host no tiene LocalForward | 2 |
| `tunnel-up-datos` — bin/tunnel up abre el túnel y los datos llegan al otro lado | 8 |
| `tunnel-up-una-vez` — Un segundo bin/tunnel up no arranca otro autossh | 4 |
| `tunnel-status-down` — status sale con 0 con el túnel activo y con 1 tras down, que no deja procesos | 6 |
| `tunnel-reconecta` — Si la conexión cae, autossh la vuelve a abrir y el túnel sigue funcionando | 8 |
| `tunnel-puerto-ocupado` — bin/tunnel up sale con 1 si el puerto local está ocupado y no deja procesos | 5 |
| `tunnel-sin-acceso` — bin/tunnel up sale con 1 en TUNNEL_TIMEOUT si no puede entrar, y no deja procesos | 7 |
| `kit-sigue-funcionando` — Los scripts de las semanas anteriores siguen respondiendo | 1 |
| `kit-completo-y-limpio` — Sin TODOs y shellcheck sin avisos | 3 |
| **Total** | **60** |

### Calidad — 40 puntos

| Criterio | Excelente | Suficiente | Puntos |
|---|---|---|:--:|
| **Comentarios Qué / Para qué / Impacto** | Cada opción de `tun-pg` con los tres; el Impacto de `LocalForward` dice qué tramo no va cifrado y por qué `127.0.0.1` | Las opciones comentadas, sin Impacto en alguna | 12 |
| **README del kit** | Filas de `conf.d/20-tuneles.conf` y `bin/tunnel` con códigos y ejemplo; bitácora de la semana 08; sección "Túneles" con uso, qué hacer con cada fallo y cómo añadir un túnel | Filas y bitácora, sin la sección completa | 10 |
| **Mensajes** | Cada salida de `bin/tunnel` dice qué pasó y qué mirar (puerto ocupado, `ssh -v`), con los errores por stderr | Mensajes correctos pero sin decir qué hacer | 6 |
| **Robustez** | `up` no deja procesos tras un fallo, no arranca dos `autossh`, valida el nombre; `down` espera a que el puerto quede libre | Falta una de las cuatro | 8 |
| **Git** | Commit nuevo en `~/ssh-infra-kit` con mensaje descriptivo y sin llaves, `.pgpass` ni pidfiles | Sin commit de la semana | 4 |
| **Total** | | | **40** |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Una llave privada o una host key en el repositorio del kit o en su historial de git | −20 pts |
| Una contraseña (de PostgreSQL o de SSH) escrita en un archivo del kit | −10 pts |
| Un `LocalForward`, `RemoteForward` o `DynamicForward` del kit que escucha fuera de `127.0.0.1` | −10 pts |
| `StrictHostKeyChecking no`, `accept-new` o `UserKnownHostsFile /dev/null` en cualquier archivo del kit | −10 pts |
| Reenvíos en `lab-server` (o en `Host *`) en lugar de en un host de túnel propio | −5 pts |

---

## 📋 Checklist de entrega

- [ ] Los 7 labs con sus criterios de éxito comprobados
- [ ] Las 10 preguntas de Conocimiento respondidas por escrito
- [ ] `3-proyecto/starter/` sin ningún `TODO`
- [ ] `./scripts/verificar-semana.sh 08` con las 15 comprobaciones en verde
- [ ] `ssh-infra-kit` con un commit nuevo y sin llaves ni contraseñas

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Proyecto — ssh-infra-kit: túneles persistentes a PostgreSQL](3-proyecto/README.md) | [Recursos — ebooks](4-recursos/ebooks-free/README.md) → |

[↑ Semana 08](README.md)
