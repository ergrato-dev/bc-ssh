# 📊 Rúbrica de Evaluación - Semana 02

![Evaluación](https://img.shields.io/badge/Evaluación-100_puntos-blue?style=for-the-badge)
![Semana](https://img.shields.io/badge/Semana-02-green?style=for-the-badge)

---

## 📋 Resumen de Evaluación

| Componente | Peso     | Puntos      |
| ---------- | -------- | ----------- |
| Teoría     | 20%      | 20 pts      |
| Prácticas  | 30%      | 30 pts      |
| Proyecto   | 50%      | 50 pts      |
| **Total**  | **100%** | **100 pts** |

---

## 📚 Teoría (20 puntos)

### Cuestionario de Conocimientos

| Criterio             | Puntos | Descripción                                      |
| -------------------- | ------ | ------------------------------------------------ |
| Contraseña vs Llaves | 7 pts  | Explicar ventajas de la autenticación por llaves |
| Algoritmos           | 7 pts  | Identificar Ed25519, RSA y sus diferencias       |
| Anatomía de Llaves   | 6 pts  | Describir estructura de llave pública/privada    |

**Preguntas de evaluación:**

1. ¿Por qué la autenticación por llaves es más segura que por contraseña? (3 pts)
2. ¿Cuál es el algoritmo recomendado para nuevas llaves y por qué? (3 pts)
3. ¿Qué archivo contiene las llaves públicas autorizadas en el servidor? (2 pts)
4. ¿Qué permisos debe tener la llave privada? (2 pts)
5. ¿Qué es una passphrase y por qué usarla? (3 pts)
6. ¿Qué información contiene una llave pública? (3 pts)
7. ¿Dónde se almacena la llave privada y la pública? (4 pts)

---

## 💻 Prácticas (30 puntos)

### Práctica 01: Generación de Llaves (10 pts)

| Criterio               | Puntos | Indicador de Logro                 |
| ---------------------- | ------ | ---------------------------------- |
| Generar llave Ed25519  | 4 pts  | Archivo `~/.ssh/id_ed25519` existe |
| Passphrase configurada | 3 pts  | Llave protegida con contraseña     |
| Permisos correctos     | 2 pts  | `chmod 600` en llave privada       |
| Comentario descriptivo | 1 pt   | `-C "email@ejemplo.com"` usado     |

### Práctica 02: Despliegue con ssh-copy-id (10 pts)

| Criterio                  | Puntos | Indicador de Logro           |
| ------------------------- | ------ | ---------------------------- |
| Usar ssh-copy-id          | 4 pts  | Llave copiada exitosamente   |
| Verificar authorized_keys | 3 pts  | Llave aparece en servidor    |
| Conexión sin contraseña   | 3 pts  | Login exitoso solo con llave |

### Práctica 03: Múltiples Llaves (10 pts)

| Criterio                 | Puntos | Indicador de Logro         |
| ------------------------ | ------ | -------------------------- |
| Crear llave para GitHub  | 3 pts  | `~/.ssh/github_ed25519`    |
| Crear llave para VPS     | 3 pts  | `~/.ssh/vps_ed25519`       |
| Configurar ~/.ssh/config | 3 pts  | Host aliases funcionando   |
| Probar conexiones        | 1 pt   | Ambos servicios accesibles |

---

## 🔨 Proyecto Integrador (50 puntos)

### Proyecto: Configuración SSH Profesional

**Objetivo:** Configurar autenticación por llaves para GitHub y un VPS personal.

| Criterio                  | Puntos | Descripción                               |
| ------------------------- | ------ | ----------------------------------------- |
| **Funcionalidad**         | 20 pts |                                           |
| ├─ Llave GitHub funcional | 6 pts  | Push/pull sin contraseña                  |
| ├─ Llave VPS funcional    | 6 pts  | SSH sin contraseña                        |
| ├─ ~/.ssh/config correcto | 5 pts  | Aliases y opciones configuradas           |
| └─ Permisos seguros       | 3 pts  | Todos los archivos con permisos correctos |
| **Seguridad**             | 15 pts |                                           |
| ├─ Passphrases en llaves  | 5 pts  | Ambas llaves protegidas                   |
| ├─ Algoritmo Ed25519      | 5 pts  | Usar algoritmo moderno                    |
| └─ Backup de llaves       | 5 pts  | Procedimiento documentado                 |
| **Documentación**         | 10 pts |                                           |
| ├─ README personal        | 5 pts  | Explicar configuración propia             |
| └─ Comandos documentados  | 5 pts  | Historial de comandos usados              |
| **Extras**                | 5 pts  |                                           |
| ├─ Llave adicional        | 2 pts  | Para otro servicio (GitLab, AWS)          |
| └─ ssh-agent configurado  | 3 pts  | Agent funcionando con llaves              |

---

## 📈 Escala de Calificación

| Rango  | Calificación    | Descripción                            |
| ------ | --------------- | -------------------------------------- |
| 90-100 | 🏆 Excelente    | Dominio completo del tema              |
| 80-89  | 🌟 Muy Bueno    | Buen entendimiento, detalles menores   |
| 70-79  | ✅ Bueno        | Conceptos claros, práctica necesaria   |
| 60-69  | ⚠️ Suficiente   | Comprensión básica, refuerzo requerido |
| 0-59   | ❌ Insuficiente | Requiere repetir la semana             |

---

## ✅ Lista de Verificación Final

Antes de entregar, verifica:

### Archivos Requeridos

```bash
# En tu máquina local
~/.ssh/
├── config                    # Con aliases para GitHub y VPS
├── id_ed25519               # Llave privada principal (opcional)
├── id_ed25519.pub           # Llave pública principal (opcional)
├── github_ed25519           # Llave privada para GitHub
├── github_ed25519.pub       # Llave pública para GitHub
├── vps_ed25519              # Llave privada para VPS
├── vps_ed25519.pub          # Llave pública para VPS
└── known_hosts              # Actualizado con nuevos hosts
```

### Comandos de Verificación

```bash
# Verificar permisos
ls -la ~/.ssh/

# Verificar conexión GitHub
ssh -T git@github.com

# Verificar conexión VPS
ssh mi-vps

# Ver llaves cargadas
ssh-add -l
```

### Documentación

- [ ] README personal con configuración explicada
- [ ] Capturas de pantalla de conexiones exitosas
- [ ] Comandos utilizados documentados

---

## 📝 Formato de Entrega

```
entrega-week-03-autenticacion_con_llaves_ssh/
├── README.md                    # Documentación personal
├── screenshots/
│   ├── github-connection.png    # Prueba de conexión GitHub
│   └── vps-connection.png       # Prueba de conexión VPS
├── config-files/
│   └── ssh-config              # Copia de tu ~/.ssh/config
└── comandos-usados.md          # Historial de comandos
```

---

<div align="center">

**Semana 02 • Rúbrica de Evaluación**

[← Volver al índice](README.md)

</div>
