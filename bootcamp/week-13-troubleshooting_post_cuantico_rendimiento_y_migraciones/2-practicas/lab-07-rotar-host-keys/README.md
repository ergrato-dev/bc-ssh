# Lab 07 — Rotar host keys

⏱ Duración estimada: ~60 min

## Objetivo

Cambiar la host key de un servidor (y quitarle de paso las RSA y ECDSA) sin que los clientes vean `REMOTE HOST IDENTIFICATION HAS CHANGED`: en dos fases, con `UpdateHostKeys` haciendo el trabajo en cada cliente que entra, y saber qué hacer con el que no entró a tiempo.

## Contexto

- `UpdateHostKeys`, el mensaje `hostkeys-00` y las dos fases de una rotación: [teoría 03](../../1-teoria/03-rendimiento-y-migraciones.md#rotar-las-host-keys).
- Cuándo se rota una host key: el servidor se reinstaló o clonó desde una imagen (todas las copias comparten llave), la llave pudo copiarse (una copia de seguridad de `/etc/ssh` perdida) o es de un tipo que quieres retirar.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-leer-ssh-v/README.md). Guarda una copia de `known_hosts` tal como queda: será el "cliente que no entró" del paso 5.
   ```bash
   cp ~/.ssh/known_hosts ~/w/kh-de-antes
   ```

1. **Lo que tu `known_hosts` aprendió solo.** En el paso 0 guardaste **una** llave de `server`, la Ed25519 (`ssh-keyscan -t ed25519`). Mira ahora:
   ```bash
   ssh-keygen -F server | grep -v '^#' | awk '{print $2}'
   ```
   ```
   ssh-ed25519
   ssh-rsa
   ecdsa-sha2-nistp256
   ```
   - `ssh-copy-id` se conectó con la Ed25519 ya comprobada y, dentro de esa conexión, `server` le mandó **todas** sus host keys (el mensaje `hostkeys-00@openssh.com`). El cliente las guardó.
   - Es seguro: solo pasa si la conexión ya verificó una llave conocida, y el servidor demuestra que tiene la privada de cada llave nueva (las firma).
   - Lo hace `UpdateHostKeys`, activo por defecto mientras no cambies `UserKnownHostsFile`. Tu kit lo deja escrito en `config` ([proyecto](../../3-proyecto/README.md)).
   - `ssh-keygen -F`: busca un host en `known_hosts`, también si los nombres van cifrados (`HashKnownHosts`).

2. **Fase 1: la nueva junto a la vieja.** En `server`, una llave Ed25519 nueva, y una configuración que ofrece la vieja y la nueva (y deja de ofrecer RSA y ECDSA):
   ```bash
   ssh server 'sudo ssh-keygen -q -t ed25519 -N "" -C server-2026 -f /etc/ssh/ssh_host_ed25519_key_2026
   printf "HostKey /etc/ssh/ssh_host_ed25519_key\nHostKey /etc/ssh/ssh_host_ed25519_key_2026\n" | sudo tee /etc/ssh/sshd_config.d/05-hostkeys.conf
   sudo sshd -t && sudo kill -HUP $(cat /run/sshd.pid)'
   ```
   ```
   HostKey /etc/ssh/ssh_host_ed25519_key
   HostKey /etc/ssh/ssh_host_ed25519_key_2026
   ```
   - Con alguna línea `HostKey`, `sshd` usa **solo** esas: por eso RSA y ECDSA dejan de ofrecerse. Sin ninguna, usa las tres de siempre.
   - De dos llaves del mismo tipo, la **primera** firma el intercambio. Los clientes siguen viendo la vieja: nadie recibe un aviso.
   - Las host keys son privadas de `root` sin frase (`-N ""`): es lo normal en un servidor, que tiene que arrancar solo.

3. **Un cliente entra y aprende.**
   ```bash
   ssh -v server true 2>&1 | grep -E 'Server host key|Learned|Removed'
   ssh-keygen -F server | grep -v '^#' | awk '{print $2}'
   ```
   ```
   debug1: Server host key: ssh-ed25519 SHA256:soK1wVe7vJ2HgYQQRvkqIy/V1UWIRd+ibT3gCGv5EC0
   Learned new hostkey: ED25519 SHA256:hZ2e3Bn5i9PnIJ482p2IAfk8WyCNqr7HqJWbaQlHqdE
   /home/alumno/.ssh/known_hosts:3: Removed RSA key for host server
   /home/alumno/.ssh/known_hosts:4: Removed ECDSA key for host server
   ssh-ed25519
   ssh-ed25519
   ```
   - Entró con la vieja (`soK1...`), aprendió la nueva (`hZ2e...`) y olvidó las dos que `server` ya no tiene.
   - Comprueba la huella nueva en el servidor, por un camino que no sea esta conexión: `docker compose exec server ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key_2026.pub` en tu equipo (en uno de verdad, la consola del proveedor).
   - En la vida real, la fase 1 dura semanas: el tiempo para que entre cada cliente que importa. Los que no tienen tu kit (un CI, otra persona) necesitan la huella nueva: actualiza el secreto `KIT_KNOWN_HOSTS` de la [semana 12](../../../week-12-automatizacion_scripting_ci_cd_y_ansible/README.md) ahora, no después.

4. **Fase 2: solo la nueva.**
   ```bash
   ssh server 'echo "HostKey /etc/ssh/ssh_host_ed25519_key_2026" | sudo tee /etc/ssh/sshd_config.d/05-hostkeys.conf
   sudo sshd -t && sudo kill -HUP $(cat /run/sshd.pid)'
   sleep 1
   ssh -v server true 2>&1 | grep -E 'Server host key|Learned|Removed'
   ssh-keygen -F server | grep -v '^#' | awk '{print $2}'
   ```
   ```
   HostKey /etc/ssh/ssh_host_ed25519_key_2026
   debug1: Server host key: ssh-ed25519 SHA256:hZ2e3Bn5i9PnIJ482p2IAfk8WyCNqr7HqJWbaQlHqdE
   /home/alumno/.ssh/known_hosts:1: Removed ED25519 key for host server
   ssh-ed25519
   ```
   El servidor firma con la nueva; tu cliente ya la conocía y entra sin avisos, y olvida la vieja. La rotación terminó para este cliente. En el servidor, borra la llave vieja (`ssh_host_ed25519_key` y su `.pub`) cuando estés seguro de que no vuelves atrás: mientras exista, quien la tenga puede hacerse pasar por `server` ante los clientes que no se actualizaron.

5. **El cliente que no entró a tiempo.** Su `known_hosts` es el de antes de la fase 1:
   ```bash
   ssh -o UserKnownHostsFile=~/w/kh-de-antes server true 2>&1 | grep -E 'WARNING|SHA256|Offending|verification'
   ```
   ```
   @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
   SHA256:hZ2e3Bn5i9PnIJ482p2IAfk8WyCNqr7HqJWbaQlHqdE.
   Offending ECDSA key in /home/alumno/w/kh-de-antes:4
   Host key verification failed.
   ```
   - Para este cliente, el cambio es indistinguible de un ataque. Hace lo correcto: no entra.
   - El arreglo **no** es borrar la línea y aceptar lo que venga. Es comprobar que `hZ2e...` es la huella que publicaste (paso 3) y, solo entonces, sustituirla: `ssh-keygen -f ~/w/kh-de-antes -R server` y `bin/kh-add server SHA256:hZ2e...` del kit (semana 02).
   - Con certificados de host ([semana 10](../../../week-10-certificados_ssh_ca_principals_krl_y_rotacion/README.md)), el cliente confía en la CA y no en cada llave: rotar es firmar la nueva y ninguno avisa, haya entrado o no.

6. **Resumen de la rotación.**

   | Momento | Servidor (`HostKey`) | Cliente al día | Cliente sin conectar |
   |---|---|---|---|
   | Antes | vieja | conoce la vieja | conoce la vieja |
   | Fase 1 (semanas) | vieja, nueva | aprende la nueva al entrar | conoce la vieja: sigue entrando |
   | Fase 2 | nueva | entra sin aviso, olvida la vieja | aviso: comprueba la huella y `kh-add` |

## Criterios de éxito

- [ ] Explicas por qué `known_hosts` tenía tres llaves de `server` tras el paso 0 y por qué es seguro (paso 1)
- [ ] Ofreces la vieja y la nueva a la vez y explicas cuál firma (paso 2)
- [ ] Compruebas que un cliente aprende la nueva y olvida las retiradas (paso 3)
- [ ] Terminas la rotación sin avisos para el cliente al día (paso 4)
- [ ] Resuelves el aviso del cliente que no entró, comprobando la huella (paso 5)

## Reto extra

Repite la rotación con `UpdateHostKeys no` en tu cliente (`-o UpdateHostKeys=no`). ¿En qué fase empiezan los avisos? Después prueba `UpdateHostKeys ask`: ¿qué te pregunta y qué huellas te enseña?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 06 — Migrar llaves de usuario](../lab-06-migrar-llaves-de-usuario/README.md) | [Proyecto — ssh-infra-kit: diagnóstico y migración de algoritmos](../../3-proyecto/README.md) → |

[↑ Semana 13](../../README.md)
