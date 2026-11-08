# Copias de seguridad por SSH y llaves que solo copian

⏱ Lectura: ~25 min

Con `rsync` y `--link-dest` ya sabes hacer copias completas que ocupan poco. Falta decidir **quién conecta a quién**, con **qué llave**, y cómo saber que una copia sirve. Son decisiones de seguridad tanto como de comodidad: el sistema de copias es lo que te salva cuando algo va mal, y es también una puerta de entrada si está mal hecho.

## Tirar o empujar

| | *Push*: el servidor envía | *Pull*: el equipo de copias tira |
|---|---|---|
| Quién tiene la llave | El servidor, para entrar en el equipo de copias | El equipo de copias, para entrar en el servidor |
| Si atacan el servidor | El atacante tiene una llave que escribe en tus copias: puede borrarlas o cifrarlas | No hay en el servidor nada que llegue a las copias |
| Si atacan el equipo de copias | | El atacante llega al servidor con la llave de copias: por eso esa llave tiene que poder poco |

- **Qué:** `bin/backup lab-server:datos ~/backups/server` se ejecuta en el equipo de copias y **tira** de los datos.
- **Para qué:** que comprometer el servidor (lo más expuesto) no sirva para destruir las copias. Un *ransomware* que cifra el servidor y después borra los backups es el caso que esto evita.
- **Impacto:** el equipo de copias necesita entrar en cada servidor. Esa llave es valiosa: la siguiente sección la limita para que, si alguien la roba, solo pueda leer una carpeta.

## Una llave que solo copia

Una copia programada con `cron` se ejecuta sin nadie delante: no puede pedir una frase de paso. O la llave va sin frase, o la carga un agente que alguien desbloqueó antes. En los dos casos, cualquiera que obtenga la llave puede usarla. Las opciones de `authorized_keys` de la [semana 03](../../week-03-autenticacion_con_llaves_ssh/README.md) deciden **qué** puede hacer:

```
command="rrsync -ro /home/alumno/datos",restrict ssh-ed25519 AAAA... backup@client
```

| Parte | Qué hace |
|---|---|
| `restrict` | Sin terminal, sin reenvío de puertos, de agente ni de X11. Se puede volver a permitir algo concreto después (`restrict,pty`) |
| `command="..."` | Lo que pida el cliente se ignora y se ejecuta esta orden. Lo pedido queda en la variable `SSH_ORIGINAL_COMMAND` |
| `rrsync -ro DIR` | Lee `SSH_ORIGINAL_COMMAND`, comprueba que es un `rsync --server`, rechaza las opciones peligrosas y lo ejecuta encerrado en `DIR`. `-ro`: solo puede leer; `-wo`: solo escribir |
| `from="10.0.0.5"` | Opcional: la llave solo vale desde esa dirección |

`rrsync` (*restricted rsync*) viene con `rsync`. En Ubuntu 24.04 es `/usr/bin/rrsync`, un script de Python 3 (por eso el laboratorio instala `python3`). Con él, una llave robada de copias:

- no abre una shell ni ejecuta otra orden ([lab 06, paso 2](../2-practicas/lab-06-llave-solo-para-rsync/README.md));
- no escribe, así que no puede cambiar ni borrar los datos (paso 6);
- no sale de su carpeta: `..` se rechaza y una ruta absoluta se interpreta dentro de ella (paso 5);
- no sirve como pasarela hacia la red del servidor, porque `restrict` niega los túneles (paso 8).

Con la llave restringida, la ruta remota es relativa a la carpeta permitida: `rsync -a ALIAS: destino/` copia toda la carpeta, y `ALIAS:sub/` solo una subcarpeta.

### ¿Y `sftp`?

Para `sftp`, el equivalente sería `command="/usr/lib/openssh/sftp-server -R -d DIR"`: `-R` impide escribir y `-d` elige la carpeta inicial. Pero `-d` no encierra: `get ../otro` funciona ([lab 06, paso 9](../2-practicas/lab-06-llave-solo-para-rsync/README.md)). Encerrar un usuario de `sftp` en una carpeta es trabajo del servidor, con `ChrootDirectory` y `ForceCommand internal-sftp` en `sshd_config`: lo harás en la semana 07.

## Una copia que se corta

Una copia puede cortarse a la mitad: la red cae, el disco se llena, alguien pulsa Ctrl+C. Si la carpeta a medias se queda con el mismo aspecto que una buena, el día que la necesites descubrirás que le faltan archivos, y la siguiente copia con `--link-dest` se habrá basado en ella.

`bin/backup` evita las dos cosas:

1. `rsync` escribe en `DESTINO/.parcial-NOMBRE`, oculta.
2. Si `rsync` falla, la borra y sale con 1. `latest` sigue apuntando a la copia anterior, que estaba completa.
3. Solo si termina bien, la renombra a `DESTINO/NOMBRE` y mueve `latest`.

Renombrar una carpeta dentro del mismo disco es instantáneo y no se queda a medias: o se ve la carpeta con su nombre final, o no se ve. Es el mismo truco que usa `rsync` con cada archivo (escribir en un temporal y renombrar).

## Cuántas copias guardar

Cada copia con `--link-dest` ocupa solo lo que cambió, pero lo que cambia mucho (logs, bases de datos) se acumula. `BACKUP_KEEP=7` guarda las siete últimas y borra las demás. Como cada copia es independiente, borrar la más antigua no estropea las siguientes: los archivos que compartía siguen teniendo otros nombres.

Esquemas habituales, de más simple a más completo:

| Esquema | Qué guardas |
|---|---|
| Las N últimas | Una por ejecución: `bin/backup` con `BACKUP_KEEP` |
| Diarias y semanales | 7 diarias + 4 semanales: dos carpetas de destino con distinto `BACKUP_KEEP` |
| Regla 3-2-1 | 3 copias, en 2 tipos de soporte, 1 fuera del edificio. Ninguna herramienta lo hace por ti |

Herramientas como `rsnapshot` automatizan los esquemas por niveles con este mismo mecanismo (`rsync --link-dest`). Si los datos tienen que ir cifrados a un sitio que no controlas, existen herramientas con cifrado y deduplicación propios (`restic`, `borg`); `rsync` copia los archivos tal cual.

## Una copia que nunca restauraste no es una copia

Una copia sirve si puedes recuperar los datos. Comprueba de vez en cuando:

1. **Que existe y es reciente:** `ls -l ~/backups/server/latest`.
2. **Que coincide con el origen**, por contenido: `rsync -a -n -i -c lab-server:datos/ ~/backups/server/latest/` no debería listar nada que no haya cambiado desde la copia.
3. **Que se restaura**, primero en seco y a una carpeta aparte:
   ```bash
   rsync -a -n -i ~/backups/server/latest/ lab-server:restaurado/
   rsync -a ~/backups/server/latest/ lab-server:restaurado/
   ```

Restaurar con `--delete` sobre la carpeta original vuelve exactamente al estado de la copia, y borra lo creado después: hazlo solo después de ensayarlo con `-n`.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — `rsync`: enviar solo lo que cambió](02-rsync.md) | [Índice de labs](../2-practicas/README.md) → |

[↑ Semana 06](../README.md)
