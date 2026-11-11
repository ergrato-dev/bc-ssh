# Lab 03 — Alta con certificado

⏱ Duración estimada: ~60 min

## Objetivo

Dar de alta a una persona nueva, Ana, con la CA del kit: preparar `server` para certificados (certificado de host, CA de usuarios, `principals/`), firmar la llave de Ana y comprobar que entra sin ninguna línea en `authorized_keys`. Por el camino, `bin/doctor` enseña su primer fallo de integración.

## Contexto

- Certificados, principals y la CA de hosts: [semana 10](../../../week-10-certificados_ssh_ca_principals_krl_y_rotacion/README.md). Los pasos para preparar un servidor están en el README del kit, "Autoridad de certificados".
- Es el procedimiento "Alta de una persona" del RUNBOOK ([proyecto](../../3-proyecto/README.md), paso 4).
- Ana no existe: su "portátil" es la carpeta `~/w/ana` de tu cliente.
- **Las llaves sin frase de este lab (la CA y la de Ana) son solo del laboratorio.** Una CA de verdad lleva frase y vive fuera del kit.

## Instrucciones

0. **Preparación**: el paso 0 del [lab 02](../lab-02-un-servidor-nuevo/README.md). `server` está como lo dejó el playbook.

1. **La CA.** Sin frase, solo porque es el laboratorio:
   ```bash
   mkdir -p ~/w
   CA_FRASE= ca/ca-init
   ```
   ```
   ca-init: CA creada en /home/alumno/.ssh-ca
   256 SHA256:RfYpbXn3l4VdKPBh/qqYPTCLQaEWMdT9zEtFYoR4NFQ CA de usuarios 2026 (ED25519)
   256 SHA256:1FrkMEJUB87CA8AVxONh7I9pVubEznKpqG+btUOeJgM CA de hosts 2026 (ED25519)
   ```
   `~/.ssh-ca`, fuera de `~/ssh-infra-kit`: la CA no entra nunca en el repositorio (`ca-init` se niega a crearla dentro de uno).

2. **El certificado de host de `server`.** Su host key pública, por una conexión ya verificada, firmada con la CA de hosts:
   ```bash
   scp -q lab-server:/etc/ssh/ssh_host_ed25519_key.pub ~/w/server.pub
   ca/ca-sign -h ~/w/server.pub server server
   ```
   ```
   ca-sign: /home/alumno/w/server-cert.pub, serie 1 (host; server; -5m:+52w)
   ```
   Válido 52 semanas para el nombre `server`. El cliente lo comprueba contra la CA, no contra la llave.

3. **Preparar `server`.** La CA de usuarios, la KRL, el certificado de host, un `principals/ana` y la cuenta de Ana en `ssh-users`:
   ```bash
   scp -q ~/.ssh-ca/user_ca.pub ~/.ssh-ca/revoked.krl ~/w/server-cert.pub lab-server:
   ssh lab-server 'sudo install -m 644 user_ca.pub revoked.krl /etc/ssh/ &&
     sudo install -m 644 server-cert.pub /etc/ssh/ssh_host_ed25519_key-cert.pub &&
     sudo install -d -m 755 /etc/ssh/principals && echo ana | sudo tee /etc/ssh/principals/ana &&
     sudo useradd -m -s /bin/bash -G ssh-users ana && rm user_ca.pub revoked.krl server-cert.pub &&
     sudo sshd -t && sudo kill -HUP $(cat /run/sshd.pid)'
   ```
   ```
   ana
   ```
   - `principals/ana` dice qué nombres de un certificado aceptan la cuenta `ana`: aquí, solo `ana`. Un certificado con `admins` no entraría en ella.
   - `sshd -t` antes del `HUP`: si algo está mal, `sshd` sigue con la configuración vieja (semana 07).
   - En un servidor de verdad, esto va en el playbook. Aquí, a mano, para ver cada pieza.

4. **El cliente confía en la CA de hosts**, y `bin/doctor` lo cuenta... o no:
   ```bash
   echo "@cert-authority server,bastion $(cat ~/.ssh-ca/host_ca.pub)" >> ~/.ssh/known_hosts
   ssh -v -o ControlPath=none lab-server true 2>&1 | grep 'Server host certificate' | cut -c1-90
   bin/doctor lab-server | grep 'host key'
   ```
   ```
   debug1: Server host certificate: ssh-ed25519-cert-v01@openssh.com SHA256:4r3jm8P1/zkQv
   host key: 
   ```
   - `server` presenta ahora su certificado, y `ssh -v` lo escribe en una línea distinta: `Server host certificate:`, no `Server host key:`.
   - `bin/doctor` (semana 13) solo conoce la segunda: deja `host key` **vacío**. Es un fallo de integración: `doctor` y los certificados de host nunca se habían usado juntos. Lo arreglas en el [proyecto](../../3-proyecto/README.md), paso 2.

5. **La llave de Ana**, creada en su portátil. Ella te manda **solo la pública**:
   ```bash
   mkdir -p -m 700 ~/w/ana
   KEY_DIR=~/w/ana KEY_PASSPHRASE= bin/key-new ana ana@portatil
   ```
   ```
   key-new: aviso: llave sin frase de paso
   /home/alumno/w/ana/ana creada
   256 SHA256:cATJhUpM1JZIuOneWXLL9fqC4i5WtKuHsNVGxbFTTBk ana@portatil (ED25519)
   ```
   En la vida real, comprueba esa huella con Ana por otro camino (teléfono, en persona) antes de firmar: firmar la llave de un impostor le da acceso.

6. **Firmar a Ana.**
   ```bash
   ca/ca-sign ~/w/ana/ana.pub ana@portatil ana
   ssh-keygen -Lf ~/w/ana/ana-cert.pub | grep -E 'Key ID|Serial|Valid|Principals' -A1 | grep -v -e '^--' -e Critical
   ```
   ```
   ca-sign: /home/alumno/w/ana/ana-cert.pub, serie 2 (usuario; ana; -5m:+8h)
           Key ID: "ana@portatil"
           Serial: 2
           Valid: from 2026-11-11T01:06:58 to 2026-11-11T09:11:58
           Principals: 
                   ana
   ```
   Ocho horas: mañana, otro certificado. Si Ana pierde el portátil esta noche, el certificado caduca solo; la llave, no (lab 04).

7. **El portátil de Ana, como un alias.** En tu `~/.ssh/config`, **después** del `Include`:
   ```bash
   printf '\nHost portatil-ana\n    HostName server\n    User ana\n    IdentityFile ~/w/ana/ana\n' >> ~/.ssh/config
   cat ~/.ssh/config
   ssh -G portatil-ana | grep -E '^(hostname|user|identityfile) '
   ```
   ```
   Include kit/config

   Host portatil-ana
       HostName server
       User ana
       IdentityFile ~/w/ana/ana
   user ana
   hostname server
   identityfile ~/w/ana/ana
   ```
   - El `Include` va arriba: un `Include` escrito después de un `Host` queda **dentro** de ese bloque y solo vale para él. Con él al principio, todos tus alias (y los del kit) funcionan.
   - Un alias propio y no `-o User=ana -o IdentityFile=...` sobre `lab-server`: `IdentityFile` se **acumula**, y `lab-server` ya ofrece `~/.ssh/lab`. Con `MaxAuthTries 3`, tres llaves ofrecidas son `Too many authentication failures`.

8. **Ana entra.**
   ```bash
   ssh portatil-ana 'whoami; ls -a .ssh'
   ssh lab-server 'sudo grep "Accepted.*for ana" /var/log/auth.log | tail -1'
   ```
   ```
   ana
   ls: cannot access '.ssh': No such file or directory
   2026-11-11 01:11:58 server sshd: Accepted publickey for ana from 172.20.0.5 port 48370 ssh2: ED25519-CERT SHA256:cATJhUpM1JZIuOneWXLL9fqC4i5WtKuHsNVGxbFTTBk ID ana@portatil (serial 2) CA ED25519 SHA256:RfYpbXn3l4VdKPBh/qqYPTCLQaEWMdT9zEtFYoR4NFQ
   ```
   - Ana no tiene `~/.ssh`: ninguna línea en `authorized_keys`. Entra porque `server` confía en la CA (`TrustedUserCAKeys`) y su certificado dice `ana`.
   - El log dice **quién** (el `ID ana@portatil`), con qué certificado (`serial 2`) y qué CA lo firmó. Es lo que buscarás si un día hay que revocarla.

## Criterios de éxito

- [ ] La CA fuera del repositorio y la host key de `server` firmada (pasos 1 y 2)
- [ ] `server` con `user_ca.pub`, KRL, certificado de host y `principals/ana`, validado con `sshd -t` antes de recargar (paso 3)
- [ ] Explicas por qué `bin/doctor` deja vacío `host key` (paso 4)
- [ ] Explicas por qué el `Include` va arriba y por qué Ana tiene su propio alias (paso 7)
- [ ] Ana entra sin `authorized_keys`, y encuentras su `ID` y su serie en el log (paso 8)

## Reto extra

Firma a Ana un segundo certificado con el principal `admins` (`ca/ca-sign ~/w/ana/ana.pub ana@portatil admins`) y prueba otra vez el paso 8. ¿Entra? ¿Qué dice el log del servidor? Después prueba `bin/kh-add server SHA256:...` con la huella de la host key de `server`: guárdate el resultado para el lab 06.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 02 — Un servidor nuevo](../lab-02-un-servidor-nuevo/README.md) | [Lab 04 — Una llave perdida](../lab-04-una-llave-perdida/README.md) → |

[↑ Semana 14](../../README.md)
