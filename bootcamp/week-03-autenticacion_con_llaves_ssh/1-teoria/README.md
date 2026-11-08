# 📚 Teoría - Semana 02

![Teoría](https://img.shields.io/badge/Tipo-Teoría-purple?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-1_hora-blue?style=for-the-badge)

---

## 📋 Módulos de Esta Semana

| #   | Módulo                                             | Duración | Descripción                        |
| --- | -------------------------------------------------- | -------- | ---------------------------------- |
| 01  | [Contraseña vs Llaves](01-contrasena-vs-llaves.md) | 20 min   | Por qué las llaves son superiores  |
| 02  | [Algoritmos de Llaves](02-algoritmos-llaves.md)    | 20 min   | RSA, Ed25519, ECDSA - cuál elegir  |
| 03  | [Anatomía de las Llaves](03-anatomia-llaves.md)    | 20 min   | Estructura y formato de llaves SSH |

---

## 🎯 Objetivos de Aprendizaje

Al completar estos módulos, entenderás:

- [ ] Por qué la autenticación por llaves es más segura
- [ ] Qué algoritmos existen y cuál elegir
- [ ] Cómo están estructuradas las llaves SSH
- [ ] El flujo de autenticación con llaves públicas

---

## 🗺️ Mapa Conceptual

```
AUTENTICACIÓN SSH
       │
       ├── Por Contraseña (❌ Menos seguro)
       │   └── Vulnerable a brute force
       │
       └── Por Llaves (✅ Recomendado)
           │
           ├── Algoritmos
           │   ├── Ed25519 (🏆 Mejor)
           │   ├── RSA-4096 (✅ Bueno)
           │   └── ECDSA (⚠️ Aceptable)
           │
           ├── Par de Llaves
           │   ├── Pública (compartir)
           │   └── Privada (NUNCA compartir)
           │
           └── Archivos
               ├── ~/.ssh/id_ed25519
               ├── ~/.ssh/id_ed25519.pub
               └── ~/.ssh/authorized_keys
```

---

## 📖 Orden de Estudio Recomendado

1. **Primero:** Lee el módulo de Contraseña vs Llaves para entender el "por qué"
2. **Segundo:** Estudia los algoritmos para elegir el adecuado
3. **Tercero:** Comprende la anatomía para saber qué estás manejando
4. **Finalmente:** Pasa a las prácticas con conocimiento sólido

---

<div align="center">

[← Volver a Semana 02](../README.md) • [Comenzar con Módulo 01 →](01-contrasena-vs-llaves.md)

</div>
