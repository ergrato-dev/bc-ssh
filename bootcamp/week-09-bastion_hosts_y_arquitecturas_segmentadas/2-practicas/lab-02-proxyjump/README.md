# Lab 02 — ProxyJump: un `ssh` dentro de otro

⏱ Duración estimada: ~60 min

## Objetivo

Entrar en `interno` con `ssh -J`, y ver que las dos conexiones salen de tu equipo. Verificar la host key de `interno` tú mismo, comprobar que el bastion no puede leer la sesión, copiar archivos a través del salto y encadenar varios saltos.

## Contexto

- Cómo funciona `-J`, la host key de un host interno y qué ve el bastion: [teoría 02](../../1-teoria/02-proxyjump-y-proxycommand.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-red-segmentada/README.md). Abre además **una segunda terminal en tu equipo** (no en el contenedor), en la raíz del repositorio.

1. **Dos conexiones, las dos tuyas.**
   ```bash
   ssh -v -J bastion interno true 2>&1 | grep -E 'proxy command|Authenticated to|Server host key'
   ```
   ```
   debug1: Executing proxy command: exec ssh -v -W '[interno]:22' bastion
   debug1: Server host key: ssh-ed25519 SHA256:KbYouQM0YPwagd76BUIJHRT5XIqzp4IThE0xmPA6eD4
   Authenticated to bastion ([172.20.0.2]:22) using "publickey".
   debug1: Server host key: ssh-ed25519 SHA256:483eGtfnnmJy3doWjmnH6pTWeTnSl1r2FtymhIDk9CY
   Authenticated to interno (via proxy) using "publickey".
   ```
   - `-J bastion`: tu `ssh` lanza otro, `ssh -W '[interno]:22' bastion`, que conecta con el bastion y le pide un canal hasta `interno:22`.
   - Tu `ssh` habla con `interno` a través de ese canal: **dos host keys** comprobadas en **tu** `known_hosts` y **dos autenticaciones** con **tu** llave. `(via proxy)`: la segunda fue por el canal.
   - `2>&1`: los mensajes de `-v` van a la salida de errores; así `grep` los ve.

2. **La host key de `interno`, verificada por ti.** Olvídala y vuelve a entrar sin dejar que `ssh` pregunte:
   ```bash
   ssh-keygen -R interno
   ssh -o StrictHostKeyChecking=yes -J bastion interno hostname
   ```
   ```
   # Host interno found: line 7
   /home/alumno/.ssh/known_hosts updated.
   Original contents retained as /home/alumno/.ssh/known_hosts.old
   No ED25519 host key is known for interno and you have requested strict checking.
   Host key verification failed.
   ```
   `ssh-keyscan` no llega a `interno`. Pide la huella por un canal que no es SSH: en la **segunda terminal**, la de tu equipo:
   ```bash
   docker compose exec interno ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
   ```
   ```
   256 SHA256:483eGtfnnmJy3doWjmnH6pTWeTnSl1r2FtymhIDk9CY root@interno (ED25519)
   ```
   De vuelta en el cliente, conecta y, cuando pregunte, **pega esa huella** en lugar de escribir `yes`:
   ```bash
   ssh -J bastion interno hostname
   ```
   ```
   The authenticity of host 'interno (<no hostip for proxy command>)' can't be established.
   ED25519 key fingerprint is SHA256:483eGtfnnmJy3doWjmnH6pTWeTnSl1r2FtymhIDk9CY.
   This key is not known by any other names.
   Are you sure you want to continue connecting (yes/no/[fingerprint])? SHA256:483eGtfnnmJy3doWjmnH6pTWeTnSl1r2FtymhIDk9CY
   Warning: Permanently added 'interno' (ED25519) to the list of known hosts.
   interno
   ```
   - Con la huella pegada, `ssh` la compara por ti: si no coincide, vuelve a preguntar. Es más seguro que leer dos cadenas de 43 caracteres.
   - `<no hostip for proxy command>`: `ssh` no conectó él mismo con `interno`, así que no sabe su IP. La línea de `known_hosts` lleva solo el nombre.
   - Compara con el lab 01: allí preguntaba el `ssh` del bastion. Ahora la decisión es tuya, aunque el bastion esté comprometido.

3. **Qué ve el bastion.** Captura en el bastion el tráfico hacia `interno` mientras mandas algo reconocible:
   ```bash
   (ssh bastion 'sudo timeout 5 tcpdump -i any -nn -A host interno and port 22 2>/dev/null' > ~/w/dump &)
   sleep 1.5
   ssh -J bastion interno 'echo secreto-de-interno'
   sleep 4
   grep -ac secreto ~/w/dump
   grep -aoE 'SSH-2.0-[A-Za-z0-9_.-]+' ~/w/dump | sort -u
   ```
   ```
   secreto-de-interno
   0
   SSH-2.0-OpenSSH_9.6p1
   ```
   - `tcpdump` (semana 08): `-A` enseña el contenido como texto. `sudo` sin contraseña: **solo en el laboratorio**.
   - `grep -c` cuenta líneas: `secreto` aparece **0** veces. Lo único legible es el saludo `SSH-2.0-...`, que se manda antes de cifrar.
   - Con las sesiones encadenadas del lab 01, el bastion descifraba y volvía a cifrar: lo habría visto todo. Con `-J`, la conexión con `interno` está cifrada de extremo a extremo.

4. **Leer la host key sin tocar tu `known_hosts`.** Para automatizar el paso 2 (el kit lo hace en el proyecto), conecta con un `known_hosts` temporal donde `accept-new` guarde la llave sin preguntar:
   ```bash
   rm -f ~/w/kh
   ssh -J bastion -o UserKnownHostsFile=~/w/kh -o StrictHostKeyChecking=accept-new -o BatchMode=yes interno true
   ssh-keygen -lf ~/w/kh
   ```
   ```
   Warning: Permanently added 'interno' (ED25519) to the list of known hosts.
   256 SHA256:483eGtfnnmJy3doWjmnH6pTWeTnSl1r2FtymhIDk9CY |1|AJ3htc50BUsJXTnuD0ncGh3GOZQ=|L9ZWo8UBTpKpXA+i3whbDEBGhIA= (ED25519)
   ```
   - `-o` en la línea de órdenes solo afecta al `ssh` de fuera; el del salto sigue usando tu `known_hosts` para el bastion. La confianza va de un host al siguiente.
   - `BatchMode=yes`: nunca pregunta nada. Aunque la autenticación fallara, la host key llega antes y ya estaría en `~/w/kh`.
   - El nombre sale cifrado (`|1|...`): Ubuntu trae `HashKnownHosts yes` en `/etc/ssh/ssh_config`. Después, comparas la huella con la que obtuviste por otro canal.

5. **Archivos a través del salto.** `scp` y `sftp` aceptan `-J`; a `rsync` se lo dices en el `ssh` que usa:
   ```bash
   echo hola > ~/w/nota.txt
   scp -J bastion ~/w/nota.txt interno:
   rsync -a -e 'ssh -J bastion' ~/w/nota.txt interno:copia.txt
   echo ls | sftp -J bastion interno
   ```
   ```
   Connected to interno.
   sftp> ls
   copia.txt  nota.txt   
   ```
   Nada pasa por el disco del bastion: los archivos viajan dentro de la conexión cifrada con `interno`.

6. **Varios saltos.** `-J` acepta una lista: salta por `server`, después por `bastion`, y llega a `interno`:
   ```bash
   ssh -J server,bastion interno 'echo $SSH_CONNECTION'
   ssh -J server bastion 'echo $SSH_CONNECTION'
   ssh -v -J server,bastion interno true 2>&1 | grep 'proxy command'
   ```
   ```
   172.19.0.2 53176 172.19.0.3 22
   172.20.0.3 38258 172.20.0.2 22
   debug1: Executing proxy command: exec ssh -J server -v -W '[interno]:22' bastion
   debug1: Executing proxy command: exec ssh -v -W '[bastion]:22' server
   ```
   - `interno` ve llegar la conexión desde el bastion (`172.19.0.2`); el bastion, desde `server` (`172.20.0.3`). Cada uno solo ve al anterior.
   - Los tres `ssh` corren en tu equipo, uno dentro de otro: ninguna máquina intermedia necesita llaves. En el laboratorio no hace falta pasar por `server`; en la vida real, es la forma de cruzar dos redes segmentadas seguidas.

## Criterios de éxito

- [ ] Explicas, con la salida de `-v`, cuántas host keys y autenticaciones hay en un `-J` y dónde ocurren (paso 1)
- [ ] Añades la host key de `interno` comparando la huella obtenida por otro canal (paso 2)
- [ ] Demuestras con `tcpdump` que el bastion no lee la sesión (paso 3)
- [ ] Lees una host key a un `known_hosts` temporal a través del salto (paso 4)
- [ ] Copias archivos con `scp`, `rsync` y `sftp` a través del salto (paso 5)
- [ ] Encadenas dos saltos y dices qué IP ve cada máquina (paso 6)

## Reto extra

Con `ssh -J bastion -L 2222:localhost:22 interno` abres un túnel cuyo extremo está en `interno`. ¿Por qué `ssh -p 2222 localhost` da un aviso de host key? ¿Qué opción de `ssh_config` lo arregla sin tocar `known_hosts`? (Pista: la teoría 02 la nombra.)

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 01 — Una red que no ves](../lab-01-red-segmentada/README.md) | [Lab 03 — `ProxyCommand` y `ssh -W`](../lab-03-proxycommand-y-w/README.md) → |

[↑ Semana 09](../../README.md)
