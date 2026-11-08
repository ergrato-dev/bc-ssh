# Glosario — Semana 02

| Término | Definición en una línea | Ejemplo |
|---------|------------------------|---------|
| **capa de transporte** | Parte de SSH que negocia algoritmos, acuerda llaves, verifica al servidor y cifra (RFC 4253) | Mensajes 1–49 |
| **capa de autenticación** | Parte de SSH que autentica al usuario dentro del transporte cifrado (RFC 4252) | Mensajes 50–79 |
| **capa de conexión** | Parte de SSH que abre canales dentro de la conexión (RFC 4254) | Mensajes 80–127 |
| **paquete binario** | Formato de todo mensaje SSH: longitud, relleno, contenido y MAC | Visible con `tcpdump` |
| **tipo de mensaje** | Primer byte del contenido; su número dice la capa | `send packet: type 20` |
| **canal** | Flujo independiente dentro de una conexión: shell, comando, túnel | `channel 0: new session` |
| **`KEXINIT`** | Mensaje 20: listas de algoritmos de cada lado, por preferencia | `local client KEXINIT proposal` |
| **negociación** | Para cada función gana el primero de la lista del cliente que el servidor soporte | `kex: algorithm: ...` |
| **`Their offer`** | En un error de negociación, la lista que envió el servidor | `no matching key exchange method found. Their offer: ...` |
| **par efímero** | Par de llaves creado para una sola conexión y descartado al acabar | Parte pública en `KEX_ECDH_INIT` |
| **secreto compartido (K)** | Valor que cliente y servidor calculan por separado sin enviarlo | Base de las llaves de sesión |
| **hash de intercambio (H)** | Resumen de banners, `KEXINIT`, host key y partes efímeras; el servidor lo firma | Firmado en `KEX_ECDH_REPLY` |
| **session ID** | El primer H de la conexión; no cambia al renegociar | Lo firma la autenticación con llave |
| **`NEWKEYS`** | Mensaje 21: desde el siguiente paquete, todo cifrado con las llaves nuevas | `SSH2_MSG_NEWKEYS sent` |
| **rekey** | Repetir el intercambio de llaves dentro de la conexión tras cierta cantidad de datos | `-o RekeyLimit=4M` |
| **KEX híbrido** | Intercambio que combina un algoritmo clásico y uno poscuántico | `sntrup761x25519-sha512@openssh.com` |
| **"guarda ahora, descifra después"** | Grabar tráfico hoy para descifrarlo con una computadora cuántica futura | Motivo de los KEX híbridos |
| **`+` / `-` / `^`** | Añadir al final, quitar o poner al principio de una lista de algoritmos por defecto | `KexAlgorithms +diffie-hellman-group14-sha1` |
| **`ssh -Q`** | Algoritmos que el binario soporta, estén o no en la oferta | `ssh -Q kex` |
| **`sshd -T`** | Configuración efectiva del servidor | `sshd -T \| grep ciphers` |
| **`ext-info`** | Extensión para que el servidor anuncie datos tras el KEX (mensaje 7) | `ext-info-c` |
| **`kex-strict`** | Defensa contra Terrapin: reinicia los números de secuencia y no tolera mensajes inesperados en el KEX | `kex-strict-s-v00@openssh.com` |
| **Terrapin** | Ataque de 2023 que borraba mensajes del inicio de la conexión (CVE-2023-48795) | Corregido en OpenSSH 9.6 |
| **tipo de llave / algoritmo de firma** | Una llave RSA (`ssh-rsa`) puede firmar con SHA-1 (`ssh-rsa`) o SHA-2 (`rsa-sha2-512`) | `HostKeyAlgorithms +ssh-rsa` |
| **`ssh-keyscan`** | Lee las host keys públicas de un servidor sin autenticarse; no verifica | `ssh-keyscan -t ed25519 server` |
| **randomart** | Dibujo derivado de la huella para notar cambios a simple vista | `ssh-keygen -lvf` |
| **`HashKnownHosts`** | Guarda los nombres de `known_hosts` como HMAC-SHA1 con sal | `\|1\|sal\|hash ssh-ed25519 ...` |
| **sal** | Valor aleatorio que hace distinto el hash de un mismo nombre en cada línea | Tercer campo de `\|1\|...` |
| **`@revoked`** | Marca una host key como comprometida: `ssh` la rechaza | `@revoked server ssh-ed25519 ...` |
| **`@cert-authority`** | Marca una llave de CA que firma host keys (semana 10) | `@cert-authority *.lab ssh-ed25519 ...` |
| **`HostKeyAlias`** | Nombre con el que `ssh` guarda y busca la host key | `-o HostKeyAlias=mi-servidor` |
| **`GlobalKnownHostsFile`** | `known_hosts` del sistema, repartido por el administrador | `/etc/ssh/ssh_known_hosts` |
| **`StrictHostKeyChecking`** | Qué hace `ssh` con llaves nuevas o cambiadas: `ask`, `yes`, `accept-new`, `no` | `StrictHostKeyChecking yes` |
| **`UpdateHostKeys`** | Aceptar las llaves adicionales que anuncia un servidor ya verificado | `Learned new hostkey: RSA ...` |
| **`hostkeys-00@openssh.com`** | Extensión con la que el servidor envía todas sus host keys | `GLOBAL_REQUEST` tipo 80 |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — web](../4-recursos/webgrafia/README.md) | [🔑 Semana 02: Autenticación con Llaves SSH](../../week-03-autenticacion_con_llaves_ssh/README.md) → |

[↑ Semana 02](../README.md)
