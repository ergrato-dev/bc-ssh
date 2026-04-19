ṕóíééé# 🔐 PLAN MAESTRO: Bootcamp SSH - 10 Semanas

**Parámetros del Bootcamp:**
- Duración: 10 semanas
- Dedicación semanal: 4 horas
- Total: 40 horas
- Teoría: 1 hora/semana (25%) - 3 módulos de 20 min
- Prácticas: 1.5 horas/semana (37.5%) - 3 prácticas de 30 min
- Proyecto: 1.5 horas/semana (37.5%)

---

## SEMANA 1: Fundamentos de SSH y Primera Conexión

**Objetivo:** Comprender qué es SSH y realizar la primera conexión exitosa.

**Teoría (1h):**
1. Historia y evolución de protocolos remotos (Telnet → SSH)
2. Arquitectura cliente-servidor de SSH
3. Conceptos de criptografía simétrica y asimétrica (introducción)

**Prácticas (1.5h):**
1. Instalación de cliente SSH en diferentes SO (⭐)
2. Primera conexión a servidor remoto con usuario/contraseña (⭐)
3. Configuración básica del archivo `~/.ssh/config` (⭐⭐)

**Proyecto (1.5h):**
Conectarse a 3 servidores diferentes usando configuración centralizada en archivo config, documentando cada paso realizado.

---

## SEMANA 2: Autenticación con Llaves SSH

**Objetivo:** Dominar la autenticación mediante criptografía de llave pública/privada.

**Teoría (1h):**
1. Diferencias entre autenticación por contraseña vs llaves
2. Funcionamiento de criptografía asimétrica RSA/Ed25519
3. Anatomía de una llave pública SSH

**Prácticas (1.5h):**
1. Generación de par de llaves SSH con diferentes algoritmos (⭐)
2. Instalación de llave pública en servidor remoto (`ssh-copy-id`) (⭐⭐)
3. Configuración de autenticación multi-factor con llaves + contraseña (⭐⭐⭐)

**Proyecto (1.5h):**
Crear infraestructura de llaves para 5 servidores diferentes, cada uno con algoritmo distinto (RSA, Ed25519, ECDSA), deshabilitando autenticación por contraseña.

---

## SEMANA 3: Configuración Avanzada del Cliente SSH

**Objetivo:** Optimizar la experiencia de usuario mediante configuración avanzada del cliente.

**Teoría (1h):**
1. Estructura completa del archivo `~/.ssh/config`
2. Opciones de conexión: timeouts, keep-alive, compression
3. ProxyJump y ProxyCommand para saltos entre servidores

**Prácticas (1.5h):**
1. Configurar aliases para conexiones frecuentes (⭐)
2. Implementar ProxyJump para acceder a servidores internos (⭐⭐)
3. Configurar multiplexing para reutilizar conexiones (⭐⭐⭐)

**Proyecto (1.5h):**
Crear archivo de configuración que gestione 10 servidores organizados jerárquicamente (bastion → servidores internos), con persistencia de conexiones y compresión activada.

---

## SEMANA 4: Transferencia de Archivos (SCP, SFTP, rsync)

**Objetivo:** Dominar las herramientas de transferencia segura de archivos sobre SSH.

**Teoría (1h):**
1. Diferencias entre SCP, SFTP y rsync
2. Uso de rsync para sincronización incremental
3. Compresión y ancho de banda en transferencias

**Prácticas (1.5h):**
1. Transferencia básica con SCP (local→remoto, remoto→local) (⭐)
2. Sesión interactiva con SFTP para gestión de archivos (⭐⭐)
3. Sincronización de directorios con rsync sobre SSH (⭐⭐⭐)

**Proyecto (1.5h):**
Crear script de backup automatizado que sincronice directorio local con servidor remoto usando rsync, excluyendo archivos temporales y con registro de cambios (log).

---

## SEMANA 5: Configuración del Servidor SSH (sshd)

**Objetivo:** Configurar y endurecer la seguridad del servidor SSH.

**Teoría (1h):**
1. Anatomía del archivo `/etc/ssh/sshd_config`
2. Directivas de seguridad críticas (PermitRootLogin, PasswordAuthentication)
3. Logs y auditoría de accesos SSH

**Prácticas (1.5h):**
1. Cambiar puerto por defecto y configurar firewall (⭐)
2. Deshabilitar autenticación root y por contraseña (⭐⭐)
3. Configurar listas blancas/negras de usuarios (AllowUsers/DenyUsers) (⭐⭐⭐)

**Proyecto (1.5h):**
Configurar servidor SSH endurecido con las mejores prácticas: puerto no estándar, sin root login, solo autenticación por llaves, límite de intentos con fail2ban, y monitoreo de logs.

---

## SEMANA 6: Port Forwarding y Túneles SSH

**Objetivo:** Utilizar SSH para crear túneles seguros entre redes.

**Teoría (1h):**
1. Conceptos de Local Port Forwarding (-L)
2. Remote Port Forwarding (-R) y casos de uso
3. Dynamic Port Forwarding (-D) como SOCKS proxy

**Prácticas (1.5h):**
1. Acceder a base de datos remota mediante túnel local (⭐)
2. Exponer servicio local a internet mediante túnel remoto (⭐⭐)
3. Configurar SOCKS proxy para navegar a través de servidor remoto (⭐⭐⭐)

**Proyecto (1.5h):**
Crear túnel persistente que permita acceder a servidor web interno (puerto 8080) desde máquina local, y configurar navegador para usar el servidor como proxy SOCKS.

---

## SEMANA 7: SSH Agent y Gestión de Llaves

**Objetivo:** Gestionar múltiples llaves SSH de forma eficiente y segura.

**Teoría (1h):**
1. Funcionamiento de ssh-agent
2. Forwarding de agente SSH (Agent Forwarding)
3. Limitaciones de seguridad del agent forwarding

**Prácticas (1.5h):**
1. Iniciar ssh-agent y agregar llaves con ssh-add (⭐)
2. Configurar agent forwarding para saltos entre servidores (⭐⭐)
3. Usar ssh-agent con llaves protegidas por passphrase (⭐⭐⭐)

**Proyecto (1.5h):**
Configurar entorno de trabajo que inicie ssh-agent automáticamente al login, cargue llaves específicas según contexto, y permita saltar entre 3 servidores sin reautenticación.

---

## SEMANA 8: Bastion Hosts y Arquitecturas de Acceso

**Objetivo:** Implementar arquitecturas de seguridad con servidores bastion/jump.

**Teoría (1h):**
1. Concepto de bastion host y su rol en seguridad
2. Arquitecturas de red con DMZ y redes privadas
3. ProxyJump vs ProxyCommand en profundidad

**Prácticas (1.5h):**
1. Configurar bastion host con autenticación dual (⭐)
2. Acceder a servidores privados mediante bastion con ProxyJump (⭐⭐)
3. Implementar rotación de llaves en bastion host (⭐⭐⭐)

**Proyecto (1.5h):**
Diseñar e implementar infraestructura completa: 1 bastion público, 3 servidores privados (web, db, cache), configurar acceso únicamente vía bastion con auditoría de conexiones.

---

## SEMANA 9: Automatización con SSH (Scripts y Ansible)

**Objetivo:** Automatizar tareas administrativas usando SSH como transporte.

**Teoría (1h):**
1. Ejecución de comandos remotos con SSH
2. Introducción a Ansible y SSH como transporte
3. Casos de uso: deployments, backups, monitoreo

**Prácticas (1.5h):**
1. Ejecutar comandos remotos y capturar output en scripts (⭐)
2. Crear playbook básico de Ansible para configuración de servidores (⭐⭐)
3. Implementar rolling deployment con Ansible sobre SSH (⭐⭐⭐)

**Proyecto (1.5h):**
Crear suite de automatización: script de health check que verifica estado de 5 servidores, playbook de Ansible que instala software común, y script de deployment que actualiza aplicación en múltiples nodos.

---

## SEMANA 10: Seguridad Avanzada y Auditoría

**Objetivo:** Implementar medidas avanzadas de seguridad y monitoreo de SSH.

**Teoría (1h):**
1. Two-Factor Authentication (2FA) con SSH
2. Análisis de logs y detección de intrusiones
3. Hardening avanzado: algoritmos modernos, rate limiting

**Prácticas (1.5h):**
1. Configurar autenticación con Google Authenticator (2FA) (⭐⭐)
2. Implementar fail2ban para bloqueo automático de atacantes (⭐⭐)
3. Configurar alertas automáticas de accesos SSH sospechosos (⭐⭐⭐)

**Proyecto Final Integrador (1.5h):**
Auditar y endurecer infraestructura completa del bootcamp: implementar 2FA en bastion, configurar fail2ban en todos los servidores, crear dashboard de monitoreo de conexiones SSH, y documentar política de seguridad.

---

## ESTRUCTURA DE ARCHIVOS POR SEMANA

Cada semana debe contener:

```
week-XX-tema_principal/
├── README.md                    # Índice principal
├── RUBRICA-EVALUACION.md        # 100 pts (20% teoría, 30% prácticas, 50% proyecto)
│
├── 0-assets/                    # Diagramas SVG
│   ├── README.md
│   └── *.svg (numerados 01-, 02-, etc.)
│
├── 1-teoria/                    # 3 módulos teóricos
│   ├── README.md
│   ├── 01-modulo-principal.md
│   ├── 02-modulo-secundario.md
│   └── 03-modulo-complementario.md
│
├── 2-practicas/                 # 3 prácticas
│   ├── README.md
│   ├── practica-01-basica.md
│   ├── practica-02-intermedia.md
│   └── practica-03-avanzada.md
│
├── 3-proyecto/                  # Proyecto integrador
│   ├── README.md
│   ├── GUIA-IMPLEMENTACION.md
│   └── EJEMPLOS-CONFIGS.md
│
├── 4-recursos/                  # Material complementario
│   ├── README.md
│   ├── 01-videos-conceptos.md
│   ├── 02-videos-practicos.md
│   ├── 03-articulos-ssh.md
│   ├── 04-documentacion-oficial.md
│   ├── 05-herramientas-ssh.md
│   ├── 06-playgrounds-online.md
│   ├── 07-comunidades-sysadmin.md
│   ├── 08-canales-youtube.md
│   ├── ebooks-free/
│   ├── videografia/
│   └── webgrafia/
│
└── 5-glosario/                  # Terminología
    └── README.md (30-40 términos)
```

---

## EVALUACIÓN

**Por Semana (100 pts):**
- Teoría: 20 pts (comprensión conceptual)
- Prácticas: 30 pts (10 pts cada una)
- Proyecto: 50 pts (funcionalidad 20 + calidad técnica 15 + código limpio 10 + documentación 5)

**Escala:**
- 90-100: Excelente
- 80-89: Muy Bueno
- 70-79: Bueno
- 60-69: Suficiente
- 0-59: Insuficiente

**Proyecto Final (Semana 10 - 60 pts ajustados a 50):**
- Infraestructura funcional: 20 pts
- Seguridad implementada: 15 pts
- Automatización: 10 pts
- Documentación completa: 10 pts
- Arquitectura coherente: 5 pts

---

## TECNOLOGÍAS Y HERRAMIENTAS

**Software Requerido:**
- Cliente SSH: OpenSSH (Linux/macOS), PuTTY o Windows OpenSSH (Windows)
- Servidores de práctica: VPS (DigitalOcean/Linode/AWS) o VMs locales
- Herramientas complementarias: fail2ban, Ansible, rsync, ssh-agent

**Sistemas Operativos:**
- Cliente: Linux (Ubuntu/Fedora), macOS, Windows 10+
- Servidor: Ubuntu Server 22.04 LTS (recomendado)

---

## PROGRESIÓN PEDAGÓGICA

**Fase 1 - Fundamentos (S1-S2):** Conexión y autenticación básica
**Fase 2 - Configuración Cliente (S3-S4):** Optimización y transferencias
**Fase 3 - Servidor (S5):** Seguridad del servidor
**Fase 4 - Avanzado (S6-S7):** Túneles y gestión de llaves
**Fase 5 - Arquitecturas (S8-S9):** Bastion hosts y automatización
**Fase 6 - Empresarial (S10):** Hardening y auditoría

---

## MEJORES PRÁCTICAS DE IMPLEMENTACIÓN

1. **Primera semana es crítica:** Asegura que todos logren conectarse exitosamente
2. **Servidores reales:** Usa VPS reales, no solo VMs locales (experiencia más valiosa)
3. **Documentación obligatoria:** Cada proyecto debe incluir README con comandos ejecutados
4. **Errores como aprendizaje:** Normaliza romper cosas, es parte del proceso
5. **Progresión respetada:** No saltar semanas, cada una construye sobre la anterior

---

## RECURSOS GENERALES

**Documentación oficial:**
- OpenSSH Manual: https://www.openssh.com/manual.html
- SSH Protocol RFC: https://www.rfc-editor.org/rfc/rfc4251.html

**Comunidades:**
- r/sysadmin (Reddit)
- ServerFault (Stack Exchange)

**Canales YouTube:**
- NetworkChuck
- Learn Linux TV
- TechWorld with Nana

---

## CHECKLIST DE PREPARACIÓN

Por cada semana debes crear:
- [ ] README principal con todos los enlaces
- [ ] Rúbrica de evaluación (100 pts)
- [ ] 3 módulos teóricos (20 min c/u)
- [ ] 3 prácticas progresivas (30 min c/u)
- [ ] 1 proyecto integrador (1.5h)
- [ ] 8 archivos de recursos mínimo
- [ ] Glosario de 30-40 términos
- [ ] Diagramas SVG necesarios

**Tiempo estimado de preparación por semana:** 8-10 horas

---

<div align="center">

**🔐 Plan Maestro - Bootcamp SSH**

10 Semanas | 4 Horas Semanales | 40 Horas Totales

Diseñado para desarrollo autónomo en VS Code

</div>
