# Rúbrica de Evaluación — Semana 09

> Bastion hosts y arquitecturas segmentadas. Se evalúan tres evidencias por separado y hace falta **70% en cada una**. No basta con llegar a `interno`: tienes que saber quién se autentica con quién, quién comprueba cada host key, qué ve el bastion y qué deja hacer a quien salta.

---

## 📊 Distribución de Evidencias

| Evidencia | Peso | Instrumento |
|---|:--:|---|
| 🧠 Conocimiento | 30% | Las 10 preguntas de esta rúbrica, respondidas por escrito |
| 💪 Desempeño | 40% | Los 7 labs, con sus criterios de éxito comprobados en el laboratorio |
| 📦 Producto | 30% | `ssh-infra-kit` con `conf.d/30-bastion.conf`, `kh-add -J` y `40-salto.conf`: 60 pts de autograding + 40 de calidad |

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
| 1 | ¿Qué es una red segmentada y qué gana? ¿Qué es un bastion, y qué riesgos nuevos trae tener uno solo? |
| 2 | Con `ssh -t bastion ssh interno`, ¿quién se autentica con `interno`, quién comprueba su host key y qué ve el bastion? ¿Por qué no copiar tu llave privada al bastion? |
| 3 | Explica qué hace `ssh -J bastion interno` paso a paso: cuántas conexiones, desde dónde, cuántas host keys y autenticaciones. ¿Qué es `ssh -W`? |
| 4 | ¿Qué ve el bastion de una sesión con `-J`? ¿Qué no ve? ¿Cómo lo comprobaste? |
| 5 | La primera vez que entras en `interno` con `-J`, ¿cómo verificas su host key si `ssh-keyscan` no llega? ¿Por qué falla después `ssh -J bastion 172.19.0.3` y qué opción lo arregla? |
| 6 | Escribe el `ProxyCommand` equivalente a `ProxyJump bastion`. ¿Qué necesita del bastion `ProxyCommand ssh bastion nc %h %p` que `-W` no necesita? |
| 7 | ¿Por qué un `ProxyJump` no va en `Host *`? ¿Qué hacen `-J none` y `Match host interno !exec "getent hosts %h"`? ¿Cuántos masters deja un salto con multiplexing? |
| 8 | Con `ssh -A bastion`, ¿qué puede hacer `root` en el bastion y durante cuánto tiempo? ¿Qué limita `ssh-add -h bastion -h 'bastion>interno'` y qué no? |
| 9 | ¿Por qué `/usr/sbin/nologin` como shell no basta para una cuenta de salto? Explica `ForceCommand`, `PermitTTY no`, `AllowTcpForwarding local` y `PermitOpen interno:22`, y por qué `PermitOpen` rechaza la IP de `interno`. |
| 10 | ¿Cómo sabes a dónde saltó cada uno? ¿Qué ve `interno` en su log? ¿Cómo cortas el acceso de alguien a toda la red privada y qué conexiones siguen abiertas? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Repartir las máquinas en redes separadas y decidir cuál habla con cuál: un ataque a una red no llega directamente a las demás. El bastion es la única máquina con SSH accesible desde fuera que está en la red privada: una puerta que vigilar, un sitio donde cortar accesos y un log de quién entra. Riesgos: quien lo controle llega a toda la red privada, y si cae nadie entra (punto único de fallo).

**2.** El `ssh` de dentro corre en el bastion: él se autentica con `interno` (con contraseña, con una llave en el bastion o con tu agente reenviado), él comprueba la host key en **su** `known_hosts`, y la sesión se descifra en el bastion: lo ve todo. Una llave privada en el bastion la copia cualquiera con `root` allí y entra donde tú, para siempre.

**3.** `ssh` lanza `ssh -W '[interno]:22' bastion`: conecta con el bastion (host key y autenticación del bastion) y le pide un canal `direct-tcpip` hasta `interno:22`, unido a su entrada y salida. Tu `ssh` habla SSH con `interno` por ese canal: segunda host key y segunda autenticación. Dos conexiones SSH, las dos desde tu equipo, con tus llaves y tu `known_hosts`.

**4.** Bytes cifrados con llaves que no tiene: solo el saludo `SSH-2.0-...` en claro (lo comprobaste con `tcpdump` buscando un texto que no apareció). Sí sabe qué cuenta y llave entraron, desde qué IP, el destino del canal, cuándo y cuánto tráfico.

**5.** Pidiendo la huella por otro canal (la consola, `docker compose exec`) y pegándola en la pregunta de `ssh`, o leyendo la llave a un `known_hosts` temporal con `accept-new` a través del salto y comparando (`kh-add -J`). Con la IP, `ssh` busca la llave con el nombre `172.19.0.3`, que no está (y con un salto no conoce la IP para buscarla por ahí); `HostKeyAlias interno`.

**6.** `ProxyCommand ssh -W %h:%p bastion`. Con `nc`, la cuenta del bastion tiene que ejecutar un comando: necesita una shell, que no tenga `ForceCommand`, y `nc` instalado. Con `-W`, `sshd` abre el canal él mismo.

**7.** En `Host *`, el propio `ssh bastion` intentaría saltar por sí mismo. `-J none` desactiva el salto de la configuración (la línea de órdenes gana). El `Match ... !exec` aplica el salto solo si tu equipo no resuelve el nombre: fuera de la red salta, dentro va directo; el comando se ejecuta cada vez que `ssh` lee la configuración. Dos masters: el del salto (el `ssh -W` también lee `Host *`) y el del destino.

**8.** Usar el socket del agente en `/tmp/ssh-*/agent.N` para firmar con tus llaves y entrar como tú en cualquier sitio donde valgan, mientras dure tu conexión. `ssh-add -h` solo deja usar la llave para entrar en `bastion` desde tu equipo y en `interno` desde `bastion`: `root` ya no entra en `server`, pero en `interno` todavía sí.

**9.** `nologin` impide la sesión, pero los reenvíos no pasan por la shell: podría saltar a cualquier host y puerto, o publicar un `-R`. `ForceCommand` ejecuta `nologin` en toda sesión aunque la cuenta tenga shell; `PermitTTY no`, sin terminal; `AllowTcpForwarding local`, `-L` y `-W` pero no `-R`; `PermitOpen interno:22`, el único destino. `PermitOpen` compara el texto que pide el cliente, sin resolverlo.

**10.** Con `LogLevel DEBUG1` en el `Match` de los saltadores, cada salto deja `server_request_direct_tcpip: ... target interno port 22`; con `VERBOSE` solo aparecen la llave y los rechazos. `interno` ve la IP del bastion: cruzas hora y huella con el log del bastion. Quitas su llave del bastion (un solo sitio), y cierras lo que ya entró con `sudo pkill -u CUENTA`: una sesión o un master autenticados siguen vivos.

</details>

---

## 💪 Desempeño (40%)

Dentro de cada lab: 10 puntos si se cumplen todos los criterios y explicas con tus palabras por qué funciona; 8 si se cumplen todos; 7 si falla uno; menos de 7 si fallan dos o más.

| Lab | Criterio | Puntos |
|---|---|:--:|
| [01 — Red segmentada](2-practicas/lab-01-red-segmentada/README.md) | Redes de cada máquina; sesiones encadenadas y quién hace qué; por qué no copiar la llave; IP que ve `interno`; mapa completo | 10 |
| [02 — ProxyJump](2-practicas/lab-02-proxyjump/README.md) | Dos conexiones en `-v`; huella pegada; `tcpdump` sin el secreto; `known_hosts` temporal; archivos y saltos encadenados | 10 |
| [03 — ProxyCommand y `-W`](2-practicas/lab-03-proxycommand-y-w/README.md) | `ssh -W` a pelo; `ProxyCommand` equivalente; `nc` y SOCKS como salto; `HostKeyAlias`; errores de cada tramo | 10 |
| [04 — Saltos en config](2-practicas/lab-04-saltos-en-config/README.md) | `ProxyJump` comprobado con `-G`; `-J none`; `Match ... !exec`; masters del salto; `scp` y `rsync` con el alias | 10 |
| [05 — Agente reenviado](2-practicas/lab-05-agente-reenviado/README.md) | `root` entra con tu agente; nada que robar con `-J`; `ssh-add -h` y lo que sigue permitido; `AllowAgentForwarding no` | 10 |
| [06 — Bastion endurecido](2-practicas/lab-06-bastion-endurecido/README.md) | Cuenta sin shell; `Match` comprobado con `sshd -T -C`; mensajes de cada rechazo; `PermitOpen` y la IP; `nc` ya no sirve | 10 |
| [07 — Auditoría y cortes](2-practicas/lab-07-auditoria-y-cortes/README.md) | `DEBUG1` con el `target`; saltos activos; logs de `interno` cruzados; acceso cortado y sesiones cerradas; bastion caído | 10 |

La nota de Desempeño es la media de los siete labs.

---

## 📦 Producto (30%)

### Verificable por el autograding — 60 puntos

Lo ejecuta `./scripts/verificar-semana.sh 09`. Es binario: pasa o no pasa.

| Comprobación | Puntos |
|---|:--:|
| `salto-alias` — lab-salto entra en bastion como salto con la llave ~/.ssh/lab | 3 |
| `interno-alias` — lab-interno entra en interno como alumno con la llave ~/.ssh/lab | 2 |
| `interno-proxyjump` — lab-interno salta por lab-salto (ProxyJump) | 4 |
| `salto-funciona` — ssh lab-interno entra a través del salto, y sin el salto no entra | 8 |
| `kh-uso` — bin/kh-add sale con 2 si -J no lleva salto o faltan argumentos | 2 |
| `kh-salto-anade` — bin/kh-add -J lee la host key a través del salto y la añade si la huella coincide | 8 |
| `kh-salto-huella-mala` — bin/kh-add -J sale con 1 y no escribe nada si la huella no coincide | 5 |
| `kh-salto-caido` — bin/kh-add -J sale con 3 si no llega a través del salto | 3 |
| `kh-sin-salto` — bin/kh-add sin -J sigue leyendo la llave directamente | 2 |
| `srv-grupos` — sshd deja entrar a los grupos ssh-users, sftp-only y saltadores | 3 |
| `srv-salto-sin-sesion` — Un usuario de saltadores no tiene shell, comandos ni terminal | 5 |
| `srv-salto-solo-interno` — Un usuario de saltadores solo reenvía a interno:22, sin -R, agente, sockets, X11 ni tun | 7 |
| `srv-salto-log` — Los saltos quedan en el log (DEBUG1 para saltadores, VERBOSE para el resto) | 3 |
| `srv-resto-sin-cambio` — El Match de saltadores no limita a los demás usuarios | 1 |
| `kit-sigue-funcionando` — Los scripts de las semanas anteriores siguen respondiendo | 1 |
| `kit-completo-y-limpio` — Sin TODOs y shellcheck sin avisos | 3 |
| **Total** | **60** |

### Calidad — 40 puntos

| Criterio | Excelente | Suficiente | Puntos |
|---|---|---|:--:|
| **Comentarios Qué / Para qué / Impacto** | `lab-salto`, `ProxyJump` y cada opción de `40-salto.conf` con los tres; el Impacto de `PermitOpen` dice que compara texto | Las opciones comentadas, sin Impacto en alguna | 12 |
| **README del kit** | Filas de `30-bastion.conf`, `kh-add -J` y `40-salto.conf`; bitácora de la semana 09; sección "Red privada" con la cuenta de salto, la host key, un host nuevo y cómo cortar un acceso | Filas y bitácora, sin la sección completa | 10 |
| **Mensajes de `kh-add`** | El uso nombra `-J`; cada fallo dice qué pasó (huella distinta, no se pudo leer), por stderr | Mensajes correctos sin actualizar el uso | 6 |
| **Robustez** | `kh-add -J` no toca tu `known_hosts` hasta comparar, borra el temporal, no deja masters (`ControlPath=none`) y exige el salto ya conocido | Falta una de las cuatro | 8 |
| **Git** | Commit nuevo en `~/ssh-infra-kit` con mensaje descriptivo y sin llaves ni `known_hosts` | Sin commit de la semana | 4 |
| **Total** | | | **40** |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Una llave privada o una host key en el repositorio del kit o en su historial de git | −20 pts |
| `ForwardAgent yes` en cualquier host del kit | −10 pts |
| `StrictHostKeyChecking no` o `UserKnownHostsFile /dev/null` en cualquier archivo del kit, o `accept-new` fuera del `known_hosts` temporal de `kh-add` | −10 pts |
| `ProxyJump` en `Host *` | −5 pts |
| `PermitOpen any` o `AllowTcpForwarding yes` en el `Match` de los saltadores | −5 pts |

---

## 📋 Checklist de entrega

- [ ] Los 7 labs con sus criterios de éxito comprobados
- [ ] Las 10 preguntas de Conocimiento respondidas por escrito
- [ ] `3-proyecto/starter/` sin ningún `TODO`
- [ ] `./scripts/verificar-semana.sh 09` con las 16 comprobaciones en verde
- [ ] `ssh-infra-kit` con un commit nuevo y sin llaves

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Proyecto — ssh-infra-kit: acceso a `interno` vía `bastion`](3-proyecto/README.md) | [Recursos — ebooks](4-recursos/ebooks-free/README.md) → |

[↑ Semana 09](README.md)
