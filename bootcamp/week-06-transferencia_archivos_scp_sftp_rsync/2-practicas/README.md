# Labs — Semana 06: transferencia de archivos

| # | Lab | Objetivo | Tiempo |
|---|-----|----------|--------|
| 1 | [lab-01-scp](lab-01-scp/) | Copiar en los dos sentidos y entre servidores; `-r`, `-p`, `-R` y el riesgo de `-O` | ~60 min |
| 2 | [lab-02-sftp](lab-02-sftp/) | Sesión interactiva, lotes con `-b`, errores que paran el lote y `reput` | ~60 min |
| 3 | [lab-03-rsync](lab-03-rsync/) | `rsync -a`, la barra final, `-n -i`, el algoritmo de diferencias y `-c` | ~60 min |
| 4 | [lab-04-delete-y-exclude](lab-04-delete-y-exclude/) | `--delete` sin sustos, exclusiones y `--backup-dir` | ~60 min |
| 5 | [lab-05-snapshots-con-link-dest](lab-05-snapshots-con-link-dest/) | Copias completas que comparten lo que no cambió, con enlaces duros | ~60 min |
| 6 | [lab-06-llave-solo-para-rsync](lab-06-llave-solo-para-rsync/) | Una llave de copias con `rrsync -ro`: sin shell, sin escribir, sin salir de su carpeta | ~60 min |
| 7 | [lab-07-transferencias-grandes](lab-07-transferencias-grandes/) | `--partial`, `--bwlimit`, progreso, multiplexing y `tar` por `ssh` | ~60 min |

**Total labs: 7 horas**

## Antes de cada lab

- **Paso 0** del [lab 01](lab-01-scp/README.md): `docker compose up -d --build --force-recreate server bastion` y `docker compose run --rm client` **en tu equipo**; `known_hosts`, llave y `cd ~/w` **en el cliente**.
- Trabajas en `~/w`, dentro del contenedor: los archivos de prueba no ensucian el repositorio. El cliente es un contenedor nuevo cada vez: `~/.ssh` y `~/w` desaparecen con `exit`. Haz cada lab en una sola sesión.
- `--force-recreate` deja `server` limpio: sin archivos ni llaves de labs anteriores.
- Antes de cualquier `rsync` con `--delete`, ensaya con `-n -i`.
- Usuario `alumno`, contraseña `alumno`. **Es una contraseña débil a propósito y solo existe en el laboratorio.** Los labs usan `sshpass` para no teclearla; fuera del laboratorio, nunca.
- Las llaves de los labs no tienen frase de paso para no escribirla en cada paso: solo en el laboratorio. **Nunca subas una llave privada a git.**

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — Copias de seguridad por SSH y llaves que solo copian](../1-teoria/03-copias-de-seguridad-y-llaves-restringidas.md) | [Lab 01 — `scp`](lab-01-scp/README.md) → |

[↑ Semana 06](../README.md)
