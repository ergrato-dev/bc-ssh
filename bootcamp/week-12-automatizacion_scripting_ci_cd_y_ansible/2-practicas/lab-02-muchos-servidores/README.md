# Lab 02 — Muchos servidores

⏱ Duración estimada: ~60 min

## Objetivo

Ejecutar un comando en una lista de servidores: en serie con un resumen de los que fallan, en paralelo con `xargs -P` sin que un servidor caído lo pare todo, y con multiplexing para no pagar una conexión entera cada vez. Al terminar sabes qué tendrías que añadir para que tu bucle fuera Ansible.

## Contexto

- Bucles, paralelo y multiplexing: [teoría 01](../../1-teoria/01-ssh-en-scripts.md#muchos-servidores).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-ssh-en-scripts/README.md).

1. **La lista**, con un servidor al que no llegas (`interno` está en la red privada):
   ```bash
   printf "server\nbastion\ninterno\n" > ~/w/hosts
   ```

2. **En serie, con resumen.**
   ```bash
   cat > ~/w/todos <<'FIN'
   #!/usr/bin/env bash
   # todos: ejecuta un comando en cada host de ~/w/hosts y resume.
   mal=()
   while read -r h; do
     if salida=$(ssh -n -o BatchMode=yes -o ConnectTimeout=5 "$h" "$@" 2>&1); then
       sed "s/^/$h: /" <<< "$salida"
     else
       echo "$h: FALLO ($?)" >&2; mal+=("$h")
     fi
   done < ~/w/hosts
   (( ${#mal[@]} == 0 )) || { echo "fallaron: ${mal[*]}" >&2; exit 1; }
   FIN
   chmod +x ~/w/todos
   ~/w/todos uptime -p; echo "código: $?"
   ```
   ```
   server: up 6 hours, 49 minutes
   bastion: up 6 hours, 49 minutes
   interno: FALLO (255)
   fallaron: interno
   código: 1
   ```
   - El nombre delante de cada línea: con 50 servidores, sin él no sabes de quién es cada salida.
   - Un servidor caído no para a los demás, pero el código final dice que algo falló: un CI o un `cron` se enteran.
   - `"$@"` pasa el comando tal cual; con espacios, recuerda el `%q` del [lab 01](../lab-01-ssh-en-scripts/README.md).

3. **En paralelo, la versión ingenua.**
   ```bash
   xargs -P 3 -I{} ssh -n -o BatchMode=yes -o ConnectTimeout=5 {} "sleep 2; hostname" < ~/w/hosts
   ```
   ```
   ssh: Could not resolve hostname interno: Name or service not known
   xargs: ssh: exited with status 255; aborting
   server
   bastion
   ```
   `xargs -P 3` lanza hasta 3 `ssh` a la vez. Pero cuando un comando sale con 255, `xargs` **deja de lanzar** los que quedan: con 50 servidores, uno caído al principio dejaría 47 sin hacer.

4. **En paralelo, bien.** Envuelve el `ssh` para que su 255 no llegue a `xargs`, y compara con la versión en serie:
   ```bash
   TIMEFORMAT="%R s"
   time xargs -P 3 -I{} sh -c 'ssh -n -o BatchMode=yes -o ConnectTimeout=5 "$1" "sleep 2; hostname" 2>/dev/null || echo "$1: FALLO"' _ {} < ~/w/hosts
   time while read -r h; do ssh -n "$h" "sleep 2; hostname" 2>/dev/null; done < ~/w/hosts
   ```
   ```
   interno: FALLO
   bastion
   server
   2.204 s
   server
   bastion
   4.385 s
   ```
   - En paralelo tarda lo que el más lento (2 s); en serie, la suma.
   - El orden de las líneas cambia de una ejecución a otra: llega primero el que termina antes. Otra razón para el nombre delante.
   - `sh -c '...' _ {}`: el host llega como `$1`, sin pegarlo dentro del texto del comando.

5. **Multiplexing.** Diez conexiones seguidas al mismo servidor, sin y con un master ([semana 05](../../../week-05-configuracion_avanzada_cliente_ssh/README.md)):
   ```bash
   time (for i in 1 2 3 4 5 6 7 8 9 10; do ssh server true; done)
   ssh -o ControlMaster=auto -o ControlPath=~/.ssh/cm-%C -o ControlPersist=1m server true
   time (for i in 1 2 3 4 5 6 7 8 9 10; do ssh -o ControlPath=~/.ssh/cm-%C server true; done)
   ssh -o ControlPath=~/.ssh/cm-%C -O exit server
   ```
   ```
   1.835 s
   0.065 s
   Exit request sent.
   ```
   Cada `ssh` sin master repite el intercambio de llaves y la autenticación. Con master, solo abre un canal en la conexión que ya existe. Ansible hace esto por ti (lab 07).

6. **Lo que le falta a tu bucle.** Escribe en `~/w/notas.md` qué tendrías que añadirle a `~/w/todos` para:
   - instalar un archivo solo si es distinto del que hay, y decir si cambió;
   - ejecutar algo como root sin escribir `sudo` en cada comando;
   - hacer los servidores de 5 en 5, y parar si falla el primer grupo;
   - recargar `sshd` solo en los servidores en los que cambió su configuración.

   Cada punto es una opción de Ansible: `copy`, `become`, `serial` y los handlers ([lab 06](../lab-06-primer-playbook/README.md)).

## Criterios de éxito

- [ ] Tu bucle pone el nombre en cada línea, sigue tras un fallo y sale con 1 si alguno falló (paso 2)
- [ ] Explicas por qué `xargs` se para con un 255 y cómo lo evitas (pasos 3 y 4)
- [ ] Mides la diferencia entre serie y paralelo, y explicas el orden de las líneas (paso 4)
- [ ] Mides la diferencia con multiplexing y explicas de dónde sale (paso 5)
- [ ] Relacionas cada carencia de tu bucle con lo que hace Ansible (paso 6)

## Reto extra

Añade a `~/w/todos` una opción `-P N` que haga lo mismo en paralelo con `xargs`, guardando la salida de cada host en `~/w/salidas/HOST` y escribiendo el resumen de fallos al final.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 01 — SSH dentro de un script](../lab-01-ssh-en-scripts/README.md) | [Lab 03 — Una llave de despliegue](../lab-03-llave-de-despliegue/README.md) → |

[↑ Semana 12](../../README.md)
