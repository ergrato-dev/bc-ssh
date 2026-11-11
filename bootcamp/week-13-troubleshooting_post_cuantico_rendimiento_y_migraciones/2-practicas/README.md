# Labs — Semana 13: Operación y troubleshooting

| # | Lab | Objetivo | Tiempo |
|---|-----|----------|--------|
| 1 | [lab-01-leer-ssh-v](lab-01-leer-ssh-v/) | `ssh -G`, las capas en `ssh -v`, las dos listas de `-vvv` y un error por capa | ~60 min |
| 2 | [lab-02-el-lado-del-servidor](lab-02-el-lado-del-servidor/) | `sshd -d` en otro puerto, permisos, `AllowGroups`, `sshd -T -C` y `sshd -t` | ~60 min |
| 3 | [lab-03-sin-algoritmo-en-comun](lab-03-sin-algoritmo-en-comun/) | Un equipo viejo: `Their offer`, `ssh -Q`, `+` en un alias y `ssh-audit` | ~60 min |
| 4 | [lab-04-postcuantico](lab-04-postcuantico/) | Qué intercambio usas, un servidor que exige postcuántico, la trampa del nombre desconocido y lo que cuesta | ~60 min |
| 5 | [lab-05-medir-el-rendimiento](lab-05-medir-el-rendimiento/) | Latencia con `tc netem`, multiplexing, cifrados y compresión, medidos | ~60 min |
| 6 | [lab-06-migrar-llaves-de-usuario](lab-06-migrar-llaves-de-usuario/) | Inventario de `authorized_keys`, `RequiredRSASize` y migrar sin dejar a nadie fuera | ~60 min |
| 7 | [lab-07-rotar-host-keys](lab-07-rotar-host-keys/) | Rotar una host key en dos fases con `UpdateHostKeys` | ~60 min |

**Total labs: 7 horas**

## Antes de cada lab

- **Paso 0** del [lab 01](lab-01-leer-ssh-v/README.md): `docker compose up -d --force-recreate server bastion interno` y `docker compose run --rm client` **en tu equipo**; `known_hosts` y tu llave de administrar en `server` y `bastion` **en el cliente**.
- Ten **otra terminal en tu equipo** en la raíz del repositorio: si te quedas fuera de `server`, entras por la consola con `docker compose exec server bash`.
- Los labs 02, 03 y 04 arrancan `sshd` extra en `server` (puertos 2222, 2223 y 2224); el 05 cambia su red con `tc`. El `--force-recreate` del paso 0 lo deja todo limpio.
- Las contraseñas y las llaves sin frase de estos labs son **solo para el laboratorio**.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — Rendimiento y migraciones](../1-teoria/03-rendimiento-y-migraciones.md) | [Lab 01 — Leer `ssh -v`](lab-01-leer-ssh-v/README.md) → |

[↑ Semana 13](../README.md)
