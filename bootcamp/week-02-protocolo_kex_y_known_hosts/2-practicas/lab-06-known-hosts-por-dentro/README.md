# Lab 06 — `known_hosts` por dentro

⏱ Duración estimada: ~60 min

## Objetivo

Leer `known_hosts` campo a campo, buscar, hashear y borrar entradas con `ssh-keygen`, y calcular a mano con `openssl` el hash de un nombre para entender qué protege `HashKnownHosts` y qué no.

## Contexto

- El formato, los nombres hasheados y las herramientas están en la [teoría 03](../../1-teoria/03-host-keys-y-known_hosts.md#el-formato-de-known_hosts).
- **Qué:** `HMAC-SHA1(sal, nombre)` es un resumen del nombre que depende de una sal aleatoria distinta en cada línea. **Para qué:** quien lea el archivo no sabe a qué hosts te conectas. **Impacto:** para saber si un nombre está, hay que calcular su HMAC con la sal de **cada** línea; es lo que hacen `ssh` y `ssh-keygen -F`, y lo que harás tú.
- Empiezas con un `known_hosts` vacío porque el cliente es un contenedor nuevo.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d
   docker compose run --rm client
   ```
   **En el cliente**:
   ```bash
   cd bootcamp/week-02-protocolo_kex_y_known_hosts/2-practicas/lab-06-known-hosts-por-dentro
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh
   ```
   `-m 700`: el directorio solo es accesible para ti, como exige `ssh`.

1. **Un `known_hosts` legible.** Escríbelo con `ssh-keyscan` (sin `-H`, nombres en claro):
   ```bash
   ssh-keyscan -t ed25519 server bastion 2>/dev/null > ~/.ssh/known_hosts
   cut -c1-70 ~/.ssh/known_hosts
   ```
   ```
   server ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHMNPVhkH/6lwbRqaCvR9UVSOxA
   bastion ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILI8Cl1bkDDCWrXAOC3nO/2H0M
   ```
   Tres campos: nombre, tipo y llave en base64. Aquí te saltas la verificación porque el lab trata del formato; en un caso real compararías antes las huellas.

2. **Buscar:**
   ```bash
   ssh-keygen -F bastion; echo "código: $?"
   ssh-keygen -F interno; echo "código: $?"
   ```
   ```
   # Host bastion found: line 2
   bastion ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILI8Cl1bkDDCWrXAOC3nO/2H0MuPug1dXVdWWJO0C4dr
   código: 0
   código: 1
   ```
   El código de salida dice si está: útil en scripts (el `kh-add` del proyecto lo usa).

3. **Hashear el archivo:**
   ```bash
   ssh-keygen -H
   cut -c1-70 ~/.ssh/known_hosts
   ```
   ```
   WARNING: /home/alumno/.ssh/known_hosts.old contains unhashed entries
   Delete this file to ensure privacy of hostnames
   /home/alumno/.ssh/known_hosts updated.
   Original contents retained as /home/alumno/.ssh/known_hosts.old
   |1|0OaQ5f3oOrWc7cO0Tl3KC10/VaA=|e1/PPQM+WeoXBTWnIX2j/GU8KZc= ssh-ed255
   |1|ysLpKiPhGzlHNg3i6KDMJysx2k0=|KFOBO629v7A9Q+rO2Cg9BB7Gm+Y= ssh-ed255
   ```
   Ya no se lee qué línea es de qué host. El aviso es importante: la copia `.old` tiene los nombres en claro. Bórrala:
   ```bash
   rm ~/.ssh/known_hosts.old
   ```

4. `ssh-keygen -F` sigue encontrándolos:
   ```bash
   ssh-keygen -F server | cut -c1-70
   ```
   ```
   # Host server found: line 1
   |1|0OaQ5f3oOrWc7cO0Tl3KC10/VaA=|e1/PPQM+WeoXBTWnIX2j/GU8KZc= ssh-ed255
   ```

5. **Las piezas de una línea hasheada.** Sepáralas:
   ```bash
   linea=$(head -1 ~/.ssh/known_hosts)
   echo "$linea" | cut -d' ' -f1 | tr '|' '\n'
   ```
   ```

   1
   0OaQ5f3oOrWc7cO0Tl3KC10/VaA=
   e1/PPQM+WeoXBTWnIX2j/GU8KZc=
   ```
   `cut -d' ' -f1` toma el primer campo y `tr` cambia cada `|` por un salto de línea. La primera línea sale vacía (antes del primer `|` no hay nada). Después: el formato (`1`), la **sal** y el **hash**, ambos en base64.

6. **Calcula el hash a mano:**
   ```bash
   sal=$(echo "$linea" | cut -d'|' -f3)
   echo "$sal" | base64 -d | od -An -tx1
   ```
   ```
    d0 e6 90 e5 fd e8 3a b5 9c ed c3 b4 4e 5d ca 0b
    5d 3f 55 a0
   ```
   La sal son 20 bytes aleatorios. `base64 -d` la decodifica y `od -An -tx1` la muestra en hexadecimal (`-An` sin direcciones, `-tx1` byte a byte). Ahora el HMAC:
   ```bash
   llave_hex=$(echo "$sal" | base64 -d | od -An -tx1 | tr -d ' \n')
   printf %s server | openssl dgst -sha1 -mac HMAC -macopt "hexkey:$llave_hex" -binary | base64
   echo "$linea" | cut -d'|' -f4 | cut -d' ' -f1
   ```
   ```
   e1/PPQM+WeoXBTWnIX2j/GU8KZc=
   e1/PPQM+WeoXBTWnIX2j/GU8KZc=
   ```
   - `printf %s server` envía `server` **sin** salto de línea final; con `echo` el HMAC sería otro.
   - `openssl dgst -sha1 -mac HMAC -macopt hexkey:...` calcula el HMAC-SHA1 con esa llave; `-binary` lo da en bytes y `base64` lo codifica como en el archivo.

   Coinciden: esa línea es de `server`. Prueba con `bastion` en el `printf`: sale otro valor.

7. **TODOs de `starter/buscar.sh`.** El script recorre el archivo línea a línea y, para cada línea hasheada, separa sal y hash con `IFS='|' read`. Completa:
   - **TODO 1**, la función `hmac SAL TEXTO`, con los comandos del paso 6:
     ```bash
     hmac() {
       local llave_hex
       llave_hex=$(base64 -d <<<"$1" | od -An -tx1 | tr -d ' \n')
       printf %s "$2" | openssl dgst -sha1 -mac HMAC -macopt "hexkey:$llave_hex" -binary | base64
     }
     ```
   - **TODO 2**, la comparación: cambia `if false; then` por
     ```bash
     if [[ $(hmac "$sal" "$nombre") == "$hash" ]]; then
     ```
   ```bash
   ./starter/buscar.sh server; echo "código: $?"
   ./starter/buscar.sh interno; echo "código: $?"
   ```
   ```
   línea 1: ssh-ed25519
   código: 0
   código: 1
   ```
   Tu script hace lo mismo que `ssh-keygen -F`.

8. **Qué no protege el hash.** Responde en tus notas: si alguien roba este `known_hosts` y sospecha que te conectas a `db.empresa.com`, ¿puede comprobarlo? (Pista: tu script del paso 7.) El hash oculta la **lista**, no impide **confirmar** un nombre que el atacante ya adivina.

9. **`HostKeyAlias`: guardar con otro nombre.**
   ```bash
   sshpass -e ssh -o HostKeyAlias=mi-servidor -o StrictHostKeyChecking=accept-new server true
   ssh-keygen -F mi-servidor | head -1
   ```
   ```
   Warning: Permanently added 'mi-servidor' (ED25519) to the list of known hosts.
   # Host mi-servidor found: line 3
   ```
   `ssh` ha guardado y buscará la llave como `mi-servidor`, aunque conectó a `server`. Lo usarás con túneles (semana 08), donde muchos servidores distintos aparecen como `localhost:puerto`.

10. **Un `known_hosts` aparte.**
    ```bash
    sshpass -e ssh -o UserKnownHostsFile=/tmp/kh-proyecto -o StrictHostKeyChecking=accept-new server true
    wc -l < /tmp/kh-proyecto
    ```
    ```
    Warning: Permanently added 'server' (ED25519) to the list of known hosts.
    1
    ```
    Una sola línea: con `UserKnownHostsFile` cambiado, `UpdateHostKeys` se desactiva y el cliente no aprende las otras llaves (teoría 03). Si usas archivos propios, actívalo a mano con `-o UpdateHostKeys=yes`.

11. **Borrar y listar:**
    ```bash
    ssh-keygen -R server
    ssh-keygen -lf ~/.ssh/known_hosts | cut -c1-60
    ```
    ```
    # Host server found: line 1
    /home/alumno/.ssh/known_hosts updated.
    Original contents retained as /home/alumno/.ssh/known_hosts.old
    256 SHA256:APuRI98Go93EXpf/RLO5tvZwGBrUxotQ6FP/EOy8L1o |1|ys
    256 SHA256:GiOO/MygF0Rrs+8btbv8PAxfRi9aDhaYQwNyfIza69M |1|D3
    ```
    Quedan `bastion` y `mi-servidor` (la segunda es la llave de `server`, con otro nombre). `-R` busca por nombre, así que no borró `mi-servidor`.

## Criterios de éxito

- [ ] Explicas los tres campos de una línea y las cuatro piezas de un nombre hasheado (pasos 1 y 5)
- [ ] Borraste el `.old` tras `ssh-keygen -H` y sabes por qué (paso 3)
- [ ] Tu HMAC calculado a mano coincide con el del archivo (paso 6)
- [ ] `./starter/buscar.sh` encuentra `server` y no `interno` (paso 7)
- [ ] Respondiste qué no protege el hash (paso 8)

## Reto extra

`known_hosts` admite patrones en líneas sin hashear. Añade a mano una línea `*.lab ssh-ed25519 LLAVE` (con la llave de `server`) y conecta con `ssh -o HostKeyAlias=web.lab server true`. ¿Pregunta por la huella? Explica por qué los patrones no pueden hashearse.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 05 — Host keys y huellas](../lab-05-host-keys-y-huellas/README.md) | [Lab 07 — Políticas de verificación](../lab-07-politicas-de-verificacion/README.md) → |

[↑ Semana 02](../../README.md)
