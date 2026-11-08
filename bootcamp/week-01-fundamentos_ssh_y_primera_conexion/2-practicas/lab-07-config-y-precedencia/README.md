# Lab 07 — `~/.ssh/config` y precedencia

⏱ Duración estimada: ~60 min

## Objetivo

Escribir alias en un archivo de configuración de cliente, comprobar con `ssh -G` qué valor gana para cada opción y corregir un `config` mal ordenado.

## Contexto

- El cliente lee la configuración en este orden: **1)** opciones de la línea de comandos (`-l`, `-p`, `-o`), **2)** tu `~/.ssh/config` (o el archivo que indiques con `-F`), **3)** el del sistema, `/etc/ssh/ssh_config`.
- Para cada opción, **gana el primer valor que encuentra** y los siguientes se ignoran. Dentro de un archivo pasa lo mismo, de arriba abajo: por eso los bloques concretos van arriba y `Host *` al final.
- **Qué:** `ssh -G HOST` imprime la configuración final para ese host, sin conectarse. **Para qué:** probar un `config` sin red ni contraseñas. **Impacto:** es la forma de resolver el clásico "¿por qué ssh usa este usuario si yo puse otro?".
- En este lab el archivo se pasa siempre con `-F config`: así no tocas `~/.ssh/config`. La semana 05 lo vuelve modular con `Include`.

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d
   docker compose run --rm client
   ```
   **En el cliente**:
   ```bash
   cd bootcamp/week-01-fundamentos_ssh_y_primera_conexion/2-practicas/lab-07-config-y-precedencia
   cat starter/config
   ```

1. Sin `config` propio, `srv` no es nadie:
   ```bash
   ssh -G srv | grep -E '^(hostname|user) '
   ```
   ```
   user alumno
   hostname srv
   ```
   `ssh` trataría `srv` como nombre real del host, y el usuario sería tu usuario local. `-G` imprime los nombres de las opciones en minúsculas.

2. La configuración del sistema:
   ```bash
   grep -v '^#' /etc/ssh/ssh_config | grep .
   ```
   ```
   Include /etc/ssh/ssh_config.d/*.conf
   Host *
       SendEnv LANG LC_*
       HashKnownHosts yes
       GSSAPIAuthentication yes
   ```
   Aquí está el `HashKnownHosts yes` que viste en el lab-02. Este archivo es de todos los usuarios de la máquina; lo tuyo va en el tuyo.

3. Ahora con el `config` del starter:
   ```bash
   ssh -G -F starter/config srv | grep -E '^(hostname|user|connecttimeout) '
   ```
   ```
   user nadie
   hostname server
   connecttimeout 10
   ```
   El bloque `Host srv` dice `User alumno` y `ConnectTimeout 3`, pero ganan `nadie` y `10`. `hostname server` sí sale del bloque `srv`, porque `Host *` no define `HostName`.

4. **TODO 1.** Explica en una línea por qué pasa (pista: el orden del archivo). Después corrígelo: mueve el bloque `Host *` entero **al final** del archivo. Comprueba:
   ```bash
   ssh -G -F starter/config srv | grep -E '^(hostname|user|connecttimeout) '
   ```
   ```
   user alumno
   hostname server
   connecttimeout 3
   ```

5. **TODO 2.** Añade un alias `bas` **antes** de `Host *`:
   ```
   Host bas
       HostName bastion
       User alumno
   ```
   ```bash
   ssh -G -F starter/config bas | grep -E '^(hostname|user|connecttimeout) '
   ```
   ```
   user alumno
   hostname bastion
   connecttimeout 10
   ```
   `bas` no define `ConnectTimeout`, así que lo hereda de `Host *`. Así se usa `Host *`: valores por defecto que cualquier bloque puede cambiar.

6. La línea de comandos gana a todo:
   ```bash
   ssh -G -F starter/config -l otro srv | grep '^user '
   ssh -G -F starter/config -o User=x srv | grep '^user '
   ```
   ```
   user otro
   user x
   ```
   `-l` es el atajo de `-o User=`. Úsalo para una excepción puntual sin editar el archivo.

7. Conéctate con el alias (huella y contraseña `alumno` como en el lab-02):
   ```bash
   ssh -F starter/config srv hostname
   ```
   ```
   server
   ```

8. Los permisos importan. Instala el archivo como tu `~/.ssh/config` con permisos demasiado abiertos y mira qué pasa:
   ```bash
   mkdir -p ~/.ssh
   cp starter/config ~/.ssh/config
   chmod 666 ~/.ssh/config
   ssh -G srv > /dev/null
   ```
   ```
   Bad owner or permissions on /home/alumno/.ssh/config
   ```
   Si otro usuario pudiera escribir tu config, podría redirigir `srv` a su máquina. `ssh` se niega a leerlo. Arréglalo:
   ```bash
   chmod 600 ~/.ssh/config
   ssh srv hostname
   ```
   `600`: lectura y escritura solo para ti. Ahora `ssh srv` funciona sin `-F`, porque `~/.ssh/config` se lee por defecto. Al salir del cliente se borra (contenedor nuevo cada vez); tu copia buena está en `starter/config`.

## Criterios de éxito

- [ ] Explicas por qué el starter da `user nadie` (pasos 3 y 4)
- [ ] Tras corregir, `ssh -G -F starter/config srv` da `user alumno` y `connecttimeout 3` (paso 4)
- [ ] `bas` resuelve a `bastion` y hereda `connecttimeout 10` (paso 5)
- [ ] `-l otro` gana al archivo (paso 6)
- [ ] Reprodujiste `Bad owner or permissions` y lo arreglaste con `chmod 600` (paso 8)

## Reto extra

Escribe un bloque `Host srv bas` (dos patrones en la misma línea) con `Port 22` y otro `Host s*` con `User prueba`. Colócalos en distintas posiciones y predice, **antes** de ejecutar `ssh -G`, qué usuario sale para `srv`, `bas` y `sistema`. Comprueba tus predicciones.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 06 — Los cinco errores más comunes](../lab-06-errores-comunes/README.md) | [Proyecto — ssh-infra-kit: config y lab-check](../../3-proyecto/README.md) → |

[↑ Semana 01](../../README.md)
