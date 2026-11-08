# 📖 Guía de Implementación - Proyecto Semana 02

![SSH](https://img.shields.io/badge/SSH-Guía-red?style=for-the-badge&logo=openssh)
![Tipo](https://img.shields.io/badge/Tipo-Paso_a_Paso-green?style=for-the-badge)

## 📋 Índice

1. [Fase 1: Preparación del Entorno](#fase-1-preparación-del-entorno)
2. [Fase 2: Generación de Llaves](#fase-2-generación-de-llaves)
3. [Fase 3: Configuración SSH](#fase-3-configuración-ssh)
4. [Fase 4: Despliegue a GitHub](#fase-4-despliegue-a-github)
5. [Fase 5: Documentación](#fase-5-documentación)
6. [Fase 6: Script de Verificación](#fase-6-script-de-verificación)
7. [Verificación Final](#verificación-final)

---

## Fase 1: Preparación del Entorno

### 1.1 Verificar Prerequisitos

```bash
# Verificar OpenSSH
ssh -V

# Verificar que existe ~/.ssh
ls -la ~/.ssh || mkdir -p ~/.ssh && chmod 700 ~/.ssh

# Limpiar llaves de prueba anteriores (opcional)
# ⚠️ CUIDADO: Solo si quieres empezar de cero
# rm ~/.ssh/id_personal* ~/.ssh/id_devopscorp* ~/.ssh/id_prod* ~/.ssh/id_dev*
```

### 1.2 Crear Directorio de Trabajo

```bash
# Crear directorio para el proyecto (documentación)
mkdir -p ~/bootcamp-ssh/week-03-autenticacion_con_llaves_ssh-proyecto
cd ~/bootcamp-ssh/week-03-autenticacion_con_llaves_ssh-proyecto
```

### 1.3 Respaldar Configuración Existente

```bash
# Si ya tienes configuración SSH, respáldala
if [ -f ~/.ssh/config ]; then
    cp ~/.ssh/config ~/.ssh/config.backup.$(date +%Y%m%d)
    echo "Backup creado: ~/.ssh/config.backup.$(date +%Y%m%d)"
fi
```

---

## Fase 2: Generación de Llaves

### 2.1 Llave Personal

```bash
# Generar llave para proyectos personales
ssh-keygen -t ed25519 \
    -C "tu-email-personal@gmail.com" \
    -f ~/.ssh/id_personal

# Cuando pida passphrase, usa una segura y memorable
# Ejemplo de passphrase fuerte: "MiGato#Come2Pescados!"
```

### 2.2 Llave DevOps Corp (GitHub Empresa)

```bash
# Generar llave para GitHub corporativo
ssh-keygen -t ed25519 \
    -C "tu.nombre@devopscorp.com" \
    -f ~/.ssh/id_devopscorp
```

### 2.3 Llave Servidor Producción

```bash
# Generar llave para servidor de producción
ssh-keygen -t ed25519 \
    -C "deploy@devopscorp.com - Produccion" \
    -f ~/.ssh/id_prod
```

### 2.4 Llave Servidor Desarrollo

```bash
# Generar llave para servidor de desarrollo
ssh-keygen -t ed25519 \
    -C "developer@devopscorp.com - Desarrollo" \
    -f ~/.ssh/id_dev
```

### 2.5 Verificar Llaves Creadas

```bash
# Listar todas las llaves del proyecto
echo "=== Llaves Generadas ==="
ls -la ~/.ssh/id_personal* ~/.ssh/id_devopscorp* ~/.ssh/id_prod* ~/.ssh/id_dev* 2>/dev/null

# Verificar fingerprints
echo -e "\n=== Fingerprints ==="
for key in personal devopscorp prod dev; do
    if [ -f ~/.ssh/id_$key.pub ]; then
        echo "id_$key:"
        ssh-keygen -lf ~/.ssh/id_$key.pub
    fi
done
```

### 2.6 Configurar Permisos

```bash
# Asegurar permisos correctos
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_personal ~/.ssh/id_devopscorp ~/.ssh/id_prod ~/.ssh/id_dev
chmod 644 ~/.ssh/id_personal.pub ~/.ssh/id_devopscorp.pub ~/.ssh/id_prod.pub ~/.ssh/id_dev.pub

# Verificar
ls -la ~/.ssh/id_*
```

---

## Fase 3: Configuración SSH

### 3.1 Crear Archivo de Configuración

```bash
# Crear archivo config
cat > ~/.ssh/config << 'EOF'
# ============================================
# SSH Configuration - DevOps Corp
# Autor: [Tu Nombre]
# Fecha: [Fecha Actual]
# ============================================

# === GITHUB PERSONAL ===
# Para proyectos personales y código open source
Host github.com-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_personal
    IdentitiesOnly yes

# Alias corto para GitHub personal
Host gh-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_personal
    IdentitiesOnly yes

# === GITHUB DEVOPS CORP ===
# Para repositorios de la empresa
Host github.com-devopscorp
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_devopscorp
    IdentitiesOnly yes

# Alias corto para GitHub corporativo
Host gh-corp
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_devopscorp
    IdentitiesOnly yes

# === SERVIDOR PRODUCCIÓN ===
# Acceso al servidor de producción de DevOps Corp
Host produccion
    HostName prod.devopscorp.local
    User deploy
    Port 22
    IdentityFile ~/.ssh/id_prod
    IdentitiesOnly yes
    # Opciones de seguridad adicionales
    StrictHostKeyChecking ask
    LogLevel INFO

# Alias alternativo
Host prod
    HostName prod.devopscorp.local
    User deploy
    IdentityFile ~/.ssh/id_prod
    IdentitiesOnly yes

# === SERVIDOR DESARROLLO ===
# Acceso al servidor de desarrollo
Host desarrollo
    HostName dev.devopscorp.local
    User developer
    Port 22
    IdentityFile ~/.ssh/id_dev
    IdentitiesOnly yes
    # Permitir forward de agente solo en desarrollo
    ForwardAgent yes

# Alias alternativo
Host dev
    HostName dev.devopscorp.local
    User developer
    IdentityFile ~/.ssh/id_dev
    IdentitiesOnly yes
    ForwardAgent yes

# === CONFIGURACIÓN GLOBAL ===
# Aplica a todas las conexiones
Host *
    # Añadir llaves al agente automáticamente
    AddKeysToAgent yes
    # Mantener conexiones vivas
    ServerAliveInterval 60
    ServerAliveCountMax 3
    # Compresión para conexiones lentas
    Compression yes
    # Usar solo IPv4 (ajustar según necesidad)
    # AddressFamily inet
    # Historial de hosts conocidos
    HashKnownHosts yes

EOF

# Configurar permisos del archivo config
chmod 600 ~/.ssh/config
```

### 3.2 Verificar Configuración

```bash
# Ver configuración para cada host
echo "=== GitHub Personal ==="
ssh -G github.com-personal | grep -E "(hostname|user|identityfile)"

echo -e "\n=== GitHub Corp ==="
ssh -G github.com-devopscorp | grep -E "(hostname|user|identityfile)"

echo -e "\n=== Producción ==="
ssh -G produccion | grep -E "(hostname|user|identityfile)"

echo -e "\n=== Desarrollo ==="
ssh -G desarrollo | grep -E "(hostname|user|identityfile)"
```

---

## Fase 4: Despliegue a GitHub

### 4.1 Copiar Llave Pública Personal

```bash
# Mostrar llave pública personal para copiar
echo "=== Llave Pública Personal (copiar a GitHub) ==="
cat ~/.ssh/id_personal.pub
```

### 4.2 Añadir a GitHub (Personal)

1. Ve a [github.com/settings/keys](https://github.com/settings/keys)
2. Click **"New SSH key"**
3. **Title**: "Laptop Personal - DevOps Bootcamp"
4. **Key type**: Authentication Key
5. Pega el contenido de `id_personal.pub`
6. Click **"Add SSH key"**

### 4.3 Verificar Conexión Personal

```bash
# Probar conexión a GitHub con llave personal
ssh -T git@github.com-personal

# Respuesta esperada:
# Hi tu-usuario! You've successfully authenticated...
```

### 4.4 (Opcional) Configurar Cuenta Corporativa

Si tienes acceso a una organización en GitHub:

```bash
# Mostrar llave corporativa
cat ~/.ssh/id_devopscorp.pub

# Añadir a GitHub de la misma forma
# Probar:
ssh -T git@github.com-devopscorp
```

---

## Fase 5: Documentación

### 5.1 Crear Documento de Inventario

```bash
# Crear documentación de llaves
cat > ~/.ssh/SSH_KEYS_DOC.md << 'EOF'
# 📋 Inventario de Llaves SSH

## Información General

| Campo | Valor |
|-------|-------|
| **Propietario** | [Tu Nombre Completo] |
| **Email** | [tu.email@ejemplo.com] |
| **Fecha Creación** | [Fecha Actual] |
| **Última Actualización** | [Fecha Actual] |

---

## 🔑 Llaves Registradas

### 1. id_personal

| Campo | Valor |
|-------|-------|
| **Archivo** | `~/.ssh/id_personal` |
| **Algoritmo** | Ed25519 |
| **Propósito** | Proyectos personales, GitHub personal |
| **Servicios** | github.com-personal |
| **Fecha Creación** | [Fecha] |
| **Fingerprint** | [Ejecutar: ssh-keygen -lf ~/.ssh/id_personal.pub] |
| **Passphrase** | ✅ Configurada |

### 2. id_devopscorp

| Campo | Valor |
|-------|-------|
| **Archivo** | `~/.ssh/id_devopscorp` |
| **Algoritmo** | Ed25519 |
| **Propósito** | Repositorios corporativos DevOps Corp |
| **Servicios** | github.com-devopscorp |
| **Fecha Creación** | [Fecha] |
| **Fingerprint** | [Ejecutar: ssh-keygen -lf ~/.ssh/id_devopscorp.pub] |
| **Passphrase** | ✅ Configurada |

### 3. id_prod

| Campo | Valor |
|-------|-------|
| **Archivo** | `~/.ssh/id_prod` |
| **Algoritmo** | Ed25519 |
| **Propósito** | Servidor de producción |
| **Servicios** | prod.devopscorp.local |
| **Usuario** | deploy |
| **Fecha Creación** | [Fecha] |
| **Fingerprint** | [Ejecutar: ssh-keygen -lf ~/.ssh/id_prod.pub] |
| **Passphrase** | ✅ Configurada |

### 4. id_dev

| Campo | Valor |
|-------|-------|
| **Archivo** | `~/.ssh/id_dev` |
| **Algoritmo** | Ed25519 |
| **Propósito** | Servidor de desarrollo |
| **Servicios** | dev.devopscorp.local |
| **Usuario** | developer |
| **Fecha Creación** | [Fecha] |
| **Fingerprint** | [Ejecutar: ssh-keygen -lf ~/.ssh/id_dev.pub] |
| **Passphrase** | ✅ Configurada |

---

## 🔄 Política de Rotación

| Tipo de Llave | Frecuencia Rotación |
|---------------|---------------------|
| Personal | Anual |
| Corporativa | Semestral |
| Producción | Trimestral |
| Desarrollo | Semestral |

### Procedimiento de Rotación

1. Generar nueva llave con fecha en nombre: `id_prod_202501`
2. Desplegar nueva llave a servidores
3. Actualizar `~/.ssh/config`
4. Verificar acceso con nueva llave
5. Eliminar llave antigua de `authorized_keys`
6. Eliminar archivos de llave antigua
7. Actualizar esta documentación

---

## 🛡️ Procedimientos de Seguridad

### Si se compromete una llave:

1. **Inmediatamente**: Eliminar llave de todos los `authorized_keys`
2. Revocar en GitHub/GitLab
3. Generar nueva llave
4. Notificar al equipo de seguridad
5. Documentar incidente

### Backup de llaves:

- Ubicación: [Disco encriptado / Gestor de contraseñas]
- Frecuencia: Después de cada cambio
- Verificación: Mensual

---

## 📞 Contactos

| Rol | Contacto |
|-----|----------|
| Administrador SSH | admin@devopscorp.com |
| Seguridad | security@devopscorp.com |

---

*Documento generado como parte del Bootcamp SSH - Semana 02*

EOF

echo "Documentación creada en ~/.ssh/SSH_KEYS_DOC.md"
```

### 5.2 Actualizar Fingerprints en la Documentación

```bash
# Mostrar fingerprints para copiar a la documentación
echo "=== FINGERPRINTS - Copiar a SSH_KEYS_DOC.md ==="
for key in personal devopscorp prod dev; do
    echo "id_$key:"
    ssh-keygen -lf ~/.ssh/id_$key.pub 2>/dev/null || echo "  (no encontrada)"
done
```

---

## Fase 6: Script de Verificación

### 6.1 Crear Script

```bash
# Crear script de verificación
cat > ~/.ssh/verify_ssh_keys.sh << 'SCRIPT'
#!/bin/bash
# ============================================
# Script de Verificación de Llaves SSH
# Bootcamp SSH - Semana 02
# ============================================

set -e

echo "╔════════════════════════════════════════════╗"
echo "║   Verificación Sistema SSH - DevOps Corp   ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para verificar archivo
check_file() {
    local file=$1
    local expected_perm=$2
    local description=$3

    if [ -f "$file" ]; then
        perm=$(stat -c %a "$file" 2>/dev/null || stat -f %Lp "$file" 2>/dev/null)
        if [ "$perm" = "$expected_perm" ]; then
            echo -e "${GREEN}✓${NC} $description - Permisos: $perm"
        else
            echo -e "${YELLOW}⚠${NC} $description - Permisos: $perm (esperado: $expected_perm)"
        fi
    else
        echo -e "${RED}✗${NC} $description - NO ENCONTRADO"
    fi
}

# Función para verificar directorio
check_dir() {
    local dir=$1
    local expected_perm=$2

    if [ -d "$dir" ]; then
        perm=$(stat -c %a "$dir" 2>/dev/null || stat -f %Lp "$dir" 2>/dev/null)
        if [ "$perm" = "$expected_perm" ]; then
            echo -e "${GREEN}✓${NC} Directorio $dir - Permisos: $perm"
        else
            echo -e "${YELLOW}⚠${NC} Directorio $dir - Permisos: $perm (esperado: $expected_perm)"
        fi
    else
        echo -e "${RED}✗${NC} Directorio $dir - NO EXISTE"
    fi
}

echo "═══════════════════════════════════════════"
echo "1. VERIFICACIÓN DE ESTRUCTURA"
echo "═══════════════════════════════════════════"

check_dir "$HOME/.ssh" "700"

echo ""
echo "═══════════════════════════════════════════"
echo "2. VERIFICACIÓN DE LLAVES PRIVADAS"
echo "═══════════════════════════════════════════"

check_file "$HOME/.ssh/id_personal" "600" "Llave Personal (privada)"
check_file "$HOME/.ssh/id_devopscorp" "600" "Llave DevOpsCorp (privada)"
check_file "$HOME/.ssh/id_prod" "600" "Llave Producción (privada)"
check_file "$HOME/.ssh/id_dev" "600" "Llave Desarrollo (privada)"

echo ""
echo "═══════════════════════════════════════════"
echo "3. VERIFICACIÓN DE LLAVES PÚBLICAS"
echo "═══════════════════════════════════════════"

check_file "$HOME/.ssh/id_personal.pub" "644" "Llave Personal (pública)"
check_file "$HOME/.ssh/id_devopscorp.pub" "644" "Llave DevOpsCorp (pública)"
check_file "$HOME/.ssh/id_prod.pub" "644" "Llave Producción (pública)"
check_file "$HOME/.ssh/id_dev.pub" "644" "Llave Desarrollo (pública)"

echo ""
echo "═══════════════════════════════════════════"
echo "4. VERIFICACIÓN DE CONFIGURACIÓN"
echo "═══════════════════════════════════════════"

check_file "$HOME/.ssh/config" "600" "Archivo config"
check_file "$HOME/.ssh/SSH_KEYS_DOC.md" "" "Documentación (cualquier permiso)"

echo ""
echo "═══════════════════════════════════════════"
echo "5. FINGERPRINTS DE LLAVES"
echo "═══════════════════════════════════════════"

for key in personal devopscorp prod dev; do
    if [ -f "$HOME/.ssh/id_$key.pub" ]; then
        echo -e "${GREEN}id_$key:${NC}"
        ssh-keygen -lf "$HOME/.ssh/id_$key.pub" | sed 's/^/  /'
    fi
done

echo ""
echo "═══════════════════════════════════════════"
echo "6. VERIFICACIÓN DE SSH-AGENT"
echo "═══════════════════════════════════════════"

if [ -n "$SSH_AUTH_SOCK" ]; then
    echo -e "${GREEN}✓${NC} ssh-agent está corriendo"
    echo "  Llaves cargadas:"
    ssh-add -l 2>/dev/null | sed 's/^/    /' || echo "    (ninguna)"
else
    echo -e "${YELLOW}⚠${NC} ssh-agent no está corriendo"
    echo "  Ejecuta: eval \"\$(ssh-agent -s)\""
fi

echo ""
echo "═══════════════════════════════════════════"
echo "7. PRUEBA DE CONEXIÓN A GITHUB"
echo "═══════════════════════════════════════════"

echo "Probando conexión a GitHub (personal)..."
if ssh -T -o ConnectTimeout=5 git@github.com-personal 2>&1 | grep -q "successfully authenticated"; then
    echo -e "${GREEN}✓${NC} GitHub Personal: Conexión exitosa"
else
    echo -e "${YELLOW}⚠${NC} GitHub Personal: No se pudo verificar (puede requerir configuración)"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "RESUMEN"
echo "═══════════════════════════════════════════"
echo "Verificación completada. Revisa los items marcados con ⚠ o ✗"
echo ""

SCRIPT

# Hacer ejecutable
chmod +x ~/.ssh/verify_ssh_keys.sh

echo "Script creado: ~/.ssh/verify_ssh_keys.sh"
```

### 6.2 Ejecutar Verificación

```bash
# Ejecutar script de verificación
~/.ssh/verify_ssh_keys.sh
```

---

## Verificación Final

### Checklist Completo

```bash
echo "=== CHECKLIST FINAL DEL PROYECTO ==="

# Verificar llaves
echo -e "\n[1/6] Llaves generadas:"
for key in personal devopscorp prod dev; do
    [ -f ~/.ssh/id_$key ] && echo "  ✓ id_$key" || echo "  ✗ id_$key"
done

# Verificar permisos
echo -e "\n[2/6] Permisos:"
ls -la ~/.ssh/id_* 2>/dev/null | awk '{print "  " $1 " " $9}'

# Verificar config
echo -e "\n[3/6] Archivo config:"
[ -f ~/.ssh/config ] && echo "  ✓ Existe" || echo "  ✗ No existe"

# Verificar documentación
echo -e "\n[4/6] Documentación:"
[ -f ~/.ssh/SSH_KEYS_DOC.md ] && echo "  ✓ Existe" || echo "  ✗ No existe"

# Verificar script
echo -e "\n[5/6] Script verificación:"
[ -x ~/.ssh/verify_ssh_keys.sh ] && echo "  ✓ Existe y es ejecutable" || echo "  ✗ No existe o no es ejecutable"

# Verificar GitHub
echo -e "\n[6/6] Conexión GitHub:"
ssh -T -o ConnectTimeout=5 git@github.com-personal 2>&1 | head -1
```

---

## 🔗 Navegación

| ← Anterior                   | Actual                  | Siguiente →                             |
| ---------------------------- | ----------------------- | --------------------------------------- |
| [README Proyecto](README.md) | **Guía Implementación** | [Ejemplos Configs](EJEMPLOS-CONFIGS.md) |

---

<div align="center">

**¡Sigue esta guía paso a paso para completar el proyecto!**

[🏠 Volver al inicio de Semana 02](../README.md)

</div>
