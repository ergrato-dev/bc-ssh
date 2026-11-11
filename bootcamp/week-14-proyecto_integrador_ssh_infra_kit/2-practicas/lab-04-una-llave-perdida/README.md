# Lab 04 — Una llave perdida

⏱ Duración estimada: ~60 min

## Objetivo

Seguir de punta a punta el incidente más probable: a Ana le roban el portátil con una sesión abierta. Revocar su llave y su certificado, comprobar que una conexión nueva ya no entra, descubrir que la **abierta sí**, y cortarla. Al final, escribir el procedimiento tal como lo hiciste.

## Contexto

- KRL y revocación: [semana 10](../../../week-10-certificados_ssh_ca_principals_krl_y_rotacion/README.md); un master abierto ya está autenticado: [semana 05](../../../week-05-configuracion_avanzada_cliente_ssh/README.md) y "Cuando cambias llaves" en el README del kit.
- Es el procedimiento "Perdí una llave o un equipo" del RUNBOOK ([proyecto](../../3-proyecto/README.md), paso 4). El ciclo entero: [teoría 02](../../1-teoria/02-documentar-para-operar.md#el-runbook-síntoma-pasos-comprobación).
- Necesitas a Ana y su alias `portatil-ana` del [lab 03](../lab-03-alta-con-certificado/README.md). Su certificado dura 8 h: si caducó, fírmalo otra vez (lab 03, paso 6).

## Instrucciones

0. **Preparación**: el paso 0 del [lab 02](../lab-02-un-servidor-nuevo/README.md).

1. **Ana trabaja.** Una conexión con master, como las que deja el kit (`ControlPersist 10m`): es "su portátil", abierto.
   ```bash
   ssh -fN portatil-ana
   ssh -O check portatil-ana
   ```
   ```
   Master running (pid=39)
   ```
   `-f` se va al fondo tras autenticar, `-N` no abre sesión: queda solo el master. `-O check` pregunta al master si vive.

2. **Esta noche le roban el portátil.** Actúa como si el ladrón ya tuviera la llave. Primero, revoca la llave (y con ella todos sus certificados):
   ```bash
   ca/ca-revoke ~/w/ana/ana.pub
   ssh-keygen -Qf ~/.ssh-ca/revoked.krl ~/w/ana/ana-cert.pub
   ```
   ```
   /home/alumno/w/ana/ana.pub (ana@portatil): REVOKED
   ca-revoke: copia /home/alumno/.ssh-ca/revoked.krl a /etc/ssh/revoked.krl en cada servidor
   /home/alumno/w/ana/ana-cert.pub (ana@portatil): REVOKED
   ```
   - Revocar la **llave** y no solo el certificado (serie 2): si el ladrón tuviera además un certificado que no conoces, también queda fuera.
   - `ssh-keygen -Q` comprueba una llave o un certificado contra la KRL, sin servidor.

3. **La KRL en cada servidor.** Hasta que no está ahí, no ha pasado nada:
   ```bash
   scp -q ~/.ssh-ca/revoked.krl lab-server:
   ssh lab-server 'sudo install -m 644 revoked.krl /etc/ssh/ && rm revoked.krl'
   ```
   `sshd` lee la KRL en cada autenticación: no hace falta recargar. En una flota, el playbook o un bucle por el inventario.

4. **Una conexión nueva no entra.**
   ```bash
   ssh -o ControlPath=none portatil-ana true; echo "código $?"
   ssh lab-server 'sudo grep revoked /var/log/auth.log | tail -1'
   ```
   ```
   ana@server: Permission denied (publickey).
   código 255
   2026-11-11 01:31:08 server sshd: Authentication key ED25519-CERT SHA256:cATJhUpM1JZIuOneWXLL9fqC4i5WtKuHsNVGxbFTTBk revoked by file /etc/ssh/revoked.krl
   ```
   `ControlPath=none`: sin el master, como entraría el ladrón desde otro equipo. El servidor dice por qué; el cliente solo ve `Permission denied`.

5. **Pero la abierta, sí.**
   ```bash
   ssh portatil-ana whoami
   ```
   ```
   ana
   ```
   El master se autenticó **antes** de la revocación, y la KRL solo se mira al autenticar. Quien tenga el portátil (y su sesión abierta) sigue dentro mientras el master viva: 10 minutos después de la última sesión, o para siempre si se usa sin parar. Revocar no basta.

6. **Cortar lo abierto.** En el servidor, las sesiones de Ana son procesos `sshd` suyos:
   ```bash
   ssh lab-server 'pgrep -u ana -a sshd; sudo pkill -u ana sshd; sleep 1; pgrep -u ana -c sshd'
   ssh -O check portatil-ana; echo "código $?"
   ssh portatil-ana true; echo "código $?"
   ```
   ```
   1016 sshd: ana@notty
   0
   Control socket connect(/home/alumno/.ssh/cm/f974d2fde428bd74aa83046b84f26134406b7072): No such file or directory
   código 255
   ana@server: Permission denied (publickey).
   código 255
   ```
   - `sshd: ana@notty` es el master de Ana visto desde el servidor (`notty`: sin terminal, el `-N`). Al matarlo, el master del cliente muere y su socket desaparece.
   - Ahora sí, ni la abierta ni una nueva.
   - Si fuera **tu** cuenta, `pkill -u` cerraría también tu sesión: hazlo desde la consola del proveedor (`docker compose exec server`).

7. **Lo que no hiciste, y harías.** Con certificados, Ana no tenía `authorized_keys`, así que no hay línea que borrar. Sin certificados, el paso 2 sería quitar su llave de cada `authorized_keys` buscando por su **contenido**, no por el comentario (semana 13), y comprobarlo con `bin/key-audit`. Después, Ana crea una llave nueva en un equipo limpio y vuelve a empezar por el alta (lab 03).

8. **Escríbelo.** Abre `RUNBOOK.md` de tu kit y redacta el procedimiento "Perdí una llave o un equipo" **en el orden en que lo hiciste**: síntoma, pasos con sus comandos (revocar, instalar la KRL, cortar lo abierto, comprobar, llave nueva) y la comprobación. Es el TODO 7 del proyecto: lo terminarás allí.

## Criterios de éxito

- [ ] Revocas la llave de Ana (no solo el certificado) y lo compruebas con `ssh-keygen -Q` (paso 2)
- [ ] Una conexión nueva falla, y encuentras `revoked by file` en el log (paso 4)
- [ ] Explicas por qué el master de Ana sigue entrando después de revocar (paso 5)
- [ ] Cortas sus sesiones y compruebas que ni la abierta ni una nueva entran (paso 6)
- [ ] El procedimiento escrito en `RUNBOOK.md`, con su comprobación (paso 8)

## Reto extra

Cronométrate: desde "me han robado el portátil" hasta el paso 6, en un servidor. ¿Cuánto tardarías con 20 servidores? Escribe en el RUNBOOK cómo lo harías con el inventario de Ansible (un `ansible servidores -b -m copy -a "src=... dest=/etc/ssh/revoked.krl mode=0644"` y un `-m command -a "pkill -u ana sshd"`), y pruébalo con los dos servidores del laboratorio.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 03 — Alta con certificado](../lab-03-alta-con-certificado/README.md) | [Lab 05 — Atacar tu servidor](../lab-05-atacar-tu-servidor/README.md) → |

[↑ Semana 14](../../README.md)
