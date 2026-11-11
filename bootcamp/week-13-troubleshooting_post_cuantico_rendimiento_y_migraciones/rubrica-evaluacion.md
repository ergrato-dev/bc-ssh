# Rúbrica de Evaluación — Semana 13

> Operación y troubleshooting: algoritmos post-cuánticos, rendimiento y migraciones. Se evalúan tres evidencias por separado y hace falta **70% en cada una**. No basta con que `bin/doctor` diga algo: tienes que saber en qué capa falla una conexión y dónde está la razón, por qué el intercambio de llaves tiene que ser postcuántico ya, qué hace lenta una conexión y en qué orden se cambia algo sin dejar a nadie fuera.

---

## 📊 Distribución de Evidencias

| Evidencia | Peso | Instrumento |
|---|:--:|---|
| 🧠 Conocimiento | 30% | Las 10 preguntas de esta rúbrica, respondidas por escrito |
| 💪 Desempeño | 40% | Los 7 labs, con sus criterios de éxito comprobados en el laboratorio |
| 📦 Producto | 30% | `ssh-infra-kit` con `bin/doctor`, `bin/key-audit`, `conf.d/90-legado.conf`, `RequiredRSASize` y `UpdateHostKeys`: 60 pts de autograding + 40 de calidad |

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
| 1 | Nombra las capas de una conexión SSH en orden y el mensaje de error típico de cada una. ¿Por qué se diagnostica de abajo arriba? |
| 2 | ¿Qué diferencia hay entre `Connection refused` y `Connection timed out`? ¿Qué compruebas en cada caso? |
| 3 | Un usuario recibe `Permission denied (publickey)`. Da tres causas distintas, dónde ves cuál es y por qué el cliente no lo sabe. ¿Cómo usas `sshd -d` sin tocar el `sshd` del puerto 22, y para qué sirve `HostKeyAlias` ahí? |
| 4 | ¿Para qué sirven `ssh -G`, `ssh -Q`, `sshd -T -C` y `sshd -t`? Pon un ejemplo de cuándo usarías cada uno. |
| 5 | Lee este error: `no matching host key type found. Their offer: ssh-rsa`. ¿Qué lista falla, qué ofrece el servidor y qué harías, en orden de preferencia? ¿Por qué no en `Host *`? |
| 6 | ¿Qué significa *store now, decrypt later*? ¿Qué parte de SSH protege un intercambio de llaves postcuántico y por qué los de OpenSSH son híbridos? ¿Por qué las host keys son menos urgentes? |
| 7 | En un servidor con OpenSSH 9.6, `KexAlgorithms +mlkem768x25519-sha256` rompe `sshd` y `KexAlgorithms -mlkem768x25519-sha256` no. ¿Por qué? ¿Qué consecuencia tiene para cómo escribes `15-algoritmos.conf`? |
| 8 | Un servidor a 50 ms tarda casi un segundo en cada `ssh`. ¿De dónde sale ese tiempo y qué lo arregla? ¿Por qué no lo arregla cambiar de cifrado? ¿Cuándo ayuda `-C` y cuándo estorba? |
| 9 | Describe el orden para migrar las llaves RSA de 2048 bits de un equipo a Ed25519. ¿Qué pasa si empiezas por `RequiredRSASize 3072`? ¿Por qué se quita una llave por su contenido y no por su comentario? |
| 10 | ¿Qué hace `UpdateHostKeys` y por qué es seguro? Describe las dos fases de una rotación de host key y qué le pasa a un cliente que no entró durante la primera. ¿Qué ventaja tienen aquí los certificados de host? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Configuración (va a otro sitio sin avisar; `ssh -G`), nombre (`Could not resolve hostname`), TCP (`Connection refused`, `Connection timed out`), banner (`kex_exchange_identification`), algoritmos (`no matching ... Their offer`), host key (`Host key verification failed`, `REMOTE HOST IDENTIFICATION HAS CHANGED`) y autenticación (`Permission denied`). Cada capa solo empieza si la anterior terminó bien: si el nombre no resuelve, mirar las llaves es perder el tiempo, y el primer error que ves es el de la capa más baja que falla.

**2.** `refused`: la máquina responde al momento, pero nadie escucha en ese puerto (sshd parado, otro puerto): miras el servicio y el puerto (`ss -tln` en el servidor, `ssh -G` en el cliente). `timed out`: nadie responde (apagada, sin ruta, un cortafuegos o fail2ban que tiran los paquetes): miras la red, el cortafuegos y las IP bloqueadas. Sin `ConnectTimeout`, el `timed out` tarda unos 2 minutos.

**3.** La llave no está en `authorized_keys`; `~/.ssh` o `authorized_keys` escribibles por otros (`StrictModes`); el usuario fuera de `AllowGroups`; una RSA más corta que `RequiredRSASize`. El cliente solo ve `Permission denied` porque el servidor no da pistas a quien prueba llaves ajenas; la razón está en el log del servidor o en `sudo /usr/sbin/sshd -d -p 2222`, que corre en otro puerto, atiende una conexión, lo cuenta todo y sale, sin tocar el del 22. `HostKeyAlias=NOMBRE`: las host keys son las mismas, pero `known_hosts` las guarda como `NOMBRE` y no como `[NOMBRE]:2222`.

**4.** `ssh -G HOST`: la configuración final del cliente para ese host, sin conectar (¿a qué nombre, puerto y usuario va de verdad?). `ssh -Q kex`: lo que tu `ssh` sabe hacer, esté o no en la lista que ofrece (¿puedo hablar con este equipo viejo?). `sshd -T -C user=...,addr=...`: la configuración que el servidor aplicaría a esa conexión, con los `Match` (¿qué le toca a esta persona?). `sshd -t`: valida la configuración antes de recargar (siempre, antes de cada `kill -HUP`).

**5.** Falla la lista de host keys (`HostKeyAlgorithms`); el servidor solo ofrece `ssh-rsa`, RSA firmando con SHA-1, que OpenSSH dejó de ofrecer en 8.8. Orden: actualizar el equipo; si no se puede, un alias para él con `HostKeyAlgorithms +ssh-rsa` (en el kit, un alias `legado-*`). No en `Host *`: cualquier servidor que solo ofrezca SHA-1 entraría sin aviso (también uno olvidado o un impostor), y la línea se quedaría ahí cuando desapareciera el último equipo viejo.

**6.** Alguien graba hoy tu tráfico cifrado y lo descifra cuando tenga un ordenador cuántico capaz de romper el intercambio de llaves clásico. El intercambio postcuántico protege la clave de la sesión, y con ella todo lo que viajó. Son híbridos (sntrup761 o ML-KEM con X25519) porque los algoritmos postcuánticos son jóvenes: hay que romper los dos, y si uno cae, el otro sigue protegiendo. Las host keys firman en el momento: romperlas dentro de años no sirve para entrar en una sesión de hoy, así que pueden cambiarse más tarde, antes de que exista el ordenador.

**7.** `+` y una lista completa nombran algoritmos que esa versión tiene que conocer: `mlkem768x25519-sha256` llegó en 9.9, y `sshd -t` falla con `Bad SSH2 KexAlgorithms` (y un `kill -HUP` sin validar deja `sshd` sin escuchar). Quitar algo que no existe no es un error. Por eso `15-algoritmos.conf` quita lo débil con `-` en lugar de escribir la lista buena: vale en cualquier versión, y al actualizar entran solos los algoritmos nuevos.

**8.** Antes de ejecutar el comando, cliente y servidor se esperan unas once veces (TCP, versiones, `KEXINIT`, intercambio, `NEWKEYS`, servicio, llave, firma, canal, comando, cierre): con 50 ms, más de medio segundo solo en esperas. Lo arregla el multiplexing: con un master, solo quedan las del canal. Un cifrado cambia la CPU por byte, no el número de esperas. `-C` ayuda en un enlace lento con datos que se comprimen (texto, logs); en una red rápida, o con datos ya comprimidos, solo añade CPU.

**9.** Inventario (`ssh-keygen -lf authorized_keys`, `bin/key-audit`); cada persona crea su Ed25519 y se añade sin quitar la vieja; se comprueba en el log que entran con la nueva; se quita la vieja; y al final se exige `RequiredRSASize 3072`. Si se exige primero, quien tiene una RSA de 2048 se queda fuera con un `Permission denied` sin explicación. El comentario lo escribe quien crea la llave y puede repetirse; el contenido de la llave (el segundo campo del `.pub`) es único.

**10.** Cuando un cliente entra con una host key que ya conocía, el servidor le manda todas las suyas firmadas (`hostkeys-00@openssh.com`); el cliente añade las nuevas y quita las que ya no están. Es seguro porque solo pasa dentro de una conexión ya verificada y el servidor demuestra tener cada llave privada. Fase 1: el servidor ofrece la vieja (que firma) y la nueva, y durante semanas los clientes aprenden la nueva. Fase 2: solo la nueva; los clientes al día entran sin aviso. Uno que no entró en la fase 1 ve `REMOTE HOST IDENTIFICATION HAS CHANGED` y tiene que comprobar la huella nueva por otro canal. Con certificados de host, los clientes confían en la CA: se firma la llave nueva y nadie ve nada.

</details>

---

## 💪 Desempeño (40%)

Dentro de cada lab: 10 puntos si se cumplen todos los criterios y explicas con tus palabras por qué funciona; 8 si se cumplen todos; 7 si falla uno; menos de 7 si fallan dos o más.

| Lab | Criterio | Puntos |
|---|---|:--:|
| [01 — Leer `ssh -v`](2-practicas/lab-01-leer-ssh-v/README.md) | `ssh -G`; las capas en una salida de `-v`; las dos listas de `-vvv`; cuatro errores por capa; la llave que no entra | 10 |
| [02 — El lado del servidor](2-practicas/lab-02-el-lado-del-servidor/README.md) | `sshd -d` en otro puerto y `HostKeyAlias`; permisos; `AllowGroups`; `sshd -T -C`; `sshd -t` | 10 |
| [03 — Sin algoritmo en común](2-practicas/lab-03-sin-algoritmo-en-comun/README.md) | `Their offer`; `ssh -Q` frente a `ssh -G`; `+` de uno en uno; el alias; por qué no `Host *` | 10 |
| [04 — Postcuántico](2-practicas/lab-04-postcuantico/README.md) | Híbridos; qué usa una conexión; el servidor que lo exige; la trampa del nombre desconocido; el coste medido | 10 |
| [05 — Medir el rendimiento](2-practicas/lab-05-medir-el-rendimiento/README.md) | `tc netem`; idas y vueltas; multiplexing medido; cifrados comparados; compresión que ayuda y que estorba; `server` sin `tc` al terminar | 10 |
| [06 — Migrar llaves de usuario](2-practicas/lab-06-migrar-llaves-de-usuario/README.md) | Inventario y filtro; DSA frente a RSA corta; `RequiredRSASize` y su log; migrar en orden; quitar por contenido | 10 |
| [07 — Rotar host keys](2-practicas/lab-07-rotar-host-keys/README.md) | Las tres llaves aprendidas; dos `HostKey`; aprender y olvidar; fase 2 sin avisos; el cliente que no entró | 10 |

La nota de Desempeño es la media de los siete labs.

---

## 📦 Producto (30%)

### Verificable por el autograding — 60 puntos

Lo ejecuta `./scripts/verificar-semana.sh 13`. Es binario: pasa o no pasa.

| Comprobación | Puntos |
|---|:--:|
| `doctor-uso` — bin/doctor sin argumentos sale con 2 y dice cómo se usa | 2 |
| `doctor-entra` — bin/doctor entra con una conexión nueva aunque haya un master abierto, y escribe destino, kex postcuántico, host key, cifrado y método de entrada | 7 |
| `doctor-sin-postcuantico` — bin/doctor avisa cuando el intercambio de llaves no es postcuántico | 4 |
| `doctor-pasa-opciones` — bin/doctor pasa a ssh las opciones que siguen al host (-o KexAlgorithms=...) | 3 |
| `doctor-sin-algoritmo` — Contra un servidor viejo, bin/doctor sale con 255, enseña lo que ofrece el servidor y apunta a los alias legado-* | 5 |
| `doctor-host-key` — Con una host key cambiada, bin/doctor sale con 255 y apunta a comprobar la huella con bin/kh-add | 4 |
| `doctor-sin-permiso` — Con una llave que el servidor no acepta, bin/doctor sale con 255 y apunta al log del servidor (sshd -d) | 4 |
| `doctor-sin-servidor` — Sin nadie escuchando, bin/doctor sale con 255 y habla del puerto | 3 |
| `legado-entra` — conf.d/90-legado.conf deja entrar a un alias legado-* en un servidor con grupo 14 SHA-1 y host key ssh-rsa | 5 |
| `legado-solo-legado` — Los algoritmos viejos solo se añaden a los alias legado-*: lab-server sigue sin ellos | 4 |
| `key-audit-detecta` — bin/key-audit marca DSA, RSA de 2048 y ECDSA, acepta Ed25519 (con opciones) y RSA de 3072, y sale con 1 | 6 |
| `key-audit-limpio-y-uso` — bin/key-audit sale con 0 si todo está bien (también leyendo de -), y con 2 sin argumentos o con un archivo sin llaves | 3 |
| `sshd-rsa-minimo` — 15-algoritmos.conf exige RSA de 3072 bits: un sshd con él rechaza una llave RSA de 2048 y acepta una de 3072 | 6 |
| `kit-completo-y-limpio` — Sin TODOs, shellcheck sin avisos, el README documenta lo nuevo y los scripts anteriores siguen respondiendo | 4 |
| **Total** | **60** |

### Calidad — 40 puntos

| Criterio | Excelente | Suficiente | Puntos |
|---|---|---|:--:|
| **Comentarios Qué / Para qué / Impacto** | `doctor` explica por qué conecta sin master y con `BatchMode`; `90-legado.conf` dice qué se pierde (SHA-1, sin postcuántico); `RequiredRSASize` dice en qué orden aplicarlo; `UpdateHostKeys` dice por qué es seguro | Comentados, sin Impacto en alguno | 12 |
| **Pistas útiles** | Cada pista de `doctor` lleva a un comando o archivo concreto (`ssh -G`, `bin/kh-add`, `sshd -d`, `90-legado.conf`) y nunca sugiere aceptar una host key sin comprobar | Pistas genéricas ("revisa la conexión") en alguna capa | 10 |
| **README del kit** | Tres filas nuevas, filas de `config` y `server/` actualizadas, bitácora de la semana 13 y sección "Diagnóstico y migraciones" con los cuatro procedimientos | Filas y bitácora, sin la sección completa | 10 |
| **Robustez** | `doctor` funciona con cualquier opción de `ssh` y con `SSH_CMD`; `key-audit` acepta opciones en `authorized_keys`, comentarios con espacios y `-`; ningún algoritmo viejo fuera de `legado-*` | Falta uno | 4 |
| **Git** | Commit nuevo en `~/ssh-infra-kit` con mensaje descriptivo y sin llaves | Sin commit de la semana | 4 |
| **Total** | | | **40** |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Una llave privada en el repositorio del kit o en su historial de git | −20 pts |
| Algoritmos con SHA-1 (`ssh-rsa`, `group14-sha1`...) en `Host *`, en `config` o en un alias que no es `legado-*` | −10 pts |
| `StrictHostKeyChecking no` o `accept-new`, o `UserKnownHostsFile /dev/null`, en `bin/doctor` o en `config` | −10 pts |
| Una lista completa de algoritmos en `15-algoritmos.conf` (en lugar de quitar con `-`) que no pasa `sshd -t` en OpenSSH 9.6 | −5 pts |

---

## 📋 Checklist de entrega

- [ ] Los 7 labs con sus criterios de éxito comprobados
- [ ] Las 10 preguntas de Conocimiento respondidas por escrito
- [ ] `3-proyecto/starter/` sin ningún `TODO`
- [ ] `./scripts/verificar-semana.sh 13` con las 14 comprobaciones en verde
- [ ] `ssh-infra-kit` con un commit nuevo y sin llaves

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Proyecto — ssh-infra-kit: diagnóstico y migración de algoritmos](3-proyecto/README.md) | [Recursos — ebooks](4-recursos/ebooks-free/README.md) → |

[↑ Semana 13](README.md)
