# Llaves FIDO2: la privada dentro de un dispositivo

⏱ Lectura: ~30 min

Con frase de paso y agente, la privada sigue siendo un archivo en tu disco y, mientras está cargada, un dato en la memoria del agente. Una **llave de seguridad FIDO2** (YubiKey, SoloKey, Nitrokey, Titan...) lleva la privada a un dispositivo USB o NFC del que no sale nunca, y exige que **lo toques** para cada firma.

## Qué cambia

- **Qué:** la privada se genera **dentro** del dispositivo y no se puede exportar. El dispositivo firma cuando se lo piden, y solo si alguien lo toca (presencia del usuario).
- **Para qué:** quien copie tus archivos o abuse de tu agente no puede firmar sin el dispositivo físico y sin tocarlo.
- **Impacto:** sin el dispositivo conectado, no entras. Necesitas un segundo dispositivo de respaldo (o una llave normal guardada) para no quedarte fuera si lo pierdes.

OpenSSH lo admite desde la versión 8.2 con dos tipos de llave. El sufijo `-sk` viene de *security key*:

| Tipo | Nombre en la `.pub` | Cuándo |
|---|---|---|
| `ed25519-sk` | `sk-ssh-ed25519@openssh.com` | Por defecto: Ed25519, como en la semana 03 |
| `ecdsa-sk` | `sk-ecdsa-sha2-nistp256@openssh.com` | Dispositivos antiguos que no admiten Ed25519 |

## Crear una

```bash
ssh-keygen -t ed25519-sk
```

```
Generating public/private ed25519-sk key pair.
You may need to touch your authenticator to authorize key generation.
```

Tocas el dispositivo, y `ssh-keygen` sigue como en la semana 03: ruta (`~/.ssh/id_ed25519_sk`), frase de paso y huella. Sin dispositivo conectado:

```
Key enrollment failed: device not found
```

Es lo que verás en el laboratorio: un contenedor Docker no ve los dispositivos USB de tu equipo. Por eso las llaves `-sk` se crean y se usan **en tu equipo** (lab 07).

## Qué hay en cada archivo

| Archivo | Contenido | Si alguien lo copia |
|---|---|---|
| `id_ed25519_sk.pub` | Tipo, llave pública y `ssh:` (la *application*) | Nada: es pública |
| `id_ed25519_sk` | Un **identificador** (*key handle*) que el dispositivo necesita para encontrar su privada, no la privada en sí | Sin el dispositivo, no sirve para firmar |

La pública tiene la misma forma que en la semana 03:

```
sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29t... alumno@portatil
```

```bash
ssh-keygen -lf id_ed25519_sk.pub
```

```
256 SHA256:kDTULHvcNvPsEUfAEHTvHQXi63AsIMRHDbNIRDF6P6k alumno@portatil (ED25519-SK)
```

Se instala con `ssh-copy-id` y va en `authorized_keys` como cualquier otra. Al entrar, `ssh` pide el toque:

```
Confirm user presence for key ED25519-SK SHA256:kDTU...
User presence confirmed
```

## Opciones al crearla

`ssh-keygen -O OPCIÓN` las fija al crear la llave:

| Opción | Qué hace |
|---|---|
| `-O verify-required` | Además de tocar, pide el **PIN** del dispositivo en cada firma (`Enter PIN for ED25519-SK key ...`) |
| `-O resident` | Guarda el identificador **en el dispositivo**: en otro equipo, `ssh-keygen -K` recupera los archivos y `ssh-add -K` carga la llave en el agente |
| `-O no-touch-required` | Firma sin tocar. Para automatización; el servidor tiene que aceptarlo expresamente (más abajo) |
| `-O application=ssh:NOMBRE` | Separa varias llaves en el mismo dispositivo; debe empezar por `ssh:` |

`resident` es cómodo, pero cualquiera que tenga el dispositivo puede extraer el identificador. Combínalo con `verify-required`: sin el PIN, el dispositivo no sirve.

## El lado del servidor

Por defecto, `sshd` solo acepta una firma `-sk` si el dispositivo confirma que alguien lo tocó. Se ajusta en dos sitios:

| Dónde | Opción | Efecto |
|---|---|---|
| `authorized_keys` | `no-touch-required` | Esa llave puede entrar sin toque (pareja de `-O no-touch-required`) |
| `authorized_keys` | `verify-required` | Esa llave tiene que haber pedido el PIN |
| `sshd_config` | `PubkeyAuthOptions touch-required` | Toque obligatorio siempre, aunque la línea diga `no-touch-required` |
| `sshd_config` | `PubkeyAuthOptions verify-required` | PIN obligatorio para todas las llaves `-sk` |

Las dos de `sshd_config` las usarás en la semana 07.

## FIDO2 y el agente

Una llave `-sk` también se carga en el agente con `ssh-add`, pero lo que guarda el agente es el identificador, no la privada: **cada firma sigue pidiendo el toque**.

- **Impacto:** el riesgo del agent forwarding ([teoría 02](02-agent-forwarding-y-riesgos.md#el-riesgo)) baja mucho. Si root del servidor usa tu socket, tu dispositivo parpadea pidiendo un toque que no esperabas, y sin tocarlo no hay firma. Es la misma idea que `ssh-add -c`, pero la confirmación la hace un dispositivo, no un programa de tu equipo.

## Cuándo usar cada tipo de llave

| Situación | Llave |
|---|---|
| Tu acceso personal a servidores importantes | `ed25519-sk` con `verify-required`, y una segunda llave de respaldo instalada |
| Tu acceso diario sin dispositivo | `ed25519` con frase de paso y agente con caducidad |
| Un script o una tarea programada | `ed25519` sin frase, limitada con `restrict` y `command=` (semana 03) |

## Puntos clave

- Con `-sk`, la privada vive en el dispositivo y no se puede copiar; el archivo local es solo un identificador.
- Cada firma exige tocar el dispositivo; con `verify-required`, también el PIN.
- `-O resident` permite usar la llave en otro equipo con `ssh-keygen -K` o `ssh-add -K`.
- `sshd` exige el toque por defecto; `no-touch-required` y `PubkeyAuthOptions` lo ajustan.
- En el agente, una llave `-sk` sigue pidiendo el toque: un abuso del forwarding se nota.
- Docker no ve tu dispositivo USB: las llaves `-sk` se usan en tu equipo.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — Agent forwarding y sus riesgos](02-agent-forwarding-y-riesgos.md) | [Índice de labs](../2-practicas/README.md) → |

[↑ Semana 04](../README.md)
