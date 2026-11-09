# Lab 07 — Quién salta a dónde, y cómo cortarlo

⏱ Duración estimada: ~60 min

## Objetivo

Hacer que el bastion registre a dónde salta cada uno, ver quién está saltando ahora y qué ve el host interno. Cortar el acceso de alguien a toda la red privada desde un solo sitio, cerrar las conexiones que ya tenía abiertas, y ver qué pasa cuando el bastion cae.

## Contexto

- Logs, cortes y el bastion como punto único: [teoría 03](../../1-teoria/03-endurecer-el-bastion.md#saber-quién-salta-a-dónde).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación.** Sigue con el bastion del [lab 06](../lab-06-bastion-endurecido/README.md), con `salto` y su `Match`. Si lo recreaste, repite el paso 0 del [lab 01](../lab-01-red-segmentada/README.md) y los pasos 0, 1 y 3 del lab 06. Abre además **una segunda terminal en tu equipo**, en la raíz del repositorio: los logs de los servidores se leen desde ahí.

1. **Lo que el log dice ahora.** Salta una vez bien y una vez a un destino prohibido, y mira el log del bastion desde la **segunda terminal**:
   ```bash
   ssh -J salto@bastion interno hostname
   ssh -J salto@bastion server hostname 2>/dev/null
   ```
   ```bash
   docker compose logs --no-log-prefix bastion | grep -E 'Accepted publickey for salto|target|denied' | tail -3
   ```
   ```
   Accepted publickey for salto from 172.20.0.4 port 44302 ssh2: ED25519 SHA256:KvVs7zr36e/wM7pG/vWX6BgGZ3mJhXKZnHvhHeNGy68
   Accepted publickey for salto from 172.20.0.4 port 44314 ssh2: ED25519 SHA256:KvVs7zr36e/wM7pG/vWX6BgGZ3mJhXKZnHvhHeNGy68
   Received request from 172.20.0.4 port 44314 to connect to host server port 22, but the request was denied.
   ```
   - `docker compose logs`: lo que escribe `sshd` (arranca con `-e`, a la salida de errores). `--no-log-prefix` quita el nombre del contenedor.
   - Sabes qué llave entró (`SHA256:KvVs...`) y desde dónde. El rechazo dice su destino. El salto **permitido**, no: con `LogLevel INFO` o `VERBOSE`, el log no dice a dónde fue.

2. **`LogLevel DEBUG1`, solo para los saltadores.** Añádelo al `Match` y repite:
   ```bash
   R='sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ssh bastion "echo '    LogLevel DEBUG1' | sudo tee -a /etc/ssh/sshd_config.d/40-salto.conf >/dev/null; sudo sshd -t && $R"
   ssh -J salto@bastion interno hostname
   ssh -J salto@bastion server hostname 2>/dev/null
   ```
   En la segunda terminal:
   ```bash
   docker compose logs --no-log-prefix bastion | grep -E 'Accepted publickey for salto|target|denied' | tail -5
   ```
   ```
   Accepted publickey for salto from 172.20.0.4 port 44330 ssh2: ED25519 SHA256:KvVs7zr36e/wM7pG/vWX6BgGZ3mJhXKZnHvhHeNGy68
   debug1: server_request_direct_tcpip: originator 127.0.0.1 port 65535, target interno port 22
   Accepted publickey for salto from 172.20.0.4 port 44342 ssh2: ED25519 SHA256:KvVs7zr36e/wM7pG/vWX6BgGZ3mJhXKZnHvhHeNGy68
   debug1: server_request_direct_tcpip: originator 127.0.0.1 port 65535, target server port 22
   Received request from 172.20.0.4 port 44342 to connect to host server port 22, but the request was denied.
   ```
   - `tee -a`: añade al final del archivo, dentro del `Match` (que dura hasta el final del archivo).
   - Cada salto tiene ahora su `target`. `originator 127.0.0.1 port 65535` no es real: así marca `ssh -W` sus canales.
   - `DEBUG1` solo en el `Match`: para `alumno` sigue el nivel normal. Para todos llenaría el log y registraría detalles de las sesiones.

3. **Quién está saltando ahora.** Con un salto abierto en segundo plano, mira el bastion:
   ```bash
   ssh -J salto@bastion interno 'sleep 6' &
   sleep 2
   ssh bastion 'ps -o user,pid,args -u salto; sudo ss -tn state established "( dport = :22 )" | grep -v 172.20; who'
   wait
   ```
   ```
   USER         PID COMMAND
   salto        922 sshd: salto
   Recv-Q Send-Q Local Address:Port  Peer Address:Port
   0      0         172.19.0.2:50330   172.19.0.3:22
   ```
   - `ps -u salto`: los procesos de `salto`. `sshd: salto` es su conexión, sin ningún comando debajo: no hay sesión, solo el canal.
   - `ss -tn state established "( dport = :22 )"`: las conexiones TCP abiertas **hacia** un puerto 22. `grep -v 172.20` quita las de la red `publica` (las tuyas con el bastion): queda la del bastion con `interno`.
   - `who` no dice nada: lista terminales, y `salto` no tiene ninguna. Un salto no aparece en `who` ni en `last`.

4. **Lo que ve `interno`.**
   ```bash
   ssh -J salto@bastion interno 'echo $SSH_CONNECTION'
   ```
   ```
   172.19.0.2 50336 172.19.0.3 22
   ```
   En la segunda terminal:
   ```bash
   docker compose logs --no-log-prefix interno | grep Accepted | tail -1
   ```
   ```
   Accepted publickey for alumno from 172.19.0.2 port 50336 ssh2: ED25519 SHA256:KvVs7zr36e/wM7pG/vWX6BgGZ3mJhXKZnHvhHeNGy68
   ```
   Para `interno`, todo llega desde el bastion (`172.19.0.2`). Para saber quién fue, cruzas la hora y la huella con el log del bastion. Si toda la empresa usara una sola llave o una sola cuenta de salto, no podrías.

5. **Cortar el acceso.** Deja una sesión abierta, quita la llave de `salto` del bastion e intenta entrar de nuevo:
   ```bash
   ssh -J salto@bastion interno 'sleep 30; echo terminado' &
   sleep 2
   ssh bastion 'sudo truncate -s 0 ~salto/.ssh/authorized_keys'
   ssh -o BatchMode=yes -J salto@bastion interno hostname; echo "código: $?"
   ```
   ```
   salto@bastion: Permission denied (publickey,password).
   código: 255
   ```
   - `truncate -s 0`: deja el archivo vacío. Con un solo cambio, en un solo sitio, `salto` ya no llega a **ningún** host de la red privada, aunque tu llave siga en el `authorized_keys` de `interno`.
   - `BatchMode=yes`: sin preguntar contraseña. El bastion del laboratorio aún acepta contraseñas; el del kit, no.

6. **Lo que sigue abierto.** La sesión del paso 5 **sigue viva**: ya estaba autenticada. Ciérrala desde el bastion:
   ```bash
   ssh bastion 'sudo pkill -u salto'
   wait
   ```
   ```
   Connection closed by UNKNOWN port 65535
   Connection to bastion closed by remote host.
   client_loop: send disconnect: Broken pipe
   ```
   - `pkill -u salto`: termina todos los procesos de `salto`, sus conexiones incluidas. `terminado` nunca aparece.
   - Igual que un master (semana 05): quitar una llave no corta lo que ya entró. Para cortar a alguien: su llave **y** sus procesos.

7. **Si el bastion cae.** En la **segunda terminal**, para el bastion; en el cliente, intenta entrar; después, arráncalo:
   ```bash
   docker compose stop bastion
   ```
   ```bash
   ssh -J bastion interno hostname; echo "código: $?"
   ```
   ```
   ssh: Could not resolve hostname bastion: Name or service not known
   Connection closed by UNKNOWN port 65535
   código: 255
   ```
   ```bash
   docker compose start bastion
   ```
   Nadie entra en la red privada mientras el bastion no esté. `start` (no `--force-recreate`) conserva sus host keys y su configuración. En producción: dos bastiones, o un acceso de emergencia por la consola del proveedor.

## Criterios de éxito

- [ ] Explicas qué dice el log del bastion con `VERBOSE` y qué añade `DEBUG1` (pasos 1 y 2)
- [ ] Encuentras los saltos activos en el bastion y explicas por qué `who` no los ve (paso 3)
- [ ] Explicas desde qué IP ve `interno` las conexiones y cómo sabrías quién entró (paso 4)
- [ ] Cortas el acceso de una cuenta a toda la red privada y cierras sus conexiones abiertas (pasos 5 y 6)
- [ ] Explicas el riesgo de tener un solo bastion (paso 7)

## Reto extra

Haz que `interno` solo acepte tu llave si llega desde el bastion: en su `~/.ssh/authorized_keys`, pon delante de la llave `from="IP_DEL_BASTION"` (la del paso 4). Compruébalo con `-J salto@bastion` y piensa: ¿qué ataque evita, si `interno` ya está en una red a la que solo llega el bastion?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 06 — Un bastion que solo deja saltar](../lab-06-bastion-endurecido/README.md) | [Proyecto — ssh-infra-kit: acceso a `interno` vía `bastion`](../../3-proyecto/README.md) → |

[↑ Semana 09](../../README.md)
