# Lab 01 — SSH dentro de un script

⏱ Duración estimada: ~60 min

## Objetivo

Usar `ssh` como un comando más dentro de un script: leer su código de salida, que no pregunte nada (`BatchMode`), que no espere para siempre (`ConnectTimeout`), que no se coma la entrada de un bucle (`-n`) y que los argumentos lleguen enteros al otro lado (`printf %q`, `bash -s`).

## Contexto

- Entrada, salidas, código y comillas: [teoría 01](../../1-teoria/01-ssh-en-scripts.md).
- **La contraseña `alumno` y las llaves sin frase de estos labs son solo para el laboratorio.**

## Instrucciones

0. **Preparación.** En tu equipo, desde la raíz del repositorio (si no lo hiciste ya esta semana, antes `docker compose build`: la imagen trae Ansible):
   ```bash
   docker compose up -d --force-recreate server bastion interno
   docker compose run --rm client
   ```
   `--force-recreate` deja los servidores como recién instalados: cada lab empieza limpio. **En el cliente**, `known_hosts` y una llave de administrador en `server` y `bastion`:
   ```bash
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh ~/w
   ssh-keyscan -t ed25519 server bastion 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -N '' -C admin@client -f ~/.ssh/id_ed25519
   sshpass -e ssh-copy-id -f server 2>&1 | grep 'Number of'
   sshpass -e ssh-copy-id -f bastion 2>&1 | grep 'Number of'
   ```
   ```
   Number of key(s) added: 1
   Number of key(s) added: 1
   ```
   Llave sin frase (`-N ''`) y la contraseña en `SSHPASS`: **solo en el laboratorio**.

1. **El código de salida.**
   ```bash
   ssh server "exit 7"; echo "código: $?"
   ssh server false; echo "código: $?"
   ssh nohay true; echo "código: $?"
   ```
   ```
   código: 7
   código: 1
   ssh: Could not resolve hostname nohay: Name or service not known
   código: 255
   ```
   El código es el del comando remoto, salvo 255: ese lo pone `ssh` cuando no llegó a ejecutar nada.

2. **Que no pregunte.** Sin llave (`-i /dev/null` con `IdentitiesOnly`), `ssh` pide la contraseña y tu script se queda esperando. Pruébalo y sal con Ctrl+C:
   ```bash
   ssh -i /dev/null -o IdentitiesOnly=yes server hostname
   ```
   ```
   Load key "/dev/null": error in libcrypto
   alumno@server's password:
   ```
   Ahora con `BatchMode`:
   ```bash
   ssh -o BatchMode=yes -i /dev/null -o IdentitiesOnly=yes server hostname; echo "código: $?"
   ```
   ```
   Load key "/dev/null": error in libcrypto
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   `BatchMode yes` convierte cualquier pregunta (contraseña, frase, `yes/no` de una host key nueva) en un fallo inmediato. Es lo que quieres en un script: que falle y se entere.

3. **Que no espere.** `10.255.255.1` no responde (los paquetes se pierden):
   ```bash
   time ssh -o ConnectTimeout=3 10.255.255.1 true; echo "código: $?"
   ```
   ```
   ssh: connect to host 10.255.255.1 port 22: Connection timed out

   real	0m3.006s
   ...
   código: 255
   ```
   Sin `ConnectTimeout`, el sistema espera unos 2 minutos por servidor. En un bucle de 50 servidores con 3 caídos, es la diferencia entre 10 s y 6 minutos.

4. **El bucle que se come la lista.**
   ```bash
   printf "server\nbastion\n" > ~/w/hosts
   while read -r h; do echo "== $h"; ssh "$h" hostname; done < ~/w/hosts
   ```
   ```
   == server
   server
   ```
   `bastion` no aparece: el primer `ssh` leyó el resto del archivo (su entrada) y se lo envió a `hostname`, que lo ignoró. Con `-n`:
   ```bash
   while read -r h; do echo "== $h"; ssh -n "$h" hostname; done < ~/w/hosts
   ```
   ```
   == server
   server
   == bastion
   bastion
   ```

5. **Las comillas se interpretan dos veces.**
   ```bash
   d="mi carpeta"
   ssh server mkdir -p "$d"; ssh server ls -d mi*
   ```
   ```
   mi
   ```
   Has creado `mi` y `carpeta`: `ssh` juntó los argumentos en `mkdir -p mi carpeta` y el shell de `server` los separó. Borra y repite con `printf %q`, que escapa el valor:
   ```bash
   ssh server "rm -rf mi carpeta"
   ssh server mkdir -p "$(printf %q "$d")"; ssh server ls -d mi*
   ```
   ```
   mi carpeta
   ```
   Y dónde se expande cada `$`:
   ```bash
   ssh server "echo \$HOSTNAME en \$(date +%Y)"; ssh server echo $HOSTNAME
   ```
   ```
   server en 2026
   client
   ```
   Escapado, lo expande `server`; sin escapar, tu shell, antes de enviar nada.

6. **Un script entero por la entrada.** Para más de una línea, `bash -s` lee el script de la entrada de `ssh`; `'FIN'` entre comillas evita que tu shell toque los `$`:
   ```bash
   ssh server bash -s -- "uno dos" <<'FIN'
   echo "argumentos: $#, el primero: $1"
   FIN
   ssh server bash -s -- "$(printf %q "uno dos")" <<'FIN'
   echo "argumentos: $#, el primero: $1"
   FIN
   ```
   ```
   argumentos: 2, el primero: uno
   argumentos: 1, el primero: uno dos
   ```
   Los argumentos de `bash -s` pasan por el shell remoto como cualquier otro: también con `%q`.

7. **Los errores del otro lado.**
   ```bash
   ssh server bash -s <<'FIN'
   set -e
   cd /no/existe
   echo "no llego"
   FIN
   echo "código: $?"
   ssh server "cat /etc/hostname; cat /no/existe" > ~/w/salida 2> ~/w/errores; echo "código: $?"
   cat ~/w/salida ~/w/errores
   ```
   ```
   bash: line 2: cd: /no/existe: No such file or directory
   código: 1
   código: 1
   server
   cat: /no/existe: No such file or directory
   ```
   - `set -e` dentro del script remoto lo para en el primer error, y el código llega a tu lado.
   - La salida y los errores remotos se redirigen por separado, como en local.

## Criterios de éxito

- [ ] Distingues un fallo de `ssh` (255) de uno del comando remoto (paso 1)
- [ ] Explicas qué hace `BatchMode` y por qué un script lo necesita (paso 2)
- [ ] Explicas por qué `ConnectTimeout` importa en un bucle (paso 3)
- [ ] Arreglas el bucle con `-n` y explicas qué pasaba (paso 4)
- [ ] Pasas un argumento con espacios entero con `printf %q` (pasos 5 y 6)
- [ ] Ejecutas un script remoto con `bash -s` y recoges su código y sus errores (paso 7)

## Reto extra

Escribe `~/w/remoto` que reciba `HOST` y un archivo con un script, y lo ejecute en el servidor con los argumentos que vengan detrás, escapados: `~/w/remoto server ~/w/info.sh "un argumento" otro`. Pruébalo con un `info.sh` que imprima `$#` y cada argumento en una línea.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Índice de labs](../README.md) | [Lab 02 — Muchos servidores](../lab-02-muchos-servidores/README.md) → |

[↑ Semana 12](../../README.md)
