# Lab 04 — `--delete` y exclusiones

⏱ Duración estimada: ~60 min

## Objetivo

Mantener una copia exacta con `--delete` sin borrar lo que no debes: ensayar siempre con `-n -i`, ver qué hace un origen equivocado, excluir archivos con `--exclude` y `--exclude-from`, y guardar lo que se borra con `--backup-dir`.

## Contexto

- `--delete`, filtros y `--backup-dir`: [teoría 02](../../1-teoria/02-rsync.md#borrar-en-el-destino).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-scp/README.md). Después, una web de ejemplo publicada en `server`:
   ```bash
   mkdir -p web/css web/cache
   echo index > web/index.html; echo css > web/css/main.css
   echo tmp > web/cache/x.tmp; echo log > web/error.log
   rsync -a web/ server:web
   ```

1. **Sin `--delete`, lo borrado se queda.** Borra un archivo en local, crea otro y sincroniza:
   ```bash
   rm web/index.html; echo nuevo > web/nuevo.html
   rsync -a -i web/ server:web
   ssh server ls web
   ```
   ```
   <f+++++++++ nuevo.html
   cache
   css
   error.log
   index.html
   nuevo.html
   ```
   `index.html` sigue publicado. Para un backup puede estar bien; para un espejo, no.

2. **Con `--delete`, primero en seco:**
   ```bash
   rsync -a -i -n --delete web/ server:web
   rsync -a -i --delete web/ server:web
   ssh server ls web
   ```
   ```
   *deleting   index.html
   *deleting   index.html
   cache
   css
   error.log
   nuevo.html
   ```
   La primera línea es el ensayo (`-n`); la segunda, el borrado de verdad. `*deleting` es la marca que tienes que buscar antes de quitar `-n`.

3. **Un origen equivocado.** Una carpeta vacía con `--delete` deja el destino vacío. Solo en seco:
   ```bash
   mkdir vacio
   rsync -a -n -i --delete vacio/ server:web
   ```
   ```
   *deleting   css/main.css
   *deleting   css/
   *deleting   cache/x.tmp
   *deleting   cache/
   *deleting   nuevo.html
   *deleting   error.log
   .d..t...... ./
   ```
   Lo mismo pasa con una variable vacía en un script: `rsync -a --delete "$ORIGEN/" server:web` con `ORIGEN` sin definir es `rsync -a --delete / server:web`. Por eso `bin/mirror` del proyecto ensaya por defecto y no acepta el home ni la raíz como destino.

4. **La barra que falta.** Sin barra final en el origen, `rsync` copia la carpeta *dentro* del destino:
   ```bash
   rsync -a -n -i --delete web server:web | head -5
   ```
   ```
   cd+++++++++ web/
   <f+++++++++ web/error.log
   <f+++++++++ web/nuevo.html
   cd+++++++++ web/cache/
   <f+++++++++ web/cache/x.tmp
   ```
   Crearía `web/web/`, una segunda copia de toda la web. `--delete` solo actúa dentro de las carpetas que se transfieren (`web/web/`), así que lo que sobra en `web/` ya no se limpia nunca: el espejo deja de serlo sin ningún error. El ensayo lo enseña antes de que pase.

5. **Excluir archivos.** `--exclude` acepta patrones; con `/` al final, solo carpetas:
   ```bash
   rsync -a -i --delete --exclude '*.log' --exclude 'cache/' web/ server:web2
   ssh server find web2 | sort
   ```
   ```
   created directory web2
   cd+++++++++ ./
   <f+++++++++ nuevo.html
   cd+++++++++ css/
   <f+++++++++ css/main.css
   web2
   web2/css
   web2/css/main.css
   web2/nuevo.html
   ```
   Las comillas evitan que tu shell expanda `*.log` antes de que lo vea `rsync`.

6. **Lo excluido tampoco se borra.** Crea en el destino un archivo que coincide con un patrón excluido:
   ```bash
   ssh server 'echo remoto > web2/remoto.log'
   rsync -a -i --delete --exclude '*.log' --exclude 'cache/' web/ server:web2
   ssh server ls web2
   rsync -a -i --delete --delete-excluded --exclude '*.log' --exclude 'cache/' web/ server:web2
   ssh server ls web2
   ```
   ```
   .d..t...... ./
   css
   nuevo.html
   remoto.log
   *deleting   remoto.log
   css
   nuevo.html
   ```
   Un patrón excluido protege también al destino: `--delete` no lo toca. `--delete-excluded` lo borra. Útil para conservar en el servidor lo que solo existe allí (subidas de usuarios, `.env`).

7. **Los patrones, en un archivo.** Uno por línea; `#` comenta:
   ```bash
   printf '# no se publica\n*.log\ncache/\n' > excluir.txt
   cat excluir.txt
   rsync -a -n -i --delete --exclude-from=excluir.txt web/ server:web2; echo "código: $?"
   ```
   ```
   # no se publica
   *.log
   cache/
   código: 0
   ```
   Sin líneas de cambios: el resultado es el del paso 6. El archivo va al repositorio junto a la web y todos publican con los mismos filtros.

8. **Guardar lo que se borra o se sustituye.** `--backup --backup-dir` mueve allí cada archivo que `rsync` borraría o sobrescribiría:
   ```bash
   rm web/nuevo.html; echo css2 > web/css/main.css
   rsync -a -i --delete --exclude-from=excluir.txt --backup --backup-dir=../web-borrados/hoy web/ server:web2
   ssh server find web-borrados | sort
   ssh server cat web-borrados/hoy/css/main.css
   ```
   ```
   *deleting   nuevo.html
   .d..t...... ./
   <f.st...... css/main.css
   web-borrados
   web-borrados/hoy
   web-borrados/hoy/css
   web-borrados/hoy/css/main.css
   web-borrados/hoy/nuevo.html
   css
   ```
   - Una ruta relativa en `--backup-dir` se cuenta desde el destino (`web2`): `../web-borrados` queda a su lado. Si quedara dentro, la siguiente sincronización con `--delete` la borraría.
   - `main.css` guardado tiene el contenido viejo (`css`). Con `--backup-dir=../web-borrados/$(date +%F)`, una carpeta por día.

## Criterios de éxito

- [ ] Explicas qué deja `rsync` sin `--delete` y qué borra con él (pasos 1 y 2)
- [ ] Identificaste en seco los dos errores que vacían un destino: origen vacío y barra que falta (pasos 3 y 4)
- [ ] Excluiste archivos y explicas qué hace `--delete-excluded` (pasos 5 a 7)
- [ ] Recuperaste un archivo borrado y otro sobrescrito de `--backup-dir` (paso 8)

## Reto extra

`--exclude 'cache/'` excluye cualquier carpeta `cache` a cualquier profundidad. Crea `web/css/cache/` y comprueba que también se excluye. ¿Cómo excluirías solo la `cache` de la raíz? Pista: un patrón que empieza por `/` se ancla al origen.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 03 — `rsync` por SSH](../lab-03-rsync/README.md) | [Lab 05 — Copias completas que ocupan poco: `--link-dest`](../lab-05-snapshots-con-link-dest/README.md) → |

[↑ Semana 06](../../README.md)
