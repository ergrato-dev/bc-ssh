# Rúbrica de Evaluación — Semana 12

> Automatización: scripting, CI/CD y Ansible. Se evalúan tres evidencias por separado y hace falta **70% en cada una**. No basta con que el playbook termine en verde: tienes que saber qué hace `ssh` cuando no hay nadie delante, qué puede hacer la llave de tu CI si se filtra, por qué el `known_hosts` es un secreto más y cómo evita el playbook dejarte fuera.

---

## 📊 Distribución de Evidencias

| Evidencia | Peso | Instrumento |
|---|:--:|---|
| 🧠 Conocimiento | 30% | Las 10 preguntas de esta rúbrica, respondidas por escrito |
| 💪 Desempeño | 40% | Los 7 labs, con sus criterios de éxito comprobados en el laboratorio |
| 📦 Producto | 30% | `ssh-infra-kit` con `ansible/`, `bin/ci-deploy` y `ci/github-actions.yml`: 60 pts de autograding + 40 de calidad |

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
| 1 | ¿Qué código de salida da `ssh HOST CMD`? ¿Qué significa 255 y por qué un comando remoto no debería salir con 255? |
| 2 | ¿Qué hace `BatchMode yes`? ¿Qué le pasa a un script sin él cuando un servidor no tiene tu llave? ¿Y sin `ConnectTimeout` cuando no responde? |
| 3 | ¿Por qué `while read h; do ssh "$h" hostname; done < hosts` solo llega al primer host? ¿Cómo se arregla? |
| 4 | `d="mi carpeta"; ssh server mkdir "$d"` crea dos carpetas. ¿Por qué? Explica `printf %q` y `ssh HOST bash -s <<'FIN'`, y qué hacen las comillas de `'FIN'`. |
| 5 | En paralelo con `xargs -P`, ¿qué pasa cuando un `ssh` sale con 255? ¿Por qué las líneas llegan desordenadas y qué haces con eso? |
| 6 | Explica `restrict,command="...",from="..."` en la llave de un CI: qué recibe el comando forzado, por qué no se usa `eval` y por qué no sirve para la llave que usa Ansible. |
| 7 | ¿Por qué `StrictHostKeyChecking no`, `accept-new` y `ssh-keyscan` en un runner son el mismo error? ¿Qué se hace en su lugar y qué pasa cuando un servidor cambia de host key? |
| 8 | En un script de CI: ¿para qué sirven `umask 077`, `trap 'rm -rf "$d"' EXIT` y `-F /dev/null`? ¿Por qué nunca `set -x`? En el workflow, ¿para qué `permissions: contents: read` y `concurrency`? |
| 9 | ¿Qué necesita Ansible en un servidor y cómo llega a él? ¿Qué es la idempotencia, cómo se ve en `PLAY RECAP` y por qué `command` siempre dice `changed`? |
| 10 | El playbook del kit cambia `sshd`. ¿Qué no hace Ansible que sí hace `bin/sshd-deploy`, y qué hace el playbook para no dejarte fuera (validación, `serial`, handler, comprobación final)? ¿Por qué hace falta `reset_connection`? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** El del comando remoto (0-254), o 255 si falló el propio `ssh`: no resolvió el nombre, no conectó, la host key no coincide o no aceptaron la llave. Un comando que sale con 255 se confunde con un fallo de conexión, y un script reintentaría o avisaría de algo que no pasó.

**2.** `BatchMode yes` hace que `ssh` no pregunte nunca (contraseña, frase, `yes/no` de host key): si tendría que preguntar, falla con 255. Sin él, el script se queda esperando una contraseña que nadie escribe, y no pasa al siguiente servidor. Sin `ConnectTimeout`, un servidor que no responde hace esperar al script unos 2 minutos (el tiempo del sistema) antes de fallar; en un bucle, multiplicado por cada servidor caído.

**3.** `ssh` reenvía su entrada al comando remoto, y la entrada del bucle es el archivo: el primer `ssh` lee el resto de la lista y se la da a `hostname`, que la ignora; `read` ya no tiene nada que leer. Se arregla con `ssh -n` (entrada vacía) o `< /dev/null`.

**4.** `ssh` junta sus argumentos con espacios y el shell remoto los vuelve a separar: llega `mkdir mi carpeta`. `printf %q "$d"` lo escapa (`mi\ carpeta`) para que el shell remoto lo deje entero. `bash -s` lee el script de la entrada de `ssh`; con `'FIN'` entre comillas, tu shell no expande nada dentro, así que los `$` los expande el servidor. Los argumentos de `bash -s -- ARG` pasan por el shell remoto y también necesitan `%q`.

**5.** `xargs` deja de lanzar los comandos que quedan (`exited with status 255; aborting`): un servidor caído al principio deja sin hacer todos los demás. Se envuelve: `sh -c 'ssh ... "$1" ... || echo "$1: FALLO"' _ {}`. Las líneas llegan en el orden en que termina cada servidor, no en el de la lista: por eso cada línea lleva el nombre de su host delante.

**6.** `restrict` quita terminal, reenvíos de puertos, agente y X11. `command=` ejecuta ese programa pida lo que pida el cliente; lo pedido llega en `$SSH_ORIGINAL_COMMAND`, y un `case` decide qué se permite. `eval` lo convertiría en un shell completo: cualquier cosa que mande el cliente se ejecutaría. `from=` solo acepta la llave desde esas direcciones (sirve con runners de IP fija). Ansible ejecuta Python arbitrario (`/bin/sh -c '...python3...'`): con un comando forzado no funciona. Para esa llave quedan `restrict`, `from=`, una cuenta propia y `sudo` limitado.

**7.** Los tres aceptan la host key que llegue: `no` cualquiera, `accept-new` la primera (y en un runner vacío siempre es la primera), `ssh-keyscan` la lee por la misma red en la que no confías. Un impostor (DNS envenenado, IP reasignada) recibe el despliegue y lo que lleve. Se guardan como secreto las líneas de `known_hosts` que comprobaste a mano y se usa `StrictHostKeyChecking yes`. Si un servidor cambia de host key, el despliegue falla: compruebas la llave nueva y actualizas el secreto (con certificados de host, una línea `@cert-authority` que no cambia).

**8.** `umask 077`: la llave y el `known_hosts` se crean solo legibles por el job (y `ssh` rechaza una llave legible por otros). `trap ... EXIT`: la carpeta se borra al salir, también si algo falla a mitad. `-F /dev/null`: ninguna configuración del runner cambia el `ssh`. `set -x` imprime cada orden con sus variables expandidas: la llave, en el log que leen otros (GitHub solo tapa el valor exacto del secreto, no lo derivado). `permissions: contents: read`: un paso comprometido no puede escribir en el repositorio. `concurrency`: dos pushes seguidos no despliegan a la vez.

**9.** `sshd`, `python3` y `sudo` (para `become`); nada instalado aparte (*agentless*). Ansible lanza tu `ssh` (lee tu configuración, llaves y `known_hosts`), envía el módulo en Python y lee su respuesta en JSON. Idempotencia: cada módulo describe un estado y solo cambia lo que no está así; la segunda ejecución da `changed=0` y no dispara handlers. `command` no sabe qué hizo el programa, así que supone que cambió algo; se usa para consultar (con `changed_when: false`) y los módulos para cambiar.

**10.** Ansible no deshace nada si la configuración nueva te deja fuera; `sshd-deploy` programa la vuelta atrás. El playbook: prueba la carpeta nueva con `sshd -t` sobre una copia del `sshd_config` completo antes de instalarla; va de uno en uno (`serial: 1`) y se para en el primer fallo; recarga con `HUP` (las conexiones siguen) y solo si algo cambió; y al final ejecuta los handlers (`flush_handlers`), cierra la conexión (`reset_connection`) y entra con una nueva (`ping`). Sin `reset_connection`, el `ping` iría por el master abierto, ya autenticado, y diría que todo va bien aunque nadie pudiera entrar.

</details>

---

## 💪 Desempeño (40%)

Dentro de cada lab: 10 puntos si se cumplen todos los criterios y explicas con tus palabras por qué funciona; 8 si se cumplen todos; 7 si falla uno; menos de 7 si fallan dos o más.

| Lab | Criterio | Puntos |
|---|---|:--:|
| [01 — SSH dentro de un script](2-practicas/lab-01-ssh-en-scripts/README.md) | Código 255; `BatchMode`; `ConnectTimeout`; `ssh -n`; `printf %q`; `bash -s` con su código y errores | 10 |
| [02 — Muchos servidores](2-practicas/lab-02-muchos-servidores/README.md) | Bucle con resumen; `xargs` que no aborta; serie frente a paralelo; multiplexing; lo que falta para ser Ansible | 10 |
| [03 — Una llave de despliegue](2-practicas/lab-03-llave-de-despliegue/README.md) | `puerta` y `$SSH_ORIGINAL_COMMAND`; publicar; lo rechazado; sin túnel; `from=`; por qué no vale para Ansible | 10 |
| [04 — Un CI sin nadie delante](2-practicas/lab-04-un-ci-sin-nadie-delante/README.md) | `ci.sh` explicado; entorno vacío y sin restos; el impostor; `known_hosts` como secreto; `set -x`; el workflow | 10 |
| [05 — Ansible sin playbook](2-practicas/lab-05-ansible-ad-hoc/README.md) | `ping`; `ansible.cfg`; `command` frente a `shell`; `become`; el `ssh` de `-vvv`; `UNREACHABLE` | 10 |
| [06 — El primer playbook](2-practicas/lab-06-primer-playbook/README.md) | Partes del playbook; `changed=0`; `--check --diff`; `validate` y el handler que no se ejecuta | 10 |
| [07 — Ansible a través del bastion](2-practicas/lab-07-ansible-por-el-bastion/README.md) | `interno` por inventario y por `~/.ssh/config`; tres tiempos medidos y explicados; el master abierto | 10 |

La nota de Desempeño es la media de los siete labs.

---

## 📦 Producto (30%)

### Verificable por el autograding — 60 puntos

Lo ejecuta `./scripts/verificar-semana.sh 12`. Es binario: pasa o no pasa.

| Comprobación | Puntos |
|---|:--:|
| `ansible-cfg` — ansible.cfg usa el inventario del kit, la configuración SSH del kit con ControlPersist, pipelining, python3 y comprobación de host keys | 5 |
| `inventario` — El grupo servidores del inventario tiene lab-server y lab-bastion | 2 |
| `playbook-sintaxis` — servidores.yml es un playbook válido para el grupo servidores, con become y de un servidor en un servidor (serial: 1) | 3 |
| `playbook-check` — Con --check el playbook dice qué cambiaría sin tocar el servidor | 4 |
| `playbook-valida` — Si sshd_config.d del kit no pasa sshd -t, el playbook falla sin instalar nada y el servidor sigue aceptando conexiones | 6 |
| `playbook-aplica` — El playbook deja sshd_config.d igual que el kit (borra lo que sobra), crea los grupos y la KRL, mantiene a quien despliega en ssh-users e instala PAM y jaula | 8 |
| `playbook-idempotente` — Recarga sshd solo si algo cambió, entra con una conexión nueva al terminar y la segunda ejecución no cambia nada | 7 |
| `ci-uso` — ci-deploy sale con 2 y nombra la variable si falta KIT_SSH_KEY o KIT_KNOWN_HOSTS | 3 |
| `ci-despliega` — En un entorno vacío, ci-deploy aplica el playbook con la llave y el known_hosts de sus variables, no los escribe en la salida y no deja archivos | 8 |
| `ci-host-desconocido` — Si la host key no es la de KIT_KNOWN_HOSTS, ci-deploy falla sin tocar el servidor ni aceptar la llave nueva | 6 |
| `ci-workflow` — ci/github-actions.yml se ejecuta en push, con permisos de solo lectura, y llama a bin/ci-deploy con los dos secretos, sin saltarse ni adivinar host keys | 5 |
| `kit-completo-y-limpio` — Sin TODOs, shellcheck sin avisos y los scripts anteriores siguen respondiendo | 3 |
| **Total** | **60** |

### Calidad — 40 puntos

| Criterio | Excelente | Suficiente | Puntos |
|---|---|---|:--:|
| **Comentarios Qué / Para qué / Impacto** | Cada opción de `ansible.cfg`, el inventario, cada tarea con riesgo del playbook (`serial`, validación, borrar lo que sobra, comprobación final), `ci-deploy` y el workflow; el Impacto dice qué pasa si se quita (sin `ssh-users`, sin `reset_connection`, sin `serial`) | Las opciones comentadas, sin Impacto en alguna | 12 |
| **README del kit** | Requisitos, cinco filas nuevas y bitácora de la semana 12; sección "Automatización: Ansible y CI" con los comandos, la diferencia con `sshd-deploy` y la preparación de la llave, el `known_hosts` y la cuenta del CI | Filas y bitácora, sin la sección completa | 10 |
| **Playbook legible** | Nombres de tarea que dicen qué y por qué (se leen en la salida), módulos en lugar de `shell` para cambiar, `changed_when: false` en lo que solo consulta | Funciona, con nombres genéricos o `shell` donde había módulo | 8 |
| **Robustez** | `ci-deploy` no deja nada en disco ni en la salida y nunca acepta una host key nueva; el playbook no toca un segundo servidor si falla el primero y no deja un `sshd_config.d` sin validar | Falta una de las cuatro | 6 |
| **Git** | Commit nuevo en `~/ssh-infra-kit` con mensaje descriptivo, sin llaves, `known_hosts` ni secretos | Sin commit de la semana | 4 |
| **Total** | | | **40** |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Una llave privada o un secreto del CI en el repositorio del kit o en su historial de git | −20 pts |
| `StrictHostKeyChecking no` o `accept-new`, `UserKnownHostsFile /dev/null` o una llamada a `ssh-keyscan` en `ci-deploy`, el workflow, `ansible/` o `config` | −10 pts |
| `host_key_checking = False` en `ansible.cfg` | −10 pts |
| `set -x` o un `echo` de la llave en `ci-deploy` | −10 pts |
| `eval` o `sh -c "$SSH_ORIGINAL_COMMAND"` en un comando forzado | −5 pts |

---

## 📋 Checklist de entrega

- [ ] Los 7 labs con sus criterios de éxito comprobados
- [ ] Las 10 preguntas de Conocimiento respondidas por escrito
- [ ] `3-proyecto/starter/` sin ningún `TODO`
- [ ] `./scripts/verificar-semana.sh 12` con las 12 comprobaciones en verde
- [ ] `ssh-infra-kit` con un commit nuevo y sin llaves ni secretos

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Proyecto — ssh-infra-kit: Ansible y despliegue desde CI](3-proyecto/README.md) | [Recursos — ebooks](4-recursos/ebooks-free/README.md) → |

[↑ Semana 12](README.md)
