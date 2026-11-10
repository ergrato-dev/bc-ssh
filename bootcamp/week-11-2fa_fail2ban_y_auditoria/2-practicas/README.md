# Labs — Semana 11: 2FA, fail2ban y auditoría

| # | Lab | Objetivo | Tiempo |
|---|-----|----------|--------|
| 1 | [lab-01-leer-ssh-audit](lab-01-leer-ssh-audit/) | Leer un informe de `ssh-audit` del servidor y del cliente; niveles, recomendaciones, Terrapin, DHEat y JSON | ~60 min |
| 2 | [lab-02-quitar-algoritmos](lab-02-quitar-algoritmos/) | Quitar algoritmos con listas `-`, comprobar con `sshd -T` y ver qué clientes dejan de conectar | ~60 min |
| 3 | [lab-03-politicas-ssh-audit](lab-03-politicas-ssh-audit/) | Políticas integradas, generadas y escritas a mano; comprobar varios servidores | ~60 min |
| 4 | [lab-04-totp-por-dentro](lab-04-totp-por-dentro/) | Crear un secreto, leer `~/.google_authenticator` y calcular códigos con `oathtool` | ~60 min |
| 5 | [lab-05-llave-y-codigo](lab-05-llave-y-codigo/) | PAM, `AuthenticationMethods` y `Match Group`: llave **y** código, solo para un grupo | ~60 min |
| 6 | [lab-06-fail2ban](lab-06-fail2ban/) | Jaula, `fail2ban-regex`, un bloqueo de verdad, nftables, desbloqueo y modos | ~60 min |
| 7 | [lab-07-leer-el-log](lab-07-leer-el-log/) | Quién entró, con qué llave, quién falla y desde dónde; `sshd -T` como foto de la configuración | ~60 min |

**Total labs: 7 horas**

## Antes de cada lab

- **Paso 0** del [lab 01](lab-01-leer-ssh-audit/README.md): `docker compose up -d --force-recreate server bastion interno` y `docker compose run --rm client` **en tu equipo**; `known_hosts` y tu llave de administrar en `server` y `bastion` **en el cliente**.
- Si aún no lo hiciste, reconstruye antes el laboratorio (`docker compose build`): esta semana la imagen trae `ssh-audit`, `fail2ban`, `nftables`, `libpam-google-authenticator` y `oathtool`.
- Ten **otra terminal en tu equipo** en la raíz del repositorio: si un lab te deja fuera de `server` (fail2ban, un PAM mal escrito), entras por la consola con `docker compose exec server bash`.
- Las contraseñas, las llaves sin frase y los secretos TOTP en variables de estos labs son **solo para el laboratorio**.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — fail2ban y el log de sshd](../1-teoria/03-fail2ban-y-registros.md) | [Lab 01 — Leer un informe de ssh-audit](lab-01-leer-ssh-audit/README.md) → |

[↑ Semana 11](../README.md)
