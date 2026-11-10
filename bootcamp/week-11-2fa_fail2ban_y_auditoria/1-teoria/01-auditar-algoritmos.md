# Auditar los algoritmos de un servidor

## Qué anuncia un servidor

En la [semana 02](../../week-02-protocolo_kex_y_known_hosts/1-teoria/02-intercambio-de-llaves.md) viste que, antes de autenticar a nadie, cliente y servidor se mandan su lista de algoritmos (el mensaje `KEXINIT`) y eligen, de cada tipo, el primero del cliente que también tenga el servidor:

| Tipo | Para qué | Ejemplo bueno | Ejemplo débil |
|---|---|---|---|
| Intercambio de llaves (`KexAlgorithms`) | Acordar la clave de la sesión sin enviarla | `sntrup761x25519-sha512@openssh.com`, `curve25519-sha256` | `diffie-hellman-group14-sha256` (2048 bits) |
| Host key (`HostKeyAlgorithms`) | Que el servidor demuestre quién es | `ssh-ed25519` | `ecdsa-sha2-nistp256` |
| Cifrado (`Ciphers`) | Cifrar los datos | `chacha20-poly1305@openssh.com`, `aes256-gcm@openssh.com` | `aes256-cbc` |
| MAC (`MACs`) | Detectar si alguien cambió un paquete | `hmac-sha2-256-etm@openssh.com` | `hmac-sha1`, `umac-64` |

Esa lista viaja **sin cifrar** y llega a cualquiera que abra una conexión al puerto 22. No hace falta cuenta, llave ni contraseña para leerla. Es lo primero que mira un atacante, y lo que mira `ssh-audit`.

## Por qué OpenSSH trae algoritmos débiles

Los valores por defecto de OpenSSH buscan que conecte casi cualquier cliente: equipos de red de hace diez años, librerías antiguas o clientes de Windows sin actualizar. Por eso Ubuntu 24.04 (OpenSSH 9.6) aún ofrece curvas NIST, el grupo 14 y MAC con SHA-1. Ninguno de ellos permite descifrar una sesión de hoy, pero son los primeros que caerán, y un servidor que solo hablas tú con OpenSSH moderno no los necesita.

Endurecer es **quitar lo que tus clientes no usan**, no copiar la lista más corta que encuentres: cada algoritmo que quitas es un cliente que puede dejar de conectar (lo pruebas en el [lab 02](../2-practicas/lab-02-quitar-algoritmos/README.md)).

## ssh-audit

[`ssh-audit`](https://github.com/jtesta/ssh-audit) se conecta, lee el banner y la lista `KEXINIT`, y compara cada algoritmo con su base de datos. No intenta entrar.

```bash
ssh-audit server
```

| Nivel | Qué significa | Qué haces |
|---|---|---|
| `[fail]` | Roto o con dudas serias (SHA-1, curvas NIST, CBC) | Quitarlo |
| `[warn]` | Débil o con un uso arriesgado (2048 bits, etiqueta de 64 bits, MAC sin `-etm`) | Quitarlo si ningún cliente lo necesita |
| `[info]` | Datos: desde qué versión existe, si es el valor por defecto | Nada |

Al final vienen las **recomendaciones** (`(rec) -hmac-sha1 -- mac algorithm to remove`) y notas sobre dos ataques:

- **Terrapin** (CVE-2023-48795): un atacante en medio puede quitar mensajes del principio de la sesión. OpenSSH 9.6 lo corrige con el *strict kex* (`kex-strict-s-v00@openssh.com` en la lista), pero solo si **los dos lados** lo tienen. La nota te recuerda que un cliente sin parchear sigue expuesto con `chacha20-poly1305` o los cifrados CBC con `-etm`.
- **DHEat** (CVE-2002-20001): muchas conexiones seguidas obligan al servidor a hacer muchas operaciones caras de Diffie-Hellman. `ssh-audit` abre unas 40 conexiones en una fracción de segundo para medirlo. Se mitiga limitando conexiones por IP: `MaxStartups` (ya en tu `10-acceso.conf`), `PerSourceMaxStartups` y, desde **OpenSSH 9.8+**, `PerSourcePenalties`. En 9.6, fail2ban y el cortafuegos hacen ese papel. `--skip-rate-test` lo omite.

`ssh-audit` sale con **0** si no hay `warn` ni `fail`, con **2** si hay algún `warn` y con **3** si hay algún `fail`: sirve en scripts. Con `-j` escribe JSON (`jq` lo filtra), y con `-c` audita a un **cliente**: escucha en un puerto y tú te conectas con `ssh`.

## Quitar sin escribir la lista entera

Cada opción de algoritmos de `sshd_config` acepta tres formas:

| Forma | Ejemplo | Resultado |
|---|---|---|
| Lista completa | `MACs hmac-sha2-256-etm@openssh.com` | Solo esos |
| `-` delante | `MACs -hmac-sha1*,umac-64*` | Los de por defecto **menos** esos (admite comodines) |
| `+` delante | `Ciphers +aes256-cbc` | Los de por defecto **más** esos |

Con `-`, al actualizar OpenSSH entran solos los algoritmos nuevos (`mlkem768x25519-sha256` llega en **OpenSSH 9.9+**) y tú solo mantienes la lista de lo que no quieres. `sudo sshd -T | grep ^macs` enseña el resultado.

Tu kit lo guarda en `server/sshd_config.d/15-algoritmos.conf`.

## Políticas

Un informe dice qué está mal; una **política** dice qué está permitido, y `ssh-audit -P POLÍTICA HOST` responde sí o no. Es lo que quieres comprobar en cada despliegue y en cada servidor.

| Origen | Cómo |
|---|---|
| Integradas | `ssh-audit -L` las lista (`Hardened Ubuntu Server 24.04 LTS`): muy estrictas, exigen el orden exacto y host keys RSA de 4096 bits |
| Generada de un servidor | `ssh-audit -M politica.txt server`: copia exacta de lo que ofrece hoy |
| Escrita por ti | Un archivo de texto con `host keys`, `key exchanges`, `ciphers` y `macs` |

Dos opciones cambian mucho el resultado:

- `allow_algorithm_subset_and_reordering = true`: el servidor puede ofrecer **menos** algoritmos o en otro orden, nunca otros. La política pasa a ser una lista de lo permitido.
- `allow_larger_keys = true`: una host key más grande que la indicada también cumple.

Tu kit guarda la suya en `server/ssh-audit-politica.txt` y la comprueba con `bin/audit`, que resuelve los alias de `conf.d/` con `ssh -G` como al conectar.

## Lo que ssh-audit no ve

Solo mira lo que el servidor anuncia antes de autenticar. No sabe si aceptas contraseñas, si root entra, quién está en `AllowGroups` ni si hay un segundo factor. Para eso están `sudo sshd -T` en el servidor, tus checks y el log ([teoría 03](03-fail2ban-y-registros.md)).

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Semana 11 — 2FA, fail2ban y auditoría con ssh-audit](../README.md) | [Teoría — El segundo factor: llave y código](02-segundo-factor.md) → |

[↑ Semana 11](../README.md)
