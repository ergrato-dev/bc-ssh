# RUNBOOK — ssh-infra-kit

Un procedimiento por incidente, para seguirlo con prisa y sin pensar mucho. Cada uno dice cómo reconocerlo, qué hacer en orden y cómo comprobar que quedó resuelto. Los porqués están en el [README](README.md): aquí solo los pasos.

Antes de cualquier cambio en un servidor: **una sesión abierta** en él, que no cierras hasta comprobar que una conexión nueva entra.

## No puedo entrar

**Síntoma:** `ssh HOST` falla, cuelga o pide algo que no esperabas.

1. `bin/doctor HOST`: dice a dónde va la conexión, en qué capa falla y una pista. Sigue la pista.
2. Si dice `Permission denied`, el motivo solo lo sabe el servidor. Por la consola del proveedor (`docker compose exec server` en el laboratorio), o por otra cuenta que sí entra: `sudo /usr/sbin/sshd -d -p 2222` y, desde tu equipo, `bin/doctor HOST -p 2222 -o HostKeyAlias=HOST`. Lee la línea del servidor justo antes de `Failed`.
3. Si cambiaste una llave hace poco y otra conexión sí entra: puede ser un master viejo. `bin/mux stop` y repite.
4. Si te bloqueó fail2ban (`Connection refused` o la conexión cuelga desde tu IP y no desde otra): en el servidor, `sudo fail2ban-client set sshd unbanip TU_IP`.

**Comprobación:** `bin/doctor HOST` sale con 0 y escribe `entrada: publickey`.

## La host key cambió

**Síntoma:** `REMOTE HOST IDENTIFICATION HAS CHANGED` o `Host key verification failed`. `ssh` no entra, y es lo correcto.

1. **No borres la línea a ciegas.** Pregunta quién gestiona el servidor si lo reinstaló o rotó sus llaves.
2. Consigue la huella nueva **por otro camino**: la consola del proveedor (`sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`) o un mensaje firmado de quien lo gestiona.
3. Si no la consigues o no coincide con lo que `ssh` enseña: **no entres**. Trátalo como un ataque y avisa.
4. Si coincide: `ssh-keygen -R HOST` y `bin/kh-add HOST SHA256:...` (con `-J SALTO` si va detrás de un bastion).
5. Si es tu servidor y tu CI despliega en él: actualiza el secreto `KIT_KNOWN_HOSTS`.

**Comprobación:** `bin/doctor HOST` sale con 0 y su `host key:` es la huella del paso 2.

## Perdí una llave o un equipo

**Síntoma:** un portátil robado o perdido, una llave privada copiada donde no debía (un repositorio, un chat), o `bin/kit-check` dice `fallo secretos`.

Actúa como si alguien ya la tuviera. En este orden, el primer paso hoy mismo:

1. **Revoca.** `ca/ca-revoke LLAVE.pub` (la llave y todos sus certificados) e instala `revoked.krl` en cada servidor (`sudo install -m 644` en `/etc/ssh/`, o el playbook). Sin certificados: quita su línea de `authorized_keys` en cada servidor, buscando por el contenido de la llave, no por el comentario (`grep -vF`).
2. **Corta lo abierto.** En cada servidor, `sudo pkill -u USUARIO sshd` cierra las sesiones de esa cuenta (también los masters que ya entraron con la llave). Si es tu cuenta, cierra también la tuya: hazlo desde la consola del proveedor.
3. **Comprueba que no queda.** `ssh HOST cat .ssh/authorized_keys | bin/key-audit -` lista las llaves que quedan, con su comentario: ninguna debe ser la perdida.
4. **Una llave nueva.** `bin/key-new NOMBRE` en un equipo limpio, y el [alta](#alta-de-una-persona) de esa llave.
5. Si la llave estaba en git: bórrala del kit, y considera que sigue en el historial y en cada copia del repositorio. Revocarla es lo que la inutiliza, no borrarla.
6. Si era la llave del CI (`KIT_SSH_KEY`): crea otra, instálala, cambia el secreto, revoca la vieja.

**Comprobación:** con la llave perdida (si aún la tienes, o una copia de su pública y certificado), `ssh -i LLAVE -o IdentitiesOnly=yes -o ControlPath=none HOST true` falla con `Permission denied`; en el log del servidor, `revoked` o `not allowed`.

## Alta de una persona

**Síntoma:** alguien nuevo necesita entrar.

1. Ella crea su llave en su equipo (`bin/key-new`, con frase) y te manda **solo la pública**. Nunca le pidas ni le mandes una privada.
2. Comprueba la llave por otro camino que el mensaje que la trajo (su huella, `ssh-keygen -lf SU.pub`, por teléfono o en persona).
3. Con certificados: `ca/ca-sign SU.pub persona@equipo ROL` y le devuelves `SU-cert.pub`. Sin certificados: `bin/ak-line SU.pub` y añade la línea a `authorized_keys` de su cuenta.
4. Su cuenta en el grupo que le toca: `ssh-users`, `sftp-only`, `saltadores` o `dosfa` (en el playbook, o `sudo usermod -aG GRUPO USUARIO`).
5. Le pasas el kit (sin `~/.ssh-ca`) y le dices que empiece por [Instalar el kit en un equipo](README.md#instalar-el-kit-en-un-equipo).

**Comprobación:** desde su equipo, `bin/doctor HOST` sale con 0. En el log del servidor, `Accepted publickey for USUARIO` con su huella (y `ID persona@equipo` si es un certificado).

## Baja de una persona

**Síntoma:** alguien deja el equipo, o deja de necesitar el acceso.

1. Revoca sus llaves y certificados: `ca/ca-revoke` con cada serie de `emitidos.log` a su nombre, o con su llave pública. Instala `revoked.krl` en cada servidor.
2. Quita sus líneas de `authorized_keys` (en su cuenta y en cualquier cuenta compartida) y sus roles de `/etc/ssh/principals/`.
3. Sácala de los grupos (`sudo gpasswd -d USUARIO GRUPO`) o bloquea la cuenta (`sudo usermod -L -e 1 USUARIO`).
4. Corta lo abierto: `sudo pkill -u USUARIO sshd`.
5. Si conocía secretos compartidos (la frase de la CA, la llave del CI): rótalos.

**Comprobación:** `id USUARIO` no lista ningún grupo de `AllowGroups` (`ssh-users`, `sftp-only`, `saltadores`). `ssh HOST cat .ssh/authorized_keys | bin/key-audit -` ya no la lista.

## Un servidor nuevo

**Síntoma:** hay que gestionar un servidor más con el kit.

1. Su host key, comprobada: la huella por la consola del proveedor y `bin/kh-add HOST SHA256:...`.
2. Un alias en `conf.d/` (usuario, llave, salto si lo hay) y `bin/kit-check`.
3. Tu llave en su cuenta de administrador (`ssh-copy-id`, la última vez que usas la contraseña) y `bin/doctor ALIAS`.
4. El alias en `ansible/inventario.ini`, y desde `ansible/`: `ansible-playbook servidores.yml --check --diff --limit ALIAS`, después sin `--check`.
5. Con certificados: los pasos de [Preparar un servidor](README.md#autoridad-de-certificados) (firmar su host key, `user_ca.pub`, `principals/`).
6. `bin/audit ALIAS`.

**Comprobación:** `bin/audit ALIAS` dice `cumple`; `bin/doctor ALIAS` dice `(postcuántico)`; una segunda vez del playbook, `changed=0`.

## La CA queda expuesta

**Síntoma:** la llave privada de la CA (`~/.ssh-ca/user_ca` o `host_ca`) se copió, se perdió con un equipo o la frase la sabe alguien que no debe.

Con la llave de usuarios, alguien puede firmarse un certificado para cualquier cuenta. No basta con revocar certificados: hay que dejar de confiar en la CA.

1. Una CA nueva en otra carpeta: `ca/ca-init ~/.ssh-ca-NUEVA`.
2. En cada servidor, `user_ca.pub` **solo con la nueva** (no las dos: la vieja ya no es de fiar) e instálalo. Las personas entran con su llave en `authorized_keys` mientras tanto, o se quedan fuera hasta tener certificado nuevo: decide antes cuál.
3. Firma de nuevo a cada persona con la nueva: `CA_DIR=~/.ssh-ca-NUEVA ca/ca-sign ...`.
4. Si fue la de hosts: firma de nuevo cada host key y cambia en cada cliente la línea `@cert-authority` por la de la nueva.
5. Borra la vieja y averigua cómo salió. Si estaba sin frase o dentro de un repositorio, ese es el arreglo.

**Comprobación:** un certificado firmado por la vieja ya no entra (`ssh -i LLAVE -o CertificateFile=VIEJO-cert.pub -o ControlPath=none HOST true` falla); uno de la nueva, sí.
