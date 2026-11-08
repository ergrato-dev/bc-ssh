# Semana 06 — Transferencia de archivos: scp, sftp y rsync

## Descripción

La conexión que ya sabes abrir, con tus alias, llaves y multiplexing, sirve también para mover archivos. Esta semana aprendes las tres herramientas y cuándo usar cada una: `scp` para copias puntuales (y por qué su protocolo antiguo deja que el servidor interprete los nombres), `sftp` para moverte por el servidor y automatizar lotes, y `rsync` para sincronizar enviando solo lo que cambió. Con `rsync` haces lo que más se usa en el día a día: espejos con `--delete` sin borrar lo que no debes, copias de seguridad completas que comparten lo que no cambió (`--link-dest`) y una llave de copias que, con `rrsync`, solo puede leer una carpeta. Tu kit gana `bin/backup` y `bin/mirror`.

## Objetivos de aprendizaje

Al terminar esta semana, podrás:

- Explicar qué piden al servidor `scp`, `sftp` y `rsync` (subsistema `sftp` o ejecutar un programa) y qué riesgo tiene `scp -O`
- Copiar con `scp` en los dos sentidos y entre servidores, y automatizar `sftp` con lotes `-b` que fallan cuando deben
- Sincronizar con `rsync -a`, usar bien la barra final del origen, leer `-n -i` y explicar la *quick check* y el algoritmo de diferencias
- Usar `--delete`, filtros y `--backup-dir` ensayando siempre antes
- Hacer copias con `--link-dest` y explicar los enlaces duros que comparten
- Limitar una llave de copias con `command="rrsync -ro ..."` y `restrict`
- Reanudar con `--partial`, limitar con `--bwlimit` y evitar el coste de muchas conexiones
- Añadir a tu `ssh-infra-kit` `bin/backup` y `bin/mirror`

## Prerrequisitos

- [Semana 05](../week-05-configuracion_avanzada_cliente_ssh/README.md) completa: `conf.d/`, multiplexing y `bin/kit-link`
- El laboratorio reconstruido y levantado: `docker compose up -d --build` (esta semana la imagen añade `python3`, que necesita `rrsync`)

## Contenido

| # | Tipo | Tema | Tiempo |
|---|------|------|--------|
| — | Teoría | [01-scp-y-sftp.md](1-teoria/01-scp-y-sftp.md) · [02-rsync.md](1-teoria/02-rsync.md) · [03-copias-de-seguridad-y-llaves-restringidas.md](1-teoria/03-copias-de-seguridad-y-llaves-restringidas.md) | 1.5 h |
| — | Conocimiento | [10 preguntas](rubrica-evaluacion.md#-conocimiento-30) | 30 min |
| 1 | Lab | [lab-01-scp](2-practicas/lab-01-scp/) | 60 min |
| 2 | Lab | [lab-02-sftp](2-practicas/lab-02-sftp/) | 60 min |
| 3 | Lab | [lab-03-rsync](2-practicas/lab-03-rsync/) | 60 min |
| 4 | Lab | [lab-04-delete-y-exclude](2-practicas/lab-04-delete-y-exclude/) | 60 min |
| 5 | Lab | [lab-05-snapshots-con-link-dest](2-practicas/lab-05-snapshots-con-link-dest/) | 60 min |
| 6 | Lab | [lab-06-llave-solo-para-rsync](2-practicas/lab-06-llave-solo-para-rsync/) | 60 min |
| 7 | Lab | [lab-07-transferencias-grandes](2-practicas/lab-07-transferencias-grandes/) | 60 min |
| — | Proyecto | [ssh-infra-kit: copias de seguridad y espejos con `rsync`](3-proyecto/) | 3 h |

**Total: 12 horas**

## Distribución del tiempo

```
[1.5 h]  Leer 1-teoria/ (scp y sftp, rsync, copias y llaves restringidas)
[30 min] Responder las 10 preguntas de Conocimiento
[60 min] lab-01 — scp: sentidos, -r, -p, entre servidores y el riesgo de -O
[60 min] lab-02 — sftp: sesión, lotes -b, errores y reput
[60 min] lab-03 — rsync -a, barra final, -n -i, diferencias y -c
[60 min] lab-04 — --delete, exclusiones y --backup-dir
[60 min] lab-05 — Copias con --link-dest y enlaces duros
[60 min] lab-06 — Llave de copias con rrsync -ro y restrict
[60 min] lab-07 — --partial, --bwlimit, multiplexing y tar por ssh
[3 h]    Proyecto: bin/backup y bin/mirror
```

## Verificación de completitud

Desde la raíz del repositorio, en tu equipo:

```bash
./scripts/verificar-semana.sh 06
```

Comprueba tu proyecto (`3-proyecto/starter/`) contra los 18 requisitos verificables de la semana; dos de ellos arrancan un `sshd` real dentro del cliente para copiar por SSH. Al terminar deben pasar todos, y dentro del cliente, con la llave del paso 5 del proyecto instalada, la segunda copia debe ocupar unos KB:

```bash
cd bootcamp/week-06-transferencia_archivos_scp_sftp_rsync/3-proyecto/starter
bin/kit-link
bin/backup lab-server:datos ~/backups/server; sleep 1
bin/backup lab-server:datos ~/backups/server
du -sh ~/backups/server/2*
```

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [← Semana 05 — Configuración avanzada del cliente](../week-05-configuracion_avanzada_cliente_ssh/README.md) | **Semana 06 — Transferencia de archivos** | Semana 07 — Servidor: `sshd_config` y hardening (próximamente) |

[← Volver al índice del bootcamp](../README.md)
