# Rúbrica de Evaluación — Semana 14

> Proyecto integrador `ssh-infra-kit`: integración, documentación y defensa. Se evalúan tres evidencias por separado y hace falta **70% en cada una**. No basta con que el kit pase sus comprobaciones: tienes que saber cómo encajan sus piezas, seguir y escribir procedimientos que otra persona pueda usar, decir qué no cubre tu kit y defenderlo delante de alguien.

---

## 📊 Distribución de Evidencias

| Evidencia | Peso | Instrumento |
|---|:--:|---|
| 🧠 Conocimiento | 30% | Las 10 preguntas de esta rúbrica, respondidas por escrito |
| 💪 Desempeño | 40% | Los 7 labs, con sus criterios de éxito comprobados en el laboratorio (50%), y la defensa (50%) |
| 📦 Producto | 30% | `ssh-infra-kit` con `bin/kit-check`, `RUNBOOK.md`, los arreglos de integración y el README final: 60 pts de autograding + 40 de calidad |

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
| 1 | ¿Qué es un fallo de integración? Explica los dos que encontraste en `bin/doctor` y `bin/kh-add`, y por qué ninguna prueba de su semana podía encontrarlos. |
| 2 | El kit vive en tres sitios: el repositorio, tu `~/.ssh` y `~/.ssh-ca`, y los secretos del CI. ¿Qué guarda cada uno y qué no guarda nunca? ¿Qué haces si una llave privada llega al repositorio, y por qué borrarla no basta? |
| 3 | Después de un `ssh-copy-id` con la configuración del kit, `ssh lab-server` entra y `bin/doctor lab-server` no. ¿Por qué? ¿Qué otras herramientas fallarían igual que `doctor`? |
| 4 | ¿Qué comprueba `bin/kit-check`, qué **no** puede comprobar, y por qué va en el CI antes del despliegue? ¿Por qué acepta una carpeta como argumento? |
| 5 | Una segunda ejecución del playbook da `changed=0`. ¿Qué demuestra? ¿Qué significa si un día da `changed=1` sin que hayas cambiado el repositorio? |
| 6 | Revocas la llave de Ana y la KRL ya está en el servidor, pero Ana sigue ejecutando comandos. ¿Cómo es posible y qué haces? ¿Por qué revocas la llave y no solo su certificado? |
| 7 | ¿Qué partes tiene un procedimiento del RUNBOOK y para qué sirve cada una? ¿Qué es la prueba del extraño y qué encontraste al hacerla en el lab 06? |
| 8 | Da tres amenazas contra las que protege el kit, con el archivo que lo hace, y tres contra las que **no**, con lo que harías. ¿Por qué se escribe la segunda lista? |
| 9 | `bin/doctor` dice `Permission denied (publickey)`. Da tres causas que viste esta semana, en qué línea del log del servidor se distingue cada una y cómo llegas a ese log si no puedes entrar. |
| 10 | La llave privada de tu CA de usuarios se ha copiado. ¿Por qué no basta con revocar certificados? Describe el procedimiento y qué cuesta. ¿Qué cambiarías para que no vuelva a pasar? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Un fallo entre dos piezas que funcionan bien por separado pero no se conocían. `bin/doctor` (semana 13) buscaba `Server host key:`, y con un certificado de host `ssh -v` escribe `Server host certificate:`: `host key` quedaba vacío. `bin/kh-add` (semana 02) tomaba la línea `@cert-authority` de la CA de hosts (semana 10) por "otra llave" del servidor y se negaba a añadir la nueva. Cada uno se probó en su semana sin la pieza que llegó después (o antes, sin usarla): solo un recorrido con todas las piezas a la vez los muestra.

**2.** El repositorio: configuración de cliente y servidor, scripts, playbook y documentación; nunca llaves privadas, la CA ni contraseñas. `~/.ssh` y `~/.ssh-ca`: tus llaves, `known_hosts`, la CA con su frase; nada que tenga que llegar a un servidor. Los secretos del CI: la llave de despliegue y las host keys comprobadas. Una llave en el repositorio queda en el historial y en cada copia o clon: se considera comprometida y se **revoca** (RUNBOOK, "Perdí una llave o un equipo"); después se borra y se crea otra.

**3.** `ssh-copy-id -F config` abre un master (`ControlMaster auto`, `ControlPersist 10m`) autenticado con la contraseña, y `ssh lab-server` entra por él sin probar la llave. `bin/doctor` abre siempre una conexión nueva (`ControlPath=none`) con `BatchMode`, que no puede pedir la frase, y la llave no estaba en el agente. Fallarían igual Ansible, el CI y cualquier script con `BatchMode`. Arreglo: `ssh-copy-id -o ControlPath=none`, y la llave en el agente.

**4.** Llaves privadas en los archivos, permisos de ejecución, que cada script esté en el README, que no queden `TODO`, que `ssh -G` acepte cada alias, que `sshd -t` acepte `sshd_config.d` y `shellcheck`. No comprueba nada que necesite un servidor: si un `AllowGroups` deja entrar a quien debe, si la CA está instalada, si una host key es la buena, ni el historial de git. En el CI, antes de `ci-deploy`, un kit roto no llega a los servidores. Acepta una carpeta para comprobar copias (y para que los checks la rompan sin tocar tu kit).

**5.** Que el servidor ya está exactamente como dice el repositorio y que el playbook es idempotente. Un `changed=1` sin cambios en el repositorio significa que alguien cambió el servidor a mano (o algo lo cambió): `--check --diff` dice qué, y aplicarlo lo deshace.

**6.** Ana tenía un master abierto, autenticado antes de la revocación; la KRL solo se mira al autenticar, y por el master no se vuelve a autenticar. Se cortan sus sesiones en cada servidor (`sudo pkill -u ana sshd`). Se revoca la llave porque revoca también cualquier certificado firmado para ella, incluido uno que no conozcas (otra serie, otra CA de la rotación).

**7.** Síntoma (el texto del error, para encontrar el procedimiento buscando lo que ves en la pantalla), pasos numerados con su comando (en orden, sin teoría) y comprobación (cómo sabes que terminaste, no que "parece que va"). La prueba del extraño: otra persona sigue el procedimiento al pie de la letra en un laboratorio limpio y cada vez que duda falta algo. En el lab 06: `kh-add` fallaba con la CA de hosts, `ssh-copy-id` necesitaba `ControlPath=none`, la CA había que reinstalarla en el servidor y `KIT_KNOWN_HOSTS` había que actualizarlo.

**8.** Protege: contraseñas probadas a fuerza (`PasswordAuthentication no` en `10-acceso.conf`, fail2ban); un servidor falso (`StrictHostKeyChecking yes` en `config`, `bin/kh-add`); root de un salto usando tu agente (`ForwardAgent no`, `AllowAgentForwarding no` en `20-sesion.conf`); algoritmos débiles (`15-algoritmos.conf`); una cuenta sin grupo con una llave buena (`AllowGroups`). No protege: tu propio equipo comprometido (llaves `-sk`, caducidad del agente), la llave de la CA o del CI robadas (procedimientos del RUNBOOK, rotación), los túneles de quien está en `ssh-users` (una decisión: `AllowTcpForwarding` si no se quiere), lo que se hace dentro del servidor. Se escribe para no crear una falsa sensación de seguridad y para que quien revisa el kit sepa dónde va el siguiente control.

**9.** `~/.ssh` escribible por otros: `Authentication refused: bad ownership or modes`. La cuenta fuera de `AllowGroups`: `not allowed because none of user's groups are listed in AllowGroups`. La llave revocada: `revoked by file /etc/ssh/revoked.krl`. (También: la llave no está en `authorized_keys`, un certificado con un principal que no está en `principals/`, una RSA corta.) Si no puedes entrar: la consola del proveedor (`docker compose exec server` en el laboratorio), y desde ella el log o `sshd -d -p 2222`.

**10.** Con la llave de la CA, quien la tiene se firma certificados nuevos para cualquier cuenta, con series que no conoces: no hay nada que revocar de antemano. Hay que dejar de confiar en la CA: una CA nueva, `user_ca.pub` con **solo** la nueva en cada servidor, volver a firmar a todas las personas (y, si fue la de hosts, todas las host keys y la línea `@cert-authority` de cada cliente). Cuesta que todo el mundo se quede sin acceso por certificado hasta tener el nuevo. Para que no vuelva: CA con frase, fuera del kit y de cualquier repositorio, en un equipo que no se usa para otra cosa o en una llave de hardware, y la CA en el agente solo unos minutos cuando firmas.

</details>

---

## 💪 Desempeño (40%)

### Los labs (50%)

Dentro de cada lab: 10 puntos si se cumplen todos los criterios y explicas con tus palabras por qué funciona; 8 si se cumplen todos; 7 si falla uno; menos de 7 si fallan dos o más.

| Lab | Criterio | Puntos |
|---|---|:--:|
| [01 — Un equipo nuevo](2-practicas/lab-01-un-equipo-nuevo/README.md) | Kit en un home vacío; host keys por la consola; la trampa del master explicada; llave con frase en el agente; `doctor` con `publickey` | 10 |
| [02 — Un servidor nuevo](2-practicas/lab-02-un-servidor-nuevo/README.md) | Un servidor sin el kit; leer `--check`; `changed=0`; `sshd -T`, `bin/audit` y `bin/doctor` | 10 |
| [03 — Alta con certificado](2-practicas/lab-03-alta-con-certificado/README.md) | CA fuera del repositorio; certificado de host; `principals/`; el `host key` vacío explicado; el `Include` arriba; Ana en el log | 10 |
| [04 — Una llave perdida](2-practicas/lab-04-una-llave-perdida/README.md) | Revocar la llave; `revoked by file`; el master que sigue dentro; cortarlo; el procedimiento escrito | 10 |
| [05 — Atacar tu servidor](2-practicas/lab-05-atacar-tu-servidor/README.md) | Contraseña, root y `AllowGroups` con su log; agente y SHA-1; el túnel como decisión; fail2ban y la consola | 10 |
| [06 — Reconstruir un servidor](2-practicas/lab-06-reconstruir-un-servidor/README.md) | El procedimiento por el error; la "otra llave" de `kh-add`; la misma copia comprobada y añadida; `cumple`; lo que faltaba | 10 |
| [07 — La defensa](2-practicas/lab-07-la-defensa/README.md) | Guion con salida esperada; ensayo en 15 min; el método en el paso 3; seis averías; seis preguntas | 10 |

### La defensa (50%)

Unos 30 minutos con tu evaluador ([teoría 03](1-teoria/03-la-defensa.md)), en un laboratorio recién creado.

| Parte | Excelente (10) | Suficiente (7) | Puntos |
|---|---|---|:--:|
| **Demo** (15 min) | Sigue el guion, cada paso demuestra algo y lo dices; `kit-check`, equipo nuevo, servidor con `changed=0`, alta y baja con su log; termina a tiempo | Funciona de punta a punta con alguna improvisación, o se pasa de tiempo | 10 |
| **Avería en vivo** (10 min) | Empieza por `bin/doctor`, nombra la capa, va al log por la consola, sigue el RUNBOOK, comprueba y dice qué lo habría evitado, todo en voz alta | La arregla, pero probando cosas sin método o en silencio | 10 |
| **Preguntas** | Respuestas cortas, con el archivo del kit delante y el coste de cada decisión; dice "no lo sé, lo comprobaría así" cuando toca | Responde, pero sin razones o sin saber dónde está en el kit | 10 |

La nota de Desempeño es la media de los labs (sobre 10) y la de la defensa (sobre 10), a partes iguales.

---

## 📦 Producto (30%)

### Verificable por el autograding — 60 puntos

Lo ejecuta `./scripts/verificar-semana.sh 14`. Es binario: pasa o no pasa.

| Comprobación | Puntos |
|---|:--:|
| `kit-check-uso` — bin/kit-check sale con 2 y dice cómo se usa con dos argumentos o con una carpeta que no es un kit | 3 |
| `kit-check-limpio` — bin/kit-check sale con 0 en tu kit, con una línea ok por cada comprobación | 5 |
| `kit-check-secretos` — bin/kit-check falla (solo en secretos) si el kit contiene una llave privada, y dice qué archivo | 5 |
| `kit-check-permisos` — bin/kit-check falla (solo en permisos) si un script de bin/ no es ejecutable | 3 |
| `kit-check-documentado` — bin/kit-check falla (solo en documentado) si un script de bin/ no aparece en el README | 3 |
| `kit-check-pendientes` — bin/kit-check falla (solo en pendientes) si queda un TODO, y dice dónde | 3 |
| `kit-check-config` — bin/kit-check falla (solo en config) si un archivo de conf.d/ tiene una opción que ssh no conoce | 4 |
| `kit-check-sshd` — bin/kit-check falla (solo en sshd) si server/sshd_config.d/ tiene un valor que sshd no acepta | 4 |
| `doctor-certificado-de-host` — Con un servidor que presenta certificado de host, bin/doctor escribe su tipo, la serie, el ID y la CA en host key | 5 |
| `doctor-pista-cortafuegos` — Con la conexión rechazada, la pista de bin/doctor habla del puerto y también de una IP bloqueada (fail2ban) | 3 |
| `kh-add-con-cert-authority` — bin/kh-add añade la host key aunque known_hosts tenga una línea @cert-authority que cubre el host, y sigue negándose si hay otra llave | 5 |
| `runbook-procedimientos` — RUNBOOK.md tiene los siete procedimientos, cada uno con Síntoma, Comprobación y el comando del kit que lo resuelve | 6 |
| `readme-final` — El README empieza por dónde mirar, documenta kit-check y RUNBOOK.md, dice qué protege el kit y qué no, y tiene la semana 14 en la bitácora | 4 |
| `ci-kit-check-antes` — El workflow del CI ejecuta bin/kit-check antes de bin/ci-deploy | 3 |
| `kit-completo-y-limpio` — Sin TODOs, shellcheck sin avisos y los scripts de semanas anteriores siguen respondiendo | 4 |
| **Total** | **60** |

### Calidad — 40 puntos

| Criterio | Excelente | Suficiente | Puntos |
|---|---|---|:--:|
| **RUNBOOK seguible** | Otra persona sigue cualquier procedimiento sin preguntarte nada; cada paso tiene su comando; incluye lo que encontraste en los labs 04 y 06 | Los siete procedimientos están, pero hay pasos sin comando o que hay que adivinar | 12 |
| **Modelo de amenazas honesto** | Cada amenaza cubierta nombra su archivo; la lista de lo que no se cubre incluye el túnel del lab 05, el propio equipo, la CA y el CI, con qué hacer | Tabla y lista presentes, pero genéricas o sin "dónde" | 10 |
| **Comentarios Qué / Para qué / Impacto** | `kit-check` explica cada comprobación y por qué la carpeta temporal y `HostCertificate`; los arreglos de `doctor` y `kh-add` dicen qué caso cubren | Comentarios presentes pero sin el Impacto | 8 |
| **README como punto de entrada** | Las primeras líneas llevan a instalar, al RUNBOOK, a qué protege y a `kit-check`; cada script tiene su fila; bitácora completa de las 14 semanas | Filas y secciones, pero hay que buscar por dónde empezar | 6 |
| **Git** | Commit de la semana, etiqueta `v1.0` y ninguna llave en `git log -p` | Sin etiqueta o sin commit de la semana | 4 |
| **Total** | | | **40** |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Una llave privada en el repositorio del kit o en su historial de git (incluida la CA o la llave del CI) | −20 pts |
| `StrictHostKeyChecking no` o `accept-new`, o `UserKnownHostsFile /dev/null`, en el kit | −10 pts |
| `bin/kh-add` que añade una llave distinta de la que ya hay para el host (la comprobación de la huella desaparece) | −10 pts |
| Un procedimiento del RUNBOOK que manda aceptar una host key sin comprobar su huella | −5 pts |

---

## 📋 Checklist de entrega

- [ ] Los 7 labs con sus criterios de éxito comprobados
- [ ] Las 10 preguntas de Conocimiento respondidas por escrito
- [ ] `3-proyecto/starter/` sin ningún `TODO`
- [ ] `./scripts/verificar-semana.sh 14` con las 15 comprobaciones en verde
- [ ] `ssh-infra-kit` con el commit de la semana, la etiqueta `v1.0` y sin llaves en el historial
- [ ] La defensa, con el guion del lab 07

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Proyecto — ssh-infra-kit: integración, documentación y defensa](3-proyecto/README.md) | [Recursos — ebooks](4-recursos/ebooks-free/README.md) → |

[↑ Semana 14](README.md)
