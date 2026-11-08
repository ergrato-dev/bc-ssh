# 🚀 Práctica 02: Conexiones con ProxyJump

## Saltar a Través de Bastiones

![Dificultad](https://img.shields.io/badge/Dificultad-⭐⭐_Intermedia-yellow?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-30_min-blue?style=for-the-badge)

---

## 🎯 Objetivo

Configurar conexiones SSH que atraviesan un servidor bastion para acceder a servidores en redes privadas, usando ProxyJump.

---

## 📋 Prerequisitos

- [ ] Práctica 01 completada (archivo `~/.ssh/config` funcional)
- [ ] OpenSSH 7.3 o superior (`ssh -V`)
- [ ] Acceso a un servidor bastion (IP pública)
- [ ] Acceso a servidores internos (IP privada)

---

## 🏗️ Arquitectura del Escenario

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│  Tu Equipo   │         │   BASTION    │         │  SERVIDOR    │
│              │ ──SSH──▶│              │ ──SSH──▶│   INTERNO    │
│ 192.168.0.10 │         │ 203.0.113.10 │         │  10.0.1.50   │
│              │         │  (público)   │         │  (privado)   │
└──────────────┘         └──────────────┘         └──────────────┘
        │                       │                        │
        │        INTERNET       │      RED PRIVADA       │
        └───────────────────────┴────────────────────────┘
```

**Reto**: El servidor interno (`10.0.1.50`) no tiene IP pública. Solo es accesible desde el bastion.

---

## 🔨 Parte 1: Configurar el Bastion

### Paso 1.1: Copiar Llave al Bastion

```bash
# Si aún no has copiado tu llave al bastion
ssh-copy-id -i ~/.ssh/id_ed25519.pub admin@203.0.113.10

# O manualmente
cat ~/.ssh/id_ed25519.pub | ssh admin@203.0.113.10 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### Paso 1.2: Configurar el Bastion en ~/.ssh/config

```ssh-config
# ~/.ssh/config

# ============================================
# BASTION (Jump Server)
# ============================================
Host bastion
    HostName 203.0.113.10
    User admin
    IdentityFile ~/.ssh/id_ed25519

    # Opciones recomendadas para bastiones
    ServerAliveInterval 30
    ServerAliveCountMax 3

    # NO habilitar ForwardAgent por seguridad
    ForwardAgent no
```

### Paso 1.3: Verificar Conexión al Bastion

```bash
# Probar conexión directa al bastion
ssh bastion

# Verificar que estás en el bastion
hostname
# bastion.empresa.com

# Salir
exit
```

---

## 🔨 Parte 2: Conexión con ProxyJump (Línea de Comandos)

### Paso 2.1: Sintaxis Básica de ProxyJump

```bash
# Formato
ssh -J usuario@bastion usuario@servidor-interno

# Ejemplo real
ssh -J admin@203.0.113.10 deploy@10.0.1.50
```

### Paso 2.2: Usando el Alias del Bastion

```bash
# Si tienes el bastion configurado como alias
ssh -J bastion deploy@10.0.1.50
```

### Paso 2.3: Con Puerto No Estándar

```bash
# Bastion en puerto 2222
ssh -J admin@203.0.113.10:2222 deploy@10.0.1.50

# Servidor interno en puerto 2222
ssh -J admin@203.0.113.10 deploy@10.0.1.50 -p 2222
```

---

## 🔨 Parte 3: Configurar ProxyJump en ~/.ssh/config

### Paso 3.1: Configuración Básica

```ssh-config
# ~/.ssh/config

# Bastion (ya configurado)
Host bastion
    HostName 203.0.113.10
    User admin
    IdentityFile ~/.ssh/id_ed25519

# Servidor interno - requiere salto por bastion
Host web-interno
    HostName 10.0.1.50
    User deploy
    IdentityFile ~/.ssh/id_ed25519
    ProxyJump bastion
```

### Paso 3.2: Probar la Conexión

```bash
# Conectar directamente (SSH salta automáticamente)
ssh web-interno

# Ver el proceso con verbose
ssh -v web-interno 2>&1 | grep -E "(Connecting|ProxyJump|channel)"
```

**Salida esperada:**

```
debug1: Setting up ProxyJump to bastion
debug1: Connecting to bastion [203.0.113.10] port 22.
debug1: Connection established.
...
debug1: channel 0: new [stdio forward to 10.0.1.50:22]
debug1: Connected to 10.0.1.50 [10.0.1.50] port 22.
```

---

## 🔨 Parte 4: Múltiples Servidores Internos

### Paso 4.1: Configurar Varios Hosts

```ssh-config
# ~/.ssh/config

# ============================================
# BASTION
# ============================================
Host bastion
    HostName 203.0.113.10
    User admin
    IdentityFile ~/.ssh/id_ed25519

# ============================================
# SERVIDORES INTERNOS (vía bastion)
# ============================================
Host web-interno
    HostName 10.0.1.50
    User deploy
    ProxyJump bastion

Host db-interno
    HostName 10.0.1.60
    User dba
    ProxyJump bastion

Host app-interno
    HostName 10.0.1.70
    User app
    ProxyJump bastion
```

### Paso 4.2: Usar Patrón para Simplificar

```ssh-config
# Todos los hosts que terminan en "-interno" usan el bastion
Host *-interno
    ProxyJump bastion
    User deploy
    IdentityFile ~/.ssh/id_interno

# Ahora solo defines HostName para cada uno
Host web-interno
    HostName 10.0.1.50

Host db-interno
    HostName 10.0.1.60
    User dba  # Sobrescribe el default

Host app-interno
    HostName 10.0.1.70
```

---

## 🔨 Parte 5: Encadenamiento de Saltos

### Paso 5.1: Escenario con Múltiples Bastiones

```
Tu PC → Bastion DMZ → Bastion Interno → Servidor Secreto
```

### Paso 5.2: Configuración en ~/.ssh/config

```ssh-config
# Primer bastion (DMZ)
Host bastion-dmz
    HostName 203.0.113.10
    User security
    IdentityFile ~/.ssh/id_dmz

# Segundo bastion (Red interna)
Host bastion-interno
    HostName 10.0.0.1
    User admin
    IdentityFile ~/.ssh/id_interno
    ProxyJump bastion-dmz

# Servidor final (Red ultra-segura)
Host servidor-secreto
    HostName 192.168.100.50
    User root
    IdentityFile ~/.ssh/id_secreto
    ProxyJump bastion-interno
```

### Paso 5.3: Probar el Encadenamiento

```bash
# Conexión atraviesa: PC → DMZ → Interno → Secreto
ssh servidor-secreto

# Ver los saltos
ssh -v servidor-secreto 2>&1 | grep "Connecting to"
```

### Paso 5.4: Alternativa en Línea de Comandos

```bash
# Múltiples saltos separados por coma
ssh -J bastion-dmz,bastion-interno root@192.168.100.50
```

---

## 🔨 Parte 6: Llaves Diferentes por Servidor

### Paso 6.1: Escenario Real

- Llave A: Para el bastion
- Llave B: Para servidores internos

```ssh-config
Host bastion
    HostName 203.0.113.10
    User admin
    IdentityFile ~/.ssh/id_bastion  # Llave específica

Host interno
    HostName 10.0.1.50
    User deploy
    ProxyJump bastion
    IdentityFile ~/.ssh/id_interno  # Llave diferente
```

### Paso 6.2: Verificar Llaves Usadas

```bash
# Ver qué llave usa cada conexión
ssh -G bastion | grep identityfile
# identityfile ~/.ssh/id_bastion

ssh -G interno | grep identityfile
# identityfile ~/.ssh/id_interno
```

---

## ✅ Verificación Final

### Checklist de Completación

- [ ] Bastion configurado y accesible
- [ ] ProxyJump funciona desde línea de comandos (`-J`)
- [ ] ProxyJump configurado en `~/.ssh/config`
- [ ] Al menos 2 servidores internos configurados
- [ ] Conexión `ssh servidor-interno` exitosa
- [ ] (Opcional) Encadenamiento de saltos funcional

### Pruebas de Verificación

```bash
# 1. Conexión directa al bastion
ssh bastion hostname
# bastion.empresa.com

# 2. Conexión a servidor interno
ssh web-interno hostname
# web-interno.local

# 3. Verificar que ProxyJump aplica
ssh -G web-interno | grep proxyjump
# proxyjump bastion

# 4. Ver flujo completo (verbose)
ssh -v web-interno 2>&1 | grep -E "(ProxyJump|Connecting|channel)"
```

---

## 🐛 Troubleshooting

### Error: "ProxyJump not supported"

```bash
# Verificar versión de OpenSSH
ssh -V
# Necesitas OpenSSH 7.3+

# Alternativa con ProxyCommand
Host interno
    ProxyCommand ssh -W %h:%p bastion
```

### Error: "Permission denied" en el Salto

```bash
# Verificar llave para cada servidor
ssh -i ~/.ssh/id_bastion bastion    # Debe funcionar
ssh bastion                          # Luego probar sin -i

# Desde el bastion, probar conexión interna
ssh bastion
ssh deploy@10.0.1.50  # Desde dentro del bastion
```

### Error: "Connection timed out"

```bash
# Verificar conectividad desde bastion
ssh bastion "ping -c 2 10.0.1.50"

# Verificar que SSH escucha en el puerto correcto
ssh bastion "nc -zv 10.0.1.50 22"
```

### El Host No Usa ProxyJump

```bash
# Verificar orden en config (específico antes de genérico)
ssh -G interno | grep proxyjump

# Si está vacío, revisa el orden de los bloques Host
```

---

## 🎯 Ejercicio Extra (Opcional)

### Configurar Acceso Dinámico por Red

```ssh-config
# Usar bastion solo cuando NO estás en la red interna
Match host *.interno exec "! ip route | grep -q 10.0.0.0/8"
    ProxyJump bastion

# En la oficina (red 10.x.x.x), conexión directa
# Fuera de la oficina, usa bastion
```

---

## 🧭 Navegación

| ⬅️ Anterior                                   |       🏠 Índice        |                                              Siguiente ➡️ |
| :-------------------------------------------- | :--------------------: | --------------------------------------------------------: |
| [Práctica 01](practica-01-aliases-basicos.md) | [Prácticas](README.md) | [Práctica 03 - Multiplexing](practica-03-multiplexing.md) |

---

<div align="center">

**🚀 Práctica 02: Conexiones con ProxyJump**

_Atraviesa bastiones como un profesional_

</div>
