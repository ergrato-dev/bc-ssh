# Glosario — Semana 07

| Término | Definición |
|---------|------------|
| **`AllowGroups` / `AllowUsers`** | Opciones de `sshd` que dejan entrar solo a los grupos o usuarios de la lista. Se acumulan y se combinan con `Deny*` |
| **chroot** | Cambio de la raíz del sistema de archivos para un proceso: lo que ve como `/` es una carpeta. `ChrootDirectory` la elige para una sesión SSH |
| **consola del proveedor** | Acceso a un servidor que no pasa por SSH (serie, VNC, KVM). En el laboratorio, `docker compose exec server` |
| **dead man's switch** | Mecanismo que actúa si nadie lo cancela. `sshd-apply` restaura la configuración anterior si no recibe confirmación |
| **`DenyUsers` / `DenyGroups`** | Opciones que impiden entrar a usuarios o grupos; se comprueban antes que las `Allow*` y ganan siempre |
| **`DisableForwarding`** | Opción que quita de una vez todos los reenvíos: puertos, agente, X11 y sockets |
| **drop-in** | Archivo de configuración suelto en una carpeta `.d/` que el archivo principal incluye: `/etc/ssh/sshd_config.d/*.conf` |
| **`ForceCommand`** | Opción que ejecuta siempre la misma orden e ignora la que pide el cliente |
| **hardening** | Endurecer un sistema: quitar lo que no se necesita y limitar lo que queda |
| **`internal-sftp`** | El servidor SFTP que va dentro de `sshd`; no necesita ningún archivo dentro del chroot |
| **`listener`** | El proceso de `sshd` que escucha en el puerto 22. Es el único que recarga la configuración |
| **`LoginGraceTime`** | Segundos que tiene una conexión para autenticarse antes de que `sshd` la cierre |
| **`Match`** | Bloque de `sshd_config` que aplica opciones solo a las conexiones que cumplen una condición (usuario, grupo, dirección...) |
| **`MaxAuthTries`** | Intentos de autenticación por conexión; cada llave ofrecida gasta uno |
| **`MaxStartups`** | Límite de conexiones sin autenticar; pasado el primero, `sshd` rechaza una parte de las nuevas |
| **`nologin`** | Shell (`/usr/sbin/nologin`) que solo escribe un mensaje y sale; la usan las cuentas que no deben abrir sesión |
| **primer valor gana** | Regla de `sshd` (y de `ssh`): para casi todas las opciones se queda con el primer valor que lee |
| **privilege separation** | División de `sshd` en procesos con distintos permisos: lo que no necesita ser root, no lo es |
| **recarga (`HUP`)** | Señal que hace que `sshd` vuelva a leer su configuración sin cortar las sesiones abiertas |
| **`sshd -t` / `sshd -T`** | Validar la configuración / escribir la configuración efectiva. Con `-C`, aplicando los `Match` de una conexión |
| **vuelta atrás** | Restaurar la configuración anterior cuando la nueva falla (*rollback*) |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — web](../4-recursos/webgrafia/README.md) | — |

[↑ Semana 07](../README.md)
