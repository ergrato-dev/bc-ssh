# Proyecto hilo conductor: `ssh-infra-kit`

**Qué:** un repositorio propio con toda tu configuración y herramientas SSH. **Para qué:** que cada semana sume una pieza real y terminado el bootcamp tengas un kit reutilizable en tu trabajo. **Impacto:** el proyecto de cada semana parte de lo que entregaste la anterior; si una semana queda floja, la siguiente lo nota.

## Estructura final (semana 14)

```
ssh-infra-kit/
├── README.md
├── config                 # punto de entrada de cliente: solo Include conf.d/*
├── conf.d/                # 10-defaults.conf, 20-lab.conf, 30-bastion.conf ...
├── bin/                   # scripts bash: diagnóstico, backups, túneles, rotación
├── server/
│   └── sshd_config.d/     # hardening del servidor
├── ca/                    # scripts de la autoridad de certificados
└── ansible/               # automatización (inventario y playbooks)
```

Las llaves privadas **nunca** van al kit: los scripts las generan en `~/.ssh` o reciben su ruta.

## Incremento por semana

| Semana | Qué añades al kit |
|---|---|
| 01 | `config` mínimo y `bin/lab-check` (diagnóstico de conectividad) |
| 02 | Gestión de `known_hosts` y verificación de huellas |
| 03 | Generación de llaves y `authorized_keys` con opciones |
| 04 | Uso de agente y llaves `-sk` |
| 05 | `conf.d/` modular con `Include`, `Match` y multiplexing |
| 06 | `bin/` de transferencia y backup con rsync |
| 07 | `server/sshd_config.d/` endurecido |
| 08 | Túneles persistentes a PostgreSQL |
| 09 | Acceso a `interno` vía `bastion` |
| 10 | `ca/`: firma de llaves de usuario y host, KRL |
| 11 | 2FA, fail2ban y auditoría con `ssh-audit` |
| 12 | `ansible/` y despliegue desde CI |
| 13 | Diagnóstico y migración de algoritmos |
| 14 | Integración, documentación y defensa |
