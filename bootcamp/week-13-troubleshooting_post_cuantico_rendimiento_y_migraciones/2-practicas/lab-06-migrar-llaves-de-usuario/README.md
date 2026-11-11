# Lab 06 — Migrar llaves de usuario

⏱ Duración estimada: ~60 min

## Objetivo

Hacer inventario de las llaves de un `authorized_keys`, encontrar las que hay que cambiar (DSA, RSA corta, ECDSA), exigir RSA de 3072 bits en el servidor con `RequiredRSASize`, y migrar a una persona a Ed25519 sin dejarla nunca fuera.

## Contexto

- Qué llave se migra, por qué y en qué orden: [teoría 03](../../1-teoria/03-rendimiento-y-migraciones.md#migrar-llaves-de-usuario).
- Las llaves de este lab representan a personas: `luis@portatil-2016` (RSA de 2048), `eva@camara` (ECDSA) y `dan@nas-2012` (DSA). **Sin frase y solo para el laboratorio.**
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-leer-ssh-v/README.md). Después, las tres llaves viejas, en el `authorized_keys` de `alumno` en `server`:
   ```bash
   cd ~/.ssh
   ssh-keygen -q -t rsa -b 2048 -N '' -C luis@portatil-2016 -f viejo-rsa
   ssh-keygen -q -t ecdsa -N '' -C eva@camara -f cam-ecdsa
   ssh-keygen -q -t dsa -N '' -C dan@nas-2012 -f nas-dsa
   cat viejo-rsa.pub cam-ecdsa.pub nas-dsa.pub | ssh server 'cat >> .ssh/authorized_keys'
   cd
   ```
   OpenSSH 9.6 aún sabe crear llaves DSA; la 10.0 ya no.

1. **El inventario.**
   ```bash
   ssh server ssh-keygen -lf .ssh/authorized_keys
   ```
   ```
   256 SHA256:Gmij3RUkXCAjU7MNogjC9Jvm0RX0Hn51wYPBFODPFdE admin@client (ED25519)
   2048 SHA256:LdkCZey5churiezYWXJ7Zhrf9WiX7aWFpCtUghnA6MU luis@portatil-2016 (RSA)
   256 SHA256:nqCMUxATIsVWnKn7/pP3FDoFt/QJh9jyhU2hZdwzPOU eva@camara (ECDSA)
   1024 SHA256:WmcThxLFE2Tkf00dRoLQ2FIEVJz1wsu3YJa4mk4IKL0 dan@nas-2012 (DSA)
   ```
   Bits, huella, comentario y tipo de cada línea. `ssh-keygen -l` entiende también las líneas con opciones (`restrict,command=...`) y salta comentarios y líneas en blanco.

2. **Las que hay que migrar.** Filtra por la última columna (el tipo) y la primera (los bits):
   ```bash
   ssh server ssh-keygen -lf .ssh/authorized_keys | awk '$NF == "(DSA)" || $NF == "(ECDSA)" || ($NF == "(RSA)" && $1 < 3072)'
   ```
   ```
   2048 SHA256:LdkCZey5churiezYWXJ7Zhrf9WiX7aWFpCtUghnA6MU luis@portatil-2016 (RSA)
   256 SHA256:nqCMUxATIsVWnKn7/pP3FDoFt/QJh9jyhU2hZdwzPOU eva@camara (ECDSA)
   1024 SHA256:WmcThxLFE2Tkf00dRoLQ2FIEVJz1wsu3YJa4mk4IKL0 dan@nas-2012 (DSA)
   ```
   `$NF` es el último campo. El `awk` corre en tu cliente (comillas simples), como en el [lab 07 de la semana 11](../../../week-11-2fa_fail2ban_y_auditoria/2-practicas/lab-07-leer-el-log/README.md). El comentario dice **de quién** es cada llave: sin comentarios útiles, la migración empieza por averiguarlo con el log.

3. **Cuáles funcionan hoy.**
   ```bash
   for k in viejo-rsa cam-ecdsa nas-dsa; do ssh -o BatchMode=yes -o IdentitiesOnly=yes -i ~/.ssh/$k server true; echo "$k: $?"; done
   ssh -v -o BatchMode=yes -o IdentitiesOnly=yes -i ~/.ssh/nas-dsa server true 2>&1 | grep Skipping
   ```
   ```
   viejo-rsa: 0
   cam-ecdsa: 0
   alumno@server: Permission denied (publickey,password).
   nas-dsa: 255
   debug1: Skipping ssh-dss key /home/alumno/.ssh/nas-dsa - corresponding algorithm not in PubkeyAcceptedAlgorithms
   ```
   - La DSA ya no entra: tu **cliente** ni la ofrece (`ssh-dss` está fuera de `PubkeyAcceptedAlgorithms` desde OpenSSH 7.0). Su línea en `authorized_keys` es basura: bórrala sin miedo.
   - La RSA de 2048 entra. Es la peligrosa: funciona, nadie se queja, y es la más débil que queda.
   - La ECDSA entra y no está rota. Se migra por coherencia con el kit (sin curvas NIST, semana 11), sin prisa.

4. **Exigir RSA de 3072.** En `server`, con `sshd -t` antes de recargar:
   ```bash
   ssh server 'echo "RequiredRSASize 3072" | sudo tee /etc/ssh/sshd_config.d/15-rsa.conf
   sudo sshd -t && sudo kill -HUP $(cat /run/sshd.pid)'
   sleep 1
   ssh -o BatchMode=yes -o IdentitiesOnly=yes -i ~/.ssh/viejo-rsa server true; echo "código: $?"
   ssh server "grep 'Invalid key length' /var/log/auth.log | tail -1"
   ```
   ```
   RequiredRSASize 3072
   alumno@server: Permission denied (publickey,password).
   código: 255
   2026-11-11 00:46:45 server sshd: refusing RSA key: Invalid key length [preauth]
   ```
   - `RequiredRSASize` (OpenSSH 9.1+) rechaza llaves RSA de usuario más cortas; por defecto, 1024. Tu kit lo pone en `15-algoritmos.conf` ([proyecto](../../3-proyecto/README.md)).
   - Para Luis, el mismo `Permission denied` de siempre (lab 02): la razón solo está en el servidor. **Así no se migra**: primero se avisa y se da la llave nueva; después se exige. Lo has hecho al revés a propósito, para ver qué le pasaría.

5. **Migrar a Luis, sin dejarlo fuera.** Él crea su llave Ed25519 y te manda la **pública**; tú la añades **sin quitar** la vieja y él prueba:
   ```bash
   ssh-keygen -q -t ed25519 -N '' -C luis@portatil-2026 -f ~/.ssh/nuevo
   ssh server 'cat >> .ssh/authorized_keys' < ~/.ssh/nuevo.pub
   ssh -o BatchMode=yes -o IdentitiesOnly=yes -i ~/.ssh/nuevo server echo entra
   ```
   ```
   entra
   ```
   En un servidor de verdad, Luis crea la llave **en su equipo**, con frase (`bin/key-new` del kit). Aquí todo es el cliente, y sin frase: solo laboratorio.

6. **Quitar la vieja.** Por el contenido de la llave (el segundo campo del `.pub`), que no se repite, con una copia antes:
   ```bash
   k=$(cut -d' ' -f2 ~/.ssh/viejo-rsa.pub)
   ssh server "cp .ssh/authorized_keys .ssh/authorized_keys.antes
   grep -vF '$k' .ssh/authorized_keys.antes > .ssh/authorized_keys
   ssh-keygen -lf .ssh/authorized_keys"
   ```
   ```
   256 SHA256:Gmij3RUkXCAjU7MNogjC9Jvm0RX0Hn51wYPBFODPFdE admin@client (ED25519)
   256 SHA256:nqCMUxATIsVWnKn7/pP3FDoFt/QJh9jyhU2hZdwzPOU eva@camara (ECDSA)
   1024 SHA256:WmcThxLFE2Tkf00dRoLQ2FIEVJz1wsu3YJa4mk4IKL0 dan@nas-2012 (DSA)
   256 SHA256:yo482eAC0Pd5bmkLsHt8jlhsyu/QYch3wNWauhbxUIY luis@portatil-2026 (ED25519)
   ```
   - `grep -F`: el texto tal cual, sin expresiones regulares (la llave lleva `+` y `/`). `-v`: todas las líneas **menos** esa.
   - Nunca por el comentario: dos llaves pueden llevar el mismo, y el comentario lo escribe quien la crea.
   - Comprueba que tu sesión de administrador sigue entrando antes de borrar `authorized_keys.antes`.
   - Si la llave vieja tenía master abierto, sigue dentro: `bin/mux stop` (semana 05).

7. **Tus propias llaves.** El mismo inventario, en tu cliente:
   ```bash
   for f in ~/.ssh/*.pub; do ssh-keygen -lf "$f"; done | awk '{print $1, $NF, $3}'
   ```
   La RSA de 2048, la ECDSA y la DSA son tuyas también: si las usas en otros sitios, ese es el siguiente inventario. Tu kit lo hace con `bin/key-audit` ([proyecto](../../3-proyecto/README.md)).

## Criterios de éxito

- [ ] Haces el inventario de un `authorized_keys` y filtras las que hay que migrar (pasos 1 y 2)
- [ ] Explicas por qué la DSA ya no entra y la RSA de 2048 sí (paso 3)
- [ ] Activas `RequiredRSASize` y encuentras la razón del rechazo en el log (paso 4)
- [ ] Migras una persona en el orden correcto: añadir, probar, quitar (pasos 5 y 6)
- [ ] Explicas por qué se quita una llave por su contenido y no por su comentario (paso 6)

## Reto extra

Migra también a Eva (la ECDSA) y borra la línea de Dan (la DSA). Después escribe el `awk` del paso 2 como un script `~/w/llaves-viejas` que reciba un archivo y salga con 1 si encuentra alguna. ¿Qué haría falta para pasarlo por todos los usuarios de un servidor (`/home/*/.ssh/authorized_keys`)? ¿Y por todos los servidores del inventario de Ansible?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 05 — Medir el rendimiento](../lab-05-medir-el-rendimiento/README.md) | [Lab 07 — Rotar host keys](../lab-07-rotar-host-keys/README.md) → |

[↑ Semana 13](../../README.md)
