# Lab 07 — Las seis averías de `romper.sh`

Mira cada una solo después de intentarla. En todas, la consola es `docker compose exec server ...` desde tu equipo.

| N | `bin/doctor` dice | El log del servidor dice | Causa | Arreglo | Qué lo habría evitado |
|:--:|---|---|---|---|---|
| 1 | `Permission denied (publickey)` | `Authentication refused: bad ownership or modes for directory /home/alumno/.ssh` | `~/.ssh` escribible por otros (`o+w`): `StrictModes` ignora `authorized_keys` | `chmod o-w /home/alumno/.ssh` | Nada en el kit: es `sshd` protegiéndote. Lo que ayuda es saber leer el log (semana 13) |
| 2 | `Permission denied (publickey)` | `User alumno from ... not allowed because none of user's groups are listed in AllowGroups` | `alumno` fuera de `ssh-users` | `gpasswd -a alumno ssh-users` | La tarea del playbook "Quien despliega sigue pudiendo entrar"; pero el playbook entra como `alumno`, así que aquí solo vale la consola |
| 3 | `no matching key exchange method found. Their offer: diffie-hellman-group14-sha1,...` | `Unable to negotiate with ...` | Un `05-cambio.conf` deja solo un intercambio con SHA-1 | Vaciar `05-cambio.conf`, `sshd -t` y `kill -HUP` | Cambios solo desde el repositorio: el playbook borra lo que no es del kit. **No** es un caso para `legado-*`: el servidor es tuyo y se arregla |
| 4 | `Connection refused` | `Server listening on :: port 2222.` | `Port 2222` en `05-cambio.conf` | Lo mismo que la 3 | Lo mismo que la 3; `bin/audit` en un cron lo habría visto antes que tú |
| 5 | `REMOTE HOST IDENTIFICATION HAS CHANGED` | Nada: el servidor no sabe que el cliente no confía | Host key Ed25519 regenerada | RUNBOOK, "La host key cambió": la huella por la consola (`ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`), `ssh-keygen -R server` y `bin/kh-add` | Un certificado de host (lab 03): el cliente confía en la CA; firmas la llave nueva y nadie ve el aviso |
| 6 | `Permission denied (publickey)` | `Authentication key ED25519 SHA256:... revoked by file /etc/ssh/revoked.krl` | Alguien escribió una KRL que revoca tu llave | Vaciar `/etc/ssh/revoked.krl` por la consola (`truncate -s0`) y, ya dentro, instalar la KRL de tu CA (`~/.ssh-ca/revoked.krl`) | Que la KRL solo salga de `ca/ca-revoke`, y comprobarla antes de instalarla (`ssh-keygen -Qf revoked.krl ~/.ssh/lab.pub`) |

## Lo que tienen en común

- **1, 2 y 6** dan el mismo error en el cliente. La diferencia solo está en el servidor: por eso la pista de `doctor` manda al log y a `sshd -d`. Quien adivina sin mirar el log tarda diez veces más.
- **3 y 4** son cambios hechos a mano fuera del repositorio. El arreglo inmediato es por la consola, y el de verdad es que no vuelva a pasar: el playbook y `changed=0` (lab 02, reto).
- **5** no es un fallo del servidor sino del cliente, que hace bien en no entrar. El arreglo es comprobar, nunca aceptar.

Si en la defensa la avería no es ninguna de estas, el método es el mismo: capa, pista, log, RUNBOOK, comprobación.
