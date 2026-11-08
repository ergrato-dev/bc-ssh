# Labs — Semana 03: Autenticación con llaves

| # | Lab | Objetivo | Tiempo |
|---|-----|----------|--------|
| 1 | [lab-01-tu-primer-par-de-llaves](lab-01-tu-primer-par-de-llaves/) | Generar un par Ed25519, reconocer sus archivos y permisos, y calcular su huella | ~60 min |
| 2 | [lab-02-entrar-sin-contrasena](lab-02-entrar-sin-contrasena/) | Instalar la llave con `ssh-copy-id` y seguir la autenticación en `ssh -v` y en el log del servidor | ~60 min |
| 3 | [lab-03-frase-de-paso](lab-03-frase-de-paso/) | Cifrar la privada con una frase, verlo dentro del archivo y medir el coste de las rondas | ~60 min |
| 4 | [lab-04-permisos-y-strictmodes](lab-04-permisos-y-strictmodes/) | Provocar y diagnosticar fallos de permisos en el cliente y en el servidor | ~60 min |
| 5 | [lab-05-varias-llaves](lab-05-varias-llaves/) | Una llave por host; provocar y evitar `Too many authentication failures` | ~60 min |
| 6 | [lab-06-opciones-de-authorized-keys](lab-06-opciones-de-authorized-keys/) | Limitar una llave con `restrict`, `command=`, `from=` y `expiry-time=` | ~60 min |
| 7 | [lab-07-rotar-una-llave](lab-07-rotar-una-llave/) | Sustituir una llave por otra sin quedarte fuera | ~60 min |

**Total labs: 7 horas**

## Antes de cada lab

- **Paso 0** con `docker compose up -d` y `docker compose run --rm client` **en tu equipo**, y `cd` a la carpeta del lab **en el cliente**.
- El cliente es un contenedor nuevo cada vez: `~/.ssh` (tus llaves) empieza vacío y desaparece con `exit`. Haz cada lab en una sola sesión.
- `server` y `bastion`, en cambio, conservan su `authorized_keys` entre sesiones. Varios labs empiezan con `docker compose up -d --force-recreate server` para partir de cero.
- Usuario `alumno`, contraseña `alumno`. **Es una contraseña débil a propósito y solo existe en el laboratorio.** Los labs usan `sshpass` para no teclearla; fuera del laboratorio, nunca.
- Las llaves de los labs no tienen frase de paso para ir rápido. Las tuyas reales, sí (lab 03).
- **Nunca subas una llave privada a git.** El `.gitignore` del repositorio bloquea los nombres habituales, pero la responsabilidad es tuya.
- Si un lab tiene `starter/`, trabaja ahí. `solucion/` es la referencia.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — `authorized_keys` y sus opciones](../1-teoria/03-authorized_keys-y-opciones.md) | [Lab 01 — Tu primer par de llaves](lab-01-tu-primer-par-de-llaves/README.md) → |

[↑ Semana 03](../README.md)
