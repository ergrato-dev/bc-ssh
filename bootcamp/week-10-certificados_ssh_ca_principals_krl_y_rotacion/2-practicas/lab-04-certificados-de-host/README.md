# Lab 04 — Certificados de host: adiós a «Are you sure?»

⏱ Duración estimada: ~60 min

## Objetivo

Firmar las host keys de `server`, `bastion` e `interno` con una CA de hosts y entrar en los tres con un `known_hosts` de **una línea**: sin preguntas la primera vez, también saltando. Ver qué pasa cuando el nombre no está en el certificado o cuando caduca.

## Contexto

- Certificados de host, `HostCertificate` y `@cert-authority`: [teoría 02](../../1-teoria/02-certificados-de-usuario-y-de-host.md#certificados-de-host).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-primera-ca/README.md). Esta vez no hace falta la CA de usuarios. Deja abierta **otra terminal en tu equipo**: en el paso 6 pides una huella desde ella.

1. **El problema: la primera vez.** Sin una línea en `known_hosts`, `ssh` no sabe si la llave que recibe es la de `server`:
   ```bash
   ssh -o UserKnownHostsFile=/dev/null server true; echo "código: $?"
   ```
   ```
   Host key verification failed.
   código: 255
   ```
   Sin terminal, falla; con una, te haría la pregunta de la semana 02 (`Are you sure you want to continue connecting`). Con 50 servidores, cada persona comprueba 50 huellas, y otra vez cada vez que un servidor se reinstala.

2. **Una CA de hosts.** Otra llave, distinta de la de usuarios: quien firma servidores no tiene por qué poder firmar personas.
   ```bash
   ssh-keygen -q -t ed25519 -N '' -C 'CA de hosts del laboratorio' -f ~/ca/host_ca
   ```
   Sin frase: **solo en el laboratorio**.

3. **Firmar la host key de `server`.** Te traes su llave **pública**, la firmas con `-h` y le devuelves el certificado:
   ```bash
   scp -q server:/etc/ssh/ssh_host_ed25519_key.pub ~/w/server.pub
   ssh-keygen -s ~/ca/host_ca -h -I server -n server -V +52w ~/w/server.pub
   ssh-keygen -Lf ~/w/server-cert.pub | grep -E 'Type|Key ID|Principals' -A1 | grep -v '^--'
   ```
   ```
   Signed host key /home/alumno/w/server-cert.pub: id "server" serial 0 for server valid from 2026-11-09T03:50:00 to 2027-11-08T03:51:44
           Type: ssh-ed25519-cert-v01@openssh.com host certificate
           Public key: ED25519-CERT SHA256:6x1QZJdEOmZb7rQCsaKuAgQ7duntl9XfP900Dt9mZNU
           Key ID: "server"
           Serial: 0
           Principals: 
                   server
   ```
   - `-h`: certificado de **host**. Sin él, sería de usuario y el cliente lo rechazaría.
   - `-n server`: los nombres con los que el cliente lo conoce, los que escribes después de `ssh`. Con un nombre completo, también: `-n server,server.empresa.com`.
   - `-V +52w`: un año. Los servidores cambian poco; los usuarios, más.
   - La llave privada del servidor (`ssh_host_ed25519_key`) no sale de él. Lo que confías es que **esa** pública es suya: la trajiste por una conexión ya verificada (tu `known_hosts` del paso 0).

   Instala el certificado junto a la llave y díselo a `sshd`:
   ```bash
   scp -q ~/w/server-cert.pub server:
   ssh server 'sudo install -m 644 server-cert.pub /etc/ssh/ssh_host_ed25519_key-cert.pub
   echo "HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub" | sudo tee /etc/ssh/sshd_config.d/50-ca.conf
   sudo sshd -t && sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ```
   ```
   HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub
   ```

4. **El cliente confía en la CA.** Una línea `@cert-authority` en un `known_hosts` nuevo:
   ```bash
   echo "@cert-authority server,bastion,interno $(cat ~/ca/host_ca.pub)" > ~/.ssh/known_hosts_ca
   cut -c1-80 ~/.ssh/known_hosts_ca
   ssh -o UserKnownHostsFile=~/.ssh/known_hosts_ca server hostname
   ssh -v -o UserKnownHostsFile=~/.ssh/known_hosts_ca server true 2>&1 | grep -E 'Server host cert|is known'
   ```
   ```
   @cert-authority server,bastion,interno ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3Xs
   server
   debug1: Server host certificate: ssh-ed25519-cert-v01@openssh.com SHA256:6x1QZJdEOmZb7rQCsaKuAgQ7duntl9XfP900Dt9mZNU, serial 0 ID "server" CA ssh-ed25519 SHA256:RgSFUOK6xBvARVlmVwvUlXl+jRHjt00KhGs/z72NXN4 valid from 2026-11-09T03:50:00 to 2027-11-08T03:51:44
   debug1: Host 'server' is known and matches the ED25519-CERT host certificate.
   ```
   - `@cert-authority PATRONES LLAVE`: para los hosts que encajen en `PATRONES`, acepta cualquier host key firmada por esa CA. Admite comodines: `*.empresa.com`.
   - Sin pregunta y sin la llave de `server` en ningún sitio: `ssh` comprueba la firma y que `server` esté en los principals.

5. **`bastion`, igual.**
   ```bash
   scp -q bastion:/etc/ssh/ssh_host_ed25519_key.pub ~/w/bastion.pub
   ssh-keygen -q -s ~/ca/host_ca -h -I bastion -n bastion -V +52w ~/w/bastion.pub
   scp -q ~/w/bastion-cert.pub bastion:
   ssh bastion 'sudo install -m 644 bastion-cert.pub /etc/ssh/ssh_host_ed25519_key-cert.pub
   echo "HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub" | sudo tee /etc/ssh/sshd_config.d/50-ca.conf
   sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ssh -o UserKnownHostsFile=~/.ssh/known_hosts_ca bastion hostname
   ```
   ```
   HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub
   bastion
   ```

6. **`interno`: firmar algo que no has verificado.** Tu equipo no llega a `interno`, y `ssh-keyscan` desde el bastion te da una llave que el bastion podría haber cambiado. **Antes de firmarla**, compara su huella con la de la consola. En la terminal de tu equipo:
   ```bash
   docker compose exec interno ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
   ```
   ```
   256 SHA256:+OAeWPsyCQAQOE0ceq6bkSwnxD6PdM5S4W1o9H36JYk root@interno (ED25519)
   ```
   En el cliente:
   ```bash
   ssh bastion ssh-keyscan -t ed25519 interno 2>/dev/null | cut -d' ' -f2- > ~/w/interno.pub
   ssh-keygen -lf ~/w/interno.pub
   ```
   ```
   256 SHA256:+OAeWPsyCQAQOE0ceq6bkSwnxD6PdM5S4W1o9H36JYk no comment (ED25519)
   ```
   Coinciden: fírmala. Firmar una llave sin verificarla es decirles a todos tus clientes que confíen en ella. Para instalar el certificado, `interno` todavía necesita tu llave, y un `known_hosts` temporal con la llave que acabas de verificar:
   ```bash
   ssh-keygen -q -s ~/ca/host_ca -h -I interno -n interno -V +52w ~/w/interno.pub
   echo "interno $(cat ~/w/interno.pub)" > ~/w/kh-interno
   sshpass -e ssh-copy-id -o UserKnownHostsFile=~/w/kh-interno -o ProxyJump=bastion interno 2>&1 | grep 'Number of'
   scp -q -o UserKnownHostsFile=~/w/kh-interno -J bastion ~/w/interno-cert.pub interno:
   ssh -o UserKnownHostsFile=~/w/kh-interno -J bastion interno 'sudo install -m 644 interno-cert.pub /etc/ssh/ssh_host_ed25519_key-cert.pub
   echo "HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub" | sudo tee /etc/ssh/sshd_config.d/50-ca.conf
   sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ```
   ```
   Number of key(s) added: 1
   HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub
   ```
   `sshpass` responde a la contraseña de `interno` (**solo del laboratorio**). El `-o UserKnownHostsFile` no llega al `ssh` del salto (semana 09): para `bastion` sigue valiendo tu `known_hosts`.

7. **Un `known_hosts` de una línea.** Guarda el viejo y quédate solo con la CA:
   ```bash
   mv ~/.ssh/known_hosts ~/w/known_hosts.viejo
   cp ~/.ssh/known_hosts_ca ~/.ssh/known_hosts
   ssh server hostname; ssh bastion hostname; ssh -J bastion interno hostname
   wc -l < ~/.ssh/known_hosts
   ```
   ```
   server
   bastion
   interno
   1
   ```
   Tres servidores, ninguna pregunta, y el salto también verifica `bastion` por la CA. Un servidor nuevo firmado por la CA no necesita nada en ningún cliente.

8. **Un nombre que no está en el certificado.** Entra en `server` por su IP:
   ```bash
   ip=$(getent hosts server | cut -d' ' -f1); echo $ip
   ssh -o BatchMode=yes $ip true; echo "código: $?"
   ssh -o HostKeyAlias=server $ip hostname
   ```
   ```
   172.20.0.2
   Host key verification failed.
   código: 255
   server
   ```
   - El certificado dice `server`, no `172.20.0.2`, y el patrón de `@cert-authority` tampoco la incluye. `ssh` trata la llave como desconocida: con terminal, la pregunta de siempre.
   - `HostKeyAlias=server` (semana 09) hace que la busque y la compruebe con el nombre `server`. O añade la IP con `-n server,172.20.0.2` al firmar, si es fija.

9. **Un certificado de host caducado.**
   ```bash
   ssh-keygen -q -s ~/ca/host_ca -h -I server -n server -V -2h:-1h ~/w/server.pub
   scp -q ~/w/server-cert.pub server:
   ssh server 'sudo install -m 644 server-cert.pub /etc/ssh/ssh_host_ed25519_key-cert.pub; sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ssh -o ControlPath=none server true; echo "código: $?"
   ```
   ```
   Certificate invalid: expired
   Host key verification failed.
   código: 255
   ```
   Este error lo da **tu** `ssh`, sin `-v`. Un certificado de host caducado deja a todos los clientes fuera: apunta cuándo caduca cada uno y renuévalo antes (el `scp` de la orden anterior funcionó porque el certificado aún valía). Vuelve a firmarlo con `-V +52w` para dejarlo bien.

## Criterios de éxito

- [ ] Explicas qué problema de la primera conexión resuelven los certificados de host (paso 1)
- [ ] Firmas una host key con `-h` y explicas `-n` y por qué la llave privada no sale del servidor (paso 3)
- [ ] Escribes la línea `@cert-authority` y entras sin preguntas, con `-v` como prueba (paso 4)
- [ ] Verificas la huella de `interno` por otro canal **antes** de firmarla y explicas por qué (paso 6)
- [ ] Entras en los tres servidores con un `known_hosts` de una línea (paso 7)
- [ ] Explicas por qué falla la IP y qué lo arregla (paso 8), y qué pasa al caducar un certificado de host (paso 9)

## Reto extra

Ejecuta `docker compose up -d --force-recreate server` y vuelve a entrar. ¿Qué mensaje da `ssh` y por qué? (Pista: `start-sshd` genera host keys nuevas, y el certificado no viene con ellas.) ¿Qué tendría que hacer un servidor real al instalarse para no necesitar a nadie?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 03 — Validez y opciones del certificado](../lab-03-validez-y-opciones/README.md) | [Lab 05 — Revocar: la KRL](../lab-05-revocacion-krl/README.md) → |

[↑ Semana 10](../../README.md)
