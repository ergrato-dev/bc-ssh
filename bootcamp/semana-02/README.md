# 🔑 Semana 02: Autenticación con Llaves SSH

![SSH](https://img.shields.io/badge/SSH-Llaves_Públicas-blue?style=for-the-badge&logo=openssh)
![Nivel](https://img.shields.io/badge/Nivel-Principiante--Intermedio-yellow?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-4_horas-green?style=for-the-badge)

---

## 📋 Descripción

Esta semana dominarás el sistema de **autenticación con llaves públicas/privadas**, el método más seguro y práctico para conectarte a servidores SSH. Aprenderás a generar, gestionar y desplegar llaves SSH, eliminando la necesidad de escribir contraseñas.

La autenticación por llaves es **el estándar de la industria** y un requisito fundamental para trabajar con servicios como GitHub, GitLab, AWS, DigitalOcean y cualquier infraestructura profesional.

---

## 🎯 Objetivos de Aprendizaje

Al finalizar esta semana, serás capaz de:

- [ ] Explicar la diferencia entre autenticación por contraseña y por llaves
- [ ] Generar pares de llaves SSH con diferentes algoritmos (Ed25519, RSA)
- [ ] Comprender la anatomía de una llave pública y privada
- [ ] Usar `ssh-copy-id` para desplegar llaves en servidores
- [ ] Configurar `authorized_keys` manualmente
- [ ] Proteger llaves privadas con passphrase
- [ ] Gestionar múltiples llaves para diferentes servicios

---

## 📚 Contenido

### 📖 Teoría (1 hora)

| #   | Módulo                                                      | Duración | Descripción                        |
| --- | ----------------------------------------------------------- | -------- | ---------------------------------- |
| 01  | [Contraseña vs Llaves](1-teoria/01-contrasena-vs-llaves.md) | 20 min   | Por qué las llaves son superiores  |
| 02  | [Algoritmos de Llaves](1-teoria/02-algoritmos-llaves.md)    | 20 min   | RSA, Ed25519, ECDSA - cuál elegir  |
| 03  | [Anatomía de las Llaves](1-teoria/03-anatomia-llaves.md)    | 20 min   | Estructura y formato de llaves SSH |

### 💻 Prácticas (1.5 horas)

| #   | Práctica                                                             | Dificultad | Duración | Descripción                                |
| --- | -------------------------------------------------------------------- | ---------- | -------- | ------------------------------------------ |
| 01  | [Generación de Llaves](2-practicas/practica-01-generacion-llaves.md) | ⭐         | 30 min   | Crear tu primer par de llaves              |
| 02  | [Despliegue con ssh-copy-id](2-practicas/practica-02-ssh-copy-id.md) | ⭐⭐       | 30 min   | Copiar llaves a servidores                 |
| 03  | [Múltiples Llaves](2-practicas/practica-03-multiples-llaves.md)      | ⭐⭐⭐     | 30 min   | Gestionar llaves para diferentes servicios |

### 🔨 Proyecto (1.5 horas)

| Documento                                                   | Descripción                         |
| ----------------------------------------------------------- | ----------------------------------- |
| [README del Proyecto](3-proyecto/README.md)                 | Configuración SSH para GitHub + VPS |
| [Guía de Implementación](3-proyecto/GUIA-IMPLEMENTACION.md) | Pasos detallados                    |
| [Ejemplos de Configuración](3-proyecto/EJEMPLOS-CONFIGS.md) | Archivos de referencia              |

---

## 📊 Distribución del Tiempo

```
┌─────────────────────────────────────────────────────────────┐
│                    SEMANA 02 (4 horas)                      │
├─────────────────────────────────────────────────────────────┤
│  Teoría    │████████████░░░░░░░░░░░░░░░░░░░░│ 1.0h  (25%)  │
│  Prácticas │██████████████████░░░░░░░░░░░░░░│ 1.5h  (37.5%)│
│  Proyecto  │██████████████████░░░░░░░░░░░░░░│ 1.5h  (37.5%)│
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Requisitos Previos

### Conocimientos

- ✅ Completar [Semana 01](../semana-01/README.md)
- ✅ Entender arquitectura cliente-servidor SSH
- ✅ Conceptos básicos de criptografía (simétrica/asimétrica)

### Software

- Cliente SSH instalado (OpenSSH)
- Acceso a un servidor para pruebas (VPS, VM o contenedor)
- Cuenta en GitHub (para el proyecto)

### Archivos de la Semana Anterior

```bash
# Deberías tener estos archivos de la semana 01:
~/.ssh/config          # Configuración básica del cliente
~/.ssh/known_hosts     # Servidores conocidos
```

---

## 📁 Estructura de la Semana

```
semana-02/
├── README.md                      # Este archivo
├── RUBRICA-EVALUACION.md          # Criterios de evaluación
├── 0-assets/                      # Diagramas SVG
│   ├── 01-flujo-autenticacion-llaves.svg
│   ├── 02-generacion-llaves.svg
│   └── 03-authorized-keys.svg
├── 1-teoria/                      # Módulos teóricos
│   ├── README.md
│   ├── 01-contrasena-vs-llaves.md
│   ├── 02-algoritmos-llaves.md
│   └── 03-anatomia-llaves.md
├── 2-practicas/                   # Ejercicios prácticos
│   ├── README.md
│   ├── practica-01-generacion-llaves.md
│   ├── practica-02-ssh-copy-id.md
│   └── practica-03-multiples-llaves.md
├── 3-proyecto/                    # Proyecto integrador
│   ├── README.md
│   ├── GUIA-IMPLEMENTACION.md
│   └── EJEMPLOS-CONFIGS.md
├── 4-recursos/                    # Material complementario
│   ├── README.md
│   ├── videos/
│   ├── herramientas/
│   └── webgrafia/
└── 5-glosario/                    # Términos de la semana
    └── README.md
```

---

## 🔗 Navegación

| ⬅️ Anterior                                      | 🏠 Inicio                | Siguiente ➡️                                         |
| ------------------------------------------------ | ------------------------ | ---------------------------------------------------- |
| [Semana 01: Fundamentos](../semana-01/README.md) | [Bootcamp](../README.md) | [Semana 03: Config Avanzada](../semana-03/README.md) |

---

<div align="center">

**🔑 Semana 02: Autenticación con Llaves SSH**

_Deja de escribir contraseñas. Usa llaves._

</div>
