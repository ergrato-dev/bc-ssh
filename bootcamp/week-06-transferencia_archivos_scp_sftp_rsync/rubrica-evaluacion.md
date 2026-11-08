# Rúbrica de Evaluación — Semana 06

> Transferencia de archivos: `scp`, `sftp`, `rsync`, copias con `--link-dest` y llaves restringidas con `rrsync`. Se evalúan tres evidencias por separado y hace falta **70% en cada una**. No basta con que la copia funcione: tienes que saber qué viaja, qué se borra y qué puede hacer una llave robada.

---

## 📊 Distribución de Evidencias

| Evidencia | Peso | Instrumento |
|---|:--:|---|
| 🧠 Conocimiento | 30% | Las 10 preguntas de esta rúbrica, respondidas por escrito |
| 💪 Desempeño | 40% | Los 7 labs, con sus criterios de éxito comprobados en el laboratorio |
| 📦 Producto | 30% | `ssh-infra-kit` con `bin/backup` y `bin/mirror`: 60 pts de autograding + 40 de calidad |

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
| 1 | ¿Qué pide al servidor `sftp`, qué pide `scp` desde OpenSSH 9.0 y qué pide `scp -O`? ¿Qué programa responde en cada caso? |
| 2 | ¿Por qué `scp -O 'server:nada$(touch /tmp/x)' .` crea `/tmp/x` en el servidor y sin `-O` no? ¿Cuándo usarías `-O`? |
| 3 | Copias de `server` a `bastion` con `scp server:a bastion:` y funciona; con `-R`, falla con `Host key verification failed`. Explica las dos cosas. |
| 4 | Tu lote `sftp -b` tiene `mkdir copia` y `put -R datos copia`. ¿Qué pasa la segunda vez que lo ejecutas? ¿Cómo lo arreglas, y qué riesgo tiene poner `-` delante de `put`? |
| 5 | ¿Qué diferencia hay entre `rsync -a datos server:copia` y `rsync -a datos/ server:copia`? ¿Por qué `bin/backup` añade la barra? |
| 6 | ¿Cómo decide `rsync` si un archivo cambió? ¿En qué caso no ve un cambio, y qué hace `-c`? ¿Por qué no usarlo siempre? |
| 7 | Un archivo de 20 MB cambia en un byte. Explica qué hacen emisor y receptor para que viajen unos KB, y qué significan `Literal data` y `Matched data`. |
| 8 | Nombra dos formas de vaciar un destino por error con `--delete`. ¿Qué haces siempre antes, y cómo te protege `bin/mirror`? |
| 9 | ¿Qué hace `--link-dest`? ¿Por qué borrar la copia más antigua no rompe las demás, y por qué nunca editas un archivo dentro de una copia? ¿Qué pasa si la ruta de `--link-dest` está mal? |
| 10 | Escribe la línea de `authorized_keys` de una llave de copias que solo pueda leer `/srv/datos` con `rsync`. ¿Qué impide cada parte? ¿Por qué el equipo de copias tira de los datos en lugar de que el servidor los envíe? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** `sftp` y `scp` (9.0+) piden el **subsistema** `sftp`; `sshd` arranca el programa de su línea `Subsystem` (`/usr/lib/openssh/sftp-server`), sin pasar por la shell del usuario. `scp -O` pide **ejecutar** `scp -t RUTA` (o `-f`), que la shell del usuario interpreta, y responde el `scp` del servidor.

**2.** Con `-O`, la ruta llega como parte de una orden que ejecuta la shell remota, y la shell expande `$(...)` antes de que `scp` la vea. Con SFTP, la ruta viaja como dato del protocolo y nadie la interpreta. `-O` solo para servidores sin subsistema `sftp`, y nunca con nombres de archivo que vengan de fuera.

**3.** Por defecto (desde OpenSSH 8.7) una copia entre dos remotos pasa por tu equipo: tú abres las dos conexiones con tus llaves y tu `known_hosts`. Con `-R`, `scp` ejecuta en `server` la copia hacia `bastion`: conecta `server`, con sus llaves y su `known_hosts`, que no conoce `bastion`.

**4.** `mkdir copia` falla porque ya existe, el lote se para en la primera orden fallida y `sftp` sale con 1 sin subir nada. `-mkdir copia` ignora ese error. Con `-put`, una subida que falla también se ignora y el lote termina con 0: un backup roto que parece bueno.

**5.** Sin barra se copia la carpeta (`copia/datos/...`); con barra, su contenido (`copia/...`). La barra en el destino no cambia nada. `bin/backup` la añade para que la copia tenga siempre la misma forma, la escribas como la escribas, y para que `--link-dest` compare los mismos caminos (excepto `host:`, que con barra sería la raíz).

**6.** La *quick check*: compara tamaño y fecha de modificación; si coinciden, no lee el archivo. No ve un cambio de contenido con el mismo tamaño y la misma fecha (fecha restaurada con `touch -r`, o el cambio en el mismo segundo que la copia). `-c` compara por hash de contenido, pero lee todos los archivos enteros en los dos lados: para verificar, no para cada sincronización.

**7.** El receptor parte su versión en bloques y envía una suma rápida (*rolling*) y una fuerte de cada uno. El emisor recorre la versión nueva byte a byte buscando bloques con la misma suma rápida, confirma con la fuerte y envía "usa tu bloque N" para cada coincidencia y los datos tal cual para lo demás. El receptor monta el archivo en un temporal y lo renombra. `Literal data`: bytes enviados; `Matched data`: bytes reutilizados del receptor.

**8.** Un origen vacío o equivocado (una carpeta vacía; `"$ORIGEN/"` con la variable vacía, que es `/`), o un destino demasiado amplio (el home o la raíz). También una barra que falta crea una copia anidada y deja el espejo sin limpiar. Siempre `rsync -n -i --delete` y buscar `*deleting`. `bin/mirror` ensaya por defecto (aplica solo con `-y`) y rechaza destinos cuya ruta es vacía, `~`, `.` o `/`.

**9.** Para cada archivo igual al de la carpeta indicada, crea un enlace duro en lugar de copiarlo: la copia es completa, pero solo ocupa lo que cambió. Un inodo se libera cuando se borra su último nombre, así que borrar una copia solo quita nombres. Editar dentro de una copia cambia el mismo inodo que ven las otras. Con una ruta mal escrita (relativa a donde estás y no al destino), `rsync` avisa `--link-dest arg does not exist` y copia todo entero.

**10.** `command="rrsync -ro /srv/datos",restrict ssh-ed25519 AAAA...`. `command=` ignora la orden pedida y ejecuta `rrsync`; `rrsync` solo acepta un `rsync --server`, lo encierra en `/srv/datos` (rechaza `..`, reinterpreta rutas absolutas) y `-ro` impide escribir; `restrict` quita terminal, túneles y reenvío de agente. Tirar de los datos deja en el servidor, lo más expuesto, ninguna llave que llegue a las copias: si lo comprometen, no pueden borrarlas.

</details>

---

## 💪 Desempeño (40%)

Dentro de cada lab: 10 puntos si se cumplen todos los criterios y explicas con tus palabras por qué funciona; 8 si se cumplen todos; 7 si falla uno; menos de 7 si fallan dos o más.

| Lab | Criterio | Puntos |
|---|---|:--:|
| [01 — `scp`](2-practicas/lab-01-scp/README.md) | Copias en los dos sentidos y con `-r`; `-p` explicado; protocolo por defecto y riesgo de `-O`; `-R` frente a la copia por tu equipo | 10 |
| [02 — `sftp`](2-practicas/lab-02-sftp/README.md) | Sesión interactiva; lote `-b` que falla con 1 y uso de `-`; subsistema y alcance de `sftp`; `reput` comprobado | 10 |
| [03 — `rsync` por SSH](2-practicas/lab-03-rsync/README.md) | Segunda pasada vacía; barra final; lectura de `-i`; ahorro de un cambio de un byte medido; `-c` explicado | 10 |
| [04 — `--delete` y exclusiones](2-practicas/lab-04-delete-y-exclude/README.md) | `--delete` ensayado; origen vacío y barra que falta vistos en seco; exclusiones y `--delete-excluded`; recuperación de `--backup-dir` | 10 |
| [05 — `--link-dest`](2-practicas/lab-05-snapshots-con-link-dest/README.md) | Copias enlazadas medidas con `du` y `stat`; copia antigua borrada; ruta mal escrita corregida; edición dentro de una copia explicada | 10 |
| [06 — Llave solo para `rsync`](2-practicas/lab-06-llave-solo-para-rsync/README.md) | Copia con la llave restringida; sin shell, escritura, salida de la carpeta, `scp` ni túneles; `sftp-server -R -d` explicado | 10 |
| [07 — Transferencias grandes](2-practicas/lab-07-transferencias-grandes/README.md) | Reanudación con `--partial`; progreso y `--bwlimit`; coste por conexión medido y reducido; `tar` por `ssh` | 10 |

La nota de Desempeño es la media de los siete labs.

---

## 📦 Producto (30%)

### Verificable por el autograding — 60 puntos

Lo ejecuta `./scripts/verificar-semana.sh 06`. Es binario: pasa o no pasa.

| Comprobación | Puntos |
|---|:--:|
| `bk-uso` — bin/backup rechaza un número de argumentos distinto de 2 y un BACKUP_KEEP no válido (sale con 2) | 1 |
| `bk-crea` — bin/backup crea una copia con fecha y hora y latest apunta a ella | 3 |
| `bk-usa-config` — bin/backup conecta con ssh -F config del kit | 3 |
| `bk-falla` — Si rsync falla, bin/backup sale con 1, no deja copia a medias y latest no cambia | 5 |
| `bk-enlaza` — Un archivo que no cambió es un enlace duro a la copia anterior | 5 |
| `bk-cambio` — Un archivo que cambió se copia de nuevo y la copia anterior conserva su versión | 3 |
| `bk-borrado` — Un archivo borrado del origen sigue en la copia anterior y no en la nueva | 3 |
| `bk-keep` — Con BACKUP_KEEP=2 quedan las 2 copias más recientes y latest en la última | 4 |
| `bk-ssh-real` — bin/backup copia una carpeta remota por SSH | 6 |
| `mi-uso` — bin/mirror rechaza argumentos de más o de menos y un origen que no es una carpeta (sale con 2) | 1 |
| `mi-vista-previa` — Sin -y, bin/mirror enseña lo que borraría y no toca el destino | 5 |
| `mi-aplica` — Con -y, bin/mirror deja el destino igual que el origen | 3 |
| `mi-usa-config` — bin/mirror conecta con ssh -F config del kit | 2 |
| `mi-ssh-real` — bin/mirror -y deja igual una carpeta remota por SSH | 5 |
| `mi-peligro` — bin/mirror rechaza como destino el home o la raíz (sale con 2 sin llamar a rsync) | 5 |
| `config-hereda` — config mantiene los valores de las semanas 02-05 | 2 |
| `kit-sigue-funcionando` — Los scripts de semanas anteriores siguen respondiendo | 1 |
| `kit-completo-y-limpio` — Sin TODO en config, conf.d/ y bin/, y shellcheck sin avisos | 3 |
| **Total** | **60** |

### Calidad — 40 puntos

| Criterio | Excelente | Suficiente | Puntos |
|---|---|---|:--:|
| **README del kit** | Filas de `backup` y `mirror` con códigos y ejemplo; bitácora de la semana 06; secciones de copias (con restauración en seco), llave de copias y publicar | Filas sin códigos o sin secciones | 8 |
| **Mensajes** | Cada error dice qué pasó y qué hacer (`espera un segundo y repite`, `repite con -y`), por stderr; la salida normal es una línea por copia o por cambio | Errores genéricos o mezclados con la salida | 8 |
| **Comentarios del porqué** | Qué / Para qué / Impacto en `.parcial`, en `--link-dest` (ruta absoluta) y en las opciones de `mirror` (por qué ensayar por defecto) | Comentarios que repiten el código | 8 |
| **Seguridad** | `bin/mirror` ensaya por defecto y rechaza home y raíz; `RSYNC_RSH` con el `config` del kit; el README propone tirar de los datos y una llave `rrsync -ro` | `mirror` aplica sin `-y` o el README propone una llave sin restringir | 8 |
| **Git** | Commit nuevo en `~/ssh-infra-kit` con mensaje descriptivo y sin llaves ni copias | Sin commit de la semana | 8 |
| **Total** | | | **40** |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Una llave privada en el repositorio del kit o en su historial de git | −20 pts |
| Copias de seguridad (`~/backups`) dentro del repositorio del kit | −10 pts |
| `StrictHostKeyChecking no`, `accept-new` o `UserKnownHostsFile /dev/null` en cualquier archivo del kit | −10 pts |
| Un script del kit que usa `scp -O` o `rsync --delete` sin ensayo previo | −10 pts |
| Contraseñas o frases de paso escritas en un archivo del kit | −10 pts |

---

## 📋 Checklist de entrega

- [ ] Los 7 labs con sus criterios de éxito comprobados
- [ ] Las 10 preguntas de Conocimiento respondidas por escrito
- [ ] `3-proyecto/starter/` sin ningún `TODO`
- [ ] `./scripts/verificar-semana.sh 06` con las 18 comprobaciones en verde
- [ ] `ssh-infra-kit` con un commit nuevo y sin llaves ni copias

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Proyecto — ssh-infra-kit: copias de seguridad y espejos con `rsync`](3-proyecto/README.md) | [Recursos — ebooks](4-recursos/ebooks-free/README.md) → |

[↑ Semana 06](README.md)
