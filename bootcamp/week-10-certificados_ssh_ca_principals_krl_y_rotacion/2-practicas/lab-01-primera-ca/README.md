# Lab 01 — Tu primera autoridad de certificados

⏱ Duración estimada: ~60 min

## Objetivo

Crear una CA de usuarios, firmar con ella una llave que **no** está en ningún `authorized_keys` y entrar en `server` con el certificado. Leer qué lleva un certificado y qué deja `sshd` en su log.

## Contexto

- Qué es una CA y qué firma: [teoría 01](../../1-teoria/01-por-que-certificados.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación.** En tu equipo, desde la raíz del repositorio:
   ```bash
   docker compose up -d --force-recreate server bastion interno
   docker compose run --rm client
   ```
   `--force-recreate` deja los servidores como recién instalados: cada lab empieza limpio. **En el cliente**, `known_hosts` y una llave de administrador en `server` y `bastion`:
   ```bash
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh ~/ca ~/w
   ssh-keyscan -t ed25519 server bastion 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -N '' -C admin@client -f ~/.ssh/id_ed25519
   sshpass -e ssh-copy-id -f server 2>&1 | grep 'Number of'
   sshpass -e ssh-copy-id -f bastion 2>&1 | grep 'Number of'
   ```
   ```
   Number of key(s) added: 1
   Number of key(s) added: 1
   ```
   - `id_ed25519` es tu llave de **administrar**: con ella configuras los servidores. Los certificados los pruebas con otra llave, que no estará en ningún `authorized_keys`.
   - Llaves sin frase (`-N ''`) y la contraseña en `SSHPASS`: **solo en el laboratorio**.
   - `~/ca` es la carpeta de la CA. Fuera de cualquier repositorio git: ahí habrá llaves privadas.

1. **La CA es una llave.** Una llave Ed25519 normal, con otro uso:
   ```bash
   ssh-keygen -q -t ed25519 -N '' -C 'CA de usuarios del laboratorio' -f ~/ca/user_ca
   ls -l ~/ca
   ssh-keygen -lf ~/ca/user_ca.pub
   ```
   ```
   total 8
   -rw------- 1 alumno alumno 432 Nov  9 03:46 user_ca
   -rw-r--r-- 1 alumno alumno 112 Nov  9 03:46 user_ca.pub
   256 SHA256:bwlf5Vt0KFbQ0rbagTSYtcEiumRoCxVNtvqjpBlhWOg CA de usuarios del laboratorio (ED25519)
   ```
   - `user_ca` firma; quien la tenga puede entrar como cualquiera en todo servidor que confíe en ella. **Sin frase solo en el laboratorio**: el lab 07 la protege.
   - `user_ca.pub` es lo que reciben los servidores. Apunta la huella: la verás en el log.

2. **Una llave que nadie conoce.**
   ```bash
   ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/trabajo
   ssh -i ~/.ssh/trabajo -o IdentitiesOnly=yes -o BatchMode=yes server hostname; echo "código: $?"
   ```
   ```
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   `trabajo.pub` no está en el `authorized_keys` de `server`. `IdentitiesOnly=yes` hace que `ssh` ofrezca solo esa llave, no tu `id_ed25519`; `BatchMode=yes`, que no pida la contraseña.

3. **Firmarla.**
   ```bash
   ssh-keygen -s ~/ca/user_ca -I alumno@client -n alumno -V +1h ~/.ssh/trabajo.pub
   ls ~/.ssh
   ```
   ```
   Signed user key /home/alumno/.ssh/trabajo-cert.pub: id "alumno@client" serial 0 for alumno valid from 2026-11-09T03:45:00 to 2026-11-09T04:46:02
   id_ed25519
   id_ed25519.pub
   known_hosts
   known_hosts.old
   trabajo
   trabajo-cert.pub
   trabajo.pub
   ```
   | Opción | Qué | Para qué |
   |---|---|---|
   | `-s ~/ca/user_ca` | Firma con esa llave privada | Es la CA |
   | `-I alumno@client` | Identidad (*key ID*) del certificado | Aparece en el log del servidor: di de quién es |
   | `-n alumno` | Principals: usuarios como los que puede entrar | Sin `-n`, `sshd` lo rechaza (lab 02) |
   | `-V +1h` | Validez: desde ahora hasta dentro de una hora | Un certificado que caduca solo no hay que revocarlo (lab 03) |

   Se firma la llave **pública**: `trabajo` (la privada) no se mueve de `~/.ssh`. El resultado, `trabajo-cert.pub`, es público también.

4. **Qué lleva un certificado.**
   ```bash
   ssh-keygen -Lf ~/.ssh/trabajo-cert.pub
   ```
   ```
   /home/alumno/.ssh/trabajo-cert.pub:
           Type: ssh-ed25519-cert-v01@openssh.com user certificate
           Public key: ED25519-CERT SHA256:/kKd53suIFP842mm7uwR8V50/wAym4jxTvEYCbVDHFc
           Signing CA: ED25519 SHA256:bwlf5Vt0KFbQ0rbagTSYtcEiumRoCxVNtvqjpBlhWOg (using ssh-ed25519)
           Key ID: "alumno@client"
           Serial: 0
           Valid: from 2026-11-09T03:45:00 to 2026-11-09T04:46:02
           Principals: 
                   alumno
           Critical Options: (none)
           Extensions: 
                   permit-X11-forwarding
                   permit-agent-forwarding
                   permit-port-forwarding
                   permit-pty
                   permit-user-rc
   ```
   - `Public key`: la huella de **tu** llave. `Signing CA`: la de `user_ca` (paso 1).
   - `Valid: from 03:45:00`: firmaste a las 03:46:02, y `-V +1h` empieza la validez un minuto antes, redondeado, para tolerar un servidor con el reloj un poco atrasado.
   - `Serial: 0`: no le diste número (`-z`). En el lab 05 lo necesitarás para revocar.
   - `Extensions`: lo que permite; `Critical Options`: lo que limita (lab 03).

5. **`server` confía en la CA.** Copia la llave pública de la CA y dile a `sshd` que la use:
   ```bash
   scp ~/ca/user_ca.pub server:
   ssh server 'sudo install -m 644 user_ca.pub /etc/ssh/
   echo "TrustedUserCAKeys /etc/ssh/user_ca.pub" | sudo tee /etc/ssh/sshd_config.d/50-ca.conf
   sudo sshd -t && sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ```
   ```
   TrustedUserCAKeys /etc/ssh/user_ca.pub
   ```
   - `TrustedUserCAKeys`: el archivo con las CA de usuarios en las que confía, una por línea. Vale para todos los usuarios del servidor.
   - `sshd -t` comprueba la configuración; `kill -HUP` la recarga (semana 07). El `sleep 1` deja a `sshd` volver a escuchar.

6. **Entrar con el certificado.**
   ```bash
   ssh -i ~/.ssh/trabajo -o IdentitiesOnly=yes server hostname
   ssh -v -i ~/.ssh/trabajo -o IdentitiesOnly=yes server true 2>&1 | grep -E 'Will attempt|Server accepts'
   ```
   ```
   server
   debug1: Will attempt key: /home/alumno/.ssh/trabajo ED25519 SHA256:/kKd53suIFP842mm7uwR8V50/wAym4jxTvEYCbVDHFc explicit
   debug1: Will attempt key: /home/alumno/.ssh/trabajo ED25519-CERT SHA256:/kKd53suIFP842mm7uwR8V50/wAym4jxTvEYCbVDHFc explicit
   debug1: Server accepts key: /home/alumno/.ssh/trabajo ED25519-CERT SHA256:/kKd53suIFP842mm7uwR8V50/wAym4jxTvEYCbVDHFc explicit
   ```
   No dijiste nada del certificado: con `-i ~/.ssh/trabajo`, `ssh` busca solo `~/.ssh/trabajo-cert.pub` y lo ofrece además de la llave. `server` rechaza la llave sola y acepta el certificado (`ED25519-CERT`). Si el certificado está en otro sitio: `-o CertificateFile=RUTA`.

7. **Qué ve `sshd`.** En **otra terminal de tu equipo**:
   ```bash
   docker compose logs --no-log-prefix server | grep 'Accepted publickey' | tail -1
   ```
   ```
   Accepted publickey for alumno from 172.20.0.6 port 44728 ssh2: ED25519-CERT SHA256:/kKd53suIFP842mm7uwR8V50/wAym4jxTvEYCbVDHFc ID alumno@client (serial 0) CA ED25519 SHA256:bwlf5Vt0KFbQ0rbagTSYtcEiumRoCxVNtvqjpBlhWOg
   ```
   Llave, identidad, número de serie y CA en una línea. Con `authorized_keys` solo verías la huella, y tendrías que buscar de quién es.

8. **Lo que no cambió.**
   ```bash
   ssh server 'cat ~/.ssh/authorized_keys' | cut -c1-30
   ssh -i ~/.ssh/trabajo -o IdentitiesOnly=yes -o BatchMode=yes bastion hostname; echo "código: $?"
   ```
   ```
   ssh-ed25519 AAAAC3NzaC1lZDI1NT
   alumno@bastion: Permission denied (publickey,password).
   código: 255
   ```
   - En `authorized_keys` solo está tu llave de administrar. `trabajo` entra sin estar ahí.
   - `bastion` no confía en la CA: el mismo certificado no vale. Cada servidor que confíe en ella necesita **una línea**, no una por persona.

9. **Sin el certificado.**
   ```bash
   mv ~/.ssh/trabajo-cert.pub ~/w/
   ssh -i ~/.ssh/trabajo -o IdentitiesOnly=yes -o BatchMode=yes server hostname; echo "código: $?"
   mv ~/w/trabajo-cert.pub ~/.ssh/
   ```
   ```
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   La llave sola no vale. Pero el certificado solo, tampoco: sin la llave privada no puedes demostrar que es tuyo. Un certificado robado no sirve; una llave privada robada, sí (hasta que caduque su certificado).

## Criterios de éxito

- [ ] Creas la CA y dices qué archivo va a los servidores y cuál no sale de `~/ca` (paso 1)
- [ ] Firmas una llave y explicas `-s`, `-I`, `-n` y `-V` (paso 3)
- [ ] Lees un certificado con `ssh-keygen -L` y localizas tu llave, la CA, la identidad y la validez (paso 4)
- [ ] Configuras `TrustedUserCAKeys` y entras sin tocar `authorized_keys` (pasos 5 y 6)
- [ ] Encuentras en el log del servidor la identidad, el número de serie y la CA (paso 7)
- [ ] Explicas por qué no basta con robar el certificado (paso 9)

## Reto extra

Firma la misma llave otra vez con `-I otra-identidad -z 42`. ¿Qué hay ahora en `trabajo-cert.pub`? ¿Puedes tener dos certificados de la misma llave a la vez? Prueba con `-o CertificateFile=` apuntando a cada uno.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Índice de labs](../README.md) | [Lab 02 — Principals: como quién puede entrar](../lab-02-principals/README.md) → |

[↑ Semana 10](../../README.md)
