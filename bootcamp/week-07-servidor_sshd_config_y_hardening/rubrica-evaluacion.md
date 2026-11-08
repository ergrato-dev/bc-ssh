# Rúbrica de Evaluación — Semana 07

> El servidor: `sshd_config`, `Match`, chroot SFTP y hardening. Se evalúan tres evidencias por separado y hace falta **70% en cada una**. No basta con que `sshd -T` diga lo correcto: tienes que saber qué valor gana y por qué, quién queda fuera con cada opción y cómo aplicar un cambio sin perder el acceso.

---

## 📊 Distribución de Evidencias

| Evidencia | Peso | Instrumento |
|---|:--:|---|
| 🧠 Conocimiento | 30% | Las 10 preguntas de esta rúbrica, respondidas por escrito |
| 💪 Desempeño | 40% | Los 7 labs, con sus criterios de éxito comprobados en el laboratorio |
| 📦 Producto | 30% | `ssh-infra-kit` con `server/sshd_config.d/` y `bin/sshd-deploy`: 60 pts de autograding + 40 de calidad |

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
| 1 | En un servidor nuevo escribes `PasswordAuthentication no` en `/etc/ssh/sshd_config.d/60-endurecido.conf`, recargas, y la contraseña sigue entrando. Da dos causas posibles y cómo las distingues. |
| 2 | ¿Qué diferencia hay entre `sshd -t`, `sshd -T` y `sshd -T -C user=ana`? ¿Por qué `sshd -T` puede decir `no` mientras el servidor sigue aceptando contraseñas? |
| 3 | ¿Qué pasa con las sesiones abiertas cuando recargas `sshd`? ¿Por qué eso te protege y a la vez te engaña? |
| 4 | ¿Qué permite el valor por defecto de `PermitRootLogin`? ¿Por qué el kit usa `no` y cómo se administra entonces el servidor? |
| 5 | Un usuario tiene cuatro llaves en su agente y `MaxAuthTries 3` en el servidor. ¿Qué le puede pasar y cómo se arregla en el cliente? ¿Qué protegen `LoginGraceTime` y `MaxStartups`? |
| 6 | Con `AllowGroups ssh-users` y `DenyUsers ana`, ¿entra `ana` si está en `ssh-users`? ¿Qué ve el cliente cuando no le dejan entrar, y dónde está el motivo? |
| 7 | Explica dos errores con `Match`: una opción global que acaba dentro de un `Match` y `Match User !ana`. ¿Cómo pruebas un `Match` antes de aplicarlo? |
| 8 | Para una cuenta que solo debe subir archivos, ¿qué cierra y qué deja abierto cada capa: shell `nologin`, `ForceCommand internal-sftp`, `ChrootDirectory` y `DisableForwarding`? |
| 9 | ¿Qué permisos exige `sshd` a la carpeta del chroot y por qué? ¿Dónde escribe entonces el usuario? |
| 10 | Describe el procedimiento para cambiar `sshd` sin quedarte fuera. ¿Por qué la prueba tiene que ir sin master, y qué hace `sshd-apply` si nadie confirma? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** (a) Otro archivo que va antes en orden alfabético pone `PasswordAuthentication yes` (`50-cloud-init.conf`, `10-bc-ssh.conf`): `sudo grep -ri password /etc/ssh/sshd_config.d/` y `sudo sshd -T | grep passwordauth`, que dirá `yes`. (b) No se recargó, o se recargó otro servicio: `sshd -T` dice `no`, pero la contraseña sigue entrando; recargar y probar con una conexión nueva. Una tercera: `KbdInteractiveAuthentication yes` sigue pidiendo contraseña a través de PAM.

**2.** `-t` valida y solo habla si hay error (archivo y línea). `-T` escribe la configuración efectiva completa, con el valor ganador de cada opción. `-T -C user=ana,addr=...` aplica además los `Match` que coincidirían con esa conexión. Las tres leen **los archivos**: el `sshd` en marcha usa lo que leyó al arrancar o en la última recarga.

**3.** Siguen como estaban: cada conexión es un proceso propio que nació con la configuración de ese momento; recargar solo afecta al `listener`. Protege porque una sesión abierta permite deshacer un cambio que te deja fuera. Engaña porque esa sesión, o el master del multiplexing, sigue entrando aunque las conexiones nuevas fallen: la prueba tiene que ser una conexión nueva.

**4.** `prohibit-password` (`without-password` en `sshd -T`): root entra con llave. Con `no`, root nunca entra por SSH: es el usuario que prueban todos los ataques, y con cuentas personales y `sudo` los logs dicen quién hizo cada cosa. Se administra entrando con tu usuario y usando `sudo`.

**5.** Cada llave ofrecida gasta un intento: si la buena es la cuarta, el servidor corta antes (`Too many authentication failures`). En el cliente: `IdentitiesOnly yes` y `IdentityFile` concreto por host. `LoginGraceTime` cierra las conexiones que no se autentican a tiempo y `MaxStartups` limita cuántas conexiones sin autenticar se aceptan: las dos evitan que una oleada de intentos ocupe los huecos de quien sí tiene llave.

**6.** No: `DenyUsers` se comprueba antes y gana siempre; hay que pasar todas las listas. El cliente ve `Permission denied`, lo mismo que con una llave mala, para no dar pistas. El motivo está en el log del servidor: `User ana from ... not allowed because listed in DenyUsers`.

**7.** Un `Match` dura hasta el siguiente `Match` o el final del archivo: ni la sangría ni una línea en blanco lo cierran, así que una opción "global" escrita debajo solo se aplica a quien coincide. Una lista solo con negaciones no coincide con nadie: se escribe `User *,!ana`. Se prueba con `sudo sshd -T -C user=...` con un usuario que debe coincidir y otro que no.

**8.** `nologin`: cierra la shell, pero `sftp` tampoco funciona (`sftp-server` se arranca a través de la shell) y deja abiertos los túneles. `ForceCommand internal-sftp`: solo SFTP, con el servidor que va dentro de `sshd`, pero el usuario lee todo el disco que sus permisos le dejan. `ChrootDirectory`: solo ve su carpeta, pero sigue pudiendo abrir túneles hacia la red del servidor. `DisableForwarding` (y `PermitTTY no`): quita túneles, agente, X11 y terminal.

**9.** La carpeta del chroot y todas las de encima tienen que ser de root y sin escritura para nadie más; si no, `bad ownership or modes for chroot directory`. Si el usuario pudiera escribir en la raíz de su chroot, podría crear allí archivos de sistema falsos que engañen a programas que root ejecuta dentro. El usuario escribe en una subcarpeta suya (`subidas`), y `-d /subidas` hace que empiece ahí.

**10.** Sesión abierta; `sudo sshd -t`; programar la vuelta atrás; recargar; probar con `ssh -o ControlPath=none`; si entra, cancelar la vuelta atrás; si nada funciona, consola. Sin master porque el master se autenticó antes del cambio y entra aunque la configuración nueva te deje fuera. Si nadie crea `CARPETA/confirmado` en `DEPLOY_TIMEOUT` segundos, `sshd-apply` restaura `/etc/ssh/sshd_config.d.anterior` y recarga.

</details>

---

## 💪 Desempeño (40%)

Dentro de cada lab: 10 puntos si se cumplen todos los criterios y explicas con tus palabras por qué funciona; 8 si se cumplen todos; 7 si falla uno; menos de 7 si fallan dos o más.

| Lab | Criterio | Puntos |
|---|---|:--:|
| [01 — `sshd_config`](2-practicas/lab-01-sshd-config/README.md) | Archivos y orden; primer valor que gana con `sshd -T`; error encontrado con `sshd -t`; diferencia entre archivos y `sshd` en marcha; recarga sin cortar sesiones | 10 |
| [02 — Autenticación](2-practicas/lab-02-autenticacion/README.md) | Llave comprobada antes; contraseñas fuera; root con llave visto y cerrado; `MaxAuthTries` y `LoginGraceTime` probados; motivos en los logs | 10 |
| [03 — Quién entra](2-practicas/lab-03-quien-entra/README.md) | `AllowUsers` y `AllowGroups`; fuera y de vuelta por sesión y por consola; orden de `Deny`/`Allow`; usuario limitado a una red; `nologin` explicado | 10 |
| [04 — `Match`](2-practicas/lab-04-match/README.md) | Excepción con `Match` probada con `-C`; alcance de un `Match`; opción no admitida; condiciones combinadas y negación corregida | 10 |
| [05 — SFTP con chroot](2-practicas/lab-05-sftp-chroot/README.md) | Las cuatro capas añadidas y probadas una a una; error de permisos encontrado en el log y corregido; túnel abierto y luego cerrado | 10 |
| [06 — Sesión y reenvíos](2-practicas/lab-06-sesion-y-reenvios/README.md) | Agente y X11 cerrados; `AcceptEnv` explicado; `MaxSessions` con multiplexing; `ClientAliveInterval` cerrando una sesión | 10 |
| [07 — Sin quedarte fuera](2-practicas/lab-07-cambios-sin-quedarte-fuera/README.md) | Fuera con una configuración válida y de vuelta; vuelta atrás automática a mano; `sshd` tumbado y recuperado; procedimiento explicado | 10 |

La nota de Desempeño es la media de los siete labs.

---

## 📦 Producto (30%)

### Verificable por el autograding — 60 puntos

Lo ejecuta `./scripts/verificar-semana.sh 07`. Es binario: pasa o no pasa.

| Comprobación | Puntos |
|---|:--:|
| `cfg-valida` — sshd -t acepta la configuración del kit | 1 |
| `cfg-solo-llaves` — Sin contraseña: PasswordAuthentication y KbdInteractiveAuthentication en no | 3 |
| `cfg-sin-root` — root no entra por SSH, ni con llave (PermitRootLogin no) | 2 |
| `cfg-grupos` — Solo entran los grupos ssh-users y sftp-only | 3 |
| `cfg-limites` — MaxAuthTries 3, LoginGraceTime 20 y MaxStartups 10:30:60 | 2 |
| `cfg-sesion` — Sin reenvío de X11 ni de agente, ClientAlive 300 x 2 y LogLevel VERBOSE | 3 |
| `cfg-sftp-match` — Un usuario de sftp-only queda en chroot, solo con internal-sftp y sin reenvíos ni terminal | 4 |
| `cfg-match-acotado` — El bloque Match no cambia nada a los demás usuarios | 2 |
| `real-llave-entra` — Con el kit en un sshd real, alumno (de ssh-users) entra con llave | 2 |
| `real-sin-password` — Con el kit en un sshd real, la contraseña de alumno (solo laboratorio) se rechaza | 3 |
| `real-fuera-de-grupos` — Un usuario con llave pero fuera de los grupos no entra | 3 |
| `real-sftp-chroot` — Un usuario de sftp-only sube a /subidas y no puede leer fuera del chroot | 5 |
| `real-sftp-sin-shell` — Un usuario de sftp-only no obtiene shell ni ejecuta órdenes | 2 |
| `deploy-aplica` — bin/sshd-deploy aplica el kit: antes la contraseña entraba, después no | 5 |
| `deploy-invalida` — Con un .conf inválido, bin/sshd-deploy sale con 1 y el servidor sigue como estaba | 6 |
| `deploy-deshace` — Si la configuración nueva deja fuera, sshd-deploy lo detecta aunque haya un master y el servidor la deshace solo | 10 |
| `kit-sigue-funcionando` — Los scripts de semanas anteriores siguen respondiendo | 1 |
| `kit-completo-y-limpio` — Sin TODO en config, conf.d/, bin/ y server/, y shellcheck sin avisos | 3 |
| **Total** | **60** |

### Calidad — 40 puntos

| Criterio | Excelente | Suficiente | Puntos |
|---|---|---|:--:|
| **Comentarios Qué / Para qué / Impacto** | Cada opción de `server/sshd_config.d/` con los tres, y el Impacto dice a quién deja fuera y qué comprobar antes | Las opciones comentadas, sin Impacto en alguna | 12 |
| **README del kit** | Filas de `bin/sshd-deploy` y `server/` con códigos y ejemplo; bitácora de la semana 07; "Endurecer un servidor" con requisitos previos, recuperación y la respuesta sobre `/tmp/confirmado` | Filas y bitácora, sin la sección completa | 10 |
| **Mensajes** | Cada salida de `sshd-deploy` y `sshd-apply` dice qué pasó y qué va a pasar (se aplicó, no se aplicó, se deshace en N s), por stderr los errores | Mensajes correctos pero sin decir qué hacer | 6 |
| **Seguridad** | Validación antes de recargar, vuelta atrás con confirmación en una carpeta de `mktemp -d`, prueba sin master; ningún `NOPASSWD` ni contraseña en el kit | Falta una de las tres protecciones | 8 |
| **Git** | Commit nuevo en `~/ssh-infra-kit` con mensaje descriptivo y sin llaves ni host keys | Sin commit de la semana | 4 |
| **Total** | | | **40** |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Una llave privada o una host key en el repositorio del kit o en su historial de git | −20 pts |
| `PasswordAuthentication yes`, `PermitRootLogin yes` o `PermitEmptyPasswords yes` en `server/sshd_config.d/` | −10 pts |
| Un script del kit que recarga `sshd` sin `sshd -t` antes | −10 pts |
| `StrictHostKeyChecking no`, `accept-new` o `UserKnownHostsFile /dev/null` en cualquier archivo del kit | −10 pts |
| Contraseñas o frases de paso escritas en un archivo del kit | −10 pts |

---

## 📋 Checklist de entrega

- [ ] Los 7 labs con sus criterios de éxito comprobados
- [ ] Las 10 preguntas de Conocimiento respondidas por escrito
- [ ] `3-proyecto/starter/` sin ningún `TODO`
- [ ] `./scripts/verificar-semana.sh 07` con las 18 comprobaciones en verde
- [ ] `ssh-infra-kit` con un commit nuevo y sin llaves

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Proyecto — ssh-infra-kit: el servidor endurecido y cómo aplicarlo](3-proyecto/README.md) | [Recursos — ebooks](4-recursos/ebooks-free/README.md) → |

[↑ Semana 07](README.md)
