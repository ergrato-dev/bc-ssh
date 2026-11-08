# Rúbrica de Evaluación — Semana 03

> Autenticación con llaves. Se evalúan tres evidencias por separado y hace falta **70% en cada una**. No basta con entrar sin contraseña: tienes que saber qué recibe el servidor, por qué una llave falla aunque esté instalada y cómo limitar y retirar una llave sin quedarte fuera.

---

## 📊 Distribución de Evidencias

| Evidencia | Peso | Instrumento |
|---|:--:|---|
| 🧠 Conocimiento | 30% | Las 10 preguntas de esta rúbrica, respondidas por escrito |
| 💪 Desempeño | 40% | Los 7 labs, con sus criterios de éxito comprobados en el laboratorio |
| 📦 Producto | 30% | `ssh-infra-kit` con llave por host, `bin/key-new` y `bin/ak-line`: 60 pts de autograding + 40 pts de calidad |

**Mínimo 70% en cada evidencia.** No en el promedio.

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
| 1 | Con contraseña, ¿qué recibe exactamente el servidor? ¿Y con llave? Explica por qué un servidor comprometido es más peligroso en el primer caso. |
| 2 | Ordena y explica los cuatro mensajes de la autenticación con llave. ¿Para qué sirve preguntar antes de firmar? |
| 3 | Un servidor malicioso recibe tu firma. ¿Puede usarla para entrar en otro servidor en tu nombre? ¿Qué dato lo impide? |
| 4 | ¿Por qué Ed25519 y no RSA o ECDSA? ¿Cuándo usarías RSA y con qué tamaño mínimo? |
| 5 | Borras sin querer `~/.ssh/id_ed25519.pub`. ¿Qué pierdes? ¿Y si borras `~/.ssh/id_ed25519`? |
| 6 | ¿Qué protege la frase de paso y qué no? ¿Cambiarla obliga a tocar los servidores? ¿Qué aporta `-a 100`? |
| 7 | Tu llave funcionaba y deja de funcionar con `Permission denied (publickey,password)`. Nombra dos causas en el servidor y dónde encuentras el motivo exacto. ¿Por qué no te lo dice el cliente? |
| 8 | Tienes la llave correcta en `-i` y aun así recibes `Too many authentication failures`. ¿Qué pasa y cómo lo arreglas en `config`? |
| 9 | Escribe la línea de `authorized_keys` de una llave que solo puede ejecutar `/usr/local/bin/backup`, solo desde `10.0.5.0/24` y hasta el 31 de diciembre de 2026. ¿Por qué empieza por `restrict`? |
| 10 | Describe en orden cómo rotar una llave sin quedarte fuera. ¿Por qué hay que probar la nueva con `IdentitiesOnly`? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Con contraseña, el secreto completo (cifrado en tránsito, pero en claro al llegar). Con llave, solo la pública y una firma válida para esa sesión. Un servidor comprometido (o un intermediario aceptado sin verificar) se queda con la contraseña y puede reutilizarla en todos los sitios donde la uses; con la firma no puede hacer nada fuera de esa conexión.

**2.** `USERAUTH_REQUEST` sin firma (¿aceptas esta llave?), `USERAUTH_PK_OK` (sí), `USERAUTH_REQUEST` con firma sobre el identificador de sesión, `USERAUTH_SUCCESS`. Preguntar antes evita abrir la privada (y pedir la frase) con llaves que el servidor no va a aceptar.

**3.** No. La firma cubre el identificador de sesión, el hash del primer intercambio de llaves de esa conexión. En otra conexión el identificador es otro y la firma no vale.

**4.** Ed25519 tiene tamaño fijo, llaves cortas, es rápida y no depende de un buen aleatorio al firmar (ECDSA sí). RSA solo para sistemas que no admiten Ed25519, con 3072 bits o más.

**5.** Nada con la `.pub`: `ssh-keygen -y -f ~/.ssh/id_ed25519` la reconstruye. Con la privada se pierde la llave: hay que generar otra e instalarla en cada servidor.

**6.** Protege el archivo de la privada en tu disco: quien lo copie no puede usarlo sin la frase. No viaja ni protege una llave ya cargada en memoria. Cambiarla solo vuelve a cifrar el archivo: la llave y su huella no cambian, así que no se toca ningún servidor. `-a 100` sube las rondas de bcrypt y encarece cada intento de adivinar la frase.

**7.** `StrictModes`: carpeta personal, `~/.ssh` o `authorized_keys` escribibles por otros (o con otro dueño); o una línea con una opción mal escrita, o un `from=`/`expiry-time=` que ya no se cumple. El motivo está en el log del servidor (`Authentication refused: bad ownership or modes...`, `Refused by key options`). No se envía al cliente para no dar pistas a un atacante.

**8.** El cliente ofrece antes otras llaves (por ejemplo las del agente) y el servidor corta tras `MaxAuthTries` (6) rechazos, antes de llegar a la buena. `IdentityFile` con la llave del host e `IdentitiesOnly yes`.

**9.** `restrict,from="10.0.5.0/24",command="/usr/local/bin/backup",expiry-time="20261231" ssh-ed25519 AAAA... backup@origen`. `restrict` desactiva terminal, reenvíos y lo que añadan versiones futuras; se añade solo lo necesario.

**10.** Generar la nueva; añadirla sin quitar la vieja; comprobar que entras con la nueva; quitar la línea de la vieja (identificada por su huella o su llave, no por el comentario); comprobar que la vieja ya no entra. Sin `IdentitiesOnly`, el cliente podría entrar con la vieja y la prueba de la nueva no demostraría nada.

</details>

---

## 💪 Desempeño (40%)

Siete labs, 10 puntos cada uno, escalados a 40.

| Lab | Criterio | Puntos |
|---|---|:--:|
| [01 — Tu primer par de llaves](2-practicas/lab-01-tu-primer-par-de-llaves/README.md) | Permisos 700/600/644; campos de la `.pub` explicados; `.pub` reconstruida con `-y` | 10 |
| [02 — Entrar sin contraseña](2-practicas/lab-02-entrar-sin-contrasena/README.md) | `BatchMode` falla antes y funciona después; líneas de `-v` asociadas al diagrama; huella encontrada en el log | 10 |
| [03 — La frase de paso](2-practicas/lab-03-frase-de-paso/README.md) | `none` y `aes256-ctr`/`bcrypt` vistos; rondas medidas; `tiene-frase.sh` completo | 10 |
| [04 — Permisos y StrictModes](2-practicas/lab-04-permisos-y-strictmodes/README.md) | Tres casos de `StrictModes` con su línea de log; excepción de Ubuntu explicada; `revisar-permisos.sh` en cliente y servidor | 10 |
| [05 — Varias llaves](2-practicas/lab-05-varias-llaves/README.md) | `Too many authentication failures` provocado y explicado; `config` con `IdentitiesOnly` funcionando con el agente cargado | 10 |
| [06 — Opciones de authorized_keys](2-practicas/lab-06-opciones-de-authorized-keys/README.md) | `solo-lectura.sh` completo y rechazando inyecciones; rechazo de `from=` leído en el log; opción mal escrita explicada | 10 |
| [07 — Rotar una llave](2-practicas/lab-07-rotar-una-llave/README.md) | Dos llaves válidas a la vez; nueva probada con `IdentitiesOnly`; `quitar-llave.sh` completo; la vieja ya no entra | 10 |

Dentro de cada lab: 10 puntos si se cumplen todos los criterios y explicas con tus palabras por qué funciona; 8 si se cumplen todos; 7 si falla uno; menos de 7 si fallan dos o más.

---

## 📦 Producto (30%)

### Verificable por el autograding — 60 puntos

Lo ejecuta `./scripts/verificar-semana.sh 03`. Es binario: pasa o no pasa.

| Comprobación | Puntos |
|---|:--:|
| `config-parsea` — El config se lee sin errores | 1 |
| `config-hereda-semana-02` — Siguen las opciones de la semana 02 (StrictHostKeyChecking yes) | 1 |
| `config-identityfile` — lab-server usa la llave ~/.ssh/lab | 3 |
| `config-identityfile-bastion` — lab-bastion usa la llave ~/.ssh/lab | 2 |
| `config-identitiesonly` — Todos los hosts ofrecen solo sus IdentityFile | 3 |
| `kn-uso` — key-new sin argumentos sale con 2 | 2 |
| `kn-nombre-invalido` — key-new rechaza un nombre con ../ | 3 |
| `kn-no-sobrescribe` — key-new no pisa una llave existente (sale con 1) | 3 |
| `kn-crea` — key-new crea la llave e imprime su huella | 2 |
| `kn-tipo-ed25519` — La llave creada es Ed25519 | 2 |
| `kn-permisos` — Privada 600 y directorio 700 | 3 |
| `kn-con-frase` — Con frase de paso, la privada no se abre sin ella | 3 |
| `kn-frase-correcta` — Con la frase correcta, la privada se abre | 2 |
| `kn-comentario` — El comentario por defecto es usuario@equipo-fecha | 2 |
| `ak-uso` — ak-line sin argumentos sale con 2 | 1 |
| `ak-restrict` — Sin opciones, la línea empieza por restrict | 3 |
| `ak-opciones` — -t -f -c -e se escriben como pty, from, command y expiry-time | 3 |
| `ak-comillas` — ak-line rechaza comillas en un valor (sale con 2) | 2 |
| `ak-fecha-mal` — ak-line rechaza una fecha que no es AAAAMMDD | 2 |
| `ak-privada` — ak-line rechaza una llave privada (sale con 1) | 3 |
| `ak-no-llave` — ak-line rechaza un archivo que no es una llave | 2 |
| `ak-sshd-comando` — Un sshd real ejecuta el comando forzado, pidas lo que pidas | 3 |
| `ak-sshd-sin-pty` — Sin -t, sshd niega la terminal | 3 |
| `ak-sshd-from` — Con -f de otra red, sshd rechaza la llave | 3 |
| `kh-sigue-funcionando` — kh-add de la semana 02 sigue en el kit | 1 |
| `bin-completo-y-limpio` — Sin TODO y shellcheck sin avisos en bin/ | 2 |
| **Total** | **60** |

### Calidad — 40 puntos

| Criterio | Excelente | Suficiente | Puntos |
|---|---|---|:--:|
| **README del kit** | Filas de `key-new` y `ak-line` con opciones, códigos de salida y ejemplo; sección para entrar con llave en un servidor nuevo; bitácora de la semana 03 | Filas sin ejemplo o sin códigos | 8 |
| **Mensajes** | Los errores van por stderr y dicen qué pasó y qué hacer (por ejemplo, "usa el .pub"); el éxito, por stdout | Mensajes genéricos | 8 |
| **Comentarios del porqué** | `config` con Qué / Para qué / Impacto en `IdentityFile` e `IdentitiesOnly`; `key-new` explica `-a 100` y por qué no sobrescribe; `ak-line` explica por qué rechaza comillas y privadas | Comentarios que repiten el código | 8 |
| **Seguridad** | `key-new` nunca pisa una llave y avisa si no hay frase; `ak-line` siempre empieza por `restrict` | Opciones permisivas por defecto | 8 |
| **Git** | Commit nuevo en `~/ssh-infra-kit` con mensaje descriptivo y sin ninguna llave en el historial | Sin commit de la semana | 8 |
| **Total** | | | **40** |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Una llave privada en el repositorio del kit o en su historial de git | −20 pts |
| `StrictHostKeyChecking no`, `accept-new` o `UserKnownHostsFile /dev/null` en cualquier archivo del kit | −10 pts |
| Contraseñas o frases de paso escritas en un archivo del kit | −10 pts |

---

## 📋 Checklist de entrega

- [ ] Los 7 labs con sus criterios de éxito comprobados
- [ ] Las 10 preguntas de Conocimiento respondidas por escrito
- [ ] `3-proyecto/starter/` sin ningún `TODO`
- [ ] `./scripts/verificar-semana.sh 03` con las 26 comprobaciones en verde
- [ ] `ssh-infra-kit` con un commit nuevo y sin llaves

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Proyecto — ssh-infra-kit: llaves propias y authorized_keys restringido](3-proyecto/README.md) | [Recursos — ebooks](4-recursos/ebooks-free/README.md) → |

[↑ Semana 03](README.md)
