# Semana 10 — Certificados SSH: CA, principals, KRL y rotación

## Descripción

Con llaves sueltas, cada servidor tiene que conocer la llave de cada persona, y cada persona la host key de cada servidor: dos listas que nunca están al día. Esta semana creas una **autoridad de certificados**: una llave que firma llaves. Firmas la tuya y entras en `server` sin tocar su `authorized_keys`; firmas las host keys y entras en `server`, `bastion` e `interno` con un `known_hosts` de una línea. Decides como quién entra cada certificado (principals y roles), cuándo y qué permite, lo revocas antes de que caduque con una KRL, cambias la CA sin dejar a nadie fuera y la proteges como lo que es: la llave de todos tus servidores. Tu kit gana `ca/`, con `ca-init`, `ca-sign` y `ca-revoke`, y la configuración de `sshd` que confía en tu CA.

## Objetivos de aprendizaje

Al terminar esta semana, podrás:

- Explicar qué problema de `authorized_keys` y `known_hosts` resuelve una CA y qué firma exactamente
- Firmar certificados de usuario con identidad, número de serie, principals y validez, y leerlos con `ssh-keygen -L`
- Configurar `TrustedUserCAKeys` y `AuthorizedPrincipalsFile` para firmar con roles
- Limitar un certificado con `force-command`, `source-address` y sus extensiones
- Firmar host keys, presentarlas con `HostCertificate` y confiar en ellas con `@cert-authority`
- Revocar certificados, llaves y números de serie con una KRL, y evitar que una KRL ausente te deje fuera
- Rotar la CA de usuarios y la de hosts en el orden correcto, con `@revoked` para la vieja
- Proteger la CA (frase, agente, `ssh-keygen -U`) y relacionar el log de un servidor con tu registro de emisiones
- Añadir a tu `ssh-infra-kit` `ca/ca-init`, `ca/ca-sign`, `ca/ca-revoke` y `server/sshd_config.d/50-ca.conf`

## Prerrequisitos

- [Semana 09](../week-09-bastion_hosts_y_arquitecturas_segmentadas/README.md) completa: el kit con `40-salto.conf` y los saltos a `interno`
- Host keys y `known_hosts` ([semana 02](../week-02-protocolo_kex_y_known_hosts/README.md)), llaves y `authorized_keys` ([semana 03](../week-03-autenticacion_con_llaves_ssh/README.md)), el agente ([semana 04](../week-04-ssh_agent_y_llaves_fido2/README.md)) y `sshd_config` con `sshd-deploy` ([semana 07](../week-07-servidor_sshd_config_y_hardening/README.md))
- El laboratorio levantado: `docker compose up -d` (esta semana no cambia `compose.yaml`)

## Contenido

| # | Tipo | Tema | Tiempo |
|---|------|------|--------|
| — | Teoría | [01-por-que-certificados.md](1-teoria/01-por-que-certificados.md) · [02-certificados-de-usuario-y-de-host.md](1-teoria/02-certificados-de-usuario-y-de-host.md) · [03-revocacion-y-rotacion.md](1-teoria/03-revocacion-y-rotacion.md) | 1.5 h |
| — | Conocimiento | [10 preguntas](rubrica-evaluacion.md#-conocimiento-30) | 30 min |
| 1 | Lab | [lab-01-primera-ca](2-practicas/lab-01-primera-ca/) | 60 min |
| 2 | Lab | [lab-02-principals](2-practicas/lab-02-principals/) | 60 min |
| 3 | Lab | [lab-03-validez-y-opciones](2-practicas/lab-03-validez-y-opciones/) | 60 min |
| 4 | Lab | [lab-04-certificados-de-host](2-practicas/lab-04-certificados-de-host/) | 60 min |
| 5 | Lab | [lab-05-revocacion-krl](2-practicas/lab-05-revocacion-krl/) | 60 min |
| 6 | Lab | [lab-06-rotacion-de-la-ca](2-practicas/lab-06-rotacion-de-la-ca/) | 60 min |
| 7 | Lab | [lab-07-proteger-y-auditar-la-ca](2-practicas/lab-07-proteger-y-auditar-la-ca/) | 60 min |
| — | Proyecto | [ssh-infra-kit: tu autoridad de certificados](3-proyecto/) | 3 h |

**Total: 12 horas**

## Distribución del tiempo

```
[1.5 h]  Leer 1-teoria/ (por qué certificados, usuario y host, revocación y rotación)
[30 min] Responder las 10 preguntas de Conocimiento
[60 min] lab-01 — Una CA, una llave firmada y entrar sin authorized_keys
[60 min] lab-02 — Principals, AuthorizedPrincipalsFile y cert-authority
[60 min] lab-03 — Validez, force-command, source-address, extensiones y agente
[60 min] lab-04 — Host keys firmadas y un known_hosts de una línea
[60 min] lab-05 — KRL: certificados, llaves y números de serie
[60 min] lab-06 — Rotar las dos CA sin dejar a nadie fuera
[60 min] lab-07 — Frase, agente, registro y auditoría
[3 h]    Proyecto: ca-init, ca-sign, ca-revoke y 50-ca.conf
```

## Verificación de completitud

Desde la raíz del repositorio, en tu equipo:

```bash
./scripts/verificar-semana.sh 10
```

Comprueba tu proyecto (`3-proyecto/starter/`) contra los 18 requisitos verificables de la semana. Crean CA de usar y tirar en carpetas temporales, firman y revocan con tus scripts, y entran en un `sshd` propio en `127.0.0.1:2211` configurado con tu `50-ca.conf`: solo funcionan dentro del laboratorio. Al terminar deben pasar todos, y tu kit debe entrar en `server` sin `authorized_keys`:

```bash
cd bootcamp/week-10-certificados_ssh_ca_principals_krl_y_rotacion/3-proyecto/starter
bin/kit-link
ssh -F config lab-server hostname
```

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [← Semana 09 — Bastion hosts y arquitecturas segmentadas](../week-09-bastion_hosts_y_arquitecturas_segmentadas/README.md) | **Semana 10 — Certificados SSH: CA, principals, KRL y rotación** | Semana 11 — 2FA, fail2ban y auditoría (próximamente) |

[← Volver al índice del bootcamp](../README.md)
