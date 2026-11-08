# Lab 03 — `Include` y `conf.d/`

⏱ Duración estimada: ~60 min

## Objetivo

Partir `~/.ssh/config` en archivos con `Include`, ver cómo el orden alfabético decide qué valor gana, descubrir un `Include` que no encuentra nada y resolver el problema de las rutas relativas con `-F`.

## Contexto

- `Include`: [teoría 02](../../1-teoria/02-include-match-y-perfiles.md#include-un-archivo-por-tema).
- Este lab escribe en `~/.ssh` del cliente, que desaparece al salir: puedes romperlo sin miedo.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-el-primer-valor-gana/README.md), con `cd` a esta carpeta.

1. **Un `config` que solo incluye.** Crea la carpeta y los dos archivos:
   ```bash
   mkdir -p -m 700 ~/.ssh/conf.d
   cat > ~/.ssh/config <<'EOF'
   Include conf.d/*.conf

   Host *
       ConnectTimeout 5
   EOF
   cat > ~/.ssh/conf.d/10-lab.conf <<'EOF'
   Host lab-server
       HostName server
       User alumno
       IdentityFile ~/.ssh/lab
   EOF
   ssh lab-server hostname
   ```
   ```
   server
   ```
   Sin `-F`: `ssh` lee `~/.ssh/config`, y este incluye `~/.ssh/conf.d/10-lab.conf`. La ruta `conf.d/*.conf` es relativa a `~/.ssh`.

2. **El orden real de lectura:**
   ```bash
   ssh -v -G lab-server 2>&1 | grep Reading
   ```
   ```
   debug1: Reading configuration data /home/alumno/.ssh/config
   debug1: Reading configuration data /home/alumno/.ssh/conf.d/10-lab.conf
   debug1: Reading configuration data /etc/ssh/ssh_config
   ```
   El incluido se lee **en el punto del `Include`**: antes del `Host *` de `config`.

3. **Un `Host *` que llega demasiado pronto.** Añade unos valores por defecto en un archivo que se lee antes:
   ```bash
   printf 'Host *\n    User nadie\n' > ~/.ssh/conf.d/05-defaults.conf
   ssh -G lab-server | grep '^user '
   ```
   ```
   user nadie
   ```
   `05-` va antes que `10-`: su `Host *` fija `User` para todos. Renómbralo para que se lea el último:
   ```bash
   mv ~/.ssh/conf.d/05-defaults.conf ~/.ssh/conf.d/90-defaults.conf
   ssh -G lab-server | grep '^user '
   ```
   ```
   user alumno
   ```
   La numeración es la forma de controlar el orden: perfiles en `00-`, hosts en `10-` a `80-`, valores por defecto en `90-`.

4. **Un `Include` que no encuentra nada.** Simula un error al escribir la extensión:
   ```bash
   sed -i 's/\*\.conf/*.cfg/' ~/.ssh/config
   ssh lab-server hostname; echo "código: $?"
   ```
   ```
   ssh: Could not resolve hostname lab-server: Name or service not known
   código: 255
   ```
   El error habla del nombre, no del `Include`: `ssh` no avisa de que el patrón no encontró archivos. Solo `-v` lo dice:
   ```bash
   ssh -v -G lab-server 2>&1 | grep 'matched no files'
   ```
   ```
   debug1: /home/alumno/.ssh/config line 1: include ~/.ssh/conf.d/*.cfg matched no files
   debug1: /etc/ssh/ssh_config line 19: include /etc/ssh/ssh_config.d/*.conf matched no files
   ```
   La segunda línea es normal: la carpeta del sistema está vacía. Deshaz el cambio:
   ```bash
   sed -i 's/\*\.cfg/*.conf/' ~/.ssh/config
   ```

5. **`-F` y las rutas relativas.** Un proyecto con su propio `config` y su `conf.d/`, fuera de `~/.ssh`:
   ```bash
   mkdir -p /tmp/proy/conf.d && cd /tmp/proy
   printf 'Include conf.d/*.conf\n' > config
   printf 'Host web\n    HostName bastion\n' > conf.d/20-web.conf
   ssh -G -F config web | grep '^hostname '
   ssh -v -G -F config web 2>&1 | grep Reading
   ```
   ```
   hostname web
   debug1: Reading configuration data config
   debug1: Reading configuration data /home/alumno/.ssh/conf.d/10-lab.conf
   debug1: Reading configuration data /home/alumno/.ssh/conf.d/90-defaults.conf
   ```
   `web` no se resolvió: el `Include` de `/tmp/proy/config` buscó en `~/.ssh/conf.d/`, no en `/tmp/proy/conf.d/`. Con `-F` pasa igual.

6. **La solución: un enlace en `~/.ssh`.**
   ```bash
   ln -s /tmp/proy ~/.ssh/proy
   sed -i 's|^Include .*|Include proy/conf.d/*.conf|' config
   ssh -G -F config web | grep '^hostname '
   ```
   ```
   hostname bastion
   ```
   - `ln -s DESTINO ENLACE` crea un enlace simbólico: `~/.ssh/proy` apunta a `/tmp/proy`.
   - `proy/conf.d/*.conf` se busca desde `~/.ssh`, y el enlace lleva a la carpeta del proyecto.

   Tu kit hará esto con `bin/kit-link` en el proyecto de la semana.

## Criterios de éxito

- [ ] `ssh lab-server` funciona con los hosts en `~/.ssh/conf.d/10-lab.conf` (paso 1)
- [ ] Explicas por qué `05-defaults.conf` rompía `lab-server` y `90-defaults.conf` no (paso 3)
- [ ] Encontraste con `-v` un `Include` que no coincidía con nada (paso 4)
- [ ] Explicas por qué `Include conf.d/*.conf` no lee `/tmp/proy/conf.d` aunque uses `-F` (pasos 5 y 6)

## Reto extra

Un `Include` dentro de un bloque solo se lee para los hosts de ese bloque. Mueve `10-lab.conf` a `~/.ssh/lab.d/` y escribe en `~/.ssh/config`, **antes** del `Include` general:

```
Host lab-*
    Include lab.d/*.conf
```

Comprueba con `ssh -v -G lab-server` y `ssh -v -G server` cuándo se lee `lab.d/`. ¿Hace falta otra línea `Host` después para que lo que sigue en `config` vuelva a aplicarse a todos?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 02 — Patrones y tokens](../lab-02-patrones-y-tokens/README.md) | [Lab 04 — `Match`](../lab-04-match/README.md) → |

[↑ Semana 05](../../README.md)
