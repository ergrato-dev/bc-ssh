# Lab 07 — Leer el log

⏱ Duración estimada: ~60 min

## Objetivo

Responder con el log de `sshd` y unos pocos comandos (`grep`, `awk`, `sort`, `uniq`) las preguntas de cualquier auditoría de acceso: quién entró, desde dónde y **con qué llave**, qué llaves se rechazaron, quién falla y probando qué usuarios, quién está dentro ahora y si la configuración que corre es la que crees.

## Contexto

- Las líneas del log de `sshd` y qué dice cada una: [teoría 03](../../1-teoria/03-fail2ban-y-registros.md#el-log-de-sshd).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-leer-ssh-audit/README.md). Además, tres llaves más: dos que estarán en `authorized_keys` (tu equipo del trabajo y tu portátil) y una que no (la de un intruso):
   ```bash
   for k in trabajo portatil intruso; do ssh-keygen -q -t ed25519 -N '' -C alumno@$k -f ~/.ssh/$k; done
   cat ~/.ssh/trabajo.pub ~/.ssh/portatil.pub | ssh server 'cat >> .ssh/authorized_keys'
   ssh server 'echo "LogLevel VERBOSE" | sudo tee /etc/ssh/sshd_config.d/20-log.conf; sudo kill -HUP $(cat /run/sshd.pid)'
   ```
   `LogLevel VERBOSE` es lo que pone tu `20-sesion.conf` del kit: añade la huella de las llaves rechazadas.

1. **Un día cualquiera.** Entras desde tus dos equipos, alguien prueba una llave que no es suya y un robot prueba usuarios:
   ```bash
   ssh -i ~/.ssh/trabajo -o IdentitiesOnly=yes server true
   ssh -i ~/.ssh/portatil -o IdentitiesOnly=yes server true
   ssh -i ~/.ssh/intruso -o IdentitiesOnly=yes -o BatchMode=yes server true
   for u in admin oracle admin postgres; do sshpass -p 1 ssh -o PubkeyAuthentication=no $u@server true 2>/dev/null; done
   ```
   ```
   alumno@server: Permission denied (publickey,password).
   ```

2. **¿Quién entró y desde dónde?**
   ```bash
   ssh server "grep 'Accepted publickey' /var/log/auth.log" | awk '{print $1, $2, $8, $10, $15}'
   ```
   ```
   2026-11-10 22:07:21 alumno 172.20.0.4 SHA256:BldJVDmNybwy7AtEYw17UA35Is4JKGAf2Z19FjoSvT8
   2026-11-10 22:07:22 alumno 172.20.0.4 SHA256:PamOKzjX8x3CovO0p2D2uubXjV/u7UZv724kNN6xZIk
   2026-11-10 22:07:22 alumno 172.20.0.4 SHA256:aZj5UabrxUpdcQ/MOVKhjBOC8JXYScb+BZ6rkg7sbgg
   ...
   ```
   - Las comillas simples alrededor de `{print ...}` hacen que `awk` corra **en tu cliente**, sobre lo que devuelve `ssh`: así no tienes que escapar los `$`.
   - Campos: fecha, hora, usuario (`$8`), IP (`$10`) y huella de la llave (`$15`). Tus huellas serán otras.
   - Todas las conexiones son `alumno`: el usuario no te dice desde qué equipo se entró. La huella sí.

3. **¿Con qué llave?** Las huellas de `authorized_keys` llevan el comentario de cada llave:
   ```bash
   ssh server ssh-keygen -lf .ssh/authorized_keys
   ```
   ```
   256 SHA256:BldJVDmNybwy7AtEYw17UA35Is4JKGAf2Z19FjoSvT8 admin@client (ED25519)
   256 SHA256:PamOKzjX8x3CovO0p2D2uubXjV/u7UZv724kNN6xZIk alumno@trabajo (ED25519)
   256 SHA256:aZj5UabrxUpdcQ/MOVKhjBOC8JXYScb+BZ6rkg7sbgg alumno@portatil (ED25519)
   ```
   Cruza las dos cosas con un `awk` que primero lee las llaves y después el log:
   ```bash
   ssh server bash -s <<'FIN'
   awk 'NR == FNR { llave[$2] = $3; next }
        /Accepted publickey/ { print $1, $2, $8, $10, llave[$15] }' \
       <(ssh-keygen -lf .ssh/authorized_keys) /var/log/auth.log
   FIN
   ```
   ```
   2026-11-10 22:07:21 alumno 172.20.0.4 admin@client
   2026-11-10 22:07:22 alumno 172.20.0.4 alumno@trabajo
   2026-11-10 22:07:22 alumno 172.20.0.4 alumno@portatil
   ...
   ```
   - `bash -s <<'FIN'`: el script viaja por la entrada de `ssh` y lo ejecuta `bash` en `server`. Las comillas de `'FIN'` impiden que tu shell toque los `$`.
   - `NR == FNR` solo es cierto mientras `awk` lee el primer archivo: guarda `huella → comentario` y pasa al siguiente.
   - Con certificados ([semana 10](../../../week-10-certificados_ssh_ca_principals_krl_y_rotacion/README.md)) es aún más directo: el log trae el `ID` y el número de serie.
   - Si mañana pierdes el portátil, sabes qué línea de `authorized_keys` borrar y qué conexiones revisar.

4. **¿Qué llaves se rechazaron?**
   ```bash
   ssh server "grep 'Failed publickey' /var/log/auth.log" | awk '{print $1, $2, $8, $10, $15}'
   ssh-keygen -lf ~/.ssh/intruso.pub
   ```
   ```
   2026-11-10 22:07:22 alumno 172.20.0.4 SHA256:mvSd2ympxyEHfdXt2gcZVYWNqr1w8hVsNSgi0BZtaDg
   256 SHA256:mvSd2ympxyEHfdXt2gcZVYWNqr1w8hVsNSgi0BZtaDg alumno@intruso (ED25519)
   ```
   Con `LogLevel INFO` esta línea no aparece. Una llave desconocida que alguien prueba contra tu usuario, desde la misma IP de la que entras tú, merece una pregunta.

5. **¿Quién falla, desde dónde y con qué usuarios?**
   ```bash
   ssh server "grep -E 'Invalid user|Failed password' /var/log/auth.log" | grep -oE 'from [0-9.]+' | sort | uniq -c | sort -rn
   ssh server "grep -oE 'Invalid user [^ ]+' /var/log/auth.log" | sort | uniq -c | sort -rn
   ```
   ```
         8 from 172.20.0.4
         2 Invalid user admin
         1 Invalid user postgres
         1 Invalid user oracle
   ```
   - `uniq -c` cuenta líneas iguales seguidas (por eso el `sort` antes); `sort -rn` pone arriba lo más repetido.
   - 4 intentos, 8 líneas: cada usuario inexistente deja `Invalid user` y `Failed password` (lo mismo que contó fail2ban en el [lab 06](../lab-06-fail2ban/README.md)).
   - La lista de usuarios probados dice qué busca el robot: servicios (`postgres`, `oracle`) con contraseñas por defecto.

6. **¿Quién está dentro ahora?** Abre una sesión en otra terminal del cliente (`ssh server`) y, desde esta:
   ```bash
   ssh server 'ps -eo user,pid,lstart,args | grep "[s]shd: .*@"; ss -tn state established "( sport = :22 )"'
   ```
   ```
   alumno       194 Tue Nov 10 22:07:42 2026 sshd: alumno@pts/0
   alumno       201 Tue Nov 10 22:07:58 2026 sshd: alumno@notty
   Recv-Q Send-Q Local Address:Port Peer Address:Port Process
   0      0         172.20.0.2:22     172.20.0.4:35012
   0      0         172.20.0.2:22     172.20.0.4:35020
   ```
   - `sshd: alumno@pts/0`: una sesión con terminal (la de la otra terminal); `@notty`: un comando sin terminal (este mismo).
   - `[s]shd`: el truco de los corchetes evita que `grep` se encuentre a sí mismo.
   - Un PID es lo que cortas con `sudo kill` si hay que echar a alguien ([semana 10](../../../week-10-certificados_ssh_ca_principals_krl_y_rotacion/README.md)).

7. **Una foto de la configuración.** El log dice qué pasó; `sshd -T` dice con qué reglas. Guarda una foto y compárala después de un cambio:
   ```bash
   ssh server sudo sshd -T > ~/w/sshd-antes.txt
   ssh server 'echo "MaxAuthTries 2" | sudo tee /etc/ssh/sshd_config.d/05-prueba.conf; sudo kill -HUP $(cat /run/sshd.pid)'
   ssh server sudo sshd -T | diff ~/w/sshd-antes.txt -
   ssh server 'sudo rm /etc/ssh/sshd_config.d/05-prueba.conf; sudo kill -HUP $(cat /run/sshd.pid)'
   ```
   ```
   MaxAuthTries 2
   50c50
   < maxauthtries 6
   ---
   > maxauthtries 2
   ```
   Guarda la foto después de cada `bin/sshd-deploy`: si un día el `diff` sale con algo que no desplegaste tú, alguien tocó el servidor a mano. El número de línea puede ser otro en tu laboratorio.

## Criterios de éxito

- [ ] Sacas fecha, usuario, IP y huella de cada acceso aceptado (paso 2)
- [ ] Cruzas huellas con `authorized_keys` y dices desde qué equipo se entró (paso 3)
- [ ] Encuentras la llave rechazada y explicas por qué hace falta `VERBOSE` (paso 4)
- [ ] Cuentas fallos por IP y usuarios probados, y explicas por qué salen 8 líneas de 4 intentos (paso 5)
- [ ] Ves quién está dentro ahora y distingues `pts` de `notty` (paso 6)
- [ ] Detectas un cambio de configuración con `sshd -T` y `diff` (paso 7)

## Reto extra

Escribe un script `resumen-ssh` (en `~/w`, no en el kit) que reciba un log y escriba tres bloques: accesos aceptados con el comentario de la llave, las 5 IP con más fallos y los 5 usuarios más probados. Pruébalo con `ssh server cat /var/log/auth.log | ~/w/resumen-ssh /dev/stdin`. ¿Qué tendrías que cambiar para leer `journalctl -u ssh` en un servidor con systemd?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 06 — fail2ban](../lab-06-fail2ban/README.md) | [Proyecto — ssh-infra-kit: auditoría, segundo factor y fail2ban](../../3-proyecto/README.md) → |

[↑ Semana 11](../../README.md)
