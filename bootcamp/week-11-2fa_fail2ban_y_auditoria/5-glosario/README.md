# Glosario — Semana 11

| Término | Definición |
|---|---|
| **ssh-audit** | Herramienta que se conecta a un servidor (o recibe a un cliente con `-c`), lee los algoritmos que anuncia y los califica. No entra |
| **`[fail]` / `[warn]` / `[info]`** | Niveles de `ssh-audit`: roto o dudoso, débil o arriesgado, solo datos. Códigos de salida 3, 2 y 0 |
| **Curvas NIST** | `nistp256/384/521`: curvas elípticas cuyas constantes despiertan dudas. `ssh-audit` las marca `fail` en intercambio de llaves y host keys |
| **encrypt-then-MAC (`-etm`)** | El MAC se calcula sobre el texto ya cifrado. Los MAC sin `-etm` lo calculan sobre el texto en claro |
| **AEAD** | Cifrado que también autentica (`chacha20-poly1305`, `aes-gcm`): no usa ninguno de los `MACs` (`MAC: <implicit>`) |
| **Terrapin** | Ataque (CVE-2023-48795) que quita mensajes del inicio de una sesión. Lo corrige el *strict kex* (`kex-strict-*-v00@openssh.com`) si lo tienen los dos lados |
| **DHEat** | Ataque de denegación (CVE-2002-20001) que abre muchas conexiones para forzar cálculos de Diffie-Hellman. Lo frenan `MaxStartups`, fail2ban y `PerSourcePenalties` (OpenSSH 9.8+) |
| **Lista `-` / `+`** | En `sshd_config`, `-ALGS` quita de la lista por defecto (con comodines) y `+ALGS` añade |
| **Política de ssh-audit** | Archivo con los algoritmos permitidos; `ssh-audit -P` dice si un servidor cumple. `-M` la genera de un servidor |
| **`allow_algorithm_subset_and_reordering`** | Opción de una política: el servidor puede ofrecer menos algoritmos o en otro orden, nunca otros |
| **Factor** | Forma distinta de demostrar quién eres: algo que tienes, que sabes o que eres |
| **TOTP** | Código de un solo uso que depende de un secreto compartido y de la hora (RFC 6238): cambia cada 30 s |
| **Secreto TOTP** | Cadena base32 que comparten servidor y móvil. Primera línea de `~/.google_authenticator`; quien la tenga genera tus códigos |
| **`WINDOW_SIZE`** | Cuántos códigos seguidos acepta el servidor (3: anterior, actual y siguiente), para relojes un poco desviados |
| **Código de emergencia** | Código de 8 cifras que vale una sola vez, para entrar sin el móvil |
| **`oathtool`** | Calcula códigos TOTP y HOTP en una terminal: en el laboratorio hace de móvil |
| **PAM** | *Pluggable Authentication Modules*: la pieza de Linux que decide cómo se autentica cada servicio, con un archivo por servicio en `/etc/pam.d/` |
| **`pam_google_authenticator.so`** | Módulo PAM que pide `Verification code:` y lo comprueba contra `~/.google_authenticator` |
| **`nullok`** | Opción del módulo que deja pasar a quien no tiene secreto. El kit no la usa |
| **keyboard-interactive** | Método de autenticación en el que el servidor hace preguntas (vía PAM) y el cliente se las enseña a la persona |
| **`AuthenticationMethods`** | Métodos que hay que superar, en orden: `publickey,keyboard-interactive` es llave **y** código |
| **`dosfa`** | Grupo del kit cuyos miembros necesitan llave y código (`Match Group dosfa`) |
| **fail2ban** | Servicio que lee logs, cuenta fallos por IP y las bloquea en el cortafuegos un tiempo |
| **Filtro / jaula / acción** | En fail2ban: qué línea es un fallo; qué log, límites y acción se aplican; qué se hace al bloquear |
| **`maxretry` / `findtime` / `bantime`** | Fallos que provocan el bloqueo, ventana en la que se cuentan y duración del bloqueo |
| **`bantime.increment`** | Cada nuevo bloqueo de la misma IP dura más, hasta `bantime.maxtime` |
| **`ignoreip`** | IP que fail2ban nunca bloquea: tampoco cuenta sus fallos |
| **Modo `normal` / `aggressive`** | Qué cuenta el filtro `sshd`: usuarios, contraseñas y códigos fallidos; o además cualquier conexión que se cierra sin autenticar |
| **`fail2ban-regex`** | Aplica un filtro a un log y dice qué líneas casan: prueba una jaula sin bloquear a nadie |
| **nftables** | Cortafuegos de Linux. fail2ban mete las IP bloqueadas en un conjunto (`addr-set-sshd`) con una regla `reject` |
| **`LogLevel VERBOSE`** | Nivel de log de `sshd` que añade la huella de las llaves rechazadas y la aceptación parcial con dos factores |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — web](../4-recursos/webgrafia/README.md) | — |

[↑ Semana 11](../README.md)
