# Lab 06 — Rotar la CA sin dejar a nadie fuera

⏱ Duración estimada: ~60 min

## Objetivo

Cambiar la CA de usuarios y la de hosts por otras nuevas sin que nadie se quede sin entrar: confiar en las dos durante la transición, firmar de nuevo, retirar la vieja y revocarla.

## Contexto

- Cuándo y cómo rotar: [teoría 03](../../1-teoria/03-revocacion-y-rotacion.md#rotar-una-ca).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 02](../lab-02-principals/README.md), y un certificado de la CA actual:
   ```bash
   ssh-keygen -q -s ~/ca/user_ca -I alumno@client -n alumno -V +1d -z 1 ~/.ssh/trabajo.pub
   ssh server-cert hostname
   ```
   ```
   server
   ```

1. **Por qué rotar.** Tres motivos, de más a menos urgente:
   - La llave privada de la CA se filtró, o alguien que tuvo acceso a ella se fue.
   - El algoritmo de la CA envejece (una CA RSA de 2048 bits que quieres cambiar por Ed25519).
   - Tu política lo pide cada cierto tiempo, para que rotar sea rutina y no una emergencia.

   El problema: los servidores confían en la CA vieja y los usuarios tienen certificados de ella. Si cambias las dos cosas a la vez, alguien queda fuera.

2. **Una CA nueva, y los servidores confían en las dos.** `TrustedUserCAKeys` admite varias llaves, una por línea:
   ```bash
   ssh-keygen -q -t ed25519 -N '' -C 'CA de usuarios 2027' -f ~/ca/user_ca2
   cat ~/ca/user_ca.pub ~/ca/user_ca2.pub > ~/w/user_ca.pub
   cut -c1-40,82- ~/w/user_ca.pub
   scp -q ~/w/user_ca.pub server:; ssh server 'sudo install -m 644 user_ca.pub /etc/ssh/'
   ```
   ```
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBT4CA de usuarios del laboratorio
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILRWCA de usuarios 2027
   ```
   Sin frase: **solo en el laboratorio**. El nombre del archivo no cambia, y `sshd` lo lee en cada autenticación: sin `kill -HUP`.

3. **Los dos certificados valen.** El viejo sigue entrando; firma uno nuevo con `user_ca2` y comprueba quién lo firmó:
   ```bash
   ssh server-cert hostname
   cp ~/.ssh/trabajo-cert.pub ~/w/trabajo-vieja-cert.pub
   ssh-keygen -q -s ~/ca/user_ca2 -I alumno@client -n alumno -V +1d -z 1 ~/.ssh/trabajo.pub
   ssh-keygen -Lf ~/.ssh/trabajo-cert.pub | grep 'Signing CA'
   ssh-keygen -lf ~/ca/user_ca2.pub
   ssh server-cert hostname
   ```
   ```
   server
           Signing CA: ED25519 SHA256:LcW9kfvt5ns4H3uoQqWutjf8K7bGFlW2LjkKbasqDN0 (using ssh-ed25519)
   256 SHA256:LcW9kfvt5ns4H3uoQqWutjf8K7bGFlW2LjkKbasqDN0 CA de usuarios 2027 (ED25519)
   server
   ```
   - Durante la transición, cada usuario recibe su certificado nuevo. Con certificados de horas, basta con esperar: el siguiente que pida ya sale de `user_ca2`.
   - Los números de serie van **por CA**: el 1 de `user_ca2` no es el 1 de `user_ca`.

4. **Cuándo retirar la vieja.** Cuando haya pasado la validez más larga que firmaste con ella: con `-V +1d`, un día después de dejar de usarla. Antes, alguien con un certificado viejo válido se quedaría fuera.

5. **Retirarla.** Solo `user_ca2` en los servidores:
   ```bash
   scp -q ~/ca/user_ca2.pub server:; ssh server 'sudo install -m 644 user_ca2.pub /etc/ssh/user_ca.pub'
   ssh server-cert hostname
   ssh -o CertificateFile=~/w/trabajo-vieja-cert.pub server-cert hostname; echo "código: $?"
   ```
   ```
   server
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   `CertificateFile` hace que `ssh` ofrezca ese certificado en lugar de `trabajo-cert.pub`. El viejo ya no vale en `server`, y `sshd` no lo dice en el log: para él, es un certificado de una CA que no conoce.

6. **Si la vieja se filtró: revocarla.** Retirarla de `TrustedUserCAKeys` no basta si queda algún servidor que no actualizaste, o una línea `cert-authority` en algún `authorized_keys` (lab 02). Revoca **la CA** en la KRL:
   ```bash
   ssh-keygen -k -f ~/ca/revoked.krl ~/ca/user_ca.pub
   ssh-keygen -Q -f ~/ca/revoked.krl ~/w/trabajo-vieja-cert.pub ~/.ssh/trabajo-cert.pub
   ```
   ```
   Revoking from /home/alumno/ca/user_ca.pub
   /home/alumno/w/trabajo-vieja-cert.pub (alumno@client): REVOKED
   /home/alumno/.ssh/trabajo-cert.pub (alumno@client): ok
   ```
   Una llave de CA revocada revoca todo lo que firmó. Con esa KRL en todos los servidores (`RevokedKeys`, lab 05), la CA vieja no sirve en ninguno. Aquí no la subes: `server` no tiene `RevokedKeys`.

7. **La CA de hosts: dos `@cert-authority`.** Lo mismo del lado del cliente. Monta la CA de hosts actual con `server` firmado (como en el lab 04):
   ```bash
   ssh-keygen -q -t ed25519 -N '' -C 'CA de hosts 2026' -f ~/ca/host_ca
   scp -q server:/etc/ssh/ssh_host_ed25519_key.pub ~/w/server.pub
   ssh-keygen -q -s ~/ca/host_ca -h -I server -n server -V +52w ~/w/server.pub
   scp -q ~/w/server-cert.pub server:
   ssh server 'sudo install -m 644 server-cert.pub /etc/ssh/ssh_host_ed25519_key-cert.pub
   echo "HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub" | sudo tee -a /etc/ssh/sshd_config.d/50-ca.conf
   sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   echo "@cert-authority server,bastion,interno $(cat ~/ca/host_ca.pub)" > ~/.ssh/known_hosts
   ssh server hostname
   ```
   ```
   HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub
   server
   ```
   Ahora la nueva: **primero en los clientes**, después en los servidores. Al revés, los clientes recibirían un certificado de una CA que aún no conocen.
   ```bash
   ssh-keygen -q -t ed25519 -N '' -C 'CA de hosts 2027' -f ~/ca/host_ca2
   echo "@cert-authority server,bastion,interno $(cat ~/ca/host_ca2.pub)" >> ~/.ssh/known_hosts
   ssh-keygen -q -s ~/ca/host_ca2 -h -I server -n server -V +52w ~/w/server.pub
   scp -q ~/w/server-cert.pub server:
   ssh server 'sudo install -m 644 server-cert.pub /etc/ssh/ssh_host_ed25519_key-cert.pub; sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ssh server hostname
   ```
   ```
   server
   ```
   Fíjate en el orden de cada orden: el `scp` todavía entra con el certificado de la CA vieja; el último `ssh`, con el de la nueva.

8. **Marcar la vieja como revocada.** Cambia su línea por `@revoked`:
   ```bash
   sed -i '1s/^@cert-authority server,bastion,interno/@revoked */' ~/.ssh/known_hosts
   cut -c1-60 ~/.ssh/known_hosts
   ssh server hostname
   ```
   ```
   @revoked * ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAt3OiF0Ayio8
   @cert-authority server,bastion,interno ssh-ed25519 AAAAC3Nza
   server
   ```
   Si alguien con la CA vieja firma un servidor falso, esto es lo que ves. Pruébalo volviendo a instalar en `server` un certificado de `host_ca`:
   ```bash
   ssh-keygen -q -s ~/ca/host_ca -h -I server -n server -V +52w ~/w/server.pub
   scp -q ~/w/server-cert.pub server:
   ssh server 'sudo install -m 644 server-cert.pub /etc/ssh/ssh_host_ed25519_key-cert.pub; sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ssh -o ControlPath=none server hostname; echo "código: $?"
   ```
   ```
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   @       WARNING: REVOKED HOST KEY DETECTED!               @
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   The ED25519-CERT host key for server is marked as revoked.
   This could mean that a stolen key is being used to
   impersonate this host.
   ED25519-CERT host key for server was revoked and you have requested strict checking.
   Host key verification failed.
   código: 255
   ```
   `@revoked *` vale para cualquier host: la llave de esa línea (una CA o una host key) no se acepta nunca, ni firmando ni firmada.

## Criterios de éxito

- [ ] Explicas por qué no se cambia la CA en clientes y servidores a la vez (paso 1)
- [ ] Configuras dos CA de usuarios en `TrustedUserCAKeys` y entras con certificados de las dos (pasos 2 y 3)
- [ ] Dices cuándo se puede retirar la CA vieja y lo compruebas (pasos 4 y 5)
- [ ] Revocas una CA entera en la KRL y explicas por qué hace falta además de retirarla (paso 6)
- [ ] Rotas la CA de hosts en el orden correcto: clientes primero, servidores después (paso 7)
- [ ] Marcas la CA de hosts vieja con `@revoked` y explicas el aviso (paso 8)

## Reto extra

Haz la rotación de la CA de hosts en `server` y `bastion` con un solo bucle `for h in server bastion` que traiga la llave, la firme con `host_ca2` y devuelva el certificado. ¿Qué tendrías que comprobar antes de quitar la línea de `host_ca` de los `known_hosts` de **todos** los clientes?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 05 — Revocar: la KRL](../lab-05-revocacion-krl/README.md) | [Lab 07 — Proteger la CA y saber qué firmó](../lab-07-proteger-y-auditar-la-ca/README.md) → |

[↑ Semana 10](../../README.md)
