# Lab 01 — El primer valor gana

⏱ Duración estimada: ~60 min

## Objetivo

Ver de qué archivos lee `ssh` su configuración y en qué orden, encontrar con `ssh -G` un error de orden en `starter/config` y corregirlo.

## Contexto

- Orden de lectura y regla del primer valor: [teoría 01](../../1-teoria/01-como-lee-ssh-su-configuracion.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d --force-recreate server bastion
   docker compose run --rm client
   ```
   **En el cliente**, prepara `known_hosts` y una llave instalada en `server` y `bastion`, como en la semana 03:
   ```bash
   cd bootcamp/week-05-configuracion_avanzada_cliente_ssh/2-practicas/lab-01-el-primer-valor-gana
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh
   ssh-keyscan -t ed25519 server bastion 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/lab
   for h in server bastion; do sshpass -e ssh-copy-id -f -i ~/.ssh/lab.pub $h; done
   ```
   La llave no tiene frase (`-N ''`) para no escribirla en cada paso: es solo del laboratorio.

1. **El archivo del sistema.** Sin comentarios ni líneas vacías:
   ```bash
   grep -v '^\s*#' /etc/ssh/ssh_config | grep .
   ```
   ```
   Include /etc/ssh/ssh_config.d/*.conf
   Host *
       SendEnv LANG LC_*
       HashKnownHosts yes
       GSSAPIAuthentication yes
   ```

2. **Qué lee `ssh` en cada caso.** `-v` cuenta los archivos y `-G` termina sin conectar:
   ```bash
   ssh -v -G server 2>&1 | grep Reading
   ssh -v -G -F starter/config lab-server 2>&1 | grep Reading
   ```
   ```
   debug1: Reading configuration data /etc/ssh/ssh_config
   debug1: Reading configuration data starter/config
   ```
   - Sin `-F`: `~/.ssh/config` (no existe, así que no aparece) y el del sistema.
   - Con `-F`: **solo** ese archivo. El del sistema ya no se lee.

   Compruébalo contando las opciones que cambian:
   ```bash
   ssh -G server | wc -l
   ssh -G -F /dev/null server | wc -l
   ```
   ```
   89
   87
   ```
   Las dos de más son las dos `sendenv` del sistema (`LANG` y `LC_*`).

3. **El error de `starter/config`.** Léelo (`cat starter/config`) y mira qué haría `ssh`:
   ```bash
   ssh -G -F starter/config lab-server | grep -E '^(user|hostname|connecttimeout) '
   ```
   ```
   user nadie
   hostname server
   connecttimeout 5
   ```
   `HostName` y `ConnectTimeout` salen bien, pero `User alumno` se pierde. Al conectar:
   ```bash
   ssh -F starter/config -o BatchMode=yes lab-server hostname; echo "código: $?"
   ```
   ```
   nadie@server: Permission denied (publickey,password).
   código: 255
   ```
   `-o BatchMode=yes`: si la llave no basta, `ssh` falla en lugar de preguntar la contraseña.

4. **Corrígelo.** Mueve el bloque `Host *` al final de `starter/config` y repite:
   ```bash
   ssh -G -F starter/config lab-server | grep '^user '
   ssh -F starter/config lab-server hostname
   ```
   ```
   user alumno
   server
   ```

5. **La línea de comandos va antes que todo:**
   ```bash
   ssh -G -F starter/config -o User=otro -p 2222 lab-server | grep -E '^(user|port) '
   ```
   ```
   user otro
   port 2222
   ```
   Útil para probar un valor sin editar el archivo.

6. **Repetidas y acumulables.** Crea un archivo de prueba:
   ```bash
   cat > /tmp/dup.conf <<'EOF'
   Host lab-server
       User uno
       User dos
       IdentityFile ~/.ssh/a
       IdentityFile ~/.ssh/b

   Host *
       IdentityFile ~/.ssh/c
   EOF
   ssh -G -F /tmp/dup.conf lab-server | grep -E '^(user|identityfile) '
   ```
   ```
   user uno
   identityfile ~/.ssh/a
   identityfile ~/.ssh/b
   identityfile ~/.ssh/c
   ```
   `User dos` se descarta, como cualquier segundo valor. `IdentityFile` se acumula: `ssh` probará `a`, `b` y `c`, en ese orden.

## Criterios de éxito

- [ ] Sabes qué archivos lee `ssh` con y sin `-F` (paso 2)
- [ ] Encontraste el error de `starter/config` con `ssh -G` y lo corregiste (pasos 3 y 4)
- [ ] Explicas por qué `User dos` no cuenta y los tres `IdentityFile` sí (paso 6)

## Reto extra

Con `ssh -G -F /dev/null x`, averigua los valores por defecto de `Port`, `ConnectTimeout`, `ServerAliveInterval` y `ForwardAgent`. ¿Cuál de ellos cambió tu kit, y en qué semana?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Índice de labs](../README.md) | [Lab 02 — Patrones y tokens](../lab-02-patrones-y-tokens/README.md) → |

[↑ Semana 05](../../README.md)
