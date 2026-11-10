# Rúbrica de Evaluación — Semana 11

> 2FA, fail2ban y auditoría con ssh-audit. Se evalúan tres evidencias por separado y hace falta **70% en cada una**. No basta con que `ssh-audit` salga en verde o con entrar con un código: tienes que saber qué ve un atacante, por qué cada factor protege de una cosa distinta, qué cuenta fail2ban y cómo no dejarte fuera a ti mismo.

---

## 📊 Distribución de Evidencias

| Evidencia | Peso | Instrumento |
|---|:--:|---|
| 🧠 Conocimiento | 30% | Las 10 preguntas de esta rúbrica, respondidas por escrito |
| 💪 Desempeño | 40% | Los 7 labs, con sus criterios de éxito comprobados en el laboratorio |
| 📦 Producto | 30% | `ssh-infra-kit` con `bin/audit`, `15-algoritmos.conf`, `60-2fa.conf`, PAM, jaula y `sshd-deploy` ampliado: 60 pts de autograding + 40 de calidad |

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
| 1 | ¿Qué ve `ssh-audit` de un servidor y por qué no necesita cuenta? ¿Qué **no** puede ver? |
| 2 | ¿Qué significan `[fail]`, `[warn]` e `[info]`? Pon un ejemplo de cada familia de problemas: curvas NIST, tamaño y forma (`-etm`). ¿Con qué códigos sale `ssh-audit`? |
| 3 | Si `server` ofrece `hmac-sha1`, ¿tu conexión lo usa? ¿Por qué quitarlo entonces? ¿Qué es `MAC: <implicit>`? |
| 4 | Explica `MACs -*-sha1*,umac-64*,hmac-sha2-256`: qué hace el `-`, qué hacen los comodines, y por qué `hmac-sha2-256` va sin `*`. ¿Qué ve un cliente que solo habla lo que quitaste? |
| 5 | ¿Qué diferencia hay entre una política generada con `-M` y la del kit? ¿Qué hacen `allow_algorithm_subset_and_reordering` y `allow_larger_keys`, y por qué la política incluye `mlkem768x25519-sha256` y `ext-info-s`? |
| 6 | ¿Cómo se calcula un código TOTP? ¿Qué pasa si el reloj del móvil se desvía 5 minutos? ¿Qué guarda `~/.google_authenticator` y quién más puede leerlo? |
| 7 | Explica las tres piezas del segundo factor (`KbdInteractiveAuthentication`, `AuthenticationMethods`, PAM). ¿Por qué se comenta `common-auth`? ¿Qué pasa con `PasswordAuthentication yes`? |
| 8 | ¿Por qué `Match Group dosfa` y no para todos? ¿En qué orden se da de alta a una persona y qué pasa con `nullok`? ¿Qué dejan de poder hacer las cuentas de `dosfa`, y qué hace el multiplexing con el código? |
| 9 | ¿Qué son filtro, jaula y acción en fail2ban? ¿Por qué el kit usa `mode = normal` y no `aggressive`? ¿Por qué fail2ban puede bloquearte nada más arrancar, y cómo te desbloqueas si estás fuera? |
| 10 | Con el log de `sshd`: ¿cómo sabes con qué llave entró alguien? ¿Qué añade `LogLevel VERBOSE`? ¿Para qué sirve guardar `sshd -T` después de cada despliegue? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** El banner y la lista `KEXINIT`: los algoritmos de intercambio de llaves, host keys, cifrados y MAC, y las huellas de las host keys. Todo eso se envía sin cifrar y antes de autenticar a nadie, a cualquiera que abra una conexión. No ve nada que dependa de la autenticación: si se aceptan contraseñas, si root entra, `AllowGroups`, el segundo factor o `Match`. Eso lo dicen `sshd -T` y el log.

**2.** `fail`: roto o con dudas serias, hay que quitarlo. `warn`: débil o arriesgado, se quita si ningún cliente lo necesita. `info`: datos. Curvas NIST: `ecdh-sha2-nistp256`, `ecdsa-sha2-nistp256` (`fail`). Tamaño: `diffie-hellman-group14-sha256` (2048 bits) y `umac-64` (etiqueta de 64 bits) (`warn`). Forma: `hmac-sha2-256` sin `-etm` (MAC sobre el texto sin cifrar, `warn`); `hmac-sha1` (`fail`). Sale con 0 sin `warn` ni `fail`, 2 con algún `warn`, 3 con algún `fail`.

**3.** No: se elige el primero de la lista del cliente que tenga el servidor, y OpenSSH moderno elige `chacha20-poly1305` o `aes-gcm`, que son AEAD y no usan MAC (`MAC: <implicit>`). Se quita porque está para otros clientes y es lo que un atacante en medio intentaría forzar; además, lo que no se ofrece no puede usarse mal.

**4.** El `-` parte de la lista por defecto y quita lo que sigue; los comodines quitan familias (`*-sha1*` incluye `hmac-sha1` y `hmac-sha1-etm@openssh.com`; `umac-64*`, las dos de 64 bits). `hmac-sha2-256*` quitaría también `hmac-sha2-256-etm@openssh.com`, que es bueno. Un cliente sin nada en común ve `Unable to negotiate ...: no matching MAC found. Their offer: ...` y no conecta.

**5.** La generada es una foto exacta: falla con cualquier cambio, aunque el servidor sea más estricto. La del kit es la lista de lo permitido: con `allow_algorithm_subset_and_reordering = true` el servidor puede ofrecer menos o en otro orden, nunca otros; con `allow_larger_keys = true`, una host key más grande también cumple. `mlkem768x25519-sha256` llega con OpenSSH 9.9+: con él en la lista, la política sigue cumpliéndose al actualizar. `ext-info-s` y `kex-strict-s-v00@openssh.com` no son algoritmos sino avisos (extensiones y defensa contra Terrapin) que aparecen en la lista; sin ellos la política falla.

**6.** Servidor y móvil comparten un secreto; cada uno calcula el número de periodos de 30 s desde 1970 y aplica HMAC-SHA1 al secreto con ese número; de ahí salen 6 cifras. Con 5 minutos de desvío, el móvil calcula el código de otro periodo y el servidor lo rechaza (`WINDOW_SIZE 3` solo acepta el anterior, el actual y el siguiente). El archivo guarda el secreto, las opciones (límite de intentos, ventana, no reutilizar), los códigos usados y los de emergencia. Lo lee su dueño y root: el segundo factor no protege de quien ya es root en el servidor.

**7.** `KbdInteractiveAuthentication yes` permite el método por el que `sshd` hace preguntas (vía PAM). `AuthenticationMethods publickey,keyboard-interactive` exige los dos métodos en ese orden. El PAM de `sshd` decide qué se pregunta: `pam_google_authenticator.so`. Se comenta `common-auth` porque si no, PAM pediría además la contraseña de Unix. Con `PasswordAuthentication yes`, PAM recibiría la contraseña como si fuera el código: por eso `10-acceso.conf` la deja en `no`.

**8.** Para activarlo persona a persona sin dejar fuera a quien aún no tiene secreto. Primero la persona crea su secreto; después entra en el grupo; y prueba con una conexión nueva antes de cerrar la que tiene. `nullok` dejaría pasar a quien no tiene secreto: el segundo factor se volvería opcional sin que nadie lo note. Las cuentas de `dosfa` necesitan una terminal: nada de `BatchMode`, `cron`, `bin/backup` ni Ansible. Lo que va por un master de multiplexing no vuelve a autenticarse: el código se pide una vez.

**9.** El filtro reconoce fallos y saca la IP de cada línea; la acción bloquea y desbloquea (un conjunto de nftables); la jaula une log, filtro, acción y límites. `aggressive` cuenta cualquier conexión cerrada antes de autenticarse: `ssh-copy-id`, `ssh-audit` (unas 40 conexiones) o una llave que el servidor no conoce te bloquean a ti. Al arrancar, fail2ban lee el log dentro de `findtime`: si ya hay `maxretry` fallos de tu IP, te bloquea. Desde fuera no hay SSH: otra IP, la consola del proveedor (`docker compose exec server fail2ban-client set sshd unbanip IP`) o esperar a que pase `bantime`.

**10.** `Accepted publickey ... ssh2: ED25519 SHA256:...`: esa huella se cruza con `ssh-keygen -lf authorized_keys` (o con el registro de la CA para certificados), y el comentario de la llave dice qué equipo era. `VERBOSE` añade las llaves rechazadas (`Failed publickey ... SHA256:...`) y la aceptación parcial con dos factores. `sshd -T` es una foto de la configuración que corre: con `diff` ves cualquier cambio que no hiciste tú.

</details>

---

## 💪 Desempeño (40%)

Dentro de cada lab: 10 puntos si se cumplen todos los criterios y explicas con tus palabras por qué funciona; 8 si se cumplen todos; 7 si falla uno; menos de 7 si fallan dos o más.

| Lab | Criterio | Puntos |
|---|---|:--:|
| [01 — Leer ssh-audit](2-practicas/lab-01-leer-ssh-audit/README.md) | Informe leído por secciones; `fail`/`warn` clasificados; ofrecido frente a usado; Terrapin y DHEat; cliente con `-c`; JSON | 10 |
| [02 — Quitar algoritmos](2-practicas/lab-02-quitar-algoritmos/README.md) | `sshd -T`; tres líneas con `-`; auditoría en 0; tres `Unable to negotiate`; host key ECDSA; código 2 con `+` | 10 |
| [03 — Políticas](2-practicas/lab-03-politicas-ssh-audit/README.md) | Integrada explicada; `-M` y `-P`; exacta frente a subconjunto; política propia; `interno` por túnel | 10 |
| [04 — TOTP por dentro](2-practicas/lab-04-totp-por-dentro/README.md) | Secreto creado; archivo explicado; `oathtool` y `Counter`; mismo código en dos sitios; hora y ventana; root y el secreto | 10 |
| [05 — Llave y código](2-practicas/lab-05-llave-y-codigo/README.md) | PAM con copia; `Match Group`; llave sola rechazada; llave y código; malo, repetido, límite y emergencia; sin llave; multiplexing | 10 |
| [06 — fail2ban](2-practicas/lab-06-fail2ban/README.md) | `fail2ban-regex`; jaula probada con `-t`; bloqueo al arrancar; nftables; desbloqueo; `bantime.increment`; `ignoreip`; `aggressive` | 10 |
| [07 — Leer el log](2-practicas/lab-07-leer-el-log/README.md) | Accesos con huella; huella cruzada con la llave; llave rechazada; fallos por IP y usuario; sesiones abiertas; `sshd -T` y `diff` | 10 |

La nota de Desempeño es la media de los siete labs.

---

## 📦 Producto (30%)

### Verificable por el autograding — 60 puntos

Lo ejecuta `./scripts/verificar-semana.sh 11`. Es binario: pasa o no pasa.

| Comprobación | Puntos |
|---|:--:|
| `audit-uso` — audit sale con 2 sin hosts, con una opción desconocida o sin política legible | 2 |
| `audit-cumple` — audit dice «cumple» y sale con 0 con un sshd que usa 15-algoritmos.conf, resolviendo el alias con ssh -G | 5 |
| `audit-no-cumple` — audit dice «no cumple», enseña qué falla y sale con 1 si un host ofrece algoritmos fuera de la política | 4 |
| `audit-no-responde` — audit dice «no responde» y sale con 1 si no puede conectar | 2 |
| `algoritmos-sshd` — 15-algoritmos.conf quita curvas NIST, grupo 14, SHA-1, umac-64 y MAC sin etm, y conserva sntrup761 y los certificados Ed25519 | 5 |
| `politica-subconjunto` — La política acepta un servidor que ofrece menos algoritmos y rechaza uno que añade un cifrado CBC | 4 |
| `dosfa-pide-codigo` — Con 60-2fa.conf, un usuario de dosfa con su llave no entra sin código (keyboard-interactive) | 5 |
| `dosfa-llave-y-codigo` — Un usuario de dosfa entra con su llave y el código TOTP, que PAM pide como «Verification code» y no como contraseña | 5 |
| `dosfa-codigo-malo` — Un código equivocado no entra, y el mismo código bueno no sirve dos veces | 3 |
| `dosfa-sin-llave` — El código TOTP sin la llave no entra: primero publickey | 2 |
| `dosfa-solo-el-grupo` — Quien no está en dosfa sigue entrando solo con su llave | 3 |
| `fail2ban-jaula` — La jaula sshd del kit es válida: activa, lee /var/log/auth.log, 5 fallos en 10m, 1h creciente hasta 1w | 4 |
| `fail2ban-banea` — fail2ban bloquea la IP con 5 usuarios inválidos, no la de 4 ni la de conexiones cerradas sin autenticar, ni 127.0.0.1 | 5 |
| `deploy-instala-todo` — sshd-deploy instala sshd_config.d, pam.d/sshd y la jaula de fail2ban, arranca fail2ban y confirma | 5 |
| `deploy-deshace-todo` — Si no se confirma, sshd-apply devuelve también el PAM y las jaulas anteriores | 5 |
| `kit-completo-y-limpio` — Sin TODOs, shellcheck sin avisos y los scripts anteriores siguen respondiendo | 1 |
| **Total** | **60** |

### Calidad — 40 puntos

| Criterio | Excelente | Suficiente | Puntos |
|---|---|---|:--:|
| **Comentarios Qué / Para qué / Impacto** | Cada línea de `15-algoritmos.conf`, `60-2fa.conf`, el PAM, la jaula y la política con los tres; el Impacto dice qué clientes dejan de conectar, qué pasa con alguien del grupo sin secreto, por qué no `nullok`, por qué no `aggressive` y por qué no redes en `ignoreip` | Las opciones comentadas, sin Impacto en alguna | 12 |
| **README del kit** | Filas nuevas y actualizadas (`sshd-deploy`, `sshd-apply`, requisitos); bitácora de la semana 11; sección "Segundo factor, fail2ban y auditoría" con auditar, alta en orden, móvil perdido, bloqueos y cómo salir de uno propio | Filas y bitácora, sin la sección completa | 10 |
| **Mensajes** | `bin/audit` distingue no cumple, no responde y política inválida, por stderr los errores; el uso nombra `-p`; `sshd-apply` dice qué no se aplicó | Mensajes correctos sin distinguir los casos | 6 |
| **Robustez** | `sshd-apply` guarda y restaura PAM y jaulas, valida con `sshd -t` y `fail2ban-client -t` antes de recargar, y no toca PAM ni fail2ban si el kit no los trae; `sshd-deploy` no envía lo que no existe | Falta una de las cuatro | 8 |
| **Git** | Commit nuevo en `~/ssh-infra-kit` con mensaje descriptivo, sin `.google_authenticator`, secretos, códigos ni llaves | Sin commit de la semana | 4 |
| **Total** | | | **40** |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Un secreto TOTP, un código de emergencia o una llave privada en el repositorio del kit o en su historial de git | −20 pts |
| `nullok` en `server/pam.d/sshd` | −10 pts |
| `common-auth` activo junto al código (se pide contraseña y código) o `PasswordAuthentication yes` en el kit | −10 pts |
| `mode = aggressive` o una red entera en `ignoreip` de la jaula del kit | −5 pts |
| `StrictHostKeyChecking no` o `UserKnownHostsFile /dev/null` en cualquier archivo del kit | −10 pts |

---

## 📋 Checklist de entrega

- [ ] Los 7 labs con sus criterios de éxito comprobados
- [ ] Las 10 preguntas de Conocimiento respondidas por escrito
- [ ] `3-proyecto/starter/` sin ningún `TODO`
- [ ] `./scripts/verificar-semana.sh 11` con las 16 comprobaciones en verde
- [ ] `ssh-infra-kit` con un commit nuevo y sin secretos TOTP ni llaves

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Proyecto — ssh-infra-kit: auditoría, segundo factor y fail2ban](3-proyecto/README.md) | [Recursos — ebooks](4-recursos/ebooks-free/README.md) → |

[↑ Semana 11](README.md)
