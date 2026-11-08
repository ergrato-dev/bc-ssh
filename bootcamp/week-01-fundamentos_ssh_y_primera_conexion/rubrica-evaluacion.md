# Rúbrica de Evaluación — Semana 01

> Fundamentos de SSH y primera conexión. Se evalúan tres evidencias por separado y hace falta **70% en cada una**. Conectarte no basta: tienes que saber por qué `ssh` se negó a darle tu contraseña a un servidor que cambió de llave.

---

## 📊 Distribución de Evidencias

| Evidencia | Peso | Instrumento |
|---|:--:|---|
| 🧠 Conocimiento | 30% | Las 10 preguntas de esta rúbrica, respondidas por escrito |
| 💪 Desempeño | 40% | Los 7 labs, con sus criterios de éxito comprobados en el laboratorio |
| 📦 Producto | 30% | `ssh-infra-kit` con `config` y `bin/lab-check`: 60 pts de autograding + 40 pts de calidad |

**Mínimo 70% en cada evidencia.** No en el promedio.

| Calificación | Rango |
|---|:--:|
| Sobresaliente | 90-100% |
| Notable | 80-89% |
| Aprobado | 70-79% |
| No aprobado | < 70% |

---

## 🧠 Conocimiento (30%)

Diez preguntas, 3 puntos cada una. No se pide recordar comandos: se pide explicar por qué SSH se comporta así.

| # | Pregunta |
|:--:|---|
| 1 | Telnet y SSH te dan una shell remota. Nombra las cuatro garantías de SSH y, para cada una, qué podría hacer un atacante en la misma Wi-Fi si faltara. |
| 2 | En la primera conexión a un servidor respondes `yes` sin mirar la huella. ¿Qué ataque queda abierto y por qué compararla con la salida de `docker compose exec server ssh-keygen -lf ...` lo cierra? |
| 3 | ¿Por qué, ante `REMOTE HOST IDENTIFICATION HAS CHANGED!`, `ssh` corta **antes** de pedir la contraseña? ¿Qué perderías si la pidiera y luego avisara? |
| 4 | Un script ejecuta `ssh server 'systemctl is-active nginx'` y recibe el código 255. Otro día recibe 3. ¿Qué significa cada uno y cuál de los dos indica un problema de red o de acceso? |
| 5 | `ssh server echo "$HOSTNAME"` imprime `client` y `ssh server 'echo "$HOSTNAME"'` imprime `server`. Explica qué shell expande la variable en cada caso. |
| 6 | Un `ssh` se queda colgado sin mensaje durante dos minutos y otro falla al instante con `Connection refused`. ¿Qué dice cada síntoma sobre el host y el puerto, y qué opción evita la espera de dos minutos? |
| 7 | Tu `~/.ssh/config` tiene `Host *` con `User root` arriba y `Host web` con `User deploy` abajo. ¿Con qué usuario entra `ssh web` y por qué? ¿Cómo lo compruebas sin conectarte? |
| 8 | La host key del servidor es asimétrica y la sesión se cifra con una llave simétrica. ¿Por qué SSH no cifra toda la sesión con la host key? |
| 9 | Alguien graba hoy todo tu tráfico SSH con un servidor y dentro de un año roba su host key privada. ¿Puede descifrar la grabación? ¿Qué propiedad del intercambio de llaves lo impide? |
| 10 | `sshd` crea dos procesos por conexión: uno `[priv]` como `root` y otro `alumno@pts/0`. ¿Qué gana la seguridad del servidor con esa separación? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Confidencialidad (sin ella lee tu contraseña y tus comandos), integridad (sin ella modifica comandos o respuestas en tránsito), autenticación del servidor (sin ella se hace pasar por el servidor y recibe tu contraseña) y autenticación del usuario (sin ella entra cualquiera como tú).

**2.** Un ataque de intermediario (*man-in-the-middle*): alguien en el camino responde en lugar del servidor con su propia host key, recibe tu contraseña y la reenvía. `yes` guarda **su** llave como buena. La huella obtenida por `docker compose exec` viene del propio servidor por un canal que no pasa por la red SSH: si coincide con la que te muestra `ssh`, hablas con el servidor real.

**3.** Porque la autenticación del usuario ocurre **después** de verificar al servidor y dentro del canal cifrado con ese servidor. Si pidiera la contraseña primero, se la entregarías al posible impostor; avisar después no la recuperaría.

**4.** 255 es un fallo del propio `ssh`: no resolvió el nombre, no conectó, la host key no coincide o no se autenticó. 3 es el código que devolvió `systemctl` en el servidor (el servicio no está activo): la conexión fue bien. El 255 es el que indica problema de red o de acceso.

**5.** Con comillas dobles, la shell **local** sustituye `$HOSTNAME` (`client`) antes de ejecutar `ssh`, y al servidor llega `echo client`. Con comillas simples, el texto viaja literal y lo expande la shell **remota**, donde `$HOSTNAME` vale `server`.

**6.** `Connection refused` al instante: el host existe y respondió, pero nadie escucha en ese puerto (`sshd` caído o puerto equivocado). Colgado: nadie responde (host apagado, IP equivocada o firewall que descarta en silencio) y se espera al timeout de TCP del sistema. `ConnectTimeout` (por ejemplo `-o ConnectTimeout=5`) acorta la espera.

**7.** Con `root`: `ssh` usa el primer valor que encuentra para cada opción, y `Host *` casa con `web` antes de llegar a su bloque. Se comprueba con `ssh -G web | grep '^user '`. La solución es poner `Host *` al final.

**8.** Porque la criptografía asimétrica es cientos de veces más lenta que la simétrica, y porque la host key no se usa para cifrar sino para firmar. SSH usa la asimetría solo para acordar una llave de sesión y demostrar la identidad del servidor, y la simétrica para los datos.

**9.** No. La llave de sesión se acordó con valores temporales que se descartan al cerrar la conexión; la host key solo firmó el intercambio. Robarla después no permite recalcular la llave de sesión. Es el **secreto hacia adelante** (*forward secrecy*).

**10.** El proceso que procesa los datos de la conexión, incluido el código que habla con desconocidos antes de autenticarse, tiene los mínimos privilegios. Si un fallo en ese código permite ejecutar algo, el atacante consigue solo los permisos de ese proceso, no los de `root`.

</details>

---

## 💪 Desempeño (40%)

Diez puntos por lab. El Desempeño es la suma sobre 70, llevada a porcentaje. Cada criterio de éxito se comprueba ejecutando el comando en el laboratorio.

| Lab | Criterio | Puntos |
|---|---|:--:|
| [01 — Laboratorio Docker](2-practicas/lab-01-laboratorio-docker/README.md) | Cuatro servicios en `Up`; explicas por qué `interno` no resuelve; `banner.sh` imprime el banner y falla con el puerto 2222 | 10 |
| [02 — Primera conexión](2-practicas/lab-02-primera-conexion/README.md) | Huella comparada antes del `yes`; `known_hosts` con la entrada; `no` corta sin pedir contraseña; `bastion` aceptado pegando la huella | 10 |
| [03 — Comandos remotos](2-practicas/lab-03-comandos-remotos/README.md) | Códigos 3 y 255 explicados; comillas explicadas; `remote-info.sh` imprime las cuatro líneas | 10 |
| [04 — Sesión y escapes](2-practicas/lab-04-sesion-interactiva-y-escapes/README.md) | Procesos de `sshd` identificados; `~?`, `~` Ctrl+Z y `~.` usados; sesión colgada recuperada | 10 |
| [05 — Modo verbose](2-practicas/lab-05-modo-verbose/README.md) | Fases localizadas en el log; `Accepted password` en el servidor; `fases.sh` imprime las seis líneas | 10 |
| [06 — Errores comunes](2-practicas/lab-06-errores-comunes/README.md) | Cinco errores reproducidos; huella nueva verificada antes de `ssh-keygen -R`; tabla de diagnóstico completa | 10 |
| [07 — Config y precedencia](2-practicas/lab-07-config-y-precedencia/README.md) | Orden de `Host *` corregido y explicado; `bas` añadido; `Bad owner or permissions` reproducido y arreglado | 10 |

Dentro de cada lab: 10 puntos si se cumplen todos los criterios y explicas con tus palabras por qué funciona; 8 si se cumplen todos; 7 si falla uno; menos de 7 si fallan dos o más.

---

## 📦 Producto (30%)

### Verificable por el autograding — 60 puntos

Lo ejecuta `./scripts/verificar-semana.sh 01`. Es binario: pasa o no pasa.

| Comprobación | Puntos |
|---|:--:|
| `config-parsea` — config carga sin errores con ssh -G | 3 |
| `config-server-hostname` — el alias lab-server apunta al host server | 4 |
| `config-server-user` — el bloque lab-server fija User alumno | 3 |
| `config-bastion-hostname` — el alias lab-bastion apunta al host bastion | 3 |
| `config-timeout-global` — ConnectTimeout 5 aplica a cualquier host | 4 |
| `config-no-desactiva-verificacion` — config no desactiva la verificación de host keys | 4 |
| `config-conecta` — ssh lab-server con este config entra en server | 4 |
| `lc-sin-argumentos` — lab-check sin argumentos sale con 2 | 3 |
| `lc-host-ok` — lab-check server sale con 0 | 3 |
| `lc-muestra-banner` — para un host sano imprime ok y el banner | 4 |
| `lc-fallo-dns` — un host que no resuelve se informa como fallo dns | 4 |
| `lc-fallo-tcp` — un puerto cerrado se informa como fallo tcp | 4 |
| `lc-fallo-banner` — un puerto que no habla SSH se informa como fallo banner | 4 |
| `lc-sale-1-si-falla-uno` — sale con 1 si falla al menos un host | 4 |
| `lc-sigue-tras-fallo` — revisa todos los hosts aunque uno falle | 4 |
| `bin-completo-y-limpio` — bin/ sin TODOs y limpio para shellcheck | 5 |
| **Total** | **60** |

### Calidad — 40 puntos

Lo que el autograding no puede ver.

| Criterio | Excelente | Suficiente | Puntos |
|---|---|---|:--:|
| **README del kit** | Explica qué es, los requisitos, cada archivo con un ejemplo y la bitácora de la semana | Lista los archivos sin ejemplos | 8 |
| **Mensajes y códigos** | El uso incorrecto va por stderr; los códigos 0, 1 y 2 están documentados en la cabecera del script | Códigos sin documentar | 8 |
| **Comentarios del porqué** | Explican decisiones (por qué capas en orden, por qué `Host *` al final), no repiten el código | Comentarios que repiten el código | 8 |
| **Sin autenticación en lab-check** | `lab-check` nunca llama a `ssh` ni pide credenciales | Llama a `ssh` aunque no se autentique | 8 |
| **Git** | `ssh-infra-kit` en un repositorio propio con al menos un commit descriptivo | Sin historial | 8 |
| **Total** | | | **40** |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| `StrictHostKeyChecking no` o `UserKnownHostsFile /dev/null` en cualquier archivo del kit | −10 pts |
| Contraseñas escritas en un archivo del kit | −10 pts |
| Rutas absolutas a tu home dentro de `ssh-infra-kit` | −5 pts |

---

## 📋 Checklist de entrega

- [ ] Los 7 labs con sus criterios de éxito comprobados
- [ ] Las 10 preguntas de Conocimiento respondidas por escrito
- [ ] `3-proyecto/starter/` sin ningún `TODO`
- [ ] `./scripts/verificar-semana.sh 01` con las 16 comprobaciones en verde
- [ ] `ssh-infra-kit` versionado con git

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Proyecto — ssh-infra-kit: config y lab-check](3-proyecto/README.md) | [Recursos — ebooks](4-recursos/ebooks-free/README.md) → |

[↑ Semana 01](README.md)
