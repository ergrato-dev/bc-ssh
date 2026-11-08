# Glosario — Semana 03

| Término | Definición |
|---|---|
| **Autenticación con llave pública** | Método `publickey`: el usuario demuestra que tiene una llave privada firmando un dato de la sesión; el servidor lo comprueba con la pública ([teoría 01](../1-teoria/01-autenticacion-con-llave-publica.md)) |
| **Llave privada** | Mitad secreta del par. Firma. Vive solo en tu equipo, con permisos 600 |
| **Llave pública** | Mitad que se reparte. Verifica firmas y no permite calcular la privada. Archivo `.pub` |
| **Par de llaves** | Privada y pública generadas juntas con `ssh-keygen` |
| **Firma** | Valor que solo la privada puede producir sobre un dato y que cualquiera con la pública puede comprobar |
| **Identificador de sesión** | Hash del primer intercambio de llaves de una conexión. La firma de usuario lo incluye, por eso no vale en otra conexión |
| **`USERAUTH_PK_OK`** | Mensaje 60: el servidor dice que aceptaría la llave ofrecida, antes de que el cliente firme |
| **`PreferredAuthentications`** | Orden en que el cliente prueba los métodos de autenticación; `publickey` va antes que `password` |
| **Ed25519** | Tipo de llave de curva elíptica, 256 bits, por defecto desde OpenSSH 9.5. El recomendado |
| **RSA** | Tipo de llave clásico. Vigente con 3072 bits o más; solo para sistemas sin Ed25519 |
| **ECDSA** | Tipo de llave sobre curvas NIST. Depende de un buen aleatorio al firmar |
| **DSA** | Tipo de llave obsoleto: rechazado por defecto desde OpenSSH 7.0 y eliminado en 10.0 |
| **`id_ed25519`** | Nombre por defecto de una llave Ed25519; uno de los que `ssh` prueba sin configuración |
| **Comentario de llave** | Tercer campo de la `.pub`. Texto libre para saber de quién es y para qué; no interviene en la autenticación |
| **Huella** | Resumen corto de una llave pública (`SHA256:...`) con `ssh-keygen -l`. Identifica la llave en `ssh -v` y en los logs |
| **`openssh-key-v1`** | Formato del archivo de llave privada de OpenSSH. Indica cifrado, derivación y contiene también la pública |
| **Frase de paso** | Contraseña que cifra la privada en tu disco. Nunca viaja al servidor |
| **bcrypt** | Función que convierte la frase de paso en la llave de cifrado del archivo, a propósito lenta |
| **Rondas (`-a`)** | Repeticiones de bcrypt (24 por defecto en 9.6). Más rondas, más caro cada intento de adivinar la frase |
| **`ssh-keygen -y`** | Imprime la pública a partir de la privada |
| **`ssh-keygen -p`** | Cambia, pone o quita la frase de paso sin cambiar la llave |
| **`ssh-copy-id`** | Instala una pública en el `authorized_keys` de un servidor sin duplicarla |
| **`authorized_keys`** | Archivo `~/.ssh/authorized_keys` de una cuenta del servidor: una línea por llave que puede entrar ([teoría 03](../1-teoria/03-authorized_keys-y-opciones.md)) |
| **`AuthorizedKeysFile`** | Opción de `sshd_config` con la ruta de `authorized_keys` |
| **`StrictModes`** | Comprobación de `sshd`: ignora `authorized_keys` si la carpeta personal, `~/.ssh` o el archivo pueden ser modificados por otros |
| **`BatchMode`** | Opción del cliente que prohíbe preguntar nada (contraseña, frase, huella). Para scripts y pruebas |
| **`IdentityFile`** | Opción del cliente con la ruta de una llave privada a usar; `-i` en la línea de comandos |
| **`IdentitiesOnly`** | Opción del cliente: ofrecer solo las llaves de `IdentityFile`, aunque el agente tenga más |
| **`MaxAuthTries`** | Intentos de autenticación por conexión que admite `sshd` (6 por defecto). Cada llave rechazada cuenta |
| **`restrict`** | Opción de `authorized_keys` que desactiva terminal, reenvíos y `~/.ssh/rc`, incluido lo que añadan versiones futuras |
| **`command=`** | Opción de `authorized_keys`: comando que se ejecuta siempre, pida lo que pida el cliente |
| **`SSH_ORIGINAL_COMMAND`** | Variable con el comando que pidió el cliente cuando hay un comando forzado |
| **`from=`** | Opción de `authorized_keys`: la llave solo vale desde esas IP, redes o nombres |
| **`expiry-time=`** | Opción de `authorized_keys`: fecha a partir de la cual la llave deja de valer |
| **Rotación de llaves** | Sustituir una llave por otra: añadir la nueva, probarla y solo después quitar la vieja |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — web](../4-recursos/webgrafia/README.md) | — |

[↑ Semana 03](../README.md)
