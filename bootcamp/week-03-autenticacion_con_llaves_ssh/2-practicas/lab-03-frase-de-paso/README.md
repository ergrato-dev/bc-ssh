# Lab 03 — La frase de paso

⏱ Duración estimada: ~60 min

## Objetivo

Poner, comprobar y cambiar la frase de paso de una llave; ver en el propio archivo qué cambia cuando está cifrada; medir el coste de las rondas de bcrypt, y escribir un script que encuentre las llaves sin frase.

## Contexto

- La frase de paso, el formato `openssh-key-v1` y las rondas: [teoría 02](../../1-teoria/02-tipos-de-llave-y-frase-de-paso.md#la-frase-de-paso).
- En este lab la frase de ejemplo es `frase-lab`. **Es solo del laboratorio**: una frase real es larga, tuya y no está escrita en ningún sitio.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d
   docker compose run --rm client
   ```
   **En el cliente**, una llave sin frase instalada en `server` (como en el lab 02):
   ```bash
   cd bootcamp/week-03-autenticacion_con_llaves_ssh/2-practicas/lab-03-frase-de-paso
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh
   ssh-keyscan -t ed25519 server 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519
   sshpass -e ssh-copy-id server
   ```

1. **Mira dentro de la privada sin frase.** El base64 decodificado tiene partes legibles:
   ```bash
   sed -n 2,3p ~/.ssh/id_ed25519 | tr -d '\n' | base64 -d 2>/dev/null | head -c 62 | tr -c '[:print:]' '.'; echo
   ```
   ```
   openssh-key-v1.....none....none...........3....ssh-ed25519...
   ```
   - `sed -n 2,3p` toma las líneas 2 y 3 (la 1 es `-----BEGIN...`); `tr -d '\n'` las une; `base64 -d` decodifica.
   - `head -c 62` corta en 62 bytes y `tr -c '[:print:]' '.'` cambia cada byte no imprimible por un punto.

   Cifrado `none`, derivación `none`: la privada está **en claro** dentro del archivo. Quien lo copie, la tiene.

2. **Ponle frase de paso:**
   ```bash
   ssh-keygen -p -f ~/.ssh/id_ed25519
   ```
   ```
   Key has comment 'alumno@client'
   Enter new passphrase (empty for no passphrase):
   Enter same passphrase again:
   Your identification has been saved with the new passphrase.
   ```
   Escribe `frase-lab` dos veces (no se ve al escribir). `-p` cambia la frase; como no tenía, no pide la antigua.

3. **El mismo archivo, ahora cifrado:**
   ```bash
   sed -n 2,3p ~/.ssh/id_ed25519 | tr -d '\n' | base64 -d 2>/dev/null | head -c 62 | tr -c '[:print:]' '.'; echo
   ```
   ```
   openssh-key-v1.....aes256-ctr....bcrypt...........f;..lG.W....
   ```
   `aes256-ctr` cifra la privada; `bcrypt` convierte tu frase en la llave de ese cifrado. Lo que sigue a `bcrypt` es la sal (aleatoria) y el número de rondas.

4. **La llave es la misma:**
   ```bash
   ssh-keygen -lf ~/.ssh/id_ed25519.pub
   ssh server 'ssh-keygen -lf ~/.ssh/authorized_keys'
   ```
   ```
   256 SHA256:86qQFfxu5fSb1n21Hs3B5ISCaS9RcTrciqakBPxrZWI alumno@client (ED25519)
   Enter passphrase for key '/home/alumno/.ssh/id_ed25519':
   256 SHA256:86qQFfxu5fSb1n21Hs3B5ISCaS9RcTrciqakBPxrZWI alumno@client (ED25519)
   ```
   Misma huella en el cliente y en el servidor: no hay que reinstalar nada. `ssh` pidió la frase porque necesita **firmar** (paso 3 del diagrama de la teoría 01). El servidor nunca supo que había frase.

5. **Sin la frase no hay llave:**
   ```bash
   ssh-keygen -y -P '' -f ~/.ssh/id_ed25519; echo "código: $?"
   ssh -o BatchMode=yes server true; echo "código: $?"
   ```
   ```
   Load key "/home/alumno/.ssh/id_ed25519": incorrect passphrase supplied to decrypt private key
   código: 255
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   - `-P ''` da la frase vacía sin preguntar.
   - `BatchMode` no puede preguntar la frase, así que la llave no sirve. Es lo que le pasaría a un script con esta llave: en la semana 04 lo resuelve `ssh-agent`.

6. **Las rondas cuestan tiempo.** Crea tres llaves con frase `x` y distinto `-a`, y mide cuánto tarda abrir cada una:
   ```bash
   for a in 24 100 500; do ssh-keygen -q -t ed25519 -a $a -N x -f /tmp/k$a; done
   for a in 24 100 500; do echo "a=$a"; ( time ssh-keygen -y -P x -f /tmp/k$a >/dev/null ) 2>&1 | grep real; done
   ```
   ```
   a=24
   real	0m0.120s
   a=100
   real	0m0.482s
   a=500
   real	0m2.385s
   ```
   `time` mide lo que tarda un comando; `( ... ) 2>&1` hace falta porque `time` escribe en stderr. Los tiempos dependen de tu equipo; la proporción no. Cada intento de adivinar tu frase con el archivo robado cuesta lo mismo: con `-a 100`, cuatro veces más que con el valor por defecto (24).

7. **TODO de `starter/tiene-frase.sh`.** Crea una llave sin frase más:
   ```bash
   ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/viejo
   ```
   El script recorre las privadas de un directorio (las que tienen un `.pub` al lado) y dice cuáles no tienen frase. Falta la prueba: cambia `if false; then` por
   ```bash
   if ssh-keygen -y -P "" -f "$privada" >/dev/null 2>&1; then
   ```
   Es el paso 5 al revés: si la frase vacía abre la llave, la llave no tiene frase.
   ```bash
   ./starter/tiene-frase.sh; echo "código: $?"
   ```
   ```
   id_ed25519 con-frase
   viejo SIN-FRASE
   código: 1
   ```
   El código 1 permite usarlo en otros scripts: `./starter/tiene-frase.sh >/dev/null || echo "hay llaves sin frase"`.

8. **Ponle frase a `viejo`:** `ssh-keygen -p -f ~/.ssh/viejo` y escribe `frase-lab`. Repite el paso 7: código 0. Responde en tus notas: ¿cuándo tiene sentido una llave **sin** frase? (Pista: [teoría 03](../../1-teoria/03-authorized_keys-y-opciones.md#partir-de-restrict) y lab 06.)

## Criterios de éxito

- [ ] Viste `none` y después `aes256-ctr` / `bcrypt` en el mismo archivo (pasos 1 y 3)
- [ ] Explicas por qué cambiar la frase no obliga a tocar el servidor (paso 4)
- [ ] Mediste el coste de las rondas (paso 6)
- [ ] `./starter/tiene-frase.sh` distingue llaves con y sin frase (paso 7)
- [ ] Respondiste cuándo tiene sentido una llave sin frase (paso 8)

## Reto extra

Cambia `tiene-frase.sh` para que reciba también `--arreglar`: para cada llave sin frase, ejecuta `ssh-keygen -p -a 100 -f LLAVE` (que pedirá la frase nueva). ¿Por qué `-p` con `-a` también cambia las rondas de una llave que ya tenía frase?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 02 — Entrar sin contraseña](../lab-02-entrar-sin-contrasena/README.md) | [Lab 04 — Permisos y `StrictModes`](../lab-04-permisos-y-strictmodes/README.md) → |

[↑ Semana 03](../../README.md)
