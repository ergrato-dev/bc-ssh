# Videografía — Semana 07

| Video | Canal | Descripción |
|-------|-------|-------------|
| [Asegura tu Servidor SSH en GNU/Linux: Hardening Paso a Paso](https://www.youtube.com/watch?v=Xa7ba6N2B7M) | — | En español: el recorrido de los labs 02 y 03 sobre `sshd_config` |
| [MEJORA LA SEGURIDAD SSH](https://www.youtube.com/watch?v=u2EqFvPC7Ec) | — | En español: opciones básicas de endurecimiento del servidor |
| [5 Must Have Tweaks to Secure OpenSSH](https://www.youtube.com/watch?v=sBrAVQumqjs) | — | Cambios habituales en el servidor, `AllowGroups` incluido (lab 03) |
| [sshd_config options for SSH server on Ubuntu Server](https://www.youtube.com/watch?v=MKMW-rBPxSw) | — | Las opciones de `sshd_config` en Ubuntu Server: el lab 01 |
| [Setup SSH and SFTP server with chroot jail](https://www.youtube.com/watch?v=bAjXR78FTs8) | — | Cuentas solo SFTP y `ChrootDirectory`: el lab 05 |
| [Ultimate Guide: Creating a Secure SFTP Server with Chroot on Ubuntu 22.04](https://www.youtube.com/watch?v=pJrK3LbB4MU) | — | Chroot SFTP en Ubuntu, paso a paso; compáralo con `30-sftp.conf` del kit |

Los que no están en español, en inglés; YouTube permite activar subtítulos traducidos. Muchos tutoriales editan `/etc/ssh/sshd_config` directamente, recargan sin `sshd -t` y prueban con la sesión que ya tenían abierta: aplica lo que viste en el lab 07. Algunos cambian el puerto 22 como medida de seguridad: reduce el ruido en los logs, pero no protege de nada que no protejan las llaves.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — ebooks](../ebooks-free/README.md) | [Recursos — web](../webgrafia/README.md) → |

[↑ Semana 07](../../README.md)
