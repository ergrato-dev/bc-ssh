# Lab 04 — Saltos en `ssh_config`

⏱ Duración estimada: ~60 min

## Objetivo

Escribir el salto una vez en `~/.ssh/config` y olvidarte de `-J`. Desactivarlo cuando no toca, saltar solo cuando no llegas directo, y ver cómo el multiplexing acelera los saltos y cómo `scp` y `rsync` los heredan.

## Contexto

- `ProxyJump` en `ssh_config`, `none` y `Match exec`: [teoría 02](../../1-teoria/02-proxyjump-y-proxycommand.md#ssh_config).
- El primer valor gana, `Match` y multiplexing: semana 05, [teoría 01](../../../week-05-configuracion_avanzada_cliente_ssh/1-teoria/01-como-lee-ssh-su-configuracion.md), [teoría 02](../../../week-05-configuracion_avanzada_cliente_ssh/1-teoria/02-include-match-y-perfiles.md) y [teoría 03](../../../week-05-configuracion_avanzada_cliente_ssh/1-teoria/03-multiplexing.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-red-segmentada/README.md).

1. **El salto en la configuración.**
   ```bash
   cat > ~/.ssh/config <<'EOF'
   Host interno
       ProxyJump bastion
   EOF
   ssh -G interno | grep -E '^(hostname|proxyjump) '
   ssh interno hostname
   ssh -G bastion | grep -c '^proxyjump'
   ```
   ```
   hostname interno
   proxyjump bastion
   interno
   0
   ```
   - `ssh interno` ya salta solo. `ssh -G` lo comprueba sin conectar (semana 05).
   - `bastion` no tiene `ProxyJump` (0 líneas): el bloque solo vale para `interno`. Si pusieras el salto en `Host *`, `ssh bastion` intentaría saltar por sí mismo.
   - `cat > archivo <<'EOF' ... EOF` escribe el texto hasta `EOF` en el archivo, como en la semana 08.

2. **No saltar.** Cuando ya estás dentro de la red (o depuras), `none` desactiva el salto de la configuración:
   ```bash
   ssh -J none interno hostname; echo "código: $?"
   ```
   ```
   ssh: Could not resolve hostname interno: Name or service not known
   código: 255
   ```
   `-J none` (o `-o ProxyJump=none`) gana a la configuración, porque la línea de órdenes va primero. Aquí falla: desde tu equipo no hay ruta directa, que es justo lo que querías comprobar.

3. **Saltar solo si hace falta.** Un portátil que a veces está dentro de la red privada (la oficina) y a veces fuera (tu casa) puede decidir solo:
   ```bash
   cat > ~/.ssh/config <<'EOF'
   Match host interno !exec "getent hosts %h >/dev/null"
       ProxyJump bastion
   EOF
   ssh -G interno | grep '^proxyjump'
   ssh interno hostname
   ssh -v interno true 2>&1 | grep -E 'Executing (command|proxy)'
   ```
   ```
   proxyjump bastion
   interno
   debug1: Executing command: 'getent hosts interno >/dev/null'
   debug1: Executing proxy command: exec ssh -v -W '[interno]:22' bastion
   ```
   - `Match host interno`: el bloque vale para el host `interno`. `exec "..."`: y solo si ese comando sale con 0; `!` lo invierte.
   - Si tu equipo **no** resuelve `interno` (estás fuera), salta. Dentro de la red privada, `getent` lo resolvería y `ssh` iría directo.
   - El comando se ejecuta **cada vez** que `ssh` lee la configuración: que sea rápido.

4. **Multiplexing a través del salto.**
   ```bash
   cat > ~/.ssh/config <<'EOF'
   Host interno
       ProxyJump bastion
   Host *
       ControlMaster auto
       ControlPath ~/.ssh/cm-%C
       ControlPersist 5m
   EOF
   time ssh interno true
   time ssh interno true
   ssh -O check interno; ssh -O check bastion
   time ssh bastion true
   pgrep -a ssh
   ```
   ```
   real	0m0.402s
   real	0m0.053s
   Master running (pid=267)
   Master running (pid=264)
   real	0m0.009s
   261 ssh -W [interno]:22 bastion
   264 ssh: /home/alumno/.ssh/cm-27162b271bc7df6d5f767d57aabb0b0a6af4459e [mux]
   267 ssh: /home/alumno/.ssh/cm-777b3dda073056e9406153ad88b7e4bcc7e6e57a [mux]
   ```
   `time` mide lo que tarda una orden (solo te interesa `real`; tus tiempos serán otros).
   - La primera conexión deja **dos** masters: el del salto (`ssh -W`, que también lee `Host *`) y el de `interno`.
   - La segunda va por el master de `interno`, sin tocar el salto: 8 veces más rápida.
   - `ssh bastion` reutiliza el master que dejó el salto. Y un segundo host interno detrás del mismo bastion también: solo negociaría con el destino.
   - El proceso `261` es el `ssh -W` que lleva el canal del master de `interno`: vive mientras ese master viva.

5. **Archivos, con el alias.** `scp` y `rsync` leen `~/.ssh/config`: saltan sin decir nada más.
   ```bash
   scp interno:/etc/hostname ~/w/de-interno; cat ~/w/de-interno
   echo hola > ~/w/nota.txt; rsync -a ~/w/nota.txt interno:w2/ && ssh interno ls w2
   ```
   ```
   interno
   nota.txt
   ```
   Con el master abierto, cada `scp` o `rsync` tarda milisegundos en conectar.

6. **Cerrar los masters.**
   ```bash
   ssh -O exit interno; ssh -O exit bastion
   pgrep -a ssh; echo "código: $?"
   ```
   ```
   Exit request sent.
   Exit request sent.
   código: 1
   ```
   Al cerrar el master de `interno` termina también su `ssh -W`. `pgrep` sale con 1 cuando no encuentra nada. Recuerda la semana 05: un master abierto sigue entrando aunque quites la llave del servidor; en el bastion, eso es una puerta abierta a toda la red privada.

## Criterios de éxito

- [ ] Escribes un host con `ProxyJump` y lo compruebas con `ssh -G`, y explicas por qué no va en `Host *` (paso 1)
- [ ] Desactivas el salto con `-J none` (paso 2)
- [ ] Explicas qué hace `Match host ... !exec` y cuándo se evalúa (paso 3)
- [ ] Explicas cuántos masters deja un salto y cuál reutiliza cada conexión (paso 4)
- [ ] Copias archivos con `scp` y `rsync` usando solo el alias (paso 5)

## Reto extra

Quieres que `ssh interno.priv` salte a `interno` sin escribir un bloque por host. Con `Host *.priv` y `ProxyJump bastion` no basta: el bastion no resuelve `interno.priv`. `ProxyCommand` se ejecuta con una shell, así que puede recortar el nombre: escribe un `Host *.priv` con `ProxyCommand ssh -W "$(basename %h .priv)":%p bastion` y comprueba que entra. ¿Qué nombre queda en `known_hosts`? ¿Qué ventaja tiene un sufijo así cuando hay decenas de hosts internos?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 03 — `ProxyCommand` y `ssh -W`](../lab-03-proxycommand-y-w/README.md) | [Lab 05 — Agente reenviado frente a ProxyJump](../lab-05-agente-reenviado/README.md) → |

[↑ Semana 09](../../README.md)
