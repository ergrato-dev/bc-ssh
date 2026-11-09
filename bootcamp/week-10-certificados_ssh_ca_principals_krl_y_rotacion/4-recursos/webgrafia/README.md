# Webgrafía — Semana 10

| Recurso | Descripción |
|---------|-------------|
| [`ssh-keygen(1)`, sección CERTIFICATES y KEY REVOCATION LISTS](https://man.openbsd.org/ssh-keygen#CERTIFICATES) | La referencia de `-s`, `-I`, `-n`, `-V`, `-z`, `-O`, `-k` y `-Q`, y el formato de texto para revocar por número o identidad |
| [`sshd_config(5)`](https://man.openbsd.org/sshd_config) | `TrustedUserCAKeys`, `AuthorizedPrincipalsFile`, `RevokedKeys`, `HostCertificate` y `ExposeAuthInfo` |
| [`sshd(8)`, AUTHORIZED_KEYS y SSH_KNOWN_HOSTS](https://man.openbsd.org/sshd#AUTHORIZED_KEYS_FILE_FORMAT) | `cert-authority`, `principals=`, `@cert-authority` y `@revoked` |
| [PROTOCOL.certkeys](https://cvsweb.openbsd.org/src/usr.bin/ssh/PROTOCOL.certkeys?rev=HEAD) | El formato de un certificado de OpenSSH, campo a campo, y la lista de opciones críticas y extensiones |
| [Hetzner Community — Simple CA for SSH](https://community.hetzner.com/tutorials/simple-ca-for-ssh) | Una CA de usuarios y de hosts de principio a fin en servidores Ubuntu |
| [Jan-Piet Mens — SSH certificates: the better SSH experience](https://jpmens.net/2026/04/03/ssh-certificates-the-better-ssh-experience/) | Experiencia real con certificados: qué cambia en el día a día y qué errores aparecen |
| [Teleport — How to configure SSH certificate-based authentication](https://goteleport.com/blog/how-to-configure-ssh-certificate-based-authentication/) | El mismo flujo, con el argumento para usar dos CA separadas |
| [HashiCorp Vault — Signed SSH certificates](https://developer.hashicorp.com/vault/docs/secrets/ssh/signed-ssh-certificates) | Un servicio que firma certificados cortos bajo demanda: el siguiente paso cuando `ca-sign` se queda pequeño |
| [GitHub Docs — Acerca de las autoridades de certificación SSH](https://docs.github.com/es/enterprise-server@3.19/organizations/managing-git-access-to-your-organizations-repositories/about-ssh-certificate-authorities) | Certificados de usuario para entrar en Git con la CA de tu organización |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — videos](../videografia/README.md) | [Glosario](../../5-glosario/README.md) → |

[↑ Semana 10](../../README.md)
