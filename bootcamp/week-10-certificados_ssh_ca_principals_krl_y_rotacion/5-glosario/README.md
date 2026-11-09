# Glosario — Semana 10

| Término | Definición |
|---|---|
| **CA (autoridad de certificados)** | Llave que firma llaves públicas. En SSH es una llave normal de `ssh-keygen`; se confía en ella con una línea, no con una por persona o servidor |
| **Certificado** | Llave pública más identidad, número de serie, principals, validez y opciones, firmado por una CA. Archivo `NOMBRE-cert.pub` junto a la llave |
| **CA de usuarios / de hosts** | Dos CA distintas: una firma personas (la comprueban los servidores), otra firma servidores (la comprueban los clientes) |
| **`ssh-keygen -s`** | Firma una llave pública. `-U` con `-s CA.pub`: firma con la llave de la CA que está en el agente |
| **`ssh-keygen -L`** | Muestra un certificado: tipo, llave, CA, identidad, serie, validez, principals, opciones y extensiones |
| **Key ID (`-I`)** | Identidad del certificado (`alumno@portatil`). Aparece en el log de cada conexión |
| **Número de serie (`-z`)** | Número del certificado. Se revoca por él; tiene que ser único en cada CA |
| **Principals (`-n`)** | Usuarios o roles para los que vale un certificado de usuario; nombres del servidor en uno de host |
| **Validez (`-V`)** | Intervalo en el que vale: `-5m:+8h`, `20270101:20270201`. Sin `-V`, `forever` |
| **Opción crítica** | Limitación que el servidor debe aplicar o rechazar el certificado: `force-command`, `source-address`, `verify-required` |
| **Extensión** | Permiso del certificado: `permit-pty`, `permit-port-forwarding`, `permit-agent-forwarding`, `permit-X11-forwarding`, `permit-user-rc`. `-O clear` las quita |
| **`TrustedUserCAKeys`** | Opción de `sshd`: archivo con las CA de usuarios en las que confía, una por línea |
| **`AuthorizedPrincipalsFile`** | Opción de `sshd`: archivo por cuenta (`%u`) con los principals que acepta. Permite firmar con roles |
| **`cert-authority`** | Opción de una línea de `authorized_keys`: esa llave es una CA que vale solo para esa cuenta |
| **`HostCertificate`** | Opción de `sshd`: el certificado de su host key, que presenta a los clientes |
| **`@cert-authority`** | Marcador de `known_hosts`: para los hosts del patrón, acepta host keys firmadas por esa CA |
| **`@revoked`** | Marcador de `known_hosts`: esa llave (host key o CA) no se acepta nunca |
| **KRL** | *Key Revocation List*: archivo compacto con llaves, certificados y CA revocados. `ssh-keygen -k` la crea, `-u` añade, `-Q` comprueba |
| **`RevokedKeys`** | Opción de `sshd`: la KRL que lee en cada autenticación. Si falta o está rota, rechaza todas las llaves |
| **`RevokedHostKeys`** | Opción de `ssh`: una KRL para host keys |
| **Rotación** | Cambiar una CA por otra confiando en las dos durante la transición: servidores primero (usuarios), clientes primero (hosts) |
| **`ExposeAuthInfo`** | Opción de `sshd`: deja en el archivo de `$SSH_USER_AUTH` cómo se autenticó la sesión, con el certificado |
| **`CA_DIR`** | Carpeta de la CA del kit (`~/.ssh-ca`): llaves, contador, registro, copias y KRL. Nunca dentro de git |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — web](../4-recursos/webgrafia/README.md) | — |

[↑ Semana 10](../README.md)
