# Lab 04 — TOTP por dentro

⏱ Duración estimada: ~60 min

## Objetivo

Crear un secreto TOTP en `server` con `google-authenticator`, leer qué guarda `~/.google_authenticator` y calcular los códigos en dos sitios distintos con `oathtool` para comprobar que coinciden sin hablarse. Al terminar sabes de qué depende el código, qué pasa con la hora y quién más puede generarlo.

## Contexto

- Cómo se calcula un código TOTP: [teoría 02](../../1-teoria/02-segundo-factor.md#totp-un-código-que-cambia-cada-30-segundos).
- En este lab, `oathtool` hace de móvil. **Un secreto TOTP en una variable o un script es solo para el laboratorio**: en un equipo de verdad vive solo en tu app.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-leer-ssh-audit/README.md).

1. **El secreto.** En `server`, como `alumno`:
   ```bash
   ssh server google-authenticator -t -d -f -r 3 -R 30 -w 3 -e 5 -C -Q NONE
   ```
   ```
   Your new secret key is: 5SOJY6NPOGVXP5K2CUNCEHIAUI
   Your verification code for code 1 is 122437
   Your emergency scratch codes are:
     16351229
     73782765
     83647926
     10097495
     99207366
   ```
   Sin opciones, `google-authenticator` hace las mismas preguntas una a una. Las respuestas:

   | Opción | Qué decide |
   |---|---|
   | `-t` | TOTP: el código depende de la hora (con `-c` sería HOTP, un contador) |
   | `-d` | Cada código vale **una vez** (`DISALLOW_REUSE`) |
   | `-f` | Escribe `~/.google_authenticator` sin preguntar (y pisa el anterior) |
   | `-r 3 -R 30` | Como mucho 3 intentos cada 30 s (`RATE_LIMIT`) |
   | `-w 3` | Acepta el código anterior, el actual y el siguiente (`WINDOW_SIZE`): 90 s de margen |
   | `-e 5` | 5 códigos de emergencia |
   | `-C` | No pide confirmar con un código (no hay móvil en el laboratorio) |
   | `-Q NONE` | No dibuja el código QR |

   Tu secreto y tus códigos serán otros. Apunta el secreto.

2. **El archivo.**
   ```bash
   ssh server 'ls -l .google_authenticator; cat .google_authenticator'
   ```
   ```
   -r-------- 1 alumno alumno 135 Nov 10 21:52 .google_authenticator
   5SOJY6NPOGVXP5K2CUNCEHIAUI
   " RATE_LIMIT 3 30
   " WINDOW_SIZE 3
   " DISALLOW_REUSE
   " TOTP_AUTH
   16351229
   73782765
   83647926
   10097495
   99207366
   ```
   - Primera línea: el secreto, en base32. Es **todo** lo que hace falta para generar tus códigos.
   - Líneas con `"`: las opciones del paso 1. El módulo de PAM las lee y escribe aquí los códigos ya usados.
   - Las últimas, los códigos de emergencia, en claro. Cada uno se borra del archivo al usarse.
   - `400`: solo tú lo lees. PAM rechaza el archivo si otros pueden leerlo.

3. **El primer código.** En el cliente, `oathtool` calcula lo mismo que una app de móvil:
   ```bash
   S=$(ssh server head -1 .google_authenticator)
   oathtool -v --totp -b "$S"
   ```
   ```
   Hex secret: ec9c9c79af71ab77f55a151a221d00a2
   Base32 secret: 5SOJY6NPOGVXP5K2CUNCEHIAUI======
   Digits: 6
   Window size: 0
   TOTP mode: SHA1
   Step size (seconds): 30
   Start time: 1970-01-01 00:00:00 UTC (0)
   Current time: 2026-11-10 21:52:55 UTC (1794347575)
   Counter: 0x390A701 (59811585)

   031517
   ```
   - `--totp`: modo TOTP con SHA1; `-b`: el secreto viene en base32; `-v`: explica cada dato.
   - `Counter`: los periodos de 30 s desde 1970. Compruébalo: `echo $(( $(date +%s) / 30 ))`.
   - El código sale de `HMAC-SHA1(secreto, Counter)`. Cambia el contador cada 30 s, cambia el código.

4. **Dos sitios, el mismo código, sin hablarse.** `server` tiene su propio `oathtool`:
   ```bash
   oathtool --totp -b "$S"; ssh server oathtool --totp -b "$S"
   ```
   ```
   364718
   364718
   ```
   Si te salen distintos, repítelo: caíste justo en el cambio de periodo. Ningún dato viajó entre los dos cálculos: solo comparten secreto y reloj.

5. **La hora.** `-N` calcula el código de otro momento; `-w 2` enseña el actual y los dos siguientes:
   ```bash
   oathtool --totp -b -w 2 "$S"
   oathtool --totp -b -N "$(date -u -d '-30 sec' '+%F %T') UTC" "$S"
   oathtool --totp -b -N "$(date -u -d '+5 min' '+%F %T') UTC" "$S"
   ```
   ```
   031517
   364718
   456622
   710938
   908813
   ```
   - El segundo es el código del periodo anterior: con `WINDOW_SIZE 3`, el servidor aún lo acepta.
   - El tercero es el de dentro de 5 minutos: un móvil con el reloj 5 minutos adelantado lo daría, y el servidor lo rechazaría. Por eso móvil y servidor sincronizan la hora (NTP).

6. **Quién más puede generar tus códigos.**
   ```bash
   ssh server 'sudo head -1 /home/alumno/.google_authenticator'
   ```
   ```
   5SOJY6NPOGVXP5K2CUNCEHIAUI
   ```
   Root lee el secreto. El segundo factor te protege si roban **tu llave**; no si alguien ya es root en el servidor (que, de todos modos, no necesita entrar por SSH). Y cualquier copia de seguridad del home lleva el secreto dentro: trátala como trataste las llaves privadas en la [semana 06](../../../week-06-transferencia_archivos_scp_sftp_rsync/README.md).

7. **Los códigos de emergencia.** Son para el día que pierdes el móvil. Mira cuántos quedan:
   ```bash
   ssh server "grep -cE '^[0-9]{8}$' .google_authenticator"
   ```
   ```
   5
   ```
   En el [lab 05](../lab-05-llave-y-codigo/README.md) usarás uno y verás que baja a 4. Guárdalos fuera del servidor y del móvil (en papel, o en tu gestor de contraseñas).

8. **El QR (opcional, con tu móvil).** Si quieres ver los mismos códigos en tu app:
   ```bash
   ssh -t server google-authenticator -t -d -f -r 3 -R 30 -w 3 -e 5 -C -Q UTF8
   ```
   Escanea el QR: tu app y `oathtool --totp -b SECRETO_NUEVO` darán el mismo número. **Es un secreto de laboratorio**: bórralo de la app al terminar la semana.

## Criterios de éxito

- [ ] Creas un secreto y explicas cada opción de `google-authenticator` (paso 1)
- [ ] Explicas cada línea de `~/.google_authenticator` (paso 2)
- [ ] Calculas el código con `oathtool` y relacionas `Counter` con `date +%s` (paso 3)
- [ ] Obtienes el mismo código en el cliente y en el servidor (paso 4)
- [ ] Explicas qué pasa si el reloj se desvía y qué hace `WINDOW_SIZE` (paso 5)
- [ ] Explicas de qué te protege el segundo factor y de qué no (paso 6)

## Reto extra

`oathtool --hotp -b "$S" -c 0 -w 3` calcula códigos HOTP, que dependen de un contador en lugar de la hora. ¿Qué problema tendría HOTP si el móvil genera códigos que nunca usas? Busca qué hace `google-authenticator -c` con `" HOTP_COUNTER` en el archivo.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 03 — Políticas de ssh-audit](../lab-03-politicas-ssh-audit/README.md) | [Lab 05 — Llave y código](../lab-05-llave-y-codigo/README.md) → |

[↑ Semana 11](../../README.md)
