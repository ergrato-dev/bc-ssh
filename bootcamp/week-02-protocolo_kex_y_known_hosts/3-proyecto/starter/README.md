# ssh-infra-kit

Kit personal de acceso SSH, construido durante el bootcamp bc-ssh.

## Requisitos

- OpenSSH 9.6 o superior (`ssh -V`)
- bash, `nc` (netcat-openbsd), `getent`, `ssh-keyscan` y `ssh-keygen`

## Contenido

| Archivo | Qué hace | Ejemplo |
|---|---|---|
| `config` | Alias `lab-server` y `lab-bastion` (usuario `alumno`); `ConnectTimeout 5` para todos los hosts | `ssh -F config lab-server` |
| `bin/lab-check` | Comprueba DNS, puerto TCP y banner SSH de cada host. Sale con 0 si todos responden, 1 si falla alguno, 2 si no recibe hosts | `bin/lab-check server bastion` |
| `bin/kh-add` | TODO: qué hace, códigos de salida | TODO |

## Bitácora

| Semana | Cambio |
|---|---|
| 01 | `config` mínimo y `bin/lab-check` |
| 02 | TODO |
