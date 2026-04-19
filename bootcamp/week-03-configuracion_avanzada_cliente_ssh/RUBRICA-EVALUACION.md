# 📊 Rúbrica de Evaluación - Semana 03

## Configuración Avanzada del Cliente SSH

![Evaluación](https://img.shields.io/badge/Evaluación-100_puntos-green?style=for-the-badge)
![Semana](https://img.shields.io/badge/Semana-03-blue?style=for-the-badge)

---

## 📋 Resumen de Evaluación

| Componente | Peso     | Puntos      |
| ---------- | -------- | ----------- |
| Teoría     | 20%      | 20 pts      |
| Prácticas  | 30%      | 30 pts      |
| Proyecto   | 50%      | 50 pts      |
| **Total**  | **100%** | **100 pts** |

---

## 📚 Evaluación de Teoría (20 pts)

### Cuestionario de Conocimientos

| Criterio                  | Puntos | Descripción                                     |
| ------------------------- | ------ | ----------------------------------------------- |
| Sintaxis ssh_config       | 5 pts  | Comprensión de directivas Host, Match, opciones |
| ProxyJump vs ProxyCommand | 5 pts  | Diferencias, casos de uso, sintaxis             |
| Multiplexing              | 5 pts  | ControlMaster, ControlPath, ControlPersist      |
| Optimización              | 5 pts  | Timeouts, keep-alives, compresión               |

### Niveles de Desempeño - Teoría

| Nivel           | Puntos | Descripción                                      |
| --------------- | ------ | ------------------------------------------------ |
| 🏆 Excelente    | 18-20  | Domina todos los conceptos, explica con ejemplos |
| 🌟 Muy Bueno    | 15-17  | Comprende conceptos, pequeñas confusiones        |
| ✅ Bueno        | 12-14  | Conocimiento básico correcto                     |
| ⚠️ Suficiente   | 10-11  | Lagunas significativas                           |
| ❌ Insuficiente | 0-9    | No comprende conceptos fundamentales             |

---

## 💻 Evaluación de Prácticas (30 pts)

### Práctica 01: Aliases y Configuración Básica (10 pts)

| Criterio           | Puntos | Descripción                                         |
| ------------------ | ------ | --------------------------------------------------- |
| Archivo creado     | 2 pts  | `~/.ssh/config` existe con permisos correctos (600) |
| Sintaxis Host      | 3 pts  | Bloques Host correctamente estructurados            |
| Directivas básicas | 3 pts  | HostName, User, Port, IdentityFile funcionando      |
| Conexión exitosa   | 2 pts  | `ssh alias` conecta correctamente                   |

### Práctica 02: Conexiones con ProxyJump (10 pts)

| Criterio            | Puntos | Descripción                         |
| ------------------- | ------ | ----------------------------------- |
| Bastion configurado | 3 pts  | Host bastion definido correctamente |
| ProxyJump funcional | 4 pts  | Salto a través de bastion exitoso   |
| Encadenamiento      | 2 pts  | Múltiples saltos configurados       |
| Documentación       | 1 pts  | Comentarios explicativos en config  |

### Práctica 03: Multiplexing y Control Master (10 pts)

| Criterio       | Puntos | Descripción                               |
| -------------- | ------ | ----------------------------------------- |
| ControlMaster  | 3 pts  | Configuración auto/autoask correcta       |
| ControlPath    | 3 pts  | Socket path funcional y seguro            |
| ControlPersist | 2 pts  | Persistencia configurada apropiadamente   |
| Verificación   | 2 pts  | Demostración de reutilización de conexión |

### Niveles de Desempeño - Prácticas

| Nivel           | Puntos | Descripción                                         |
| --------------- | ------ | --------------------------------------------------- |
| 🏆 Excelente    | 27-30  | Todas las prácticas perfectas, extras implementados |
| 🌟 Muy Bueno    | 24-26  | Prácticas completas, mínimos errores                |
| ✅ Bueno        | 20-23  | Mayoría funcional, algunos problemas menores        |
| ⚠️ Suficiente   | 15-19  | Funcionalidad básica, errores significativos        |
| ❌ Insuficiente | 0-14   | Prácticas incompletas o no funcionales              |

---

## 🔨 Evaluación del Proyecto (50 pts)

### Proyecto: Configuración SSH Multi-Entorno

#### Funcionalidad Completa (20 pts)

| Criterio             | Puntos | Descripción                             |
| -------------------- | ------ | --------------------------------------- |
| Entorno desarrollo   | 5 pts  | Configuración dev completa y funcional  |
| Entorno staging      | 5 pts  | Configuración staging con ProxyJump     |
| Entorno producción   | 5 pts  | Configuración prod con máxima seguridad |
| Wildcards y patrones | 5 pts  | Uso efectivo de Host \* y Match         |

#### Seguridad (10 pts)

| Criterio              | Puntos | Descripción                         |
| --------------------- | ------ | ----------------------------------- |
| Permisos archivos     | 2 pts  | 600 para config, 700 para ~/.ssh    |
| Llaves específicas    | 3 pts  | IdentityFile por entorno/servidor   |
| IdentitiesOnly        | 2 pts  | Evita envío de llaves incorrectas   |
| StrictHostKeyChecking | 3 pts  | Configuración apropiada por entorno |

#### Documentación (10 pts)

| Criterio              | Puntos | Descripción                 |
| --------------------- | ------ | --------------------------- |
| Comentarios en config | 3 pts  | Cada bloque documentado     |
| README del proyecto   | 4 pts  | Instrucciones claras de uso |
| Troubleshooting       | 3 pts  | Guía de problemas comunes   |

#### Código Limpio (5 pts)

| Criterio        | Puntos | Descripción                          |
| --------------- | ------ | ------------------------------------ |
| Organización    | 2 pts  | Bloques ordenados lógicamente        |
| Consistencia    | 2 pts  | Estilo uniforme, indentación         |
| Sin redundancia | 1 pts  | Uso de Host \* para opciones comunes |

#### Creatividad y Extras (5 pts)

| Criterio            | Puntos | Descripción                        |
| ------------------- | ------ | ---------------------------------- |
| Multiplexing global | 1 pts  | ControlMaster para todos los hosts |
| Aliases adicionales | 1 pts  | Hosts extra útiles configurados    |
| Include files       | 2 pts  | Uso de Include para modularidad    |
| Automatización      | 1 pts  | Scripts de validación/testing      |

### Niveles de Desempeño - Proyecto

| Nivel           | Puntos | Descripción                               |
| --------------- | ------ | ----------------------------------------- |
| 🏆 Excelente    | 45-50  | Proyecto excepcional, extras innovadores  |
| 🌟 Muy Bueno    | 40-44  | Proyecto completo, bien documentado       |
| ✅ Bueno        | 35-39  | Funcional con documentación básica        |
| ⚠️ Suficiente   | 25-34  | Funcionalidad mínima, documentación pobre |
| ❌ Insuficiente | 0-24   | Proyecto incompleto o no funcional        |

---

## 📝 Entregables Requeridos

### Lista de Verificación

- [ ] Archivo `~/.ssh/config` con mínimo 5 hosts configurados
- [ ] Configuración de al menos un ProxyJump funcional
- [ ] Multiplexing habilitado para al menos un grupo de hosts
- [ ] README.md documentando la configuración
- [ ] Capturas de pantalla demostrando:
  - [ ] Conexión exitosa usando alias
  - [ ] Conexión a través de ProxyJump
  - [ ] Verificación de multiplexing activo

### Formato de Entrega

```
entrega-week-03-configuracion_avanzada_cliente_ssh/
├── ssh-config/
│   └── config                    # Tu archivo ~/.ssh/config
├── documentacion/
│   ├── README.md                 # Documentación del proyecto
│   └── troubleshooting.md        # Guía de problemas
└── evidencias/
    ├── conexion-alias.png
    ├── proxyjump-demo.png
    └── multiplexing-verificacion.png
```

---

## 🎯 Escala de Calificación Final

| Rango  | Calificación        | Descripción                                   |
| ------ | ------------------- | --------------------------------------------- |
| 90-100 | 🏆 **Excelente**    | Dominio completo de configuración SSH         |
| 80-89  | 🌟 **Muy Bueno**    | Configuración profesional con mínimas mejoras |
| 70-79  | ✅ **Bueno**        | Configuración funcional y segura              |
| 60-69  | ⚠️ **Suficiente**   | Configuración básica, necesita práctica       |
| 0-59   | ❌ **Insuficiente** | No cumple requisitos mínimos                  |

---

## 💡 Consejos para Maximizar tu Puntuación

### Teoría

- Practica explicando ProxyJump vs ProxyCommand con tus palabras
- Dibuja diagramas de flujo de conexiones con bastiones
- Lee `man ssh_config` para entender todas las opciones

### Prácticas

- Prueba cada configuración antes de avanzar
- Usa `ssh -v` para debugging
- Comenta cada línea mientras aprendes

### Proyecto

- Empieza con configuración simple y añade complejidad
- Usa `Include` para mantener organización
- Testa en entorno seguro antes de producción

---

## 🔗 Recursos de Apoyo

- [Teoría: El Archivo ~/.ssh/config](1-teoria/01-archivo-ssh-config.md)
- [Práctica 01: Aliases Básicos](2-practicas/practica-01-aliases-basicos.md)
- [Proyecto: Configuración Multi-Entorno](3-proyecto/README.md)
- [Glosario de Términos](5-glosario/README.md)

---

<div align="center">

**📊 Rúbrica de Evaluación - Semana 03**

_Configuración Avanzada del Cliente SSH_

</div>
