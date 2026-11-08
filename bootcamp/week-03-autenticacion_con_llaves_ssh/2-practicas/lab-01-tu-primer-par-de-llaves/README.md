# Lab 01 — Tu primer par de llaves

⏱ Duración estimada: ~60 min

## Objetivo

Generar un par Ed25519, reconocer cada archivo y sus permisos, leer los campos de la pública, calcular su huella y reconstruir la pública a partir de la privada.

## Contexto

- Tipos de llave, archivos y huellas: [teoría 02](../../1-teoria/02-tipos-de-llave-y-frase-de-paso.md).
- Hoy no tocas ningún servidor: todo pasa en el cliente.
- **Nunca** subas una llave privada a git ni la copies en un chat. En este lab la llave vive en el contenedor y desaparece al salir.

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d
   docker compose run --rm client
   ```
   **En el cliente**, comprueba que no tienes llaves:
   ```bash
   ls -la ~/.ssh
   ```
   ```
   ls: cannot access '/home/alumno/.ssh': No such file or directory
   ```
   El cliente es un contenedor nuevo: ni siquiera existe `~/.ssh`.

1. **Genera el par.** Sin `-N`, `ssh-keygen` pregunta la frase de paso; hoy pulsa **Intro** dos veces (sin frase). En el lab 03 verás por qué no deberías hacerlo con una llave real.
   ```bash
   ssh-keygen -t ed25519
   ```
   ```
   Generating public/private ed25519 key pair.
   Enter file in which to save the key (/home/alumno/.ssh/id_ed25519):
   Created directory '/home/alumno/.ssh'.
   Enter passphrase (empty for no passphrase):
   Enter same passphrase again:
   Your identification has been saved in /home/alumno/.ssh/id_ed25519
   Your public key has been saved in /home/alumno/.ssh/id_ed25519.pub
   The key fingerprint is:
   SHA256:86qQFfxu5fSb1n21Hs3B5ISCaS9RcTrciqakBPxrZWI alumno@client
   The key's randomart image is:
   +--[ED25519 256]--+
   ...
   ```
   - `-t ed25519` elige el tipo (en OpenSSH 9.5+ ya es el valor por defecto, pero escribirlo deja claro qué creas).
   - A la pregunta de la ruta, **Intro** acepta la propuesta: `~/.ssh/id_ed25519`, uno de los nombres que `ssh` prueba solo.
   - `ssh-keygen` creó `~/.ssh` porque no existía.

   Tus huellas serán distintas: la llave es aleatoria.

2. **Los archivos y sus permisos:**
   ```bash
   ls -ld ~/.ssh
   ls -l ~/.ssh
   ```
   ```
   drwx------ 2 alumno alumno 4096 Nov  8 05:26 /home/alumno/.ssh
   total 8
   -rw------- 1 alumno alumno 399 Nov  8 05:26 id_ed25519
   -rw-r--r-- 1 alumno alumno  95 Nov  8 05:26 id_ed25519.pub
   ```
   - `ls -ld` muestra el directorio en sí, no su contenido.
   - `~/.ssh` en `700` (`drwx------`): solo tú entras.
   - La privada en `600` (`-rw-------`): solo tú la lees. La pública en `644`: cualquiera puede leerla, y no pasa nada.

3. **La pública, campo a campo:**
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   ```
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO/mMUNZ/v4H9cXYEOkepJYw... alumno@client
   ```
   Tipo, llave en base64 y comentario (`usuario@equipo`). Compara el principio del base64 con el de un compañero (o con el de la [teoría 02](../../1-teoria/02-tipos-de-llave-y-frase-de-paso.md#la-pública-tres-campos)): `AAAAC3NzaC1lZDI1NTE5` es igual en todas las Ed25519, porque codifica el nombre del tipo.

4. **La privada** (solo para mirarla; nunca la copies a ningún sitio):
   ```bash
   head -2 ~/.ssh/id_ed25519
   ```
   ```
   -----BEGIN OPENSSH PRIVATE KEY-----
   b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
   ```
   `head -2` muestra las dos primeras líneas. `b3BlbnNzaC1rZXktdjE` es `openssh-key-v1` en base64; lo decodificarás en el lab 03.

5. **La huella:**
   ```bash
   ssh-keygen -lf ~/.ssh/id_ed25519.pub
   ```
   ```
   256 SHA256:86qQFfxu5fSb1n21Hs3B5ISCaS9RcTrciqakBPxrZWI alumno@client (ED25519)
   ```
   `-l` muestra la huella y `-f` dice de qué archivo. Es la misma que imprimió el paso 1. La verás en `ssh -v` y en los logs del servidor (lab 02).

6. **La pública sale de la privada.** Borra la `.pub` y recupérala:
   ```bash
   rm ~/.ssh/id_ed25519.pub
   ssh-keygen -y -f ~/.ssh/id_ed25519 > ~/.ssh/id_ed25519.pub
   ssh-keygen -lf ~/.ssh/id_ed25519.pub
   ```
   ```
   256 SHA256:86qQFfxu5fSb1n21Hs3B5ISCaS9RcTrciqakBPxrZWI alumno@client (ED25519)
   ```
   `-y` lee la privada e imprime su pública; `>` la guarda en el archivo. Misma huella: perder la `.pub` no es un problema. Perder la **privada** sí: no se puede reconstruir.

7. **Comparar con RSA:**
   ```bash
   ssh-keygen -q -t rsa -N '' -f /tmp/rsa
   ssh-keygen -lf /tmp/rsa.pub
   wc -c /tmp/rsa.pub ~/.ssh/id_ed25519.pub
   ```
   ```
   3072 SHA256:tdGOyLNIgUAEtyfPFBkdJzD7rn5dXBnNXDaF97O+4co alumno@client (RSA)
    567 /tmp/rsa.pub
     95 /home/alumno/.ssh/id_ed25519.pub
    662 total
   ```
   - `-q` silencioso, `-N ''` sin frase de paso (sin preguntar), `-f` dónde guardarla.
   - `wc -c` cuenta bytes. La pública RSA es seis veces más larga para una seguridad parecida; además, crearla tarda más.

8. **Cambiar el comentario.** El comentario `alumno@client` no dice para qué es la llave:
   ```bash
   ssh-keygen -c -C "alumno lab bc-ssh" -f ~/.ssh/id_ed25519
   cat ~/.ssh/id_ed25519.pub | cut -d' ' -f3-
   ```
   ```
   Old comment: alumno@client
   Comment 'alumno lab bc-ssh' applied
   alumno lab bc-ssh
   ```
   `-c` cambia el comentario de la privada y de la pública; `cut -d' ' -f3-` muestra del tercer campo al final. La llave y su huella no cambian.

## Criterios de éxito

- [ ] Tienes `~/.ssh` en 700, la privada en 600 y la pública en 644 (paso 2)
- [ ] Explicas los tres campos de la `.pub` (paso 3)
- [ ] Reconstruiste la `.pub` con `-y` y su huella coincide (paso 6)
- [ ] Explicas por qué perder la `.pub` no importa y perder la privada sí (paso 6)

## Reto extra

Genera una llave ECDSA (`-t ecdsa`) y otra con `-t ecdsa -b 521`. Compara tamaños y huellas con `ssh-keygen -lf`. Busca en la [teoría 02](../../1-teoria/02-tipos-de-llave-y-frase-de-paso.md#qué-tipo-elegir) por qué el bootcamp prefiere Ed25519 a ECDSA aunque las dos sean curvas elípticas.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Índice de labs](../README.md) | [Lab 02 — Entrar sin contraseña](../lab-02-entrar-sin-contrasena/README.md) → |

[↑ Semana 03](../../README.md)
