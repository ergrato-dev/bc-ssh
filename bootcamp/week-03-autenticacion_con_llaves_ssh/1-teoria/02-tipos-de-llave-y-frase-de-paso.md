# Tipos de llave, archivos y frase de paso

⏱ Lectura: ~30 min

La [teoría 01](01-autenticacion-con-llave-publica.md) explicó para qué sirve un par de llaves. Este archivo trata de cómo se crea uno: qué tipo elegir, qué hay dentro de cada archivo y cómo proteger la privada.

## Qué tipo elegir

`ssh-keygen -t TIPO` crea el par. Los tipos que encontrarás:

| Tipo | Tamaño | Estado | Cuándo usarlo |
|---|---|---|---|
| `ed25519` | 256 bits, fijo | Valor por defecto desde OpenSSH 9.5 | **Siempre que puedas.** Rápido, llaves cortas, sin parámetros que elegir mal |
| `rsa` | 3072 bits por defecto (`-b`) | Vigente | Servidores o dispositivos antiguos que no admiten Ed25519. Nunca menos de 3072 |
| `ecdsa` | 256, 384 o 521 bits | Vigente | Cuando una política exige curvas NIST. Si no, Ed25519 |
| `dsa` | 1024 bits, fijo | Rechazado por defecto desde OpenSSH 7.0; eliminado en 10.0 | Nunca |
| `ed25519-sk`, `ecdsa-sk` | — | Vigente | Llave en un dispositivo FIDO2 (semana 04) |

- **Qué:** una llave RSA de 3072 bits y una Ed25519 de 256 bits tienen una seguridad parecida; la pública RSA ocupa 567 bytes y la Ed25519, 95.
- **Para qué:** Ed25519 no depende de un buen generador de números aleatorios al **firmar** (ECDSA sí: una firma con un número repetido revela la privada), y no tiene tamaño que elegir.
- **Impacto:** el bootcamp usa Ed25519 en todo. RSA aparece solo para servidores antiguos, como el del lab 04 de la semana 02.

En OpenSSH 9.6, `ssh-keygen -t dsa` todavía crea la llave, pero ni el cliente la ofrece ni el servidor la acepta. No la generes.

## Los dos archivos

`ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519` escribe:

| Archivo | Permisos | Contenido |
|---|---|---|
| `id_ed25519` | `600` (`-rw-------`) | La **privada**, en formato OpenSSH |
| `id_ed25519.pub` | `644` (`-rw-r--r--`) | La **pública**, en una línea |

Sin `-f`, `ssh-keygen` pregunta la ruta y propone `~/.ssh/id_TIPO`: los nombres que el cliente prueba solo ([teoría 01](01-autenticacion-con-llave-publica.md#qué-llaves-prueba-el-cliente)). Con otro nombre (`~/.ssh/lab`, `~/.ssh/github`), hay que decírselo con `IdentityFile` o `-i`.

### La pública: tres campos

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGj+aEJVkWpScJAU6a2BLaY095NdeRLXayBb+zydx21+ alumno@client
```

1. **Tipo**: `ssh-ed25519`.
2. **La llave**, en base64. Empieza siempre igual (`AAAAC3NzaC1lZDI1NTE5`) porque lleva el nombre del tipo codificado dentro.
3. **Comentario**: texto libre, por defecto `usuario@equipo`. No interviene en la autenticación, pero es lo que leerás en un `authorized_keys` con veinte líneas para saber de quién es cada una. Cámbialo con `ssh-keygen -c -C "nuevo comentario" -f LLAVE`.

Es la misma estructura que una línea de `known_hosts` sin el nombre del host, y que una línea de `authorized_keys` sin las opciones ([teoría 03](03-authorized_keys-y-opciones.md)).

### La privada: formato `openssh-key-v1`

```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABAwLG2pa4
...
-----END OPENSSH PRIVATE KEY-----
```

El base64 decodificado empieza por:

| Campo | Sin frase de paso | Con frase de paso |
|---|---|---|
| Identificador | `openssh-key-v1` | `openssh-key-v1` |
| Cifrado | `none` | `aes256-ctr` |
| Derivación de la llave de cifrado | `none` | `bcrypt`, con una sal y un número de rondas |
| La pública | en claro | en claro |
| La privada y el comentario | **en claro** | cifrados |

Por eso `ssh-keygen -y -f LLAVE` puede reconstruir la `.pub` desde la privada: pedirá la frase si la hay. Si borras la `.pub` no pierdes nada; si borras la privada, la llave ya no existe. Las llaves antiguas en formato PEM (`-----BEGIN RSA PRIVATE KEY-----`) siguen funcionando; `ssh-keygen -p -f LLAVE` las convierte al formato nuevo.

## La frase de paso

- **Qué:** una contraseña que cifra el archivo de la privada **en tu disco**. No viaja nunca: el servidor no sabe si tu llave la tiene.
- **Para qué:** si alguien copia `~/.ssh/` (un portátil robado, una copia de seguridad en un sitio equivocado, un `git add .` descuidado), se lleva un archivo cifrado que no le sirve sin la frase.
- **Impacto:** `ssh` te la pide cada vez que necesita firmar (paso 3 de la teoría 01). La semana 04 resuelve esa molestia con `ssh-agent`, que la pide una vez por sesión.

`ssh-keygen -p -f LLAVE` cambia la frase (o la quita, dejándola vacía). Vuelve a cifrar el mismo archivo: la llave y su huella no cambian, así que no hay que tocar ningún servidor. Si **olvidas** la frase, no hay recuperación: generas una llave nueva y la instalas en cada servidor.

### Rondas de bcrypt

La frase no cifra directamente: `bcrypt` la convierte en la llave de cifrado repitiendo un cálculo costoso `N` veces. `-a N` elige `N` (24 por defecto en OpenSSH 9.6).

| `-a` | Tiempo para abrir la llave (laboratorio) |
|---|---|
| 24 (por defecto) | ~0.12 s |
| 100 | ~0.5 s |
| 500 | ~2.4 s |

**Impacto:** para ti, medio segundo al abrir la llave. Para quien robó el archivo y prueba millones de frases, cada intento cuesta lo mismo: con 100 rondas, unas cuatro veces más que con 24. Las rondas no salvan una frase débil (`123456` cae en el primer segundo), pero encarecen todo lo demás. Tu `bin/key-new` usa `-a 100`.

## Huellas de tus llaves

Igual que con las host keys (semana 02), `ssh-keygen -lf LLAVE.pub` da la huella:

```
256 SHA256:/MOIMbMhL5oIXEpO1UhqQf1IICnE3ebjGyPrMBuXLnY alumno@client (ED25519)
```

Es lo que aparece en `ssh -v` (`Offering public key: ... SHA256:...`) y en los logs del servidor (`Accepted publickey for alumno ... ED25519 SHA256:...`). Con ella sabes qué llave se usó en cada conexión sin comparar líneas de base64.

## Permisos en el cliente

`ssh` se niega a usar una privada que otros pueden leer:

```
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
Permissions 0644 for '/home/alumno/.ssh/id_ed25519' are too open.
...
This private key will be ignored.
```

- **Qué:** si el grupo o los demás tienen **cualquier** permiso sobre la privada, `ssh` la ignora.
- **Para qué:** una privada legible por otros usuarios del equipo ya no es privada; `ssh` prefiere fallar a usar una llave que quizá está comprometida.
- **Impacto:** la privada va en `600` (o `400`) y `~/.ssh` en `700`. Pasa sobre todo al copiar llaves entre equipos o desde Windows. Lo corregirás en el [lab 04](../2-practicas/lab-04-permisos-y-strictmodes/README.md).

## Puntos clave

- Ed25519 por defecto; RSA de 3072 bits o más solo si el otro lado no admite Ed25519; DSA nunca.
- La `.pub` tiene tipo, llave y comentario; la privada contiene también la pública.
- Sin frase de paso, la privada está en claro en tu disco.
- La frase cifra el archivo y nunca viaja; cambiarla no cambia la llave.
- `-a` sube el coste de cada intento de adivinar la frase.
- `ssh` ignora una privada con permisos abiertos a otros usuarios.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — Autenticación con llave pública](01-autenticacion-con-llave-publica.md) | [Teoría — `authorized_keys` y sus opciones](03-authorized_keys-y-opciones.md) → |

[↑ Semana 03](../README.md)
