# Rúbrica de Evaluación — Semana 10

> Certificados SSH: CA, principals, KRL y rotación. Se evalúan tres evidencias por separado y hace falta **70% en cada una**. No basta con entrar con un certificado: tienes que saber qué firma la CA, qué comprueba cada lado, cómo se deja fuera a alguien antes de que caduque y cómo se cambia la CA sin dejar a nadie fuera.

---

## 📊 Distribución de Evidencias

| Evidencia | Peso | Instrumento |
|---|:--:|---|
| 🧠 Conocimiento | 30% | Las 10 preguntas de esta rúbrica, respondidas por escrito |
| 💪 Desempeño | 40% | Los 7 labs, con sus criterios de éxito comprobados en el laboratorio |
| 📦 Producto | 30% | `ssh-infra-kit` con `ca/ca-init`, `ca/ca-sign`, `ca/ca-revoke` y `50-ca.conf`: 60 pts de autograding + 40 de calidad |

| Calificación | Rango |
|---|:--:|
| Sobresaliente | 90-100% |
| Notable | 80-89% |
| Aprobado | 70-79% |
| No aprobado | < 70% |

---

## 🧠 Conocimiento (30%)

Diez preguntas, 3 puntos cada una.

| # | Pregunta |
|:--:|---|
| 1 | ¿Qué problema de `authorized_keys` y de `known_hosts` resuelve una CA? ¿Qué firma exactamente la CA, y qué archivo va a los servidores y cuál no sale nunca de su sitio? |
| 2 | Lee un certificado con `ssh-keygen -L`: ¿qué son `Key ID`, `Serial`, `Valid`, `Principals`, `Critical Options` y `Extensions`? ¿Por qué un certificado robado sin su llave privada no sirve? |
| 3 | Con `TrustedUserCAKeys`, ¿como qué usuarios entra un certificado con `-n alumno,deploy`? ¿Y uno sin `-n`? ¿Qué cambia `AuthorizedPrincipalsFile /etc/ssh/principals/%u`, y qué pasa con una cuenta sin archivo? |
| 4 | ¿Para qué sirven `force-command`, `source-address` y `-O clear`? Si el certificado permite reenvíos y `sshd_config` no, ¿qué vale? ¿Por qué hay que poner siempre `-V`? |
| 5 | Un certificado caduca con un master abierto. ¿Qué sigue funcionando y qué no? ¿Qué comprueba el agente al cargar un certificado? |
| 6 | ¿Qué cambia en la primera conexión con un certificado de host? Escribe la línea de `known_hosts` y la de `sshd_config`. ¿Por qué falla entrar por IP y qué tienes que comprobar **antes** de firmar la host key de un servidor? |
| 7 | ¿Qué es una KRL? ¿Qué diferencia hay entre revocar un certificado, revocar su llave y revocar por número de serie? ¿Por qué no hay que recargar `sshd` al cambiarla? |
| 8 | ¿Qué hace `sshd` si el archivo de `RevokedKeys` falta o está roto? ¿En qué orden se instala todo en un servidor nuevo y por qué? |
| 9 | Explica cómo rotar la CA de usuarios y la de hosts sin dejar a nadie fuera: qué va primero, cuándo se retira la vieja, y qué añaden la KRL y `@revoked` si la vieja se filtró. |
| 10 | ¿Cómo proteges la llave de la CA (frase, agente con `-t`, `ssh-keygen -U`, fuera del disco)? ¿Qué registro llevas de cada certificado y cómo lo cruzas con el log de un servidor? ¿Por qué los certificados cortos reducen la necesidad de revocar? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Con llaves sueltas, cada servidor necesita la llave de cada persona (`authorized_keys`) y cada cliente la de cada servidor (`known_hosts`): N × M líneas que nunca están al día, y una pregunta de confianza cada primera vez. La CA firma la **llave pública** de una persona o de un servidor junto con unos datos (identidad, nombres, validez); los servidores y clientes solo necesitan la pública de la CA. `user_ca.pub` va a los servidores; `user_ca` (la privada) no sale de su sitio, y con ella se entra como cualquiera.

**2.** `Key ID`: la identidad, que aparece en los logs. `Serial`: el número para revocarlo. `Valid`: desde cuándo hasta cuándo vale. `Principals`: usuarios o roles (o nombres de host) para los que vale. `Critical Options`: limitaciones que el servidor debe aplicar o rechazar el certificado (`force-command`, `source-address`). `Extensions`: lo que permite (`permit-pty`, `permit-port-forwarding`...). El certificado es público: para usarlo hay que firmar el reto con la llave privada que corresponde a la pública que lleva dentro.

**3.** Como `alumno` y como `deploy`, solo esos. Sin `-n`, `sshd` lo rechaza (`Certificate lacks principal list`): valdría para cualquiera. Con `AuthorizedPrincipalsFile`, el nombre de usuario ya no cuenta: el certificado tiene que llevar alguno de los principals del archivo de esa cuenta (roles como `admins`). Una cuenta sin archivo no acepta ningún certificado; su `authorized_keys` sigue valiendo.

**4.** `force-command`: ejecuta siempre esa orden. `source-address`: solo desde esas redes. `-O clear`: quita todas las extensiones (luego devuelves las que quieras). Vale lo más restrictivo de los dos. Sin `-V`, el certificado es eterno (`forever`): solo la KRL lo para.

**5.** La conexión del master ya está autenticada: sigue abierta, y las sesiones nuevas dentro de ella también funcionan. Una conexión nueva no. El agente no comprueba nada: acepta un certificado caducado; quien decide es `sshd`.

**6.** El cliente acepta la host key porque está firmada por una CA en la que confía y el nombre está en sus principals: no pregunta. `@cert-authority server,bastion,interno ssh-ed25519 AAAA...` en `known_hosts`; `HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub` en `sshd_config`. La IP no está en los principals del certificado (ni en el patrón): se trata como una llave desconocida (`HostKeyAlias` o firmar también la IP). Antes de firmar, que la llave pública es de verdad la del servidor (su huella, por otro canal): la firma les dice a todos los clientes que confíen en ella.

**7.** Una lista compacta de llaves, certificados (por número de serie y CA, o por identidad) y CA revocados, hecha con `ssh-keygen -k`. Revocar un certificado deja entrar otro certificado de la misma llave; revocar la llave deja fuera todos sus certificados y su línea en `authorized_keys`; por número de serie (`serial: N`, con `-s CA.pub`) no necesitas el certificado. `sshd` lee la KRL en cada autenticación.

**8.** Rechaza **todas** las llaves, también las de `authorized_keys` (`No such file or directory`, `invalid format`). Primero los archivos (`user_ca.pub`, `revoked.krl`, principals, certificado de host), luego la configuración que los nombra: al revés, el despliegue te deja fuera (y `sshd-deploy` lo deshace).

**9.** Usuarios: la nueva **en los servidores** junto a la vieja (`TrustedUserCAKeys` con dos líneas), firmar con la nueva, y quitar la vieja cuando haya caducado el último certificado que firmó. Hosts: la nueva **en los clientes** primero (segunda `@cert-authority`), luego los certificados nuevos en los servidores, y la vieja como `@revoked`. Si se filtró, la llave pública de la CA vieja en la KRL revoca todo lo que firmó, aunque algún servidor aún confíe en ella.

**10.** Frase en la llave; en el agente con caducidad (`ssh-add -t 15m`) y el archivo fuera del disco, firmando con `ssh-keygen -U -s CA.pub`; nunca reenviar ese agente. Un registro con fecha, serie, identidad, principals, validez y huella; el log de `sshd` da `ID ... (serial N) CA ... SHA256:...`, que cruzas con el registro y con la huella de la CA. Con certificados de horas, una llave robada deja de servir sola en poco tiempo, y quien se va simplemente no recibe más.

</details>

---

## 💪 Desempeño (40%)

Dentro de cada lab: 10 puntos si se cumplen todos los criterios y explicas con tus palabras por qué funciona; 8 si se cumplen todos; 7 si falla uno; menos de 7 si fallan dos o más.

| Lab | Criterio | Puntos |
|---|---|:--:|
| [01 — Primera CA](2-practicas/lab-01-primera-ca/README.md) | CA creada; llave firmada con `-s -I -n -V`; certificado leído; `TrustedUserCAKeys`; log con identidad y serie | 10 |
| [02 — Principals](2-practicas/lab-02-principals/README.md) | Principal distinto rechazado; varios principals; sin principals; roles con `AuthorizedPrincipalsFile`; `cert-authority` en una cuenta | 10 |
| [03 — Validez y opciones](2-practicas/lab-03-validez-y-opciones/README.md) | Ventanas de validez; `force-command`; `source-address`; extensiones; agente; sesión tras caducar | 10 |
| [04 — Certificados de host](2-practicas/lab-04-certificados-de-host/README.md) | Host keys firmadas con `-h`; `@cert-authority`; huella de `interno` verificada antes; `known_hosts` de una línea; IP y caducidad | 10 |
| [05 — KRL](2-practicas/lab-05-revocacion-krl/README.md) | KRL instalada en orden; certificado, llave y número revocados; `-Q -l`; KRL ausente o rota | 10 |
| [06 — Rotación](2-practicas/lab-06-rotacion-de-la-ca/README.md) | Dos CA de usuarios; retirada en su momento; CA vieja en la KRL; CA de hosts rotada en orden; `@revoked` | 10 |
| [07 — Proteger y auditar](2-practicas/lab-07-proteger-y-auditar-la-ca/README.md) | Frase; firma con `-U` sin el archivo; registro; log cruzado con el registro; `ExposeAuthInfo`; certificados cortos | 10 |

La nota de Desempeño es la media de los siete labs.

---

## 📦 Producto (30%)

### Verificable por el autograding — 60 puntos

Lo ejecuta `./scripts/verificar-semana.sh 10`. Es binario: pasa o no pasa.

| Comprobación | Puntos |
|---|:--:|
| `ca-init-crea` — ca-init crea user_ca y host_ca Ed25519 en una carpeta 700, con contador a 0 y una KRL vacía | 4 |
| `ca-init-no-pisa` — ca-init sale con 1 y no toca una CA que ya existe | 3 |
| `ca-init-fuera-de-git` — ca-init sale con 1 y no crea nada dentro de un repositorio git | 2 |
| `ca-uso` — ca-init, ca-sign y ca-revoke salen con 2 por uso incorrecto (sin .pub, identidad con espacios, opción desconocida) | 2 |
| `ca-sign-usuario` — ca-sign firma un certificado de usuario con user_ca, la identidad, los principals y el número de serie 1 | 5 |
| `ca-sign-validez` — ca-sign da 8 h y 5 min de margen por defecto a un usuario, y respeta -V | 3 |
| `ca-sign-host` — ca-sign -h firma un certificado de host con host_ca, sus nombres y un año de validez | 4 |
| `ca-sign-registro` — ca-sign numera cada certificado, guarda una copia en emitidos/ y una línea en emitidos.log | 5 |
| `ca-sign-opciones` — ca-sign pasa las -O a ssh-keygen (force-command, source-address) | 2 |
| `ca-sign-errores` — ca-sign sale con 1 sin CA o sin la llave, y no gasta números de serie | 2 |
| `ca-sign-agente` — ca-sign firma con la CA cargada en el agente si su llave privada no está en la carpeta | 3 |
| `ca-revoke-certificado` — ca-revoke revoca un certificado sin revocar su llave ni los demás certificados | 5 |
| `ca-revoke-serie` — ca-revoke SERIE revoca por número; con un número que no existe sale con 1 y no toca la KRL | 4 |
| `ca-revoke-llave` — ca-revoke de una llave pública revoca sus certificados de antes y de después | 3 |
| `srv-ca` — sshd confía en /etc/ssh/user_ca.pub, lee principals/%u y revoked.krl, y presenta el certificado de host | 5 |
| `certificado-entra` — Con el kit, un certificado con el rol admins entra sin authorized_keys en un sshd que solo conoces por la CA de hosts | 4 |
| `certificado-revocado` — Tras ca-revoke y copiar la KRL, el mismo certificado ya no entra | 3 |
| `kit-completo-y-limpio` — Sin TODOs, shellcheck sin avisos y los scripts anteriores siguen respondiendo | 1 |
| **Total** | **60** |

### Calidad — 40 puntos

| Criterio | Excelente | Suficiente | Puntos |
|---|---|---|:--:|
| **Comentarios Qué / Para qué / Impacto** | Cada script y cada opción de `50-ca.conf` con los tres; el Impacto de `RevokedKeys` dice qué pasa si falta el archivo y el de `AuthorizedPrincipalsFile`, qué pasa con una cuenta sin archivo | Las opciones comentadas, sin Impacto en alguna | 12 |
| **README del kit** | Filas de los tres scripts y de `50-ca.conf`; bitácora de la semana 10; sección "Autoridad de certificados" con dónde vive la CA, servidor nuevo en orden, firmar, revocar y rotar | Filas y bitácora, sin la sección completa | 10 |
| **Mensajes** | Cada fallo dice qué pasó (CA existente, dentro de git, sin CA, número inexistente, KRL sin cambios), por stderr; los usos nombran todas las opciones | Mensajes correctos sin explicar el porqué | 6 |
| **Robustez** | `ca-sign` no gasta números si la firma falla; `ca-revoke` no toca la KRL hasta comprobar la nueva y borra el temporal; `ca-init` no deja la CA legible por otros | Falta una de las tres | 8 |
| **Git** | Commit nuevo en `~/ssh-infra-kit` con mensaje descriptivo, sin la carpeta de la CA, llaves ni certificados | Sin commit de la semana | 4 |
| **Total** | | | **40** |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| La llave privada de una CA, una llave privada o una host key en el repositorio del kit o en su historial de git | −20 pts |
| Un certificado de usuario sin `-V` (eterno) en los ejemplos o en los valores por defecto del kit | −10 pts |
| `StrictHostKeyChecking no` o `UserKnownHostsFile /dev/null` en cualquier archivo del kit | −10 pts |
| `ForwardAgent yes` en cualquier host del kit | −10 pts |
| `@cert-authority *` (la CA vale para cualquier host) | −5 pts |

---

## 📋 Checklist de entrega

- [ ] Los 7 labs con sus criterios de éxito comprobados
- [ ] Las 10 preguntas de Conocimiento respondidas por escrito
- [ ] `3-proyecto/starter/` sin ningún `TODO`
- [ ] `./scripts/verificar-semana.sh 10` con las 18 comprobaciones en verde
- [ ] `ssh-infra-kit` con un commit nuevo y sin llaves ni certificados

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Proyecto — ssh-infra-kit: tu autoridad de certificados](3-proyecto/README.md) | [Recursos — ebooks](4-recursos/ebooks-free/README.md) → |

[↑ Semana 10](README.md)
