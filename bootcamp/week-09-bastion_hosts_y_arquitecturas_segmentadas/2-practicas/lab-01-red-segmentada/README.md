# Lab 01 — Una red que no ves

⏱ Duración estimada: ~60 min

## Objetivo

Dibujar el mapa del laboratorio: qué máquina alcanza a cuál. Comprobar que `interno` no existe para tu equipo, entrar en él con dos sesiones encadenadas a través de `bastion`, y ver por qué esa forma de saltar es mala.

## Contexto

- Redes segmentadas y bastion: [teoría 01](../../1-teoria/01-redes-segmentadas-y-bastion.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación.** En tu equipo, desde la raíz del repositorio:
   ```bash
   docker compose up -d --force-recreate bastion interno server
   docker compose run --rm client
   ```
   `--force-recreate` deja los tres servidores como recién instalados: cada lab empieza limpio. **En el cliente**, `known_hosts` y una llave instalada en `bastion`, `server` e `interno`:
   ```bash
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh ~/w
   ssh-keyscan -t ed25519 bastion server 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/id_ed25519
   sshpass -e ssh-copy-id -f bastion 2>&1 | grep 'Number of'
   sshpass -e ssh-copy-id -f server 2>&1 | grep 'Number of'
   ssh bastion ssh-keyscan -t ed25519 interno 2>/dev/null >> ~/.ssh/known_hosts
   sshpass -e ssh-copy-id -f -o ProxyJump=bastion interno 2>&1 | grep 'Number of'
   ```
   ```
   Number of key(s) added: 1
   Number of key(s) added: 1
   Number of key(s) added: 1
   ```
   - La llave no tiene frase (`-N ''`) y `SSHPASS` lleva la contraseña: **solo en el laboratorio**.
   - Las dos últimas líneas preparan `interno`, al que no llegas directamente: le piden su host key **a `bastion`** y copian la llave saltando por él. El lab 02 explica cómo hacerlo sin fiarte del bastion. Los labs siguientes repiten este paso 0.

1. **Dónde está cada uno.** `hostname -I` lista las IP de una máquina, una por red; `getent hosts` pregunta un nombre al sistema, como haría `ssh`:
   ```bash
   hostname -I
   getent hosts interno; echo "código: $?"
   ssh bastion 'hostname -I; getent hosts interno server'
   ```
   ```
   172.20.0.4 
   código: 2
   172.19.0.2 172.20.0.2 
   172.19.0.3      interno
   172.20.0.3      server
   ```
   - Tu equipo tiene una IP: solo está en la red `publica` (`172.20.x.x`).
   - `bastion` tiene dos: `publica` y `privada` (`172.19.x.x`). Es la única máquina en las dos.
   - Para tu equipo, `interno` **ni siquiera es un nombre** (código 2: no encontrado). Docker solo lo resuelve dentro de su red. Las IP serán otras en tu laboratorio.

2. **Desde fuera no se llega.**
   ```bash
   nc -zv -w 2 interno 22
   ssh interno
   ssh bastion 'nc -zv -w 2 interno 22'
   ```
   ```
   nc: getaddrinfo for host "interno" port 22: Name or service not known
   ssh: Could not resolve hostname interno: Name or service not known
   Connection to interno (172.19.0.3) 22 port [tcp/ssh] succeeded!
   ```
   `nc -z` comprueba si un puerto acepta conexiones (semana 08). Aunque supieras su IP, la red `privada` es `internal: true`: no tiene ruta desde ninguna otra red.

3. **Dos sesiones encadenadas.** Entra en `bastion` y, desde allí, en `interno`:
   ```bash
   ssh -t bastion ssh interno hostname
   ```
   ```
   The authenticity of host 'interno (172.19.0.3)' can't be established.
   ED25519 key fingerprint is SHA256:483eGtfnnmJy3doWjmnH6pTWeTnSl1r2FtymhIDk9CY.
   This key is not known by any other names.
   Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
   Warning: Permanently added 'interno' (ED25519) to the list of known hosts.
   alumno@interno's password:
   interno
   Connection to bastion closed.
   ```
   Escribe `yes` y la contraseña `alumno` (**solo del laboratorio**). `-t` pide una terminal para el `ssh` de dentro, que la necesita para preguntar. Funciona, pero fíjate en **quién** hace cada cosa:
   - La pregunta de la host key la hace el `ssh` **del bastion**, y la guarda en **su** `known_hosts`. Tú solo ves lo que el bastion te enseña.
   - La contraseña la recibe el `ssh` del bastion. Tu llave no sirve: está en tu equipo, y el `ssh` que conecta con `interno` corre en el bastion.

4. **La tentación: tu llave en el bastion.** Para no escribir la contraseña, podrías copiar tu llave privada al bastion. Mira qué tiene ahora:
   ```bash
   ssh bastion 'ls -A ~/.ssh'
   ```
   ```
   authorized_keys
   known_hosts
   ```
   Si copias ahí tu `id_ed25519`, cualquiera con `root` en el bastion (un administrador, o un atacante que lo comprometa) la copia y entra donde tú entras, para siempre. **No lo hagas.** El lab 05 enseña por qué tampoco sirve reenviar el agente, y el lab 02, la forma correcta.

5. **Qué ve `interno`.** `SSH_CONNECTION` dice desde qué IP y puerto llegó la conexión, y a qué IP y puerto:
   ```bash
   ssh -t bastion ssh interno 'echo \$SSH_CONNECTION'
   ```
   ```
   alumno@interno's password:
   172.19.0.2 57102 172.19.0.3 22
   Connection to bastion closed.
   ```
   `172.19.0.2` es el bastion. `interno` nunca ve tu IP: para él, todo llega desde el bastion. La `\` delante de `$` hace que la variable la expanda la shell de `interno`, no la del bastion.

6. **Cada puerta abre solo su red.** Completa el mapa:
   ```bash
   ssh bastion 'nc -zv -w 2 server 22; nc -zv -w 2 db 5432'
   ssh server 'nc -zv -w 2 interno 22; nc -zv -w 2 db 5432'
   ```
   ```
   Connection to server (172.20.0.3) 22 port [tcp/ssh] succeeded!
   nc: getaddrinfo for host "db" port 5432: Name or service not known
   nc: getaddrinfo for host "interno" port 22: Name or service not known
   Connection to db (172.25.0.2) 5432 port [tcp/postgresql] succeeded!
   ```
   | Desde \ hacia | `server` | `bastion` | `interno` | `db` |
   |---|:-:|:-:|:-:|:-:|
   | tu equipo | ✅ | ✅ | ❌ | ❌ |
   | `bastion` | ✅ | — | ✅ | ❌ |
   | `server` | — | ✅ | ❌ | ✅ |

   Si alguien compromete `server`, llega a `db`, pero no a `interno`; si compromete `bastion`, al revés. Es la segmentación de la [teoría 01](../../1-teoria/01-redes-segmentadas-y-bastion.md#por-qué-no-todo-está-en-internet).

7. **Lo que viene.** Prueba esto, que el lab 02 explica:
   ```bash
   ssh -J bastion interno hostname
   ```
   ```
   interno
   ```
   Sin contraseña, sin terminal extra, y sin que el bastion tenga nada tuyo.

## Criterios de éxito

- [ ] Explicas qué redes tiene cada máquina y por qué tu equipo no resuelve `interno` (pasos 1 y 2)
- [ ] Entras en `interno` con dos sesiones encadenadas y dices quién comprueba la host key y quién se autentica (paso 3)
- [ ] Explicas por qué no se copia una llave privada al bastion (paso 4)
- [ ] Explicas desde qué IP ve `interno` las conexiones (paso 5)
- [ ] Completas el mapa de quién alcanza a quién (paso 6)

## Reto extra

Con dos sesiones encadenadas, ¿cómo copiarías un archivo de tu equipo a `interno` con `scp`? Hazlo sin `-J` ni `ProxyJump` y cuenta cuántas órdenes y contraseñas necesitas. Borra después lo que hayas dejado en el bastion.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Índice de labs](../README.md) | [Lab 02 — ProxyJump: un `ssh` dentro de otro](../lab-02-proxyjump/README.md) → |

[↑ Semana 09](../../README.md)
