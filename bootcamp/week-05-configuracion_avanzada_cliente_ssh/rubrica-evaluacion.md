# Rúbrica de Evaluación — Semana 05

> Configuración avanzada del cliente: orden de lectura, patrones, `Include`, `Match`, perfiles y multiplexing. Se evalúan tres evidencias por separado y hace falta **70% en cada una**. No basta con que el `config` funcione: tienes que saber por qué gana cada valor y qué decide un master abierto.

---

## 📊 Distribución de Evidencias

| Evidencia | Peso | Instrumento |
|---|:--:|---|
| 🧠 Conocimiento | 30% | Las 10 preguntas de esta rúbrica, respondidas por escrito |
| 💪 Desempeño | 40% | Los 7 labs, con sus criterios de éxito comprobados en el laboratorio |
| 📦 Producto | 30% | `ssh-infra-kit` con `conf.d/`, multiplexing, perfil `sinmux`, `bin/kit-link` y `bin/mux`: 60 pts de autograding + 40 de calidad |

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
| 1 | ¿En qué orden lee `ssh` sus fuentes de configuración? ¿Qué cambia cuando usas `-F`? |
| 2 | En `ssh_config`, ¿qué valor gana si una opción aparece dos veces? ¿Qué opciones son la excepción y por qué tiene sentido que lo sean? |
| 3 | Un compañero tiene `Host *` con `User root` al principio de su `config` y no entiende por qué su alias con `User deploy` entra como root. Explícaselo y dile cómo arreglarlo. |
| 4 | ¿Con qué compara `Host` sus patrones? ¿Qué hace `Host * !bastion`, y qué hace `Host !bastion` solo? |
| 5 | Tu `config` tiene `Include conf.d/*.conf` y lo lees con `ssh -F ~/proyecto/config`. ¿Dónde busca `ssh` los archivos? ¿Cómo te enteras si no encuentra ninguno? |
| 6 | ¿Qué diferencia hay entre `Match host server` y `Match originalhost server`? ¿Por qué importa dónde está el `Match host` respecto al bloque con `HostName`? |
| 7 | ¿Qué riesgos y costes tiene `Match exec`? ¿Qué hace OpenSSH 9.6 con un nombre de host como `server;id`, y por qué? |
| 8 | ¿Qué hacen `ssh -P viaje` y `Match tagged viaje`? ¿Por qué un `Tag viaje` dentro del bloque de un host puede no aplicar el perfil? |
| 9 | Explica qué hacen `ControlMaster auto`, `ControlPath ~/.ssh/cm/%C` y `ControlPersist 10m`. ¿Por qué `%C` y no `%r@%h:%p`? ¿Qué pasa si la carpeta no existe? |
| 10 | Quitaste tu llave de `authorized_keys` y sigues entrando. ¿Por qué? Abriste un master con `ssh -A` y luego conectas sin `-A`: ¿qué recibe el servidor? ¿Cómo conectas sin pasar por el master? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Línea de comandos (`-o` y opciones cortas), después el archivo del usuario (`~/.ssh/config`) y por último el del sistema (`/etc/ssh/ssh_config` y lo que incluya). Con `-F archivo`, `ssh` lee solo ese archivo: ni `~/.ssh/config` ni el del sistema.

**2.** El primero: los siguientes se descartan, también dentro del mismo bloque. Se acumulan `IdentityFile`, `CertificateFile`, `SendEnv` y los `LocalForward`, `RemoteForward` y `DynamicForward`: tiene sentido probar varias llaves o abrir varios túneles a la vez.

**3.** `ssh` se queda con el primer valor de cada opción. `Host *` coincide con todo y está arriba, así que fija `User root` antes de llegar al alias; `User deploy` llega tarde. Arreglo: bloques concretos arriba y `Host *` al final. `ssh -G alias | grep ^user` lo comprueba sin conectar.

**4.** Con el nombre escrito en la línea de comandos (el alias), no con el `HostName`. `Host * !bastion` se aplica a todos los nombres excepto `bastion`. `Host !bastion` solo no se aplica a nada: un patrón negado solo excluye, y hace falta uno positivo que incluya.

**5.** En `~/.ssh/conf.d/`: las rutas relativas de `Include` en la configuración de usuario se resuelven desde `~/.ssh`, aunque el archivo se lea con `-F` desde otra carpeta. Si el patrón no coincide con nada, `ssh` no da error; solo `ssh -v` muestra `include ... matched no files`. Solución: ruta absoluta, o un enlace en `~/.ssh` (lo que hace `bin/kit-link`).

**6.** `host` compara con el host al que se conectará en ese momento de la lectura, después de los `HostName` ya leídos; `originalhost`, con el nombre escrito (como `Host`). Como `ssh` lee una sola vez de arriba abajo, un `Match host server` escrito antes del bloque que pone `HostName server` no se cumple para el alias; escrito después, sí.

**7.** La orden se ejecuta en cada `ssh` (también `ssh -G`): si es lenta, todas tus conexiones esperan. Y si lleva tokens como `%h`, mete en la shell texto que puede venir de fuera (un enlace, un submódulo de git). OpenSSH 9.6 rechaza nombres de host con caracteres de shell (`hostname contains invalid characters`) para que no lleguen a esas órdenes; aun así, se entrecomillan los tokens.

**8.** `-P viaje` pone la etiqueta `viaje` a la conexión, y `Match tagged viaje` aplica su bloque solo a las conexiones con esa etiqueta: un perfil que eliges al escribir el comando. `ssh` evalúa cada `Match` al pasar por él; si el `Tag` está en un bloque que se lee después del `Match tagged`, la etiqueta llega tarde. Va en un bloque anterior (o se usa `Match final`).

**9.** `auto`: usa un master si existe y, si no, se convierte en master. `ControlPath`: ruta del socket, una por destino; `%C` es un hash de 40 caracteres, de longitud fija, mientras que `%r@%h:%p` crece con el nombre y puede superar el límite de 108 bytes de un socket Unix (`ControlPath too long`). `ControlPersist 10m`: el master sigue diez minutos tras la última sesión. Si la carpeta no existe, `ssh` no la crea y la conexión falla (`unix_listener: cannot bind to path ...`).

**10.** Las sesiones nuevas viajan por el master, que se autenticó antes de la revocación: `ssh` no vuelve a autenticarse. Hay que cerrarlo (`ssh -O exit`, `bin/mux stop`). Un master abierto con `-A` reenvía el agente a todas las sesiones que pasan por él, aunque no pidan `-A`, mientras viva el master. Sin master: `-o ControlMaster=no -o ControlPath=none` (`ControlMaster=no` solo seguiría usando el existente), o el perfil `ssh -P sinmux` del kit.

</details>

---

## 💪 Desempeño (40%)

Dentro de cada lab: 10 puntos si se cumplen todos los criterios y explicas con tus palabras por qué funciona; 8 si se cumplen todos; 7 si falla uno; menos de 7 si fallan dos o más.

| Lab | Criterio | Puntos |
|---|---|:--:|
| [01 — El primer valor gana](2-practicas/lab-01-el-primer-valor-gana/README.md) | Archivos leídos con y sin `-F`; error de orden encontrado con `ssh -G` y corregido; repetidas frente a acumulables | 10 |
| [02 — Patrones y tokens](2-practicas/lab-02-patrones-y-tokens/README.md) | Bloque `lab-*` combinado con los alias; `* !lab-bastion` explicado; tokens sustituidos en `HostName` e `IdentityFile` | 10 |
| [03 — `Include` y `conf.d/`](2-practicas/lab-03-include-y-conf-d/README.md) | `~/.ssh/conf.d/` funcionando; orden alfabético explicado; `Include` vacío encontrado con `-v`; rutas relativas con `-F` resueltas con un enlace | 10 |
| [04 — `Match`](2-practicas/lab-04-match/README.md) | Las seis líneas de `host`/`originalhost` explicadas; llave según host y usuario; modo viaje con `exec`; coste de `exec` medido | 10 |
| [05 — Perfiles con `Tag`](2-practicas/lab-05-perfiles-con-tag/README.md) | Perfiles `depurar` y `viaje`; `Tag` por defecto bien colocado; `-P` sustituye la etiqueta | 10 |
| [06 — Multiplexing](2-practicas/lab-06-multiplexing/README.md) | Multiplexing activo y ahorro medido; socket, master y `-O check` vistos; `-O exit`; `ControlPersist no` y `%C` explicados | 10 |
| [07 — Lo que decide el master](2-practicas/lab-07-lo-que-decide-el-master/README.md) | Entrada con llave revocada por el master y rechazo sin él; agent forwarding decidido por el master; preguntas respondidas | 10 |

La nota de Desempeño es la media de los siete labs.

---

## 📦 Producto (30%)

### Verificable por el autograding — 60 puntos

Lo ejecuta `./scripts/verificar-semana.sh 05`. Es binario: pasa o no pasa.

| Comprobación | Puntos |
|---|:--:|
| `kl-uso` — bin/kit-link rechaza argumentos (sale con 2) | 1 |
| `kl-enlaza` — bin/kit-link enlaza ~/.ssh/kit a la carpeta del kit | 3 |
| `kl-repite` — bin/kit-link se puede repetir sin crear enlaces dentro del kit | 2 |
| `kl-no-pisa` — bin/kit-link no borra una carpeta ~/.ssh/kit que no es un enlace (sale con 1) | 3 |
| `kl-cm-700` — bin/kit-link deja ~/.ssh/cm con permisos 700, aunque ya existiera | 3 |
| `config-sin-hosts` — config ya no define hosts: viven en conf.d/ | 2 |
| `conf-lab` — conf.d/10-lab.conf define lab-server y lab-bastion | 2 |
| `config-include` — config incluye conf.d/ a través de ~/.ssh/kit | 5 |
| `config-hereda` — config mantiene los valores de las semanas 02-04 | 2 |
| `config-controlmaster` — config activa el multiplexing (ControlMaster auto) | 2 |
| `config-controlpath` — Los sockets van a ~/.ssh/cm/%C | 2 |
| `config-controlpersist` — El master sigue 10 min tras la última sesión | 2 |
| `perfil-sinmux` — ssh -P sinmux desactiva el multiplexing que config activa | 3 |
| `mux-real` — La segunda conexión viaja por el master: entra aunque la llave ya no esté en authorized_keys | 6 |
| `sinmux-real` — Con -P sinmux, la conexión no usa el master: se autentica de nuevo y falla | 4 |
| `mux-uso` — bin/mux rechaza una orden desconocida (sale con 2) | 1 |
| `mux-vacio` — bin/mux list sin sockets no escribe nada | 2 |
| `mux-list-huerfano` — bin/mux list marca un socket sin master como huérfano | 3 |
| `mux-stop-huerfano` — bin/mux stop borra los sockets huérfanos | 3 |
| `mux-stop-real` — bin/mux list ve el master y bin/mux stop lo cierra | 5 |
| `kit-sigue-funcionando` — Los scripts de semanas anteriores siguen respondiendo | 1 |
| `kit-completo-y-limpio` — Sin TODO en config, conf.d/ y bin/, y shellcheck sin avisos | 3 |
| **Total** | **60** |

### Calidad — 40 puntos

| Criterio | Excelente | Suficiente | Puntos |
|---|---|---|:--:|
| **README del kit** | Filas de `conf.d/`, `kit-link` y `mux` con códigos y ejemplo; bitácora de la semana 05; secciones "Instalar el kit en un equipo" y "Cuando cambias llaves" | Filas sin códigos o sin secciones | 8 |
| **Organización** | `config` solo con valores por defecto; un archivo de `conf.d/` por tema, numerados según el orden en que deben leerse | Hosts repartidos sin criterio | 8 |
| **Comentarios del porqué** | Qué / Para qué / Impacto en `Include` (ruta relativa a `~/.ssh`), en el multiplexing (riesgos) y en `sinmux`; `kit-link` explica por qué no pisa y por qué 700 | Comentarios que repiten el código | 8 |
| **Seguridad** | `~/.ssh/cm` en 700; `ControlPersist` limitado; `ForwardAgent no` intacto; el README dice qué hacer con los masters al cambiar llaves | `ControlPersist yes` o carpeta de sockets abierta | 8 |
| **Git** | Commit nuevo en `~/ssh-infra-kit` con mensaje descriptivo y sin llaves, sockets ni el enlace `kit` | Sin commit de la semana | 8 |
| **Total** | | | **40** |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Una llave privada en el repositorio del kit o en su historial de git | −20 pts |
| `ForwardAgent yes` en `Host *` | −10 pts |
| `StrictHostKeyChecking no`, `accept-new` o `UserKnownHostsFile /dev/null` en cualquier archivo del kit | −10 pts |
| `ControlPath` en una carpeta compartida (`/tmp`) o sin tokens que distingan el destino | −10 pts |
| Contraseñas o frases de paso escritas en un archivo del kit | −10 pts |

---

## 📋 Checklist de entrega

- [ ] Los 7 labs con sus criterios de éxito comprobados
- [ ] Las 10 preguntas de Conocimiento respondidas por escrito
- [ ] `3-proyecto/starter/` sin ningún `TODO`
- [ ] `./scripts/verificar-semana.sh 05` con las 22 comprobaciones en verde
- [ ] `ssh-infra-kit` con un commit nuevo y sin llaves

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Proyecto — ssh-infra-kit: `conf.d/`, perfiles y multiplexing](3-proyecto/README.md) | [Recursos — ebooks](4-recursos/ebooks-free/README.md) → |

[↑ Semana 05](README.md)
