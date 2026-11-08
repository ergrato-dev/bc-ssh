# Rúbrica de Evaluación — Semana 02

> Protocolo por dentro: KEX, host keys y `known_hosts`. Se evalúan tres evidencias por separado y hace falta **70% en cada una**. No basta con conectarte: tienes que saber qué viajó en claro, quién eligió cada algoritmo y por qué tu `known_hosts` es lo único que separa al servidor real de un impostor.

---

## 📊 Distribución de Evidencias

| Evidencia | Peso | Instrumento |
|---|:--:|---|
| 🧠 Conocimiento | 30% | Las 10 preguntas de esta rúbrica, respondidas por escrito |
| 💪 Desempeño | 40% | Los 7 labs, con sus criterios de éxito comprobados en el laboratorio |
| 📦 Producto | 30% | `ssh-infra-kit` con `config` endurecido y `bin/kh-add`: 60 pts de autograding + 40 pts de calidad |

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
| 1 | Nombra las tres capas de SSH y di a cuál pertenecen los mensajes 20, 52 y 90. ¿Cómo lo sabes sin consultar una lista de nombres? |
| 2 | Alguien captura todo el tráfico de tu conexión SSH. Di tres cosas que puede leer y tres que no. ¿Por qué no es un problema que vea la host key? |
| 3 | El cliente ofrece `A,B,C` y el servidor `C,B`. ¿Qué algoritmo se usa y por qué? ¿Y si el servidor ofrece solo `D`? |
| 4 | `ssh -Q kex` lista `diffie-hellman-group1-sha1`, pero `ssh -G server` no. ¿Qué responde cada comando y por qué la diferencia? |
| 5 | Explica qué es el hash de intercambio H y por qué la firma del servidor sobre H impide que un intermediario se haga pasar por él… siempre que se cumpla una condición. ¿Cuál? |
| 6 | Un servidor antiguo solo acepta `diffie-hellman-group14-sha1`. ¿Dónde y cómo lo activas para conectarte, y por qué no en `Host *`? ¿Por qué `+` y no `^`? |
| 7 | Conoces la llave ECDSA de un servidor y este te presenta su llave Ed25519, que es legítima. ¿Qué hace `ssh` y por qué es la decisión correcta? ¿Qué mecanismo evita el problema? |
| 8 | ¿Qué protege `HashKnownHosts` y qué no? ¿Por qué hay que borrar `known_hosts.old` tras `ssh-keygen -H`? |
| 9 | Compara `StrictHostKeyChecking accept-new` y `yes` ante un host nuevo y ante una llave cambiada. ¿Cuál usarías en un script de despliegue y cómo entrarían las llaves? |
| 10 | `ssh-keyscan` te da la llave de un servidor. ¿La has verificado? ¿Qué le falta para serlo y cómo lo resuelve `kh-add`? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Transporte, autenticación y conexión. Por el rango del número (RFC 4250): 1–49 transporte (20 `KEXINIT`), 50–79 autenticación (52 `USERAUTH_SUCCESS`), 80–127 conexión (90 `CHANNEL_OPEN`).

**2.** Puede leer los banners, las listas de algoritmos de los `KEXINIT`, la host key pública y su firma, además de IPs, puertos, tamaños y tiempos. No puede leer el usuario, la contraseña, los comandos ni su salida. La host key es pública: lo que importa es la privada, la única que puede firmar.

**3.** `B`: es el primero de la lista del **cliente** que el servidor también tiene; el orden del servidor no cuenta. Con `D` no hay ninguno en común y la conexión se corta con `Unable to negotiate ... Their offer: D`.

**4.** `-Q` lista lo que el binario sabe hacer; `-G` lo que ofrecerá a ese host con la configuración actual. `group1-sha1` está compilado pero desactivado por defecto: está en `-Q` y no en la oferta.

**5.** H es el hash de todo el intercambio: banners, los dos `KEXINIT`, la host key, las partes públicas efímeras y el secreto K. El servidor lo firma con su host key privada. Un intermediario no puede producir esa firma para el H que ve el cliente sin la privada del servidor; solo puede firmar con una llave suya. La condición: que la host key con que el cliente comprueba la firma sea la verdadera, es decir, que esté verificada en `known_hosts`.

**6.** En un bloque `Host` solo para ese servidor: `KexAlgorithms +diffie-hellman-group14-sha1`. En `Host *` todos los servidores podrían negociar SHA-1. `+` lo pone al final: solo se elige si el servidor no admite nada mejor; con `^` se elegiría siempre primero aunque el servidor ya admitiera algoritmos modernos.

**7.** Corta con `REMOTE HOST IDENTIFICATION HAS CHANGED`. Un atacante podría elegir justo el tipo que no tienes guardado para presentarse como "llave nueva"; tratarlo como cambio cierra esa vía. `UpdateHostKeys` lo evita: tras una conexión verificada con una llave conocida, el servidor envía sus otras llaves y el cliente las guarda.

**8.** Protege la lista de hosts: quien robe el archivo no sabe a qué servidores te conectas. No impide confirmar un nombre que el atacante ya sospecha: basta calcular su HMAC con la sal de cada línea. El `.old` conserva los nombres en claro.

**9.** Host nuevo: `accept-new` lo añade sin verificar; `yes` corta. Llave cambiada: los dos cortan. En un script, `yes` con un `known_hosts` preparado de antemano con llaves verificadas (con `kh-add` o un archivo global).

**10.** No. `ssh-keyscan` habla con quien responda en la red, que podría ser un intermediario. Falta compararla con una huella obtenida por un canal independiente. `kh-add` exige esa huella como argumento y no escribe nada si no coincide.

</details>

---

## 💪 Desempeño (40%)

Diez puntos por lab. El Desempeño es la suma sobre 70, llevada a porcentaje.

| Lab | Criterio | Puntos |
|---|---|:--:|
| [01 — Lo que ve un espía](2-practicas/lab-01-lo-que-ve-un-espia/README.md) | Contraseña vista en claro por el 2300; banners y algoritmos vistos por el 22; `alumno` y `secreto-remoto` en 0, explicado | 10 |
| [02 — Mensajes y capas](2-practicas/lab-02-mensajes-y-capas/README.md) | `capas.sh` completo; preguntas del paso 4; `GLOBAL_REQUEST` explicados; 5 renegociaciones provocadas | 10 |
| [03 — Negociación de algoritmos](2-practicas/lab-03-negociacion-de-algoritmos/README.md) | `-Q`, `-G` y `sshd -T` distinguidos; `elegido.sh` coincide con `ssh`; `+`, `-` y `^` explicados | 10 |
| [04 — Servidor antiguo](2-practicas/lab-04-servidor-antiguo/README.md) | Errores leídos con `Their offer`; huella RSA verificada; algoritmos SHA-1 solo en `legado` | 10 |
| [05 — Host keys y huellas](2-practicas/lab-05-host-keys-y-huellas/README.md) | Tres huellas por canal independiente; aviso de llave cambiada con un tipo nuevo explicado; `UpdateHostKeys` comprobado | 10 |
| [06 — known_hosts por dentro](2-practicas/lab-06-known-hosts-por-dentro/README.md) | HMAC calculado a mano coincide; `buscar.sh` completo; `.old` borrado; límite del hash explicado | 10 |
| [07 — Políticas de verificación](2-practicas/lab-07-politicas-de-verificacion/README.md) | `matriz.sh` completo; riesgo de `no` explicado; tabla de políticas justificada | 10 |

Dentro de cada lab: 10 puntos si se cumplen todos los criterios y explicas con tus palabras por qué funciona; 8 si se cumplen todos; 7 si falla uno; menos de 7 si fallan dos o más.

---

## 📦 Producto (30%)

### Verificable por el autograding — 60 puntos

Lo ejecuta `./scripts/verificar-semana.sh 02`. Es binario: pasa o no pasa.

| Comprobación | Puntos |
|---|:--:|
| `config-parsea` — config carga sin errores con ssh -G | 2 |
| `config-hereda-semana-01` — el alias lab-server sigue apuntando a server | 2 |
| `config-strict` — StrictHostKeyChecking yes aplica a cualquier host | 4 |
| `config-hash` — HashKnownHosts yes aplica a cualquier host | 3 |
| `config-no-desactiva-verificacion` — config no desactiva la verificación | 3 |
| `kh-uso` — kh-add sin argumentos sale con 2 | 2 |
| `kh-huella-mal-formada` — una huella sin SHA256: sale con 2 | 2 |
| `kh-anade` — con la huella correcta añade e informa | 4 |
| `kh-linea-hasheada` — la línea añadida va hasheada | 3 |
| `kh-crea-directorio` — crea el directorio con permisos 700 | 3 |
| `kh-ssh-confia` — tras kh-add, ssh con el config del kit entra | 4 |
| `kh-idempotente` — dos ejecuciones no duplican la línea | 4 |
| `kh-huella-distinta` — con la huella de otro host sale con 1 | 4 |
| `kh-distinta-no-escribe` — con una huella distinta no escribe nada | 4 |
| `kh-conflicto` — con otra llave del mismo tipo ya guardada sale con 1 | 4 |
| `kh-puerto` — HOST:PUERTO usa [host]:puerto y no duplica | 4 |
| `kh-fallo-scan` — un host que no responde sale con 3 | 3 |
| `lc-sigue-funcionando` — lab-check de la semana 01 sigue funcionando | 2 |
| `bin-completo-y-limpio` — bin/ sin TODOs y limpio para shellcheck | 3 |
| **Total** | **60** |

### Calidad — 40 puntos

| Criterio | Excelente | Suficiente | Puntos |
|---|---|---|:--:|
| **README del kit** | Fila de `kh-add` con códigos de salida y ejemplo; sección para añadir un servidor nuevo; bitácora de la semana 02 | Fila sin ejemplo o sin códigos | 8 |
| **Mensajes** | Los errores van por stderr y dicen qué pasó y qué hacer (por ejemplo, `ssh-keygen -R`); el éxito, por stdout | Mensajes genéricos | 8 |
| **Comentarios del porqué** | `config` con Qué / Para qué / Impacto en cada opción nueva; `kh-add` explica por qué no sobrescribe un conflicto | Comentarios que repiten el código | 8 |
| **Seguridad** | `kh-add` no escribe nada ante cualquier duda; nunca usa `StrictHostKeyChecking no` ni `accept-new` | Escribe antes de comprobar | 8 |
| **Git** | Commit nuevo en `~/ssh-infra-kit` con mensaje descriptivo | Sin commit de la semana | 8 |
| **Total** | | | **40** |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| `StrictHostKeyChecking no`, `accept-new` o `UserKnownHostsFile /dev/null` en cualquier archivo del kit | −10 pts |
| Algoritmos SHA-1 (`group14-sha1`, `ssh-rsa`) en `Host *` | −10 pts |
| Contraseñas escritas en un archivo del kit | −10 pts |

---

## 📋 Checklist de entrega

- [ ] Los 7 labs con sus criterios de éxito comprobados
- [ ] Las 10 preguntas de Conocimiento respondidas por escrito
- [ ] `3-proyecto/starter/` sin ningún `TODO`
- [ ] `./scripts/verificar-semana.sh 02` con las 19 comprobaciones en verde
- [ ] `ssh-infra-kit` con un commit nuevo

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Proyecto — ssh-infra-kit: known_hosts verificado](3-proyecto/README.md) | [Recursos — ebooks](4-recursos/ebooks-free/README.md) → |

[↑ Semana 02](README.md)
