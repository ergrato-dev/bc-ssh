# Semana 03 — Autenticación con llaves

## Descripción

Dejas de escribir la contraseña. Verás por qué una llave es más segura que una contraseña aunque las dos viajen cifradas: el servidor recibe una firma que solo vale para esa conexión, nunca un secreto reutilizable. Generarás llaves Ed25519, las protegerás con una frase de paso, las instalarás en el servidor y diagnosticarás los fallos más comunes (permisos, demasiadas llaves) leyendo el log del servidor. La segunda mitad trata del lado del servidor: `authorized_keys` y sus opciones para limitar lo que puede hacer una llave, y cómo rotar una llave sin quedarte fuera. Tu kit pasa a entrar con llave y a crear llaves y líneas restringidas siempre bien hechas.

## Objetivos de aprendizaje

Al terminar esta semana, podrás:

- Explicar qué recibe el servidor con contraseña y con llave, y por qué una firma no se puede reutilizar
- Seguir en `ssh -v` y en el log del servidor los cuatro pasos de la autenticación con llave
- Generar llaves Ed25519 con frase de paso y elegir el tipo adecuado cuando Ed25519 no está disponible
- Diagnosticar fallos de permisos en el cliente y de `StrictModes` en el servidor
- Usar una llave por host con `IdentityFile` e `IdentitiesOnly`
- Limitar una llave con `restrict`, `command=`, `from=` y `expiry-time=`
- Rotar una llave sin perder el acceso
- Añadir a tu `ssh-infra-kit` `bin/key-new` y `bin/ak-line`

## Prerrequisitos

- [Semana 02](../week-02-protocolo_kex_y_known_hosts/README.md) completa: `known_hosts` verificado con `bin/kh-add` e identificador de sesión (hash del intercambio)
- El laboratorio levantado: `docker compose up -d`

## Contenido

| # | Tipo | Tema | Tiempo |
|---|------|------|--------|
| — | Teoría | [01-autenticacion-con-llave-publica.md](1-teoria/01-autenticacion-con-llave-publica.md) · [02-tipos-de-llave-y-frase-de-paso.md](1-teoria/02-tipos-de-llave-y-frase-de-paso.md) · [03-authorized_keys-y-opciones.md](1-teoria/03-authorized_keys-y-opciones.md) | 1.5 h |
| — | Conocimiento | [10 preguntas](rubrica-evaluacion.md#-conocimiento-30) | 30 min |
| 1 | Lab | [lab-01-tu-primer-par-de-llaves](2-practicas/lab-01-tu-primer-par-de-llaves/) | 60 min |
| 2 | Lab | [lab-02-entrar-sin-contrasena](2-practicas/lab-02-entrar-sin-contrasena/) | 60 min |
| 3 | Lab | [lab-03-frase-de-paso](2-practicas/lab-03-frase-de-paso/) | 60 min |
| 4 | Lab | [lab-04-permisos-y-strictmodes](2-practicas/lab-04-permisos-y-strictmodes/) | 60 min |
| 5 | Lab | [lab-05-varias-llaves](2-practicas/lab-05-varias-llaves/) | 60 min |
| 6 | Lab | [lab-06-opciones-de-authorized-keys](2-practicas/lab-06-opciones-de-authorized-keys/) | 60 min |
| 7 | Lab | [lab-07-rotar-una-llave](2-practicas/lab-07-rotar-una-llave/) | 60 min |
| — | Proyecto | [ssh-infra-kit: llaves propias y authorized_keys restringido](3-proyecto/) | 3 h |

**Total: 12 horas**

## Distribución del tiempo

```
[1.5 h]  Leer 1-teoria/ (llave pública, tipos y frase de paso, authorized_keys)
[30 min] Responder las 10 preguntas de Conocimiento
[60 min] lab-01 — ssh-keygen, archivos, permisos y huellas
[60 min] lab-02 — ssh-copy-id, ssh -v y el log del servidor
[60 min] lab-03 — Frase de paso, openssh-key-v1 y rondas de bcrypt
[60 min] lab-04 — Permisos en el cliente y StrictModes en el servidor
[60 min] lab-05 — Una llave por host y Too many authentication failures
[60 min] lab-06 — restrict, command=, from= y expiry-time=
[60 min] lab-07 — Rotar una llave sin quedarte fuera
[3 h]    Proyecto: IdentityFile/IdentitiesOnly, bin/key-new y bin/ak-line
```

## Verificación de completitud

Desde la raíz del repositorio, en tu equipo:

```bash
./scripts/verificar-semana.sh 03
```

Comprueba tu proyecto (`3-proyecto/starter/`) contra los 26 requisitos verificables de la semana; tres de ellos arrancan un `sshd` real dentro del cliente para probar tus líneas de `authorized_keys`. Al terminar deben pasar todos, y esto debe funcionar dentro del cliente sin pedir la contraseña del servidor (solo la frase de tu llave):

```bash
cd bootcamp/week-03-autenticacion_con_llaves_ssh/3-proyecto/starter
bin/key-new lab
ssh-copy-id -F config -i ~/.ssh/lab.pub lab-server
ssh -F config lab-server hostname
```

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [← Semana 02 — Protocolo por dentro: KEX, host keys y known_hosts](../week-02-protocolo_kex_y_known_hosts/README.md) | **Semana 03 — Autenticación con llaves** | Semana 04 — `ssh-agent`, agent forwarding y llaves FIDO2 (próximamente) |

[← Volver al índice del bootcamp](../README.md)
