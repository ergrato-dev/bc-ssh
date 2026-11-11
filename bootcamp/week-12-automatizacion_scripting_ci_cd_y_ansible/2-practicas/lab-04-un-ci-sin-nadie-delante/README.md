# Lab 04 — Un CI sin nadie delante

⏱ Duración estimada: ~60 min

## Objetivo

Hacer lo que hace un runner de CI: un entorno vacío (sin `~/.ssh`, sin agente) que recibe la llave y el `known_hosts` como variables, los escribe en una carpeta temporal que borra al salir y despliega con `BatchMode` y `StrictHostKeyChecking yes`. Ver qué pasa con `StrictHostKeyChecking no` cuando alguien se hace pasar por el servidor, y leer un workflow de GitHub Actions.

## Contexto

- Secretos, `known_hosts` y GitHub Actions: [teoría 02](../../1-teoria/02-despliegue-desde-ci.md#los-secretos).
- **La contraseña `alumno` y las llaves sin frase de este lab son solo para el laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-ssh-en-scripts/README.md) y los pasos 1 a 3 del [lab 03](../lab-03-llave-de-despliegue/README.md) (la llave `ci` con su `puerta` en `server`). Y la web que publicará el CI:
   ```bash
   mkdir -p ~/w/web; echo v2 > ~/w/web/VERSION; echo hola > ~/w/web/index.html
   ```

1. **El script del runner.**
   ```bash
   cat > ~/w/ci.sh <<'FIN'
   #!/usr/bin/env bash
   # ci.sh: lo que haría un runner de CI. Recibe los secretos como variables.
   set -euo pipefail
   : "${CI_SSH_KEY:?falta}" "${CI_KNOWN_HOSTS:?falta}"
   d=$(mktemp -d)
   trap 'rm -rf "$d"' EXIT
   umask 077
   printf "%s\n" "$CI_SSH_KEY" > "$d/llave"
   printf "%s\n" "$CI_KNOWN_HOSTS" > "$d/known_hosts"
   ssh_ci() {
     ssh -F /dev/null -i "$d/llave" -o IdentitiesOnly=yes -o BatchMode=yes \
         -o UserKnownHostsFile="$d/known_hosts" -o StrictHostKeyChecking=yes "$@"
   }
   tar -czf - -C web . | ssh_ci alumno@server publicar
   echo "carpeta temporal: $d"
   FIN
   chmod +x ~/w/ci.sh
   ```
   - `: "${VAR:?falta}"`: sin la variable, sale con error antes de hacer nada.
   - `trap ... EXIT`: la carpeta se borra al salir, también si `ssh` falla a mitad y `set -e` corta el script.
   - `umask 077`: la llave nace con permisos 600; `ssh` rechaza una llave que otros pueden leer.
   - `-F /dev/null`: ninguna configuración del runner cambia lo que hace `ssh`.

2. **Los secretos.** En un CI de verdad los guardas una vez en su almacén de secretos. Aquí, en variables. El `known_hosts` sale del tuyo, que comprobaste en el paso 0, no de un `ssh-keyscan` en el runner:
   ```bash
   KH=$(ssh-keygen -F server | grep -v '^#')
   echo "$KH" | wc -l
   ```
   ```
   3
   ```
   Tres líneas: la del `ssh-keyscan` del paso 0 y dos más que `ssh` añadió solo (`UpdateHostKeys`) con las otras host keys de `server`, en forma cifrada (`|1|...`, `HashKnownHosts`).

3. **El despliegue.** `env -i` vacía el entorno: sin `HOME` real, sin `SSH_AUTH_SOCK`, como un runner recién creado:
   ```bash
   cd ~/w
   env -i PATH=/usr/bin:/bin HOME=$(mktemp -d) CI_SSH_KEY="$(cat ~/.ssh/ci)" CI_KNOWN_HOSTS="$KH" ./ci.sh; echo "código: $?"
   ```
   ```
   publicada v2
   carpeta temporal: /tmp/tmp.xiQu3GJW2d
   código: 0
   ```
   Comprueba que la carpeta ya no existe (usa la tuya): `ls /tmp/tmp.xiQu3GJW2d` da `No such file or directory`.

4. **Sin un secreto.**
   ```bash
   env -i PATH=/usr/bin:/bin HOME=$(mktemp -d) CI_KNOWN_HOSTS="$KH" ./ci.sh; echo "código: $?"
   ```
   ```
   ./ci.sh: line 4: CI_SSH_KEY: falta
   código: 1
   ```

5. **Un impostor.** `HostKeyAlias=server` hace que `ssh` compruebe la llave de `bastion` como si fuera la de `server`: es lo que verías si alguien desviara el nombre `server` a otra máquina. Primero con lo que se ve en muchos CI:
   ```bash
   H=$(mktemp -d)
   ssh -F /dev/null -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=$H/kh -o HostKeyAlias=server bastion hostname; echo "código: $?"
   ```
   ```
   Warning: Permanently added 'server' (ED25519) to the list of known hosts.
   bastion
   código: 0
   ```
   Entró en la máquina equivocada sin un error: tu despliegue (y lo que lleve) habría ido al impostor. Con el `known_hosts` comprobado:
   ```bash
   ssh -F /dev/null -o BatchMode=yes -o StrictHostKeyChecking=yes -o HostKeyAlias=server bastion hostname 2>&1 | grep -E "IDENTIFICATION|verification"
   ```
   ```
   @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
   Host key verification failed.
   ```

6. **Un runner sin `known_hosts`.** `StrictHostKeyChecking yes` con un `known_hosts` vacío no conecta a nada:
   ```bash
   ssh -F /dev/null -o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$H/vacio server true; echo "código: $?"
   ```
   ```
   No ED25519 host key is known for server and you have requested strict checking.
   Host key verification failed.
   código: 255
   ```
   Por eso el `known_hosts` es un secreto más: sin él, la única forma de que «funcione» es apagar la comprobación.

7. **Lo que no se hace con un secreto.** Añade `set -x` en la segunda línea de `~/w/ci.sh`, repite el paso 3 y mira la salida. Después quítalo.
   - `set -x` imprime cada comando con sus variables ya expandidas: la llave entera, en el log del CI.
   - GitHub tapa los valores exactos de los secretos en el log; no lo que derives de ellos.

8. **Un workflow de GitHub Actions.** Lee el del proyecto, [`ci/github-actions.yml`](../../3-proyecto/solucion/ci/github-actions.yml), y responde en `~/w/notas.md`: ¿cuándo se ejecuta?, ¿qué puede hacer su token?, ¿qué pasa si haces dos pushes seguidos?, ¿en qué paso entran los secretos y por qué solo en ese?

## Criterios de éxito

- [ ] Explicas `trap`, `umask 077` y `-F /dev/null` en `ci.sh` (paso 1)
- [ ] Despliegas en un entorno vacío y compruebas que no queda nada en disco (paso 3)
- [ ] Explicas qué pasa con `StrictHostKeyChecking no` ante un impostor, y qué pasa con el `known_hosts` comprobado (paso 5)
- [ ] Explicas por qué el `known_hosts` es un secreto del CI y no un `ssh-keyscan` (pasos 2 y 6)
- [ ] Explicas por qué `set -x` es peligroso con secretos (paso 7)
- [ ] Respondes las cuatro preguntas del workflow (paso 8)

## Reto extra

Cambia `ci.sh` para que use un `ssh-agent` propio en lugar del archivo: `eval "$(ssh-agent -s)"`, `ssh-add - <<< "$CI_SSH_KEY"` y `ssh-agent -k` en el `trap`. ¿Qué ganas y qué pierdes?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 03 — Una llave de despliegue](../lab-03-llave-de-despliegue/README.md) | [Lab 05 — Ansible sin playbook](../lab-05-ansible-ad-hoc/README.md) → |

[↑ Semana 12](../../README.md)
