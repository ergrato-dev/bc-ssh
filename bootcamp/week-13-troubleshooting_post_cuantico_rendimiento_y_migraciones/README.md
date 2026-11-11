# Semana 13 — Operación y troubleshooting: algoritmos post-cuánticos, rendimiento y migraciones

## Descripción

Tu kit ya monta, endurece y despliega. Esta semana toca lo que pasa después, cuando algo no va. Primero, **diagnosticar**: las siete capas de una conexión, qué error da cada una, `ssh -v` para el lado del cliente y `sshd -d`, `sshd -T -C` y `sshd -t` para el del servidor, que es el único que sabe por qué no entras. Después, **los algoritmos**: cómo se negocian, qué hacer con un equipo viejo que solo habla SHA-1 sin bajar la guardia en el resto, y por qué el intercambio de llaves tiene que ser **postcuántico** ya, aunque los ordenadores cuánticos no existan todavía. Por último, **rendimiento y migraciones**: medir dónde se va el tiempo (latencia, CPU, ancho de banda), y cambiar llaves de usuario y host keys en un orden que no deje a nadie fuera. Tu kit gana `bin/doctor`, `bin/key-audit`, los alias `legado-*`, `RequiredRSASize` y `UpdateHostKeys`.

## Objetivos de aprendizaje

Al terminar esta semana, podrás:

- Diagnosticar una conexión por capas, de abajo arriba, y reconocer el error de cada una
- Leer `ssh -v` y `-vvv`: lo negociado, la host key, las llaves ofrecidas y las dos listas de algoritmos
- Encontrar en el servidor la razón de un `Permission denied` con `sshd -d`, y comprobar la configuración con `sshd -T -C` y `sshd -t`
- Leer un `no matching ... Their offer` y entrar en un equipo viejo con `+` solo en su alias
- Explicar *store now, decrypt later*, los intercambios híbridos postcuánticos y por qué las host keys son menos urgentes
- Exigir algoritmos sin romper `sshd` con nombres que su versión no conoce
- Medir el efecto de la latencia, el multiplexing, el cifrado y la compresión, y elegir el arreglo según la causa
- Migrar llaves de usuario (inventario, añadir, comprobar, quitar, `RequiredRSASize`) y rotar host keys en dos fases con `UpdateHostKeys`
- Añadir a tu `ssh-infra-kit` `bin/doctor`, `bin/key-audit` y `conf.d/90-legado.conf`

## Prerrequisitos

- [Semana 12](../week-12-automatizacion_scripting_ci_cd_y_ansible/README.md) completa: el kit con `ansible/` y el playbook de los servidores
- `known_hosts` y huellas ([semana 02](../week-02-protocolo_kex_y_known_hosts/README.md)), multiplexing ([semana 05](../week-05-configuracion_avanzada_cliente_ssh/README.md)), `sshd_config` ([semana 07](../week-07-servidor_sshd_config_y_hardening/README.md)), certificados de host ([semana 10](../week-10-certificados_ssh_ca_principals_krl_y_rotacion/README.md)) y `ssh-audit` y los logs ([semana 11](../week-11-2fa_fail2ban_y_auditoria/README.md))
- El laboratorio de la semana 12 (con `ansible-core`); no hace falta reconstruirlo

## Contenido

| # | Tipo | Tema | Tiempo |
|---|------|------|--------|
| — | Teoría | [01-diagnostico-por-capas.md](1-teoria/01-diagnostico-por-capas.md) · [02-algoritmos-y-postcuantico.md](1-teoria/02-algoritmos-y-postcuantico.md) · [03-rendimiento-y-migraciones.md](1-teoria/03-rendimiento-y-migraciones.md) | 1.5 h |
| — | Conocimiento | [10 preguntas](rubrica-evaluacion.md#-conocimiento-30) | 30 min |
| 1 | Lab | [lab-01-leer-ssh-v](2-practicas/lab-01-leer-ssh-v/) | 60 min |
| 2 | Lab | [lab-02-el-lado-del-servidor](2-practicas/lab-02-el-lado-del-servidor/) | 60 min |
| 3 | Lab | [lab-03-sin-algoritmo-en-comun](2-practicas/lab-03-sin-algoritmo-en-comun/) | 60 min |
| 4 | Lab | [lab-04-postcuantico](2-practicas/lab-04-postcuantico/) | 60 min |
| 5 | Lab | [lab-05-medir-el-rendimiento](2-practicas/lab-05-medir-el-rendimiento/) | 60 min |
| 6 | Lab | [lab-06-migrar-llaves-de-usuario](2-practicas/lab-06-migrar-llaves-de-usuario/) | 60 min |
| 7 | Lab | [lab-07-rotar-host-keys](2-practicas/lab-07-rotar-host-keys/) | 60 min |
| — | Proyecto | [ssh-infra-kit: diagnóstico y migración de algoritmos](3-proyecto/) | 3 h |

**Total: 12 horas**

## Distribución del tiempo

```
[1.5 h]  Leer 1-teoria/ (diagnóstico por capas, algoritmos y postcuántico, rendimiento y migraciones)
[30 min] Responder las 10 preguntas de Conocimiento
[60 min] lab-01 — Leer ssh -v: capas, listas y errores
[60 min] lab-02 — El lado del servidor: sshd -d, permisos, grupos, sshd -T y -t
[60 min] lab-03 — Sin algoritmo en común: un equipo viejo y un alias
[60 min] lab-04 — Postcuántico: qué usas, exigirlo y lo que cuesta
[60 min] lab-05 — Medir el rendimiento: latencia, multiplexing, cifrado y compresión
[60 min] lab-06 — Migrar llaves de usuario sin dejar a nadie fuera
[60 min] lab-07 — Rotar host keys con UpdateHostKeys
[3 h]    Proyecto: bin/doctor, conf.d/90-legado.conf, bin/key-audit, RequiredRSASize y UpdateHostKeys
```

## Verificación de completitud

Desde la raíz del repositorio, en tu equipo:

```bash
./scripts/verificar-semana.sh 13
```

Comprueba tu proyecto (`3-proyecto/starter/`) contra los 14 requisitos verificables de la semana. Arrancan varios `sshd` sin root en `127.0.0.1` (uno moderno, uno sin postcuántico y uno viejo) y ejecutan contra ellos tu `bin/doctor` y tus alias `legado-*`: solo funcionan dentro del laboratorio. Al terminar deben pasar todos, y tu kit debe decir de cada servidor del laboratorio que entra con intercambio postcuántico:

```bash
cd bootcamp/week-13-troubleshooting_post_cuantico_rendimiento_y_migraciones/3-proyecto/starter
bin/doctor lab-server && bin/doctor lab-bastion
```

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [← Semana 12 — Automatización: scripting, CI/CD y Ansible](../week-12-automatizacion_scripting_ci_cd_y_ansible/README.md) | **Semana 13 — Operación y troubleshooting: algoritmos post-cuánticos, rendimiento y migraciones** | Semana 14 — Proyecto integrador `ssh-infra-kit` (próximamente) |

[← Volver al índice del bootcamp](../README.md)
