# Glosario — Semana 13

| Término | Definición |
|---|---|
| **Capa** | Cada paso de una conexión (configuración, nombre, TCP, banner, algoritmos, host key, autenticación). Cada una falla con su propio mensaje |
| **`ssh -v`, `-vv`, `-vvv`** | Modo detallado del cliente: escribe cada paso en `stderr`. Más `v`, más detalle |
| **`ssh -G`** | Imprime la configuración final del cliente para un host, sin conectar |
| **`ssh -Q`** | Lista lo que tu `ssh` sabe hacer (`kex`, `cipher`, `mac`, `key`), lo ofrezca o no |
| **`sshd -d`** | `sshd` de depuración: en primer plano, todo a `stderr`, una sola conexión |
| **`sshd -T -C`** | Imprime la configuración del servidor que se aplicaría a una conexión concreta, con los `Match` evaluados |
| **`HostKeyAlias`** | Nombre con el que `ssh` busca la host key en `known_hosts`, en lugar del nombre y puerto reales |
| **`StrictModes`** | `sshd` ignora `authorized_keys` si el home, `~/.ssh` o el archivo los puede escribir otro usuario |
| **`KEXINIT`** | Mensaje con el que cada lado manda sus listas de algoritmos al empezar |
| **`Their offer`** | En un `no matching`, lo que acepta el otro lado para la lista que falló |
| **`+`, `-`, `^`** | En una lista de algoritmos: añadir al final, quitar, poner al principio de la lista por defecto |
| **Equipo legado** | Uno que solo habla algoritmos retirados y no se puede actualizar. En el kit, un alias `legado-*` |
| **`ssh-rsa`** | Firma con una llave RSA y SHA-1. Fuera de la lista por defecto desde OpenSSH 8.8; la misma llave firma con `rsa-sha2-256/512` |
| **Postcuántico** | Que resiste a un ordenador cuántico. En SSH, hoy, el intercambio de llaves |
| **Store now, decrypt later** | Grabar hoy tráfico cifrado para descifrarlo cuando exista un ordenador cuántico capaz |
| **Híbrido** | Intercambio que combina un algoritmo postcuántico con X25519: hay que romper los dos |
| **`sntrup761x25519-sha512`** | Híbrido con Streamlined NTRU Prime. Por defecto desde OpenSSH 9.0 |
| **`mlkem768x25519-sha256`** | Híbrido con ML-KEM (FIPS 203). Desde OpenSSH 9.9, por defecto desde 10.0 |
| **`WarnWeakCrypto`** | Opción de OpenSSH 10.1+ que avisa cuando una conexión no usa intercambio postcuántico |
| **RTT** | Tiempo de ida y vuelta de un paquete. Abrir una conexión SSH cuesta unas once |
| **`tc netem`** | Herramienta de Linux que simula latencia, pérdidas o un ancho de banda limitado |
| **AES-NI** | Instrucciones de la CPU para AES: lo hacen varias veces más rápido que ChaCha20 en esa CPU |
| **`Compression`** | Compresión zlib antes de cifrar (`ssh -C`). Ayuda en enlaces lentos; estorba en los rápidos |
| **`RequiredRSASize`** | Longitud mínima de las llaves RSA que acepta `sshd` (OpenSSH 9.1+) |
| **Migración** | Cambiar algo de lo que dependen otros en orden: inventario, añadir, comprobar, quitar, exigir |
| **`UpdateHostKeys`** | El cliente aprende las host keys nuevas de un servidor ya verificado y olvida las retiradas |
| **`hostkeys-00@openssh.com`** | Mensaje con el que el servidor manda todas sus host keys tras la autenticación |
| **Rotación de host key** | Cambiar la llave de un servidor en dos fases: la nueva junto a la vieja, y después solo la nueva |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — web](../4-recursos/webgrafia/README.md) | — |

[↑ Semana 13](../README.md)
