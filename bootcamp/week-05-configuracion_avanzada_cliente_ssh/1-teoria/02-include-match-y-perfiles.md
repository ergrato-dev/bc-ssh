# `Include`, `Match` y perfiles con `-P`

⏱ Lectura: ~30 min

Con diez hosts, un solo `config` todavía se lee bien. Con cincuenta, entre trabajo, laboratorio y proyectos personales, ya no. `Include` lo parte en archivos, `Match` aplica opciones según condiciones que `Host` no puede comprobar y `Tag` deja elegir un perfil al conectar.

## `Include`: un archivo por tema

```
Include conf.d/*.conf
```

- **Qué:** lee los archivos indicados en ese punto, como si su texto estuviera escrito ahí.
- **Para qué:** un archivo por grupo de hosts o por tema (`10-trabajo.conf`, `20-lab.conf`), que puedes añadir, quitar o compartir sin tocar el resto.
- **Impacto:** la regla del primer valor sigue valiendo **a través** de los archivos: un `Host *` dentro del primer archivo incluido fija valores para todo lo que venga después.

Cómo busca los archivos:

- **Rutas relativas:** desde `~/.ssh` si el `Include` está en tu configuración de usuario, y desde `/etc/ssh` si está en la del sistema. **Nunca desde la carpeta del archivo que contiene el `Include`**, aunque lo leas con `-F`.
- **Comodines:** `*` y `?`, como en la shell. Los archivos se leen en orden alfabético; por eso se numeran (`00-`, `10-`, `90-`).
- **Si no existe:** `ssh` no avisa. Solo `-v` lo dice:
  ```
  debug1: /home/alumno/.ssh/config line 2: include ~/.ssh/no-existe.conf matched no files
  ```
- **Dentro de un bloque:** un `Include` debajo de `Host` o `Match` solo se lee para los hosts de ese bloque.

La búsqueda desde `~/.ssh` es la que obliga a tu kit a un paso más: su `config` dice `Include kit/conf.d/*.conf`, y `bin/kit-link` crea el enlace `~/.ssh/kit` a la carpeta del kit. Lo haces en el [proyecto](../3-proyecto/README.md).

## `Match`: condiciones

`Host` solo mira el nombre escrito. `Match` abre un bloque igual que `Host`, pero con **criterios**; el bloque se aplica si se cumplen todos:

| Criterio | Se cumple si... |
|----------|-----------------|
| `host PATRONES` | el host **en ese momento** (después de un `HostName` anterior) coincide |
| `originalhost PATRONES` | el nombre escrito coincide (como `Host`) |
| `user PATRONES` | el usuario remoto coincide |
| `localuser PATRONES` | tu usuario local coincide |
| `exec "ORDEN"` | la orden termina con código 0 |
| `tagged NOMBRE` | la conexión tiene esa etiqueta (`Tag` o `-P`) |
| `all` | siempre |

Los patrones son los de `Host` (`*`, `?`, listas separadas por **comas**, `!`). Varios criterios en una línea se combinan con "y": `Match host server user alumno`.

### `host` frente a `originalhost`

`ssh` lee el archivo de arriba abajo, y `Match host` compara con el `HostName` que ya tenga **cuando llega a esa línea**:

```
Match host server
    User antes
Host lab-server
    HostName server
Match host server
    Port 2222
Match originalhost server
    ConnectTimeout 9
```

| Escribes | `User` | `Port` | `ConnectTimeout` |
|----------|--------|--------|------------------|
| `ssh lab-server` | `alumno` (tu usuario local) | `2222` | `none` |
| `ssh server` | `antes` | `2222` | `9` |

Con `ssh lab-server`, el primer `Match host server` no se cumple: todavía no se ha leído `HostName server`. El segundo sí. `originalhost` solo se cumple con lo que escribiste.

### `Match exec`

```
Match exec "test -f ~/.ssh/modo-viaje"
    ConnectTimeout 30
    ServerAliveInterval 15
```

- **Qué:** ejecuta la orden con tu shell; si sale con 0, el bloque se aplica. Acepta tokens (`%h`, `%n`, `%r`...).
- **Para qué:** condiciones que `ssh` no conoce: si estás en una red, si existe un archivo, si un programa responde.
- **Impacto:** la orden se ejecuta en **cada** `ssh`, también con `ssh -G`. Una orden lenta (un `ping` a un host caído) retrasa todas tus conexiones.

Un token dentro de `exec` lleva a la shell un texto que no escribiste tú: el nombre de host de un enlace, de un submódulo de git o de un script. OpenSSH 9.6 rechaza nombres de host con caracteres de shell:

```bash
ssh -G 'a;b'
```
```
hostname contains invalid characters
```

Aun así, entrecomilla los tokens en `exec`, y no los uses en órdenes que borren o escriban.

## Perfiles: `Tag` y `-P`

```
Match tagged depurar
    LogLevel DEBUG1
```
```bash
ssh -P depurar lab-server
```

- **Qué:** `-P NOMBRE` (o `Tag NOMBRE` en un bloque) pone una etiqueta a la conexión, y `Match tagged NOMBRE` aplica el bloque solo a las etiquetadas.
- **Para qué:** variantes de la misma conexión que eliges al escribir el comando: depurar, red lenta, sin multiplexing.
- **Impacto:** cada conexión tiene **una** etiqueta: `-P` gana a un `Tag` del archivo (regla del primer valor). `Tag` y `Match tagged` llegaron en OpenSSH 9.4: en un equipo con una versión anterior, el archivo da error.

Como todo, los bloques `Match tagged` van **antes** de los valores que cambian. Tu kit tendrá `ssh -P sinmux` ([teoría 03](03-multiplexing.md#cuándo-no-quieres-el-master)) en `conf.d/00-perfiles.conf`, que se lee primero.

## Puntos clave

- `Include` lee archivos en ese punto; rutas relativas desde `~/.ssh` (o `/etc/ssh`), comodines en orden alfabético, y un archivo que falta no da error.
- `Match` aplica un bloque si se cumplen todos sus criterios; `host` mira el host en ese momento y `originalhost` el nombre escrito.
- `Match exec` ejecuta una orden en cada `ssh`: que sea rápida, y con los tokens entre comillas.
- `-P NOMBRE` y `Match tagged NOMBRE` dan perfiles que eliges al conectar.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — Cómo lee `ssh` su configuración](01-como-lee-ssh-su-configuracion.md) | [Teoría — Multiplexing: una conexión, muchas sesiones](03-multiplexing.md) → |

[↑ Semana 05](../README.md)
