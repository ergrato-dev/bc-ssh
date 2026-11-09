# Lab 05 — Revocar: la KRL

⏱ Duración estimada: ~60 min

## Objetivo

Dejar fuera un certificado antes de que caduque: crear una KRL, revocar un certificado, una llave y un número de serie, y ver qué pasa cuando el archivo de la KRL falta o está roto.

## Contexto

- KRL y `RevokedKeys`: [teoría 03](../../1-teoria/03-revocacion-y-rotacion.md#la-krl).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 02](../lab-02-principals/README.md). Además, una segunda llave, la de tu «portátil», con su alias, y una función que sube la KRL a `server`:
   ```bash
   ssh-keygen -q -t ed25519 -N '' -C alumno@portatil -f ~/.ssh/portatil
   cat >> ~/.ssh/config <<'FIN'
   Host portatil-cert
       HostName server
       IdentityFile ~/.ssh/portatil
       IdentitiesOnly yes
       PasswordAuthentication no
   FIN
   sube_krl() { scp -q ~/ca/revoked.krl server: && ssh server 'sudo install -m 644 revoked.krl /etc/ssh/'; }
   ```

1. **Dos certificados con número de serie.** `-z` le da a cada certificado su número: es lo que revocarás después.
   ```bash
   ssh-keygen -q -s ~/ca/user_ca -I alumno@client -n alumno -V +1d -z 1 ~/.ssh/trabajo.pub
   ssh-keygen -q -s ~/ca/user_ca -I alumno@portatil -n alumno -V +1d -z 2 ~/.ssh/portatil.pub
   ssh server-cert hostname; ssh portatil-cert hostname
   ```
   ```
   server
   server
   ```
   Lleva la cuenta de los números: dos certificados con el mismo número se revocan juntos.

2. **Una KRL vacía en el servidor.**
   ```bash
   ssh-keygen -k -f ~/ca/revoked.krl; ls -l ~/ca/revoked.krl
   sube_krl
   ssh server 'echo "RevokedKeys /etc/ssh/revoked.krl" | sudo tee -a /etc/ssh/sshd_config.d/50-ca.conf
   sudo sshd -t && sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ssh server-cert hostname; ssh portatil-cert hostname
   ```
   ```
   -rw-r--r-- 1 alumno alumno 44 Nov  9 03:53 /home/alumno/ca/revoked.krl
   RevokedKeys /etc/ssh/revoked.krl
   server
   server
   ```
   - `ssh-keygen -k`: crea una KRL (*Key Revocation List*). Sin llaves que revocar, vacía: 44 bytes de cabecera.
   - **Primero el archivo, después `RevokedKeys`**: el paso 7 enseña por qué.

3. **Revocar un certificado.**
   ```bash
   ssh-keygen -k -u -f ~/ca/revoked.krl ~/.ssh/trabajo-cert.pub
   ssh-keygen -Q -f ~/ca/revoked.krl ~/.ssh/trabajo-cert.pub ~/.ssh/portatil-cert.pub; echo "código: $?"
   sube_krl
   ssh server-cert hostname; echo "código: $?"
   ssh portatil-cert hostname
   ```
   ```
   Revoking from /home/alumno/.ssh/trabajo-cert.pub
   /home/alumno/.ssh/trabajo-cert.pub (alumno@client): REVOKED
   /home/alumno/.ssh/portatil-cert.pub (alumno@portatil): ok
   código: 1
   alumno@server: Permission denied (publickey,password).
   código: 255
   server
   ```
   - `-u` **añade** a la KRL que ya existe. Sin `-u`, la crea de nuevo solo con lo que pases: perderías lo revocado antes.
   - `-Q`: comprueba llaves contra la KRL; sale con 1 si alguna está revocada.
   - No hizo falta `kill -HUP`: `sshd` lee la KRL en cada autenticación. Basta con copiar el archivo.

   En el log de `server` (desde tu equipo, `docker compose logs --no-log-prefix server | grep revoked | tail -1`):
   ```
   Authentication key ED25519-CERT SHA256:... revoked by file /etc/ssh/revoked.krl
   ```

4. **Revocaste el certificado, no la llave.** Firma otra vez la misma llave:
   ```bash
   ssh-keygen -q -s ~/ca/user_ca -I alumno@client -n alumno -V +1d -z 3 ~/.ssh/trabajo.pub
   ssh server-cert hostname
   ssh-keygen -k -u -f ~/ca/revoked.krl ~/.ssh/trabajo.pub
   sube_krl; ssh server-cert hostname; echo "código: $?"
   ```
   ```
   server
   Revoking from /home/alumno/.ssh/trabajo.pub
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   - Un certificado se revoca por su **número de serie** (y su CA): el número 3 es otro certificado y entra.
   - Si la **llave** se filtró, revoca la llave (`trabajo.pub`): fuera todos sus certificados, los de antes y los de después, y también su línea en cualquier `authorized_keys`.

5. **Revocar sin tener el certificado.** El portátil se perdió con su certificado dentro. Te basta su número de serie, en un archivo de texto:
   ```bash
   printf 'serial: 2\n' > ~/w/revocar
   ssh-keygen -k -u -s ~/ca/user_ca.pub -f ~/ca/revoked.krl ~/w/revocar
   sube_krl; ssh portatil-cert hostname; echo "código: $?"
   ```
   ```
   Revoking from /home/alumno/w/revocar
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   - `-s ~/ca/user_ca.pub`: un número de serie solo tiene sentido con su CA. Basta la llave **pública**.
   - El archivo admite `serial: 10-20` (un rango), `id: alumno@portatil` (por identidad) y `key: ssh-ed25519 AAAA...`. Por eso las identidades (`-I`) y los números tienen que ser únicos: si no, revocas de más o de menos.

6. **Qué hay en la KRL.**
   ```bash
   ssh-keygen -Q -l -f ~/ca/revoked.krl
   ```
   ```
   # KRL version 0
   # Generated at 20261109T035338

   hash: SHA256:r19QxoMF5w4J6j7FDHCaUNXF4YAy2VGKTvhIOmmJs3s # ssh-ed25519

   # CA key ssh-ed25519 SHA256:m/tKr5gQfcT/MLmPOSL86pr+jXrCSIDkUVKgeQw3nhs
   serial: 1-2
   ```
   La llave `trabajo` (por su hash) y los números 1 y 2 de tu CA, que `ssh-keygen` junta en un rango. Una KRL con miles de números ocupa unos pocos bytes.

7. **Si la KRL falta o está rota.** Un certificado nuevo, y prueba a quitar el archivo:
   ```bash
   ssh-keygen -q -s ~/ca/user_ca -I alumno@portatil -n alumno -V +1d -z 4 ~/.ssh/portatil.pub
   ssh portatil-cert hostname
   ssh server 'sudo mv /etc/ssh/revoked.krl /etc/ssh/revoked.krl.bak'
   ssh portatil-cert hostname; echo "código: $?"
   ssh -o BatchMode=yes server hostname; echo "código: $?"
   ```
   ```
   server
   alumno@server: Permission denied (publickey,password).
   código: 255
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   **Tampoco entra tu llave de administrar**, que no tiene certificado. Si `sshd` no puede leer la KRL, no sabe qué está revocado y rechaza **todas** las llaves:
   ```
   Error checking authentication key ED25519 SHA256:... in revoked keys file /etc/ssh/revoked.krl: No such file or directory
   ```
   Entra con la contraseña (**solo del laboratorio**; en un servidor real, por la consola), estropea el archivo y luego arréglalo:
   ```bash
   sshpass -e ssh server 'echo basura | sudo tee /etc/ssh/revoked.krl >/dev/null'
   ssh portatil-cert hostname; echo "código: $?"
   sshpass -e ssh server 'sudo mv /etc/ssh/revoked.krl.bak /etc/ssh/revoked.krl'
   ssh portatil-cert hostname; ssh server hostname
   ```
   ```
   alumno@server: Permission denied (publickey,password).
   código: 255
   server
   server
   ```
   Con un archivo roto, el log dice `invalid format`. Por eso el orden del paso 2, y por eso conviene comprobar la KRL antes de subirla (`ssh-keygen -Q -l`).

## Criterios de éxito

- [ ] Creas una KRL, la instalas y configuras `RevokedKeys` en el orden correcto (paso 2)
- [ ] Revocas un certificado, lo compruebas con `ssh-keygen -Q` y explicas `-u` y por qué no hace falta recargar `sshd` (paso 3)
- [ ] Explicas la diferencia entre revocar un certificado y revocar una llave (paso 4)
- [ ] Revocas por número de serie sin tener el certificado (paso 5)
- [ ] Lees el contenido de una KRL (paso 6)
- [ ] Explicas qué pasa con **todas** las llaves si la KRL falta o está rota (paso 7)

## Reto extra

Revocar no sirve si la KRL no llega a todos los servidores. Escribe un bucle que suba `~/ca/revoked.krl` a `server` y `bastion` y, en cada uno, compruebe con `ssh-keygen -Q` que tu certificado aparece como `REVOKED`. ¿Qué pasa con un servidor apagado durante la subida?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 04 — Certificados de host: adiós a «Are you sure?»](../lab-04-certificados-de-host/README.md) | [Lab 06 — Rotar la CA sin dejar a nadie fuera](../lab-06-rotacion-de-la-ca/README.md) → |

[↑ Semana 10](../../README.md)
