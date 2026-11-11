# Lab 05 — Medir el rendimiento

⏱ Duración estimada: ~60 min

## Objetivo

Medir dónde se va el tiempo de SSH en una red lenta simulada: cuánto cuesta abrir una conexión con latencia y cuánto lo arregla el multiplexing, qué cifrado mueve más datos por segundo y cuándo la compresión ayuda y cuándo estorba.

## Contexto

- Las tres cosas que hacen lento a SSH (ida y vuelta, CPU y ancho de banda): [teoría 03](../../1-teoria/03-rendimiento-y-migraciones.md#dónde-se-va-el-tiempo).
- `tc` (*traffic control*) con `netem` hace que `server` se comporte como si estuviera lejos: retrasa o limita lo que envía. Solo afecta a la red del contenedor `server` (por eso tiene `NET_ADMIN` en `compose.yaml`), nunca a la de tu equipo. `server` tiene dos interfaces (`eth0` y `eth1`), y los pasos las tocan las dos.
- Tus tiempos serán otros: dependen de tu equipo. Lo que importa es la proporción.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-leer-ssh-v/README.md). `TIMEFORMAT` hace que `time` escriba solo los segundos reales:
   ```bash
   TIMEFORMAT='%R s'
   ```

1. **Sin latencia.**
   ```bash
   time ssh server true
   ping -c 3 -q server | tail -1
   ```
   ```
   0.196 s
   rtt min/avg/max/mdev = 0.050/0.071/0.109/0.026 ms
   ```
   Una ida y vuelta (*RTT*) de 0,07 ms: los 0,2 s son casi todo CPU (el intercambio de llaves y las firmas).

2. **50 ms de latencia**, como un servidor en otro país:
   ```bash
   ssh server 'for i in eth0 eth1; do sudo tc qdisc add dev $i root netem delay 50ms; done'
   ping -c 3 -q server | tail -1
   for i in 1 2 3; do time ssh server true; done
   ```
   ```
   rtt min/avg/max/mdev = 50.112/50.127/50.154/0.019 ms
   0.773 s
   0.791 s
   0.775 s
   ```
   - `qdisc add ... root netem delay 50ms`: todo lo que **sale** de `server` espera 50 ms. Cada ida y vuelta, 50 ms más.
   - De 0,2 a 0,78 s: casi 0,6 s más, unas **11 idas y vueltas** de 50 ms. TCP, versiones, `KEXINIT`, el intercambio, `NEWKEYS`, pedir el servicio, probar la llave, firmar, abrir el canal, el comando y cerrarlo: cada una espera a la anterior.
   - Con 150 ms (otro continente), cada `ssh` pasaría de 1,8 s. Un script que abre una conexión por comando se vuelve inservible.

3. **El multiplexing.** Un master abierto y diez conexiones dentro:
   ```bash
   time (for i in $(seq 10); do ssh server true; done)
   ssh -o ControlMaster=auto -o ControlPath=~/.ssh/cm-%C -o ControlPersist=60 server true
   time (for i in $(seq 10); do ssh -o ControlPath=~/.ssh/cm-%C server true; done)
   ssh -o ControlPath=~/.ssh/cm-%C -O exit server
   ```
   ```
   7.781 s
   1.102 s
   Exit request sent.
   ```
   - Dentro del master solo quedan abrir el canal, el comando y cerrarlo: unas 2 idas y vueltas por conexión (0,11 s).
   - Siete veces menos con 50 ms de latencia; sin latencia, la diferencia es la CPU del intercambio. Tu kit tiene el master activado para todo (`config`, semana 05).
   - Cerrar el master con `-O exit` antes de seguir: si no, el paso 6 lo reutilizaría y no verías la compresión.

4. **La latencia no la arregla un cifrado.** Ninguna opción de cifrado o compresión quita idas y vueltas:
   ```bash
   time ssh -o KexAlgorithms=curve25519-sha256 server true
   ssh server 'for i in eth0 eth1; do sudo tc qdisc del dev $i root; done'
   ```
   ```
   0.765 s
   ```
   Sin postcuántico, lo mismo: los 50 ms del [lab 04](../lab-04-postcuantico/README.md) se pierden entre 600 ms de esperas. El `del` quita la latencia.

5. **El cifrado: cuántos datos por segundo.** Sin latencia, 1 GB por cada cifrado:
   ```bash
   for c in chacha20-poly1305@openssh.com aes128-gcm@openssh.com aes256-gcm@openssh.com aes128-ctr; do
     echo -n "$c "; time (head -c 1G /dev/zero | ssh -c $c server 'cat > /dev/null')
   done
   ```
   ```
   chacha20-poly1305@openssh.com 5.832 s
   aes128-gcm@openssh.com 2.070 s
   aes256-gcm@openssh.com 1.983 s
   aes128-ctr 2.301 s
   ```
   - `chacha20-poly1305` es el primero de la lista por defecto y aquí el más lento: unos 175 MB/s frente a ~500 MB/s de AES-GCM.
   - AES va rápido porque la CPU tiene instrucciones para él (AES-NI en Intel y AMD; también los ARM modernos): `grep -o -m1 aes /proc/cpuinfo`. En una CPU sin ellas (un router, una Raspberry antigua), ChaCha20 gana. Por eso OpenSSH pone ChaCha20 primero: va bien en todas.
   - `aes128-ctr` necesita además un MAC (umac-64-etm por defecto) y queda detrás de GCM, que cifra y autentica a la vez.
   - Solo importa cuando mueves gigas en una red rápida (copias de seguridad, `rsync` de semana 06): `-c aes128-gcm@openssh.com` o, en el kit, `Ciphers ^aes128-gcm@openssh.com` en el alias de las copias.

6. **La compresión.** Un enlace de 20 Mbit/s, un archivo de texto (23 MB) y uno de bytes al azar (20 MB):
   ```bash
   ssh server 'seq 1 3000000 > texto; head -c 20M /dev/urandom > azar'
   ssh server 'for i in eth0 eth1; do sudo tc qdisc add dev $i root netem rate 20mbit; done'
   for f in texto azar; do for o in "" -C; do echo "$f $o $( { time ssh $o server cat $f > /dev/null; } 2>&1 )"; done; done
   ssh -v -C server cat texto 2>&1 >/dev/null | grep 'compress incoming'
   ```
   ```
   texto  12.727 s
   texto -C 4.080 s
   azar  8.981 s
   azar -C 8.983 s
   debug1: compress incoming: raw data 22896094, compressed 9246431, factor 0.40
   ```
   - `-C` (`Compression yes`) comprime con zlib antes de cifrar. El texto ocupa el 40 % (`factor 0.40`) y llega tres veces antes.
   - Los bytes al azar no se comprimen: lo mismo con o sin `-C`. Igual pasa con lo que ya va comprimido (`.gz`, `.jpg`, `.mp4`, copias con `rsync -z`).
   - `2>&1 >/dev/null`: el orden importa. Primero `stderr` va a donde va `stdout` (la tubería), y después `stdout` a `/dev/null`: por la tubería solo pasa el `-v`.

7. **Cuando la compresión estorba.** Sin límite de velocidad:
   ```bash
   ssh server 'for i in eth0 eth1; do sudo tc qdisc del dev $i root; done'
   for o in "" -C; do echo "rápida $o $( { time ssh $o server cat texto > /dev/null; } 2>&1 )"; done
   ssh server 'rm texto azar'
   ```
   ```
   rápida  0.263 s
   rápida -C 0.372 s
   ```
   En una red rápida, comprimir cuesta más CPU de lo que ahorra en red. Por eso `Compression` está en `no` por defecto: actívala en el alias de un enlace lento, no en `Host *`.

## Criterios de éxito

- [ ] Simulas latencia con `tc netem` y explicas por qué una conexión cuesta unas 11 idas y vueltas (paso 2)
- [ ] Mides el efecto del multiplexing con latencia (paso 3)
- [ ] Explicas por qué ni el cifrado ni el postcuántico cambian el tiempo de conexión con latencia (paso 4)
- [ ] Comparas cifrados y explicas cuándo gana AES-GCM y cuándo ChaCha20 (paso 5)
- [ ] Explicas cuándo `-C` ayuda y cuándo no (pasos 6 y 7)
- [ ] Dejas `server` sin `tc` (`ssh server tc qdisc show` solo enseña `noqueue`)

## Reto extra

Con `netem delay 50ms` otra vez, compara `scp` de 100 archivos pequeños (`for i in $(seq 100); do echo $i > ~/w/f$i; done`) con un solo `tar` por la tubería: `tar -C ~/w -cf - . | ssh server 'tar -xf - -C /tmp'`. ¿Cuántas idas y vueltas te ahorra la tubería? ¿Y con el master del paso 3?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 04 — Postcuántico](../lab-04-postcuantico/README.md) | [Lab 06 — Migrar llaves de usuario](../lab-06-migrar-llaves-de-usuario/README.md) → |

[↑ Semana 13](../../README.md)
