# 📝 Ejemplos de Configuración - Proyecto Semana 02

![SSH](https://img.shields.io/badge/SSH-Ejemplos-red?style=for-the-badge&logo=openssh)
![Tipo](https://img.shields.io/badge/Tipo-Plantillas-orange?style=for-the-badge)

## 📋 Índice

1. [Plantilla ~/.ssh/config Básica](#plantilla-sshconfig-básica)
2. [Plantilla ~/.ssh/config Avanzada](#plantilla-sshconfig-avanzada)
3. [Plantilla Documentación SSH_KEYS_DOC.md](#plantilla-documentación)
4. [Script de Verificación Completo](#script-de-verificación)
5. [Comandos de Generación de Llaves](#comandos-de-generación)
6. [Configuraciones Específicas por Servicio](#configuraciones-por-servicio)

---

## Plantilla ~/.ssh/config Básica

Esta configuración cubre los requisitos mínimos del proyecto:

```bash
# ============================================
# ~/.ssh/config - Configuración Básica
# Bootcamp SSH - Semana 02
# ============================================

# === GITHUB PERSONAL ===
Host github.com-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_personal
    IdentitiesOnly yes

# === GITHUB CORPORATIVO ===
Host github.com-devopscorp
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_devopscorp
    IdentitiesOnly yes

# === PRODUCCIÓN ===
Host produccion
    HostName prod.devopscorp.local
    User deploy
    IdentityFile ~/.ssh/id_prod
    IdentitiesOnly yes

# === DESARROLLO ===
Host desarrollo
    HostName dev.devopscorp.local
    User developer
    IdentityFile ~/.ssh/id_dev
    IdentitiesOnly yes

# === GLOBAL ===
Host *
    AddKeysToAgent yes
    ServerAliveInterval 60
```

---

## Plantilla ~/.ssh/config Avanzada

Configuración completa con todas las opciones recomendadas:

```bash
# ╔════════════════════════════════════════════════════════════════╗
# ║           SSH Configuration - DevOps Corp                       ║
# ║           Autor: [Tu Nombre]                                    ║
# ║           Última actualización: [Fecha]                         ║
# ╚════════════════════════════════════════════════════════════════╝

# ┌────────────────────────────────────────────────────────────────┐
# │                     GITHUB - PERSONAL                          │
# └────────────────────────────────────────────────────────────────┘
# Uso: git clone git@github.com-personal:usuario/repo.git

Host github.com-personal gh-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_personal
    IdentitiesOnly yes
    # Evitar timeout en operaciones largas
    ServerAliveInterval 60
    ServerAliveCountMax 10

# ┌────────────────────────────────────────────────────────────────┐
# │                    GITHUB - DEVOPS CORP                        │
# └────────────────────────────────────────────────────────────────┘
# Uso: git clone git@github.com-devopscorp:devopscorp/proyecto.git

Host github.com-devopscorp gh-corp gh-trabajo
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_devopscorp
    IdentitiesOnly yes
    ServerAliveInterval 60

# ┌────────────────────────────────────────────────────────────────┐
# │                   SERVIDOR DE PRODUCCIÓN                       │
# └────────────────────────────────────────────────────────────────┘
# Uso: ssh produccion
# PRECAUCIÓN: Este es el servidor de producción real

Host produccion prod
    HostName prod.devopscorp.local
    # Alternativa con IP: HostName 10.0.1.100
    User deploy
    Port 22
    IdentityFile ~/.ssh/id_prod
    IdentitiesOnly yes
    # Seguridad reforzada para producción
    StrictHostKeyChecking ask
    LogLevel INFO
    # NO permitir forward de agente en producción
    ForwardAgent no
    # Timeout estricto
    ConnectTimeout 10
    # Compresión para transferencias
    Compression yes

# ┌────────────────────────────────────────────────────────────────┐
# │                   SERVIDOR DE DESARROLLO                       │
# └────────────────────────────────────────────────────────────────┘
# Uso: ssh desarrollo

Host desarrollo dev
    HostName dev.devopscorp.local
    # Alternativa con IP: HostName 10.0.2.100
    User developer
    Port 22
    IdentityFile ~/.ssh/id_dev
    IdentitiesOnly yes
    # Forward de agente permitido en desarrollo
    ForwardAgent yes
    # Menor estrictez para desarrollo
    StrictHostKeyChecking accept-new
    # Mantener conexiones
    ServerAliveInterval 30
    # Multiplexing para conexiones más rápidas
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600

# ┌────────────────────────────────────────────────────────────────┐
# │                      CONFIGURACIÓN GLOBAL                      │
# └────────────────────────────────────────────────────────────────┘
# Aplica a todas las conexiones que no tengan configuración específica

Host *
    # Añadir llaves al agente automáticamente
    AddKeysToAgent yes
    # Tiempo máximo de conexión inicial
    ConnectTimeout 30
    # Mantener conexiones vivas
    ServerAliveInterval 60
    ServerAliveCountMax 3
    # Compresión habilitada
    Compression yes
    # Hash de hosts conocidos para privacidad
    HashKnownHosts yes
    # Verificar llave del servidor
    StrictHostKeyChecking ask
    # Algoritmos preferidos (seguridad moderna)
    PubkeyAcceptedAlgorithms +ssh-ed25519,ssh-rsa
    # Usar solo IPv4 (descomentar si hay problemas con IPv6)
    # AddressFamily inet
```

---

## Plantilla Documentación

### SSH_KEYS_DOC.md Completo

```markdown
# 🔐 Inventario de Llaves SSH - DevOps Corp

## 📊 Resumen Ejecutivo

| Métrica              | Valor   |
| -------------------- | ------- |
| Total de Llaves      | 4 pares |
| Algoritmo            | Ed25519 |
| Todas con Passphrase | ✅ Sí   |
| Última Auditoría     | [FECHA] |

---

## 👤 Información del Propietario

| Campo                 | Valor                    |
| --------------------- | ------------------------ |
| **Nombre**            | [Tu Nombre Completo]     |
| **Email Personal**    | tu.email@gmail.com       |
| **Email Corporativo** | tu.nombre@devopscorp.com |
| **Departamento**      | Desarrollo / DevOps      |
| **Fecha Alta**        | [Fecha de creación]      |

---

## 🔑 Inventario de Llaves

### Llave 1: Personal
```

Nombre: id_personal
Algoritmo: Ed25519
Ubicación: ~/.ssh/id_personal
Propósito: Proyectos personales y GitHub personal
Hosts: github.com-personal
Fecha Creación: [YYYY-MM-DD]
Expiración: N/A (rotación anual recomendada)
Passphrase: ✅ Configurada

```

**Fingerprint:**
```

256 SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx tu.email@gmail.com (ED25519)

```

---

### Llave 2: DevOps Corp

```

Nombre: id_devopscorp
Algoritmo: Ed25519
Ubicación: ~/.ssh/id_devopscorp
Propósito: Repositorios GitHub corporativos
Hosts: github.com-devopscorp
Fecha Creación: [YYYY-MM-DD]
Expiración: N/A (rotación semestral recomendada)
Passphrase: ✅ Configurada

```

**Fingerprint:**
```

256 SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx tu.nombre@devopscorp.com (ED25519)

```

---

### Llave 3: Producción

```

Nombre: id_prod
Algoritmo: Ed25519
Ubicación: ~/.ssh/id_prod
Propósito: Acceso servidor de producción
Hosts: prod.devopscorp.local (alias: produccion, prod)
Usuario: deploy
Puerto: 22
Fecha Creación: [YYYY-MM-DD]
Expiración: N/A (rotación trimestral OBLIGATORIA)
Passphrase: ✅ Configurada

```

**Fingerprint:**
```

256 SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx deploy@devopscorp.com - Produccion (ED25519)

```

⚠️ **NOTA CRÍTICA**: Esta llave tiene acceso a producción. Manejar con extremo cuidado.

---

### Llave 4: Desarrollo

```

Nombre: id_dev
Algoritmo: Ed25519
Ubicación: ~/.ssh/id_dev
Propósito: Acceso servidor de desarrollo
Hosts: dev.devopscorp.local (alias: desarrollo, dev)
Usuario: developer
Puerto: 22
Fecha Creación: [YYYY-MM-DD]
Expiración: N/A (rotación semestral recomendada)
Passphrase: ✅ Configurada

```

**Fingerprint:**
```

256 SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx developer@devopscorp.com - Desarrollo (ED25519)

````

---

## 📅 Calendario de Rotación

| Llave | Frecuencia | Próxima Rotación | Responsable |
|-------|------------|------------------|-------------|
| id_personal | Anual | [FECHA] | Usuario |
| id_devopscorp | Semestral | [FECHA] | Usuario |
| id_prod | Trimestral | [FECHA] | Usuario + Admin |
| id_dev | Semestral | [FECHA] | Usuario |

---

## 🔄 Procedimiento de Rotación

### Pasos:

1. **Generar nueva llave**
   ```bash
   ssh-keygen -t ed25519 -C "comentario" -f ~/.ssh/id_nombre_YYYYMM
````

2. **Desplegar nueva llave**

   ```bash
   ssh-copy-id -i ~/.ssh/id_nombre_YYYYMM.pub usuario@servidor
   ```

3. **Actualizar ~/.ssh/config**

4. **Verificar acceso**

   ```bash
   ssh -i ~/.ssh/id_nombre_YYYYMM usuario@servidor
   ```

5. **Eliminar llave antigua del servidor**

6. **Eliminar archivos locales de llave antigua**

7. **Actualizar esta documentación**

---

## 🚨 Procedimiento de Compromiso

### Si sospechas que una llave fue comprometida:

1. **INMEDIATO** (< 5 minutos):
   - Eliminar llave de `authorized_keys` en todos los servidores
   - Revocar en GitHub/GitLab
2. **CORTO PLAZO** (< 1 hora):
   - Generar nueva llave
   - Desplegar nueva llave
   - Notificar a seguridad: security@devopscorp.com
3. **SEGUIMIENTO**:
   - Revisar logs de acceso
   - Documentar incidente
   - Actualizar políticas si es necesario

---

## 💾 Backup

| Destino               | Frecuencia  | Última Copia |
| --------------------- | ----------- | ------------ |
| Disco encriptado USB  | Mensual     | [FECHA]      |
| Gestor de contraseñas | Cada cambio | [FECHA]      |

### Comando de backup:

```bash
tar -czf ssh_backup_$(date +%Y%m%d).tar.gz ~/.ssh/id_* ~/.ssh/config
gpg -c ssh_backup_$(date +%Y%m%d).tar.gz
```

---

## 📞 Contactos

| Rol       | Nombre   | Email                   | Teléfono    |
| --------- | -------- | ----------------------- | ----------- |
| Admin SSH | [Nombre] | admin@devopscorp.com    | +XX XXX XXX |
| Seguridad | [Nombre] | security@devopscorp.com | +XX XXX XXX |
| Helpdesk  | -        | help@devopscorp.com     | +XX XXX XXX |

---

_Documento actualizado: [FECHA]_
_Versión: 1.0_

````

---

## Script de Verificación

### verify_ssh_keys.sh Completo

```bash
#!/bin/bash
# ============================================
# Script de Verificación de Llaves SSH
# Bootcamp SSH - Semana 02
# Versión: 1.0
# ============================================

# Configuración
SSH_DIR="$HOME/.ssh"
EXPECTED_KEYS=("id_personal" "id_devopscorp" "id_prod" "id_dev")

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Contadores
PASS=0
WARN=0
FAIL=0

# Funciones
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}   $1"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
}

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASS++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARN++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAIL++))
}

# Banner
clear
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}        🔐 Verificación Sistema SSH - DevOps Corp       ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}              Bootcamp SSH - Semana 02                  ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# 1. Verificar directorio
print_header "1. DIRECTORIO ~/.ssh"
if [ -d "$SSH_DIR" ]; then
    perm=$(stat -c %a "$SSH_DIR" 2>/dev/null || stat -f %Lp "$SSH_DIR")
    if [ "$perm" = "700" ]; then
        check_pass "Directorio existe con permisos correctos (700)"
    else
        check_warn "Directorio existe pero permisos incorrectos: $perm (esperado: 700)"
    fi
else
    check_fail "Directorio no existe"
fi
echo ""

# 2. Verificar llaves
print_header "2. LLAVES PRIVADAS"
for key in "${EXPECTED_KEYS[@]}"; do
    if [ -f "$SSH_DIR/$key" ]; then
        perm=$(stat -c %a "$SSH_DIR/$key" 2>/dev/null || stat -f %Lp "$SSH_DIR/$key")
        if [ "$perm" = "600" ]; then
            check_pass "$key - Permisos: $perm"
        else
            check_warn "$key - Permisos: $perm (esperado: 600)"
        fi
    else
        check_fail "$key - NO ENCONTRADA"
    fi
done
echo ""

print_header "3. LLAVES PÚBLICAS"
for key in "${EXPECTED_KEYS[@]}"; do
    if [ -f "$SSH_DIR/${key}.pub" ]; then
        perm=$(stat -c %a "$SSH_DIR/${key}.pub" 2>/dev/null || stat -f %Lp "$SSH_DIR/${key}.pub")
        if [ "$perm" = "644" ]; then
            check_pass "${key}.pub - Permisos: $perm"
        else
            check_warn "${key}.pub - Permisos: $perm (esperado: 644)"
        fi
    else
        check_fail "${key}.pub - NO ENCONTRADA"
    fi
done
echo ""

# 3. Verificar config
print_header "4. ARCHIVO DE CONFIGURACIÓN"
if [ -f "$SSH_DIR/config" ]; then
    perm=$(stat -c %a "$SSH_DIR/config" 2>/dev/null || stat -f %Lp "$SSH_DIR/config")
    if [ "$perm" = "600" ]; then
        check_pass "config existe con permisos correctos (600)"
    else
        check_warn "config existe pero permisos: $perm (esperado: 600)"
    fi

    # Verificar hosts configurados
    echo "  Hosts configurados:"
    grep "^Host " "$SSH_DIR/config" | sed 's/^/    /'
else
    check_fail "config - NO ENCONTRADO"
fi
echo ""

# 4. Verificar documentación
print_header "5. DOCUMENTACIÓN"
if [ -f "$SSH_DIR/SSH_KEYS_DOC.md" ]; then
    check_pass "SSH_KEYS_DOC.md existe"
else
    check_fail "SSH_KEYS_DOC.md - NO ENCONTRADO"
fi
echo ""

# 5. Fingerprints
print_header "6. FINGERPRINTS"
for key in "${EXPECTED_KEYS[@]}"; do
    if [ -f "$SSH_DIR/${key}.pub" ]; then
        echo -e "${GREEN}$key:${NC}"
        ssh-keygen -lf "$SSH_DIR/${key}.pub" 2>/dev/null | sed 's/^/  /'
    fi
done
echo ""

# 6. SSH Agent
print_header "7. SSH-AGENT"
if [ -n "$SSH_AUTH_SOCK" ]; then
    check_pass "ssh-agent está corriendo"
    count=$(ssh-add -l 2>/dev/null | wc -l)
    echo "  Llaves cargadas: $count"
    ssh-add -l 2>/dev/null | sed 's/^/    /'
else
    check_warn "ssh-agent no está corriendo"
fi
echo ""

# 7. Test GitHub
print_header "8. CONEXIÓN GITHUB"
echo "Probando github.com-personal..."
result=$(ssh -T -o ConnectTimeout=5 -o BatchMode=yes git@github.com-personal 2>&1)
if echo "$result" | grep -q "successfully authenticated"; then
    check_pass "GitHub Personal: Autenticación exitosa"
else
    check_warn "GitHub Personal: No verificado (puede requerir configuración)"
fi
echo ""

# Resumen
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}                      RESUMEN                           ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo -e "  ${GREEN}✓ Pasaron:${NC}     $PASS"
echo -e "  ${YELLOW}⚠ Advertencias:${NC} $WARN"
echo -e "  ${RED}✗ Fallaron:${NC}    $FAIL"
echo ""

# Resultado final
if [ $FAIL -eq 0 ] && [ $WARN -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡Todo perfecto! Tu configuración SSH está completa.${NC}"
elif [ $FAIL -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Configuración funcional pero con advertencias.${NC}"
else
    echo -e "${RED}❌ Hay problemas que requieren atención.${NC}"
fi
echo ""
````

---

## Comandos de Generación

### Script de generación completo

```bash
#!/bin/bash
# Generar todas las llaves del proyecto

echo "=== Generando llaves SSH para el proyecto ==="

# Personal
echo -e "\n[1/4] Llave Personal..."
ssh-keygen -t ed25519 -C "tu.email@gmail.com" -f ~/.ssh/id_personal

# DevOps Corp
echo -e "\n[2/4] Llave DevOps Corp..."
ssh-keygen -t ed25519 -C "tu.nombre@devopscorp.com" -f ~/.ssh/id_devopscorp

# Producción
echo -e "\n[3/4] Llave Producción..."
ssh-keygen -t ed25519 -C "deploy@devopscorp.com - Produccion" -f ~/.ssh/id_prod

# Desarrollo
echo -e "\n[4/4] Llave Desarrollo..."
ssh-keygen -t ed25519 -C "developer@devopscorp.com - Desarrollo" -f ~/.ssh/id_dev

# Verificar
echo -e "\n=== Llaves generadas ==="
ls -la ~/.ssh/id_personal* ~/.ssh/id_devopscorp* ~/.ssh/id_prod* ~/.ssh/id_dev*

echo -e "\n=== Fingerprints ==="
for key in personal devopscorp prod dev; do
    echo "id_$key:"
    ssh-keygen -lf ~/.ssh/id_$key.pub
done
```

---

## Configuraciones por Servicio

### GitLab

```bash
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_gitlab
    IdentitiesOnly yes
    PreferredAuthentications publickey
```

### Bitbucket

```bash
Host bitbucket.org
    HostName bitbucket.org
    User git
    IdentityFile ~/.ssh/id_bitbucket
    IdentitiesOnly yes
```

### AWS (EC2)

```bash
Host aws-prod
    HostName ec2-XX-XX-XX-XX.compute-1.amazonaws.com
    User ec2-user
    IdentityFile ~/.ssh/id_aws_prod.pem
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new

Host aws-*.compute
    User ec2-user
    IdentityFile ~/.ssh/id_aws.pem
```

### DigitalOcean

```bash
Host do-web
    HostName XXX.XXX.XXX.XXX
    User root
    IdentityFile ~/.ssh/id_digitalocean
    IdentitiesOnly yes
```

### Raspberry Pi

```bash
Host raspi
    HostName 192.168.1.XX
    User pi
    IdentityFile ~/.ssh/id_raspi
    IdentitiesOnly yes
    # Conexión lenta, aumentar timeouts
    ServerAliveInterval 30
    ConnectTimeout 60
```

### Jump/Bastion Host

```bash
# Servidor bastion
Host bastion
    HostName bastion.empresa.com
    User admin
    IdentityFile ~/.ssh/id_bastion
    IdentitiesOnly yes

# Servidor interno (acceso vía bastion)
Host interno
    HostName 10.0.0.50
    User developer
    IdentityFile ~/.ssh/id_interno
    ProxyJump bastion
```

---

## 🔗 Navegación

| ← Anterior                                    | Actual               | Siguiente →                           |
| --------------------------------------------- | -------------------- | ------------------------------------- |
| [Guía Implementación](GUIA-IMPLEMENTACION.md) | **Ejemplos Configs** | [4-Recursos](../4-recursos/README.md) |

---

<div align="center">

**Usa estas plantillas como punto de partida y personalízalas según tus necesidades.**

[🏠 Volver al inicio de Semana 02](../README.md)

</div>
