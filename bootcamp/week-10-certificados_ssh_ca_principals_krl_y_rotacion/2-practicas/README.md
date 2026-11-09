# Labs — Semana 10: certificados SSH

| # | Lab | Objetivo | Tiempo |
|---|-----|----------|--------|
| 1 | [lab-01-primera-ca](lab-01-primera-ca/) | Crear una CA, firmar una llave, leer el certificado y entrar sin `authorized_keys` | ~60 min |
| 2 | [lab-02-principals](lab-02-principals/) | Principals, roles con `AuthorizedPrincipalsFile` y `cert-authority` en una sola cuenta | ~60 min |
| 3 | [lab-03-validez-y-opciones](lab-03-validez-y-opciones/) | Ventanas de validez, `force-command`, `source-address`, extensiones, el agente y la sesión que sobrevive | ~60 min |
| 4 | [lab-04-certificados-de-host](lab-04-certificados-de-host/) | Firmar host keys, `@cert-authority` y un `known_hosts` de una línea, también saltando | ~60 min |
| 5 | [lab-05-revocacion-krl](lab-05-revocacion-krl/) | KRL: revocar certificados, llaves y números de serie; qué pasa si falta | ~60 min |
| 6 | [lab-06-rotacion-de-la-ca](lab-06-rotacion-de-la-ca/) | Rotar la CA de usuarios y la de hosts sin dejar a nadie fuera; `@revoked` | ~60 min |
| 7 | [lab-07-proteger-y-auditar-la-ca](lab-07-proteger-y-auditar-la-ca/) | Frase, firma desde el agente, registro de emisiones, auditoría y `ExposeAuthInfo` | ~60 min |

**Total labs: 7 horas**

## Antes de cada lab

- **Paso 0** del [lab 01](lab-01-primera-ca/README.md): `docker compose up -d --force-recreate server bastion interno` y `docker compose run --rm client` **en tu equipo**; `known_hosts` y tu llave de administrar en `server` y `bastion` **en el cliente**. Desde el lab 02, además, el paso 0 del [lab 02](lab-02-principals/README.md): la CA de usuarios, la llave `trabajo` y el alias `server-cert`.
- La CA vive en `~/ca`, dentro del contenedor: desaparece al salir, y cada lab crea la suya. **Nunca la crees dentro del repositorio** (`/bc-ssh`): las llaves privadas acabarían en git.
- Ten **otra terminal en tu equipo** en la raíz del repositorio: lees el log de `server` con `docker compose logs --no-log-prefix server`.
- Las CA sin frase y las contraseñas de estos labs son **solo para el laboratorio**.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — Revocación, rotación y cuidado de la CA](../1-teoria/03-revocacion-y-rotacion.md) | [Lab 01 — Tu primera autoridad de certificados](lab-01-primera-ca/README.md) → |

[↑ Semana 10](../README.md)
