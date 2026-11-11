# Lab 06 — Reconstruir un servidor

⏱ Duración estimada: ~60 min

## Objetivo

Someter tu documentación a la prueba del extraño: `server` se reinstala (host key nueva, configuración de fábrica) y lo devuelves a su estado siguiendo **al pie de la letra** los procedimientos "La host key cambió" y "Un servidor nuevo". Por el camino aparece el segundo fallo de integración del kit, y cada paso que tuviste que adivinar es una línea que le falta al RUNBOOK.

## Contexto

- La prueba del extraño y la forma de un procedimiento: [teoría 02](../../1-teoria/02-documentar-para-operar.md#la-prueba-del-extraño).
- Los dos procedimientos están en el `RUNBOOK.md` de la [solución del proyecto](../../3-proyecto/solucion/RUNBOOK.md). Si ya escribiste los tuyos, usa los tuyos.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación.** En tu equipo, `server` como recién instalado: host keys nuevas, sin tu llave, sin la configuración del kit, sin la CA.
   ```bash
   docker compose up -d --force-recreate server
   ```
   Después, el paso 0 del [lab 02](../lab-02-un-servidor-nuevo/README.md). Ten a la vista el RUNBOOK.

1. **El síntoma.**
   ```bash
   bin/doctor lab-server; echo "código $?"
   ```
   ```
   destino:  alumno@server:22
   error:      ssh-keygen -f '/home/alumno/.ssh/known_hosts' -R 'server'
             Host key for server has changed and you have requested strict checking.
             Host key verification failed.
   pista:    host key desconocida o cambiada: comprueba la huella por otro canal y añádela con bin/kh-add; nunca la aceptes sin comprobar
   código 255
   ```
   Busca en el RUNBOOK el texto del error: "La host key cambió". Desde aquí, solo lo que diga.

2. **La huella, por otro camino.** El RUNBOOK dice: la consola del proveedor. En tu equipo:
   ```bash
   docker compose exec server ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
   ```
   ```
   256 SHA256:dGSv0t7VJ9885Xhq1SzcOZlDTkc2+BWqzl2emmaY0ik root@server (ED25519)
   ```
   Aquí sabes que lo reinstalaste tú. En la vida real, este es el paso en que preguntas a quien gestiona el servidor: si nadie lo reinstaló, **no sigas**.

3. **Quitar la vieja.**
   ```bash
   ssh-keygen -R server
   ```
   ```
   # Host server found: line 1
   # Host server found: line 3
   # Host server found: line 4
   /home/alumno/.ssh/known_hosts updated.
   Original contents retained as /home/alumno/.ssh/known_hosts.old
   ```
   Tres líneas: la Ed25519 que añadiste en el lab 01 y la RSA y la ECDSA que `UpdateHostKeys` aprendió solo al entrar (semana 13).

4. **Añadir la nueva con `bin/kh-add`.**
   ```bash
   bin/kh-add server SHA256:dGSv0t7VJ9885Xhq1SzcOZlDTkc2+BWqzl2emmaY0ik; echo "código $?"
   ```
   ```
   server: known_hosts ya tiene otra llave ssh-ed25519; verifica y usa ssh-keygen -R server
   código 1
   ```
   Acabas de hacer `ssh-keygen -R server`. ¿Qué "otra llave"?
   ```bash
   ssh-keygen -F server | grep -v '^#' | cut -d' ' -f1-3
   ```
   ```
   @cert-authority server,bastion ssh-ed25519
   ```
   La línea `@cert-authority` del lab 03 cubre `server`, y `ssh-keygen -F` la encuentra. `bin/kh-add` (semana 02) es anterior a la CA (semana 10) y la toma por una host key. `ssh-keygen -R` no la borra, y hace bien: es la CA, no el servidor. Es el **segundo fallo de integración**; lo arreglas en el [proyecto](../../3-proyecto/README.md), paso 3.

5. **Mientras tanto, lo que hace `kh-add`, a mano.** Leer la llave una vez, comprobar **esa misma** copia y añadirla:
   ```bash
   ssh-keyscan -H -t ed25519 server 2>/dev/null > ~/w/server.kh
   ssh-keygen -lf ~/w/server.kh | cut -d' ' -f2
   cat ~/w/server.kh >> ~/.ssh/known_hosts
   ```
   ```
   SHA256:dGSv0t7VJ9885Xhq1SzcOZlDTkc2+BWqzl2emmaY0ik
   ```
   Coincide con el paso 2: solo entonces el `cat`. Un `ssh-keyscan` para mirar y otro para añadir serían dos lecturas distintas: un intermediario podría enseñarte la buena y colarte la suya.

6. **El resto, "Un servidor nuevo".** El servidor reinstalado no tiene tu llave ni la configuración:
   ```bash
   SSHPASS=alumno sshpass -e ssh-copy-id -F config -o ControlPath=none -i ~/.ssh/lab lab-server 2>&1 | grep 'Number of'
   cd ansible && ansible-playbook servidores.yml --limit lab-server | grep -A2 'PLAY RECAP' | grep ^lab; cd ..
   bin/audit lab-server
   bin/doctor lab-server | grep -E 'kex|host key|entrada'
   ```
   ```
   Number of key(s) added: 1
   lab-server                 : ok=14   changed=10   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
   lab-server: cumple
   kex:      sntrup761x25519-sha512@openssh.com (postcuántico)
   host key: ssh-ed25519 SHA256:dGSv0t7VJ9885Xhq1SzcOZlDTkc2+BWqzl2emmaY0ik
   entrada:  publickey
   ```
   - `ControlPath=none` en `ssh-copy-id`: la trampa del lab 01.
   - `--limit lab-server`: solo el reinstalado; `bastion` no se toca.
   - La `host key` de `doctor` es la del paso 2. La comprobación del procedimiento se cumple.

7. **Lo que el RUNBOOK no decía.** Repasa lo que hiciste y apunta, para tu `RUNBOOK.md`, cada cosa que tuviste que saber o adivinar. Por ejemplo:
   - `bin/kh-add` falla con una CA de hosts (hasta el proyecto, paso 3): el paso 5 como alternativa.
   - `ssh-copy-id` necesita `-o ControlPath=none`.
   - La CA: `server` ya no tiene `user_ca.pub`, la KRL, su certificado de host ni `principals/`. Ana no entra hasta repetir los pasos 2 y 3 del [lab 03](../lab-03-alta-con-certificado/README.md) (con la host key nueva: un certificado nuevo).
   - El CI: `KIT_KNOWN_HOSTS` tiene la huella vieja; el próximo despliegue fallará (y debe).

   Un procedimiento que necesita estas notas no está terminado: añádelas a los pasos, con su comando.

## Criterios de éxito

- [ ] Encuentras el procedimiento por el texto del error y consigues la huella por la consola (pasos 1 y 2)
- [ ] Explicas qué "otra llave" encuentra `bin/kh-add` y por qué `ssh-keygen -R` no la borra (paso 4)
- [ ] Añades la host key nueva comprobando la misma copia que añades (paso 5)
- [ ] `server` vuelve a `cumple` y `bin/doctor` enseña la huella nueva (paso 6)
- [ ] Una lista de lo que faltaba en el RUNBOOK, pasada a tu `RUNBOOK.md` (paso 7)

## Reto extra

Haz la prueba del extraño de verdad: pide a otra persona que siga tu procedimiento "Un servidor nuevo" con `bastion` (`docker compose up -d --force-recreate bastion`) sin preguntarte nada. Apunta cada vez que se detiene. ¿Cuántas líneas tuviste que añadir?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 05 — Atacar tu servidor](../lab-05-atacar-tu-servidor/README.md) | [Lab 07 — La defensa](../lab-07-la-defensa/README.md) → |

[↑ Semana 14](../../README.md)
