# Lab 07 — Llaves FIDO2

⏱ Duración estimada: ~60 min

## Objetivo

Reconocer una llave `-sk` por su pública, ver qué pasa al crearla sin dispositivo, preparar el servidor para aceptarla con las opciones adecuadas y, si tienes una llave de seguridad FIDO2, usarla de verdad desde tu equipo.

## Contexto

- Llaves FIDO2, opciones y lado del servidor: [teoría 03](../../1-teoria/03-llaves-fido2-sk.md).
- La **parte A** se hace en el laboratorio. La **parte B** necesita un dispositivo FIDO2 (YubiKey, SoloKey, Nitrokey, Titan...) y se hace **en tu equipo**, fuera de Docker: un contenedor no ve tus dispositivos USB. Si no tienes uno, haz solo la parte A y lee la B.
- `ejemplo-sk.pub` es la pública de una llave `ed25519-sk` de ejemplo, escrita para este lab. Su privada no existe en ningún dispositivo: sirve para leerla, no para entrar.
- **La contraseña `alumno` es solo del laboratorio.**

## Parte A — En el laboratorio

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d
   docker compose run --rm client
   ```
   **En el cliente:**
   ```bash
   cd bootcamp/week-04-ssh_agent_y_llaves_fido2/2-practicas/lab-07-llaves-fido2
   mkdir -p -m 700 ~/.ssh
   ```

1. **Crear una sin dispositivo:**
   ```bash
   ssh-keygen -t ed25519-sk -f ~/.ssh/sk; echo "código: $?"
   ls ~/.ssh
   ```
   ```
   Generating public/private ed25519-sk key pair.
   You may need to touch your authenticator to authorize key generation.
   Key enrollment failed: device not found
   código: 255
   ```
   `ssh-keygen` sabe crear llaves `-sk` (OpenSSH 9.6 trae `ssh-sk-helper` y `libfido2`), pero sin dispositivo no hay dónde generar la privada, y no deja ningún archivo a medias. `ls` no imprime nada: `~/.ssh` sigue vacía.

2. **La pública de una llave `-sk`:**
   ```bash
   cat ejemplo-sk.pub
   ssh-keygen -lf ejemplo-sk.pub
   ```
   ```
   sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAI... alumno@portatil
   256 SHA256:kDTULHvcNvPsEUfAEHTvHQXi63AsIMRHDbNIRDF6P6k alumno@portatil (ED25519-SK)
   ```
   Los mismos tres campos que en la semana 03. El tipo es `sk-ssh-ed25519@openssh.com` y la huella termina en `(ED25519-SK)`.

3. **Lo que lleva dentro:**
   ```bash
   cut -d' ' -f2 ejemplo-sk.pub | base64 -d | tr -c '[:print:]' '.'; echo
   ```
   ```
   ....sk-ssh-ed25519@openssh.com... .A....6.@......8=..t.......L........ssh:
   ```
   - `base64 -d` decodifica el segundo campo; `tr -c '[:print:]' '.'` cambia por `.` los bytes que no son texto.
   - Se leen el tipo, 32 bytes de llave pública (los puntos y símbolos del medio) y, al final, `ssh:`: la *application*, que en una llave normal no existe. Con `-O application=ssh:NOMBRE` puedes tener varias llaves en el mismo dispositivo.

4. **Qué exige el servidor por defecto:**
   **En tu equipo:**
   ```bash
   docker compose exec server sshd -T | grep pubkeyauthoptions
   ```
   ```
   pubkeyauthoptions none
   ```
   - `sshd -T` muestra la configuración efectiva del servidor.
   - `none` no significa "sin exigencias": por defecto `sshd` ya exige el toque en las llaves `-sk`. `touch-required` lo exigiría incluso a las líneas con `no-touch-required`, y `verify-required` exigiría además el PIN ([teoría 03](../../1-teoria/03-llaves-fido2-sk.md#el-lado-del-servidor)). Lo configurarás en la semana 07.

5. **Líneas de `authorized_keys` para llaves `-sk`.** **En el cliente**, escribe las dos variantes en un archivo de notas:
   ```bash
   echo "verify-required $(cat ejemplo-sk.pub)" > ~/notas-ak.txt
   echo "restrict,no-touch-required,command=\"/usr/local/bin/backup\" $(cat ejemplo-sk.pub)" >> ~/notas-ak.txt
   cut -c1-80 ~/notas-ak.txt
   ```
   ```
   verify-required sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY
   restrict,no-touch-required,command="/usr/local/bin/backup" sk-ssh-ed25519@openss
   ```
   - La primera: tu acceso personal, con PIN en cada uso.
   - La segunda: una llave de automatización que firma sin toque; precisamente por eso, limitada con `restrict` y un comando forzado (semana 03).

   `~/notas-ak.txt` es solo para este lab: no lo instales en ningún servidor. Está en tu carpeta personal del cliente, no en el repositorio, y desaparece al salir.

## Parte B — Con una llave FIDO2, en tu equipo

Requisitos: OpenSSH 8.2 o superior en tu equipo (`ssh -V`) y la llave de seguridad conectada.

- **Linux:** funciona con el `ssh` del sistema.
- **macOS:** el `ssh` de Apple puede no traer soporte FIDO2 (error `No FIDO SecurityKeyProvider specified`). Instala OpenSSH con Homebrew.
- **Windows con WSL2:** WSL2 no ve los dispositivos USB sin configuración extra. Hazlo desde Linux o macOS.

1. **Crea la llave, con PIN y guardada en el dispositivo:**
   ```bash
   ssh-keygen -t ed25519-sk -O resident -O verify-required -O application=ssh:bc-ssh -f ~/.ssh/bc-ssh-sk
   ```
   Pide el PIN del dispositivo, que lo toques y una frase de paso para el archivo local (puedes dejarla vacía: sin el dispositivo, el archivo no sirve).

2. **Mira los archivos:**
   ```bash
   ls -l ~/.ssh/bc-ssh-sk*
   ssh-keygen -lf ~/.ssh/bc-ssh-sk.pub
   ```
   Compara la huella terminada en `(ED25519-SK)` con el paso A2.

3. **Úsala.** Necesitas un servidor SSH al que llegues desde tu equipo. Puede ser el `server` del laboratorio si publicas su puerto: añade a `compose.yaml`, en `server`, `ports: ["127.0.0.1:2222:22"]` y ejecuta `docker compose up -d server`. Después:
   ```bash
   ssh-copy-id -i ~/.ssh/bc-ssh-sk.pub -p 2222 alumno@127.0.0.1
   ssh -i ~/.ssh/bc-ssh-sk -p 2222 alumno@127.0.0.1 hostname
   ```
   `ssh-copy-id` pide la contraseña `alumno` (solo laboratorio). Al entrar, `ssh` pide el PIN (`Enter PIN for ED25519-SK key ...`), te pide que toques el dispositivo (`Confirm user presence for key ED25519-SK SHA256:...`) y confirma con `User presence confirmed`.

4. **Recupérala en otro equipo** (o borrando los archivos locales):
   ```bash
   mkdir /tmp/sk && cd /tmp/sk
   ssh-keygen -K
   ls
   ```
   `-K` descarga del dispositivo las llaves guardadas con `resident` (pide el PIN) y escribe sus archivos en la carpeta actual.

5. **Al terminar**, deshaz el cambio de `compose.yaml` (`git checkout compose.yaml`) y recrea `server`.

## Criterios de éxito

- [ ] Explicas por qué `ssh-keygen -t ed25519-sk` falla en el contenedor y no deja archivos (paso A1)
- [ ] Reconoces una llave `-sk` por su tipo, su huella y su *application* (pasos A2 y A3)
- [ ] Explicas qué exige `sshd` por defecto y qué cambian `verify-required` y `no-touch-required` (pasos A4 y A5)
- [ ] (Si tienes dispositivo) Entraste con la llave `-sk` tocando el dispositivo (parte B)

## Reto extra

Carga tu llave `-sk` en el agente (`ssh-add ~/.ssh/bc-ssh-sk`) y entra dos veces seguidas. ¿Te pide el toque las dos veces aunque la llave esté en el agente? Relaciónalo con el riesgo del agent forwarding de la [teoría 03](../../1-teoria/03-llaves-fido2-sk.md#fido2-y-el-agente). Sin dispositivo, responde a partir de la teoría.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 06 — Confirmar cada uso con `ssh-add -c`](../lab-06-confirmar-cada-uso/README.md) | [Proyecto — ssh-infra-kit: agente y llaves `-sk`](../../3-proyecto/README.md) → |

[↑ Semana 04](../../README.md)
