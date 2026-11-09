# Lab 02 — Principals: como quién puede entrar

⏱ Duración estimada: ~60 min

## Objetivo

Decidir con el certificado **como qué usuario** entra cada uno: principals iguales al usuario, varios principals, ninguno, y roles con `AuthorizedPrincipalsFile`. Aceptar una CA para una sola cuenta, sin ser `root`.

## Contexto

- Principals y `AuthorizedPrincipalsFile`: [teoría 02](../../1-teoria/02-certificados-de-usuario-y-de-host.md#principals-como-quién-entras).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación.** El paso 0 del [lab 01](../lab-01-primera-ca/README.md). Después, la CA, la llave `trabajo` y `server` confiando en la CA (los pasos 1, 2 y 5 del lab 01), y un alias para entrar con `trabajo`:
   ```bash
   ssh-keygen -q -t ed25519 -N '' -C 'CA de usuarios del laboratorio' -f ~/ca/user_ca
   ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/trabajo
   scp -q ~/ca/user_ca.pub server:
   ssh server 'sudo install -m 644 user_ca.pub /etc/ssh/
   echo "TrustedUserCAKeys /etc/ssh/user_ca.pub" | sudo tee /etc/ssh/sshd_config.d/50-ca.conf
   sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   cat > ~/.ssh/config <<'FIN'
   Host server-cert
       HostName server
       IdentityFile ~/.ssh/trabajo
       IdentitiesOnly yes
       PasswordAuthentication no
   FIN
   ```
   ```
   TrustedUserCAKeys /etc/ssh/user_ca.pub
   ```
   - La CA sin frase: **solo en el laboratorio**.
   - `server-cert` es `server` con la llave `trabajo` y solo ella. `PasswordAuthentication no` en el cliente: si el certificado no vale, falla en lugar de pedirte la contraseña.
   - Los labs siguientes repiten este paso 0.

1. **Un principal es un nombre de usuario.** Crea otro usuario en `server` y firma `trabajo` solo para `alumno`:
   ```bash
   ssh server 'sudo useradd -m -s /bin/bash deploy; id deploy'
   ssh-keygen -q -s ~/ca/user_ca -I alumno@client -n alumno -V +1h ~/.ssh/trabajo.pub
   ssh server-cert whoami
   ssh deploy@server-cert whoami; echo "código: $?"
   ```
   ```
   uid=1001(deploy) gid=1001(deploy) groups=1001(deploy)
   alumno
   deploy@server: Permission denied (publickey,password).
   código: 255
   ```
   En **otra terminal de tu equipo**:
   ```bash
   docker compose logs --no-log-prefix server | grep Certificate | tail -1
   ```
   ```
   Certificate invalid: name is not a listed principal
   ```
   Con `TrustedUserCAKeys`, `sshd` deja entrar como `deploy` solo si `deploy` está en los principals. El usuario que pides tiene que estar **en el certificado**.

2. **Varios principals.** Firmar otra vez **sustituye** `trabajo-cert.pub`:
   ```bash
   ssh-keygen -q -s ~/ca/user_ca -I alumno@client -n alumno,deploy -V +1h ~/.ssh/trabajo.pub
   ssh-keygen -Lf ~/.ssh/trabajo-cert.pub | grep -A2 Principals
   ssh server-cert whoami
   ssh deploy@server-cert whoami
   ```
   ```
           Principals: 
                   alumno
                   deploy
   alumno
   deploy
   ```
   `-n` lleva la lista separada por comas, sin espacios. Para que alguien deje de entrar como `deploy`, firmas sin él: el certificado viejo sigue valiendo hasta que caduque (por eso `-V +1h`, y el lab 05).

3. **Sin principals.**
   ```bash
   ssh-keygen -q -s ~/ca/user_ca -I alumno@client -V +1h ~/.ssh/trabajo.pub
   ssh-keygen -Lf ~/.ssh/trabajo-cert.pub | grep Principals
   ssh server-cert whoami; echo "código: $?"
   ```
   ```
           Principals: (none)
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   ```
   Certificate lacks principal list
   ```
   Un certificado sin principals valdría para **cualquier** usuario. `sshd` lo rechaza siempre que la CA venga de `TrustedUserCAKeys`. Pon siempre `-n`.

4. **Roles: `AuthorizedPrincipalsFile`.** Con muchos servidores, firmar con nombres de usuario obliga a saber qué cuentas hay en cada uno. Mejor firmar con **roles** y que cada servidor diga qué roles acepta cada cuenta:
   ```bash
   ssh server 'sudo mkdir -p /etc/ssh/principals
   printf "alumno\nadmins\n" | sudo tee /etc/ssh/principals/alumno
   printf "despliegue\nadmins\n" | sudo tee /etc/ssh/principals/deploy
   echo "AuthorizedPrincipalsFile /etc/ssh/principals/%u" | sudo tee -a /etc/ssh/sshd_config.d/50-ca.conf
   sudo sshd -t && sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ```
   ```
   alumno
   admins
   despliegue
   admins
   AuthorizedPrincipalsFile /etc/ssh/principals/%u
   ```
   `%u` es el usuario que pide entrar: para `deploy`, `sshd` lee `/etc/ssh/principals/deploy`. Ahora firma con el rol `admins`, y luego solo con `alumno`:
   ```bash
   ssh-keygen -q -s ~/ca/user_ca -I alumno@client -n admins -V +1h ~/.ssh/trabajo.pub
   ssh server-cert whoami
   ssh deploy@server-cert whoami
   ssh-keygen -q -s ~/ca/user_ca -I alumno@client -n alumno -V +1h ~/.ssh/trabajo.pub
   ssh server-cert whoami
   ssh deploy@server-cert whoami; echo "código: $?"
   ```
   ```
   alumno
   deploy
   alumno
   deploy@server: Permission denied (publickey,password).
   código: 255
   ```
   ```
   Certificate does not contain an authorized principal
   ```
   - `admins` está en los dos archivos: entra en las dos cuentas.
   - Con `AuthorizedPrincipalsFile`, el nombre de usuario **ya no cuenta solo**: `alumno` entra como `alumno` porque esa línea está en su archivo, no por llamarse igual.
   - El mensaje cambia: ahora es el archivo el que no tiene ninguno de los principals del certificado.

5. **Una cuenta sin archivo.**
   ```bash
   ssh server 'sudo useradd -m -s /bin/bash ana'
   ssh-keygen -q -s ~/ca/user_ca -I ana@client -n ana -V +1h ~/.ssh/trabajo.pub
   ssh ana@server-cert whoami; echo "código: $?"
   ```
   ```
   ana@server: Permission denied (publickey,password).
   código: 255
   ```
   Sin `/etc/ssh/principals/ana`, ningún certificado entra como `ana`. Su `authorized_keys` sigue funcionando: `AuthorizedPrincipalsFile` solo afecta a los certificados.

6. **Compruébalo sin conectar.** `sshd -T -C user=...` (semana 07) dice qué se aplica a cada usuario:
   ```bash
   ssh server 'sudo sshd -T -C user=deploy | grep -E "^(authorizedprincipalsfile|trustedusercakeys)"'
   ```
   ```
   trustedusercakeys /etc/ssh/user_ca.pub
   authorizedprincipalsfile /etc/ssh/principals/%u
   ```

7. **Una CA para una sola cuenta.** `bastion` no confía en la CA y no eres `root` en él... o haz como si no. Una línea `cert-authority` en **tu** `authorized_keys` acepta los certificados de esa CA solo para tu cuenta:
   ```bash
   ssh-keygen -q -s ~/ca/user_ca -I alumno@client -n alumno -V +1h ~/.ssh/trabajo.pub
   ssh bastion "echo 'cert-authority,principals=\"alumno\" $(cat ~/ca/user_ca.pub)' >> ~/.ssh/authorized_keys"
   ssh bastion 'tail -1 ~/.ssh/authorized_keys' | cut -c1-70
   ssh -i ~/.ssh/trabajo -o IdentitiesOnly=yes bastion hostname
   ```
   ```
   cert-authority,principals="alumno" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAA
   bastion
   ```
   - `cert-authority`: la llave de esa línea no entra; firma a quien entra.
   - `principals="alumno"`: qué principals acepta. Sin él, valdría cualquier certificado de la CA que nombre a tu usuario.
   - Las comillas dobles de fuera dejan que **tu** shell expanda `$(cat ...)`; las `\"` llegan como comillas a la línea.

## Criterios de éxito

- [ ] Explicas por qué un certificado para `alumno` no entra como `deploy`, con el mensaje del log (paso 1)
- [ ] Firmas con varios principals y explicas qué pasa con el certificado anterior (paso 2)
- [ ] Explicas por qué `sshd` rechaza un certificado sin principals (paso 3)
- [ ] Configuras `AuthorizedPrincipalsFile` con roles y explicas por qué el nombre de usuario ya no basta (paso 4)
- [ ] Explicas qué pasa con una cuenta sin archivo de principals y con su `authorized_keys` (paso 5)
- [ ] Aceptas una CA en una sola cuenta con `cert-authority,principals=` (paso 7)

## Reto extra

`AuthorizedPrincipalsCommand` ejecuta un programa en lugar de leer un archivo (por ejemplo, preguntar los roles a un directorio LDAP). Lee `man sshd_config`: ¿qué argumentos recibe con `%u`, `%f` y `%i`? ¿Con qué usuario se ejecuta (`AuthorizedPrincipalsCommandUser`) y por qué no debería ser `root`?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 01 — Tu primera autoridad de certificados](../lab-01-primera-ca/README.md) | [Lab 03 — Validez y opciones del certificado](../lab-03-validez-y-opciones/README.md) → |

[↑ Semana 10](../../README.md)
