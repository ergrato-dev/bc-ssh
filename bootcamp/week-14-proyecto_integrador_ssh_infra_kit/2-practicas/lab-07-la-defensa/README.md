# Lab 07 — La defensa

⏱ Duración estimada: ~60 min

## Objetivo

Ensayar la defensa del kit: escribir el guion de la demo y cronometrarlo, y practicar la avería en vivo con `romper.sh`, que estropea `server` de una de seis formas sin decirte cuál. Lo que se entrena es el método: `bin/doctor`, la pista, el log, el RUNBOOK y la comprobación, en voz alta.

## Contexto

- Cómo es la defensa, el guion y las preguntas: [teoría 03](../../1-teoria/03-la-defensa.md).
- **Haz este lab al final de la semana, con el proyecto terminado**: la demo usa `bin/kit-check`, y las pistas de `bin/doctor` que aparecen abajo son las del proyecto (paso 2).
- `starter/romper.sh` se ejecuta en **tu equipo** y actúa como root dentro del contenedor `server`: **solo para el laboratorio**. Las respuestas, en [`solucion/README.md`](solucion/README.md): no las mires hasta haber intentado cada avería.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 02](../lab-02-un-servidor-nuevo/README.md), con `server` como lo dejó el [lab 06](../lab-06-reconstruir-un-servidor/README.md) (`bin/doctor lab-server` sale con 0). Copia en tu kit los scripts que arreglaste en el proyecto, si trabajas en `~/ssh-infra-kit`:
   ```bash
   cp /bc-ssh/bootcamp/week-14-proyecto_integrador_ssh_infra_kit/3-proyecto/starter/bin/* ~/ssh-infra-kit/bin/
   ```
   Y en tu equipo, otra terminal en la raíz del repositorio para la consola de `server`.

1. **El guion.** En `~/w/guion.md`, los seis bloques de la [teoría 03](../../1-teoria/03-la-defensa.md#la-demo-un-guion-no-una-improvisación), y en cada uno: los comandos exactos, la salida que esperas (cópiala de los labs 01 a 04) y una frase de lo que demuestra. Por ejemplo:
   ```markdown
   ## 2. Un equipo nuevo (3 min)
   - `bin/kh-add server SHA256:...` → `server añadida SHA256:...`
     Demuestra: ninguna host key entra sin comprobar (StrictHostKeyChecking yes).
   - `bin/doctor lab-server` → `kex: sntrup761x25519-sha512@openssh.com (postcuántico)`, `entrada: publickey`
     Demuestra: la conexión es la que dice el kit, sin master y con la llave.
   ```

2. **Ensayo cronometrado.** Sigue el guion entero en voz alta con `time`, o con un reloj al lado. Si pasa de 15 minutos, recorta: lo que demuestra lo mismo que otro bloque, fuera. Apunta en el guion lo que tardó cada bloque.

3. **Una avería conocida, para ver el método.** En tu equipo:
   ```bash
   bootcamp/week-14-proyecto_integrador_ssh_infra_kit/2-practicas/lab-07-la-defensa/starter/romper.sh 4
   ```
   ```
   server roto. Empieza por bin/doctor lab-server.
   ```
   En el cliente, y diciendo en voz alta lo que haces:
   ```bash
   bin/mux stop >/dev/null
   bin/doctor lab-server
   ```
   ```
   destino:  alumno@server:22
   error:    ssh: connect to host server port 22: Connection refused
   pista:    nadie escucha en ese puerto (¿sshd está arrancado? ¿es el puerto correcto?) o un cortafuegos rechaza tu IP: si desde otra IP entra, mira fail2ban-client status sshd en el servidor
   ```
   - **Capa**: TCP. El servidor responde, pero nada acepta en el 22. No es la llave ni la host key.
   - **Por la consola** (no puedes entrar por SSH), en tu equipo:
   ```bash
   docker compose exec server sh -c 'grep "Server listening" /var/log/auth.log | tail -2; grep -r "^Port" /etc/ssh/sshd_config.d/'
   ```
   ```
   2026-11-11 01:21:26 server sshd: Server listening on 0.0.0.0 port 2222.
   2026-11-11 01:21:26 server sshd: Server listening on :: port 2222.
   /etc/ssh/sshd_config.d/05-cambio.conf:Port 2222
   ```
   - **Causa**: un archivo que no es del kit cambió el puerto. **Arreglo**: vaciarlo y recargar (`truncate -s0` deja el archivo sin efecto; el playbook lo borrará la próxima vez, porque no es del kit):
   ```bash
   docker compose exec server sh -c 'truncate -s0 /etc/ssh/sshd_config.d/05-cambio.conf && sshd -t && kill -HUP $(cat /run/sshd.pid)'
   ```
   - **Comprobación**: `bin/doctor lab-server` sale con 0.
   - **Qué lo habría evitado**: que la configuración solo cambie desde el repositorio (el playbook), y `bin/audit` o `bin/doctor` en un cron que avise.

4. **Seis averías al azar.** Por parejas: una persona ejecuta `romper.sh` **sin número** y cronometra; la otra diagnostica en voz alta, con este orden:
   1. `bin/doctor lab-server`: ¿qué capa?
   2. La pista. Si es `Permission denied`, el log del servidor por la consola: `docker compose exec server tail -5 /var/log/auth.log`.
   3. El procedimiento del RUNBOOK para ese síntoma.
   4. El arreglo, y la comprobación del procedimiento.
   5. Qué lo habría evitado.

   Después de cada una, comprobad con [`solucion/README.md`](solucion/README.md). Repetid hasta que salgan las seis (`romper.sh N` para una concreta). Si `server` queda en un estado raro, déjalo como nuevo con el [lab 06](../lab-06-reconstruir-un-servidor/README.md).

5. **Las preguntas.** Contesta en voz alta, en menos de un minuto cada una, las seis preguntas de la [teoría 03](../../1-teoria/03-la-defensa.md#las-preguntas). Grábate o que te escuche tu pareja. Para cada respuesta que dudes: abre el archivo del kit que la contesta, y apunta en el guion dónde está.

## Criterios de éxito

- [ ] Un guion con los seis bloques, comandos, salida esperada y lo que demuestra cada uno (paso 1)
- [ ] El guion ensayado entero en 15 minutos o menos (paso 2)
- [ ] La avería del paso 3 resuelta con el método: capa, consola, causa, arreglo, comprobación (paso 3)
- [ ] Las seis averías de `romper.sh` diagnosticadas y arregladas, cada una en menos de 10 minutos (paso 4)
- [ ] Las seis preguntas contestadas en voz alta, con el archivo del kit que respalda cada respuesta (paso 5)

## Reto extra

Añade una séptima avería a `romper.sh` que tu kit **no** diagnostique bien (por ejemplo, `MaxStartups 1:100:1` con un master abierto, o un `ForceCommand` en un `Match User alumno`). Prueba qué dice `bin/doctor`, y decide qué cambiarías en el kit o en el RUNBOOK para que la próxima persona la encuentre antes.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 06 — Reconstruir un servidor](../lab-06-reconstruir-un-servidor/README.md) | [Proyecto — ssh-infra-kit: integración, documentación y defensa](../../3-proyecto/README.md) → |

[↑ Semana 14](../../README.md)
