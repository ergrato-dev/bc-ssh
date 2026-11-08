# 💻 Prácticas - Semana 03

## Configuración Avanzada del Cliente SSH

![Prácticas](https://img.shields.io/badge/Prácticas-3_ejercicios-orange?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-1.5_horas-blue?style=for-the-badge)

---

## 🎯 Objetivo

Aplicar los conocimientos teóricos de configuración SSH en ejercicios prácticos progresivos, desde aliases básicos hasta multiplexing avanzado.

---

## 📋 Prácticas de la Semana

| #   | Práctica                                                         | Dificultad | Duración | Descripción                   |
| --- | ---------------------------------------------------------------- | ---------- | -------- | ----------------------------- |
| 01  | [Aliases y Configuración Básica](practica-01-aliases-basicos.md) | ⭐         | 30 min   | Crear ~/.ssh/config con hosts |
| 02  | [Conexiones con ProxyJump](practica-02-proxyjump.md)             | ⭐⭐       | 30 min   | Saltar a través de bastiones  |
| 03  | [Multiplexing y Control Master](practica-03-multiplexing.md)     | ⭐⭐⭐     | 30 min   | Reutilizar conexiones SSH     |

---

## 🔧 Prerequisitos

Antes de comenzar las prácticas, asegúrate de tener:

- [ ] OpenSSH cliente instalado
- [ ] Al menos un par de llaves SSH generadas
- [ ] Acceso a servidores remotos (VPS, VM, o contenedores)
- [ ] Conocimientos de la teoría de esta semana

### Verificar Versión de OpenSSH

```bash
# Necesitas OpenSSH 7.3+ para ProxyJump
ssh -V
# OpenSSH_8.9p1, OpenSSL 3.0.2 15 Mar 2022
```

---

## 🏗️ Entorno de Prácticas

### Opción 1: VMs Locales con VirtualBox/VMware

```bash
# Crear 3 VMs Ubuntu Server
# - bastion: 192.168.56.10 (red pública + privada)
# - web:     192.168.56.20 (solo red privada)
# - db:      192.168.56.30 (solo red privada)
```

### Opción 2: Contenedores Docker

```bash
# docker-compose.yml para prácticas
version: '3'
services:
  bastion:
    image: linuxserver/openssh-server
    ports:
      - "2222:2222"
    environment:
      - USER_NAME=admin
      - PUBLIC_KEY_FILE=/keys/id_ed25519.pub
    networks:
      - public
      - private

  web:
    image: linuxserver/openssh-server
    environment:
      - USER_NAME=deploy
    networks:
      - private

  db:
    image: linuxserver/openssh-server
    environment:
      - USER_NAME=dba
    networks:
      - private

networks:
  public:
  private:
    internal: true
```

### Opción 3: VPS en la Nube

Usa cualquier proveedor (DigitalOcean, Linode, AWS) con:

- 1 servidor con IP pública (bastion)
- 2 servidores en red privada

---

## 📊 Progresión de Dificultad

```
Práctica 01 ⭐
│  • Crear ~/.ssh/config
│  • Definir hosts con alias
│  • Configurar IdentityFile
│
└──▶ Práctica 02 ⭐⭐
     │  • Configurar bastion
     │  • Implementar ProxyJump
     │  • Encadenar saltos
     │
     └──▶ Práctica 03 ⭐⭐⭐
          │  • Activar ControlMaster
          │  • Configurar sockets
          │  • Gestionar conexiones
          │
          └──▶ Proyecto Semanal 🎯
```

---

## ✅ Criterios de Éxito

### Práctica 01 - Aliases

- [ ] Archivo `~/.ssh/config` creado con permisos 600
- [ ] Al menos 3 hosts configurados
- [ ] Conexión exitosa con `ssh alias`

### Práctica 02 - ProxyJump

- [ ] Bastion configurado correctamente
- [ ] Conexión a servidor interno vía ProxyJump
- [ ] Al menos un salto encadenado

### Práctica 03 - Multiplexing

- [ ] ControlMaster activado
- [ ] Socket de control funcional
- [ ] Demostración de reutilización de conexión

---

## 🛠️ Comandos Útiles

```bash
# Ver configuración aplicada a un host
ssh -G nombre-host

# Debug de conexión
ssh -v nombre-host

# Verificar socket de control
ssh -O check nombre-host

# Cerrar conexión master
ssh -O exit nombre-host
```

---

## 🧭 Navegación

| Práctica                                               | Siguiente |
| ------------------------------------------------------ | --------- |
| [01 - Aliases Básicos](practica-01-aliases-basicos.md) | ➡️        |

---

<div align="center">

**💻 Prácticas - Semana 03**

_Configuración SSH en acción_

</div>
