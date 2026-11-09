# Semana 07 — Servidor: `sshd_config`, `Match`, chroot SFTP y hardening

## Descripción

Seis semanas en el lado del cliente; esta cambias de lado. Administras `server`: lees de dónde saca `sshd` cada valor (y por qué un `PasswordAuthentication no` puede no hacer nada), decides quién entra y con qué método, aplicas reglas a unos pocos con `Match` y creas una cuenta que solo sube archivos, encerrada en su carpeta. Sobre todo, aprendes a cambiar `sshd` sin quedarte fuera: te quedas fuera a propósito varias veces, vuelves a entrar, y conviertes el procedimiento en una herramienta. Tu kit gana su primera carpeta de servidor, `server/sshd_config.d/`, y `bin/sshd-deploy`, que la aplica con vuelta atrás automática.

## Objetivos de aprendizaje

Al terminar esta semana, podrás:

- Explicar el orden en que `sshd` lee `sshd_config` y `sshd_config.d/`, y encontrar el valor que gana con `sshd -T`
- Validar con `sshd -t` y recargar sin cortar las sesiones abiertas, sabiendo por qué una sesión abierta no prueba nada
- Desactivar contraseñas y root, y limitar los intentos (`MaxAuthTries`, `LoginGraceTime`, `MaxStartups`)
- Decidir quién entra con `AllowGroups`, `AllowUsers` y `DenyUsers`, y leer en los logs el motivo de cada rechazo
- Escribir bloques `Match` sin sus trampas y probarlos con `sshd -T -C`
- Crear una cuenta solo SFTP con `internal-sftp`, `ChrootDirectory` y `DisableForwarding`
- Aplicar un cambio en `sshd` con validación, prueba sin master y vuelta atrás automática, y recuperarte por la consola
- Añadir a tu `ssh-infra-kit` `server/sshd_config.d/`, `server/sshd-apply` y `bin/sshd-deploy`

## Prerrequisitos

- [Semana 06](../week-06-transferencia_archivos_scp_sftp_rsync/README.md) completa: el kit con `bin/backup` y `bin/mirror`
- Multiplexing y el perfil `sinmux` de la [semana 05](../week-05-configuracion_avanzada_cliente_ssh/README.md): esta semana importa saber cuándo una conexión es nueva
- El laboratorio reconstruido y levantado: `docker compose up -d --build` (esta semana la imagen añade `sudo` sin contraseña para `alumno`, **solo en el laboratorio**)

## Contenido

| # | Tipo | Tema | Tiempo |
|---|------|------|--------|
| — | Teoría | [01-sshd-config-por-dentro.md](1-teoria/01-sshd-config-por-dentro.md) · [02-autenticacion-y-acceso.md](1-teoria/02-autenticacion-y-acceso.md) · [03-sftp-chroot-y-cambios-seguros.md](1-teoria/03-sftp-chroot-y-cambios-seguros.md) | 1.5 h |
| — | Conocimiento | [10 preguntas](rubrica-evaluacion.md#-conocimiento-30) | 30 min |
| 1 | Lab | [lab-01-sshd-config](2-practicas/lab-01-sshd-config/) | 60 min |
| 2 | Lab | [lab-02-autenticacion](2-practicas/lab-02-autenticacion/) | 60 min |
| 3 | Lab | [lab-03-quien-entra](2-practicas/lab-03-quien-entra/) | 60 min |
| 4 | Lab | [lab-04-match](2-practicas/lab-04-match/) | 60 min |
| 5 | Lab | [lab-05-sftp-chroot](2-practicas/lab-05-sftp-chroot/) | 60 min |
| 6 | Lab | [lab-06-sesion-y-reenvios](2-practicas/lab-06-sesion-y-reenvios/) | 60 min |
| 7 | Lab | [lab-07-cambios-sin-quedarte-fuera](2-practicas/lab-07-cambios-sin-quedarte-fuera/) | 60 min |
| — | Proyecto | [ssh-infra-kit: el servidor endurecido y cómo aplicarlo](3-proyecto/) | 3 h |

**Total: 12 horas**

## Distribución del tiempo

```
[1.5 h]  Leer 1-teoria/ (sshd_config por dentro, quién entra y cómo, SFTP y cambios seguros)
[30 min] Responder las 10 preguntas de Conocimiento
[60 min] lab-01 — Archivos, primer valor, sshd -t / -T y recarga
[60 min] lab-02 — Solo llaves, sin root, MaxAuthTries y LoginGraceTime
[60 min] lab-03 — AllowUsers, AllowGroups, DenyUsers y volver a entrar
[60 min] lab-04 — Match y sus trampas, sshd -T -C
[60 min] lab-05 — Cuenta solo SFTP con chroot y sin reenvíos
[60 min] lab-06 — Agente, X11, MaxSessions y ClientAliveInterval
[60 min] lab-07 — Quedarte fuera, volver, y la vuelta atrás automática
[3 h]    Proyecto: server/sshd_config.d/ y bin/sshd-deploy
```

## Verificación de completitud

Desde la raíz del repositorio, en tu equipo:

```bash
./scripts/verificar-semana.sh 07
```

Comprueba tu proyecto (`3-proyecto/starter/`) contra los 18 requisitos verificables de la semana. Arrancan un `sshd` real como root dentro del contenedor `client`, con tu configuración, usuarios de prueba y despliegues de verdad: solo funcionan dentro del laboratorio. Al terminar deben pasar todos, y `server` debe rechazar la contraseña:

```bash
cd bootcamp/week-07-servidor_sshd_config_y_hardening/3-proyecto/starter
bin/kit-link
bin/sshd-deploy lab-server
sshpass -p alumno ssh -F config -P sinmux -o PubkeyAuthentication=no lab-server true
```

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [← Semana 06 — Transferencia de archivos](../week-06-transferencia_archivos_scp_sftp_rsync/README.md) | **Semana 07 — Servidor: `sshd_config` y hardening** | [Semana 08 — Port forwarding, SOCKS y túneles →](../week-08-port_forwarding_socks_y_tuneles/README.md) |

[← Volver al índice del bootcamp](../README.md)
