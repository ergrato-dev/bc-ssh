# Lab 07 — Políticas de verificación

⏱ Duración estimada: ~60 min

## Objetivo

Comprobar qué hace `ssh` con cada valor de `StrictHostKeyChecking` ante una host key nueva, cambiada y revocada; automatizar esa comparación en un script, y usar un `known_hosts` global para que una máquina confíe en servidores sin preguntar a cada usuario.

## Contexto

- La tabla de comportamientos y el diagrama están en la [teoría 03](../../1-teoria/03-host-keys-y-known_hosts.md#qué-hace-ssh-según-stricthostkeychecking). Aquí la compruebas en vez de creerla.
- Para simular una **llave cambiada** sin tocar el servidor, pondrás en `known_hosts` una llave falsa que generas tú: para `ssh` es lo mismo que si el servidor hubiera cambiado (o que si hubiera un intermediario).
- **La contraseña `alumno` es solo del laboratorio.** Este lab demuestra por qué `StrictHostKeyChecking no` es peligroso: úsalo solo aquí.

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d
   docker compose run --rm client
   ```
   **En el cliente**:
   ```bash
   cd bootcamp/week-02-protocolo_kex_y_known_hosts/2-practicas/lab-07-politicas-de-verificacion
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh
   ```

1. **Host nuevo.** Con `known_hosts` vacío, prueba tres valores:
   ```bash
   for v in yes accept-new no; do
     rm -f ~/.ssh/known_hosts
     echo "--- $v"
     sshpass -e ssh -o StrictHostKeyChecking=$v -o UpdateHostKeys=no server 'echo DENTRO'
   done
   ```
   ```
   --- yes
   No ED25519 host key is known for server and you have requested strict checking.
   Host key verification failed.
   --- accept-new
   Warning: Permanently added 'server' (ED25519) to the list of known hosts.
   DENTRO
   --- no
   Warning: Permanently added 'server' (ED25519) to the list of known hosts.
   DENTRO
   ```
   - `yes` corta: solo entra lo que ya está en `known_hosts`.
   - `accept-new` y `no` añaden la llave **sin que nadie la haya comparado**. Si había un intermediario, su llave queda guardada como buena.
   - `ask` (el valor por defecto) no aparece porque preguntaría por teclado: ya lo conoces de la semana 01.

2. **Llave cambiada.** Genera una llave que no es la de `server` y ponla en `known_hosts` como si lo fuera:
   ```bash
   ssh-keygen -q -t ed25519 -N '' -f /tmp/falsa
   echo "server $(cut -d' ' -f1,2 /tmp/falsa.pub)" > ~/.ssh/known_hosts
   cat ~/.ssh/known_hosts
   ```
   ```
   server ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...
   ```
   `-q` silencioso, `-N ''` sin frase de paso, `-f` dónde guardarla. `cut -d' ' -f1,2` toma tipo y llave del `.pub`, sin el comentario.

3. Prueba los valores contra la llave "cambiada":
   ```bash
   for v in ask yes accept-new; do
     echo "--- $v"
     sshpass -e ssh -o StrictHostKeyChecking=$v -o UpdateHostKeys=no server 'echo DENTRO' 2>&1 | tail -2
   done
   ```
   ```
   --- ask
   Host key for server has changed and you have requested strict checking.
   Host key verification failed.
   --- yes
   Host key for server has changed and you have requested strict checking.
   Host key verification failed.
   --- accept-new
   Host key for server has changed and you have requested strict checking.
   Host key verification failed.
   ```
   `tail -2` muestra solo las dos últimas líneas; antes va el aviso grande de la semana 01. Los tres cortan: `accept-new` acepta llaves **nuevas**, nunca **cambiadas**.

4. Ahora con `no`:
   ```bash
   sshpass -e ssh -o StrictHostKeyChecking=no -o UpdateHostKeys=no server 'echo DENTRO' 2>&1 | grep -v '^@'
   ```
   ```
   ...
   Password authentication is disabled to avoid man-in-the-middle attacks.
   Keyboard-interactive authentication is disabled to avoid man-in-the-middle attacks.
   alumno@server: Permission denied (publickey,password).
   ```
   `ssh` **sí** conectó con quien tenía la llave distinta. Solo desactivó la contraseña para no entregársela. Pero con una llave de usuario (semana 03) habría entrado, y todo lo que escribieras iría a ese servidor. Responde en tus notas: ¿por qué "no me pidió la contraseña" no significa "estoy a salvo"?

5. **Llave revocada.** Marca como `@revoked` la llave **real** de `server`:
   ```bash
   echo "@revoked server $(ssh-keyscan -t ed25519 server 2>/dev/null | cut -d' ' -f2,3)" > ~/.ssh/known_hosts
   sshpass -e ssh -o UpdateHostKeys=no server 'echo DENTRO'; echo "código: $?"
   ```
   ```
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   @       WARNING: REVOKED HOST KEY DETECTED!               @
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   The ED25519 host key for server is marked as revoked.
   This could mean that a stolen key is being used to
   impersonate this host.
   ED25519 host key for server was revoked and you have requested strict checking.
   Host key verification failed.
   código: 255
   ```
   Así se reacciona cuando la llave privada de un servidor se filtra: se marca como revocada en los `known_hosts` de todos (o en el global), y nadie vuelve a aceptarla aunque la presente "el servidor de siempre".

6. **TODO de `starter/matriz.sh`.** Los pasos 1 a 5 a mano son lentos. El script prepara en un `known_hosts` temporal cada escenario (`nueva`, `cambiada`, `revocada`), conecta con cada valor y resume el resultado en una palabra. Falta la función `resultado`:
   ```bash
   resultado() {
     if   grep -q DENTRO <<<"$1"; then echo conecta
     elif grep -q 'Password authentication is disabled' <<<"$1"; then echo sin-clave
     else echo corta
     fi
   }
   ```
   `<<<"$1"` pasa el texto a `grep` como stdin; `-q` solo devuelve el código, sin imprimir.
   ```bash
   ./starter/matriz.sh server
   ```
   ```
                nueva           cambiada        revocada
   yes          corta           corta           corta
   accept-new   conecta         corta           corta
   no           conecta         sin-clave       sin-clave
   ```
   Es la tabla de la teoría 03, medida. Lee el script entero: `mktemp -d` crea un directorio temporal y `trap '...' EXIT` lo borra al salir, pase lo que pase.

7. **`known_hosts` global.** En un equipo compartido, el administrador reparte las llaves verificadas en `/etc/ssh/ssh_known_hosts` y ningún usuario tiene que verificar nada. Como `alumno` no puede escribir en `/etc/ssh`, simúlalo con `GlobalKnownHostsFile`:
   ```bash
   rm -rf ~/.ssh
   ssh-keyscan -t ed25519 server 2>/dev/null > /tmp/global
   sshpass -e ssh -v -o GlobalKnownHostsFile=/tmp/global -o StrictHostKeyChecking=yes server 'echo DENTRO' 2>&1 | grep -E 'Found key|DENTRO'
   ls ~/.ssh
   ```
   ```
   debug1: Found key in /tmp/global:1
   DENTRO
   ls: cannot access '/home/alumno/.ssh': No such file or directory
   ```
   Con `StrictHostKeyChecking yes` y un archivo vacío (ni siquiera existe), entra: la llave estaba en el global. `ssh` no escribe en el global ni creó el tuyo. En un caso real, la línea del global se habría verificado antes (aquí la tomaste de `ssh-keyscan` por brevedad).

8. **Tu política.** Escribe en tus notas, con una frase de justificación cada una, qué valor usarías en:

   | Situación | `StrictHostKeyChecking` | Cómo entran las llaves |
   |---|---|---|
   | Tu portátil, servidores nuevos de vez en cuando | | |
   | Un script de CI que despliega en 3 servidores fijos | | |
   | Contenedores de laboratorio que se recrean cada hora | | |
   | Un equipo con 200 servidores | | |

   Pistas: teoría 03 ("Otras formas de distribuir llaves") y el proyecto de esta semana.

## Criterios de éxito

- [ ] Explicas por qué `accept-new` no protege la primera conexión (paso 1)
- [ ] Explicas por qué `accept-new` sí corta con una llave cambiada (paso 3)
- [ ] Respondiste por qué "no me pidió la contraseña" no es estar a salvo (paso 4)
- [ ] `./starter/matriz.sh server` imprime la tabla completa (paso 6)
- [ ] Tu tabla de políticas tiene las cuatro filas justificadas (paso 8)

## Reto extra

Añade a `matriz.sh` una columna `conocida` (el `known_hosts` tiene la llave real) y una fila para `UpdateHostKeys=ask` en lugar de `StrictHostKeyChecking`. ¿Cambia algo en `conocida`? Explica por qué `UpdateHostKeys` no puede servir para colar una llave falsa.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 06 — `known_hosts` por dentro](../lab-06-known-hosts-por-dentro/README.md) | [Proyecto — ssh-infra-kit: known_hosts verificado](../../3-proyecto/README.md) → |

[↑ Semana 02](../../README.md)
