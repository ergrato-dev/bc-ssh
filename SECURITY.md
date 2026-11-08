# Política de Seguridad

## Versiones Soportadas

| Versión | Soportada |
| ------- | --------- |
| main    | Sí        |

## Reportar una vulnerabilidad

Si descubres una vulnerabilidad de seguridad en este material o en los scripts del repositorio, te pedimos que la reportes de manera responsable.

### NO hacer público el reporte

Por favor, **NO** abras un issue público para reportar vulnerabilidades de seguridad.

### Cómo reportar

1. **Abre un Security Advisory privado** en GitHub:
   - Ve a la pestaña "Security" del repositorio
   - Haz clic en "Report a vulnerability"
   - Completa el formulario con los detalles

2. **Incluye en tu reporte**:
   - Descripción detallada de la vulnerabilidad
   - Pasos para reproducir el problema
   - Impacto potencial
   - Sugerencias de solución (si las tienes)

### Tiempo de respuesta

- **Confirmación inicial**: 48 horas
- **Evaluación**: 7 días
- **Resolución**: Dependiendo de la severidad

---

## Qué se considera vulnerabilidad en este repositorio

Este es material educativo, no un servicio en producción. Cuentan como vulnerabilidad:

- **Un secreto real comiteado** en cualquier archivo del repositorio.
- **Un ejemplo que enseña un antipatrón sin marcarlo como tal** y que un alumno copiaría a su equipo: `StrictHostKeyChecking no` fuera del laboratorio, `ForwardAgent yes` hacia hosts no confiables, `PasswordAuthentication yes` en un servidor expuesto, una llave privada sin passphrase presentada como buena práctica.
- **Un script de `bin/` o `scripts/` con inyección de comandos**, escalada de privilegios o borrado fuera de su directorio.
- **Un plugin o una imagen Docker sin versión fijada.**

## Prácticas de seguridad que enseña este bootcamp

### El laboratorio es inseguro a propósito

Los contenedores de `compose.yaml` usan el usuario `alumno` con contraseña `alumno` y `PasswordAuthentication yes`. Es el punto de partida de la semana 01; nunca copies esa configuración a un servidor real. En la semana 07 la endureces.

### Nunca subas llaves privadas

`.gitignore` excluye `id_*`, `*.pem` y `*.key`. Si una llave privada llega a un commit, considérala comprometida: revócala y genera otra, aunque borres el commit.

### Verifica la huella antes de aceptar un host

La primera conexión a un host muestra su huella. Aceptarla sin compararla con una fuente confiable abre la puerta a un ataque man-in-the-middle (semana 02).

## Dependencias

Este bootcamp referencia:

- OpenSSH >= 9.6 (ver [`docs/stack-versions.md`](docs/stack-versions.md))
- Docker con Compose v2 para el laboratorio y el autograding
- bash, jq y shellcheck para los scripts de verificación
- Python solo en las semanas 11 y 12 y siempre con uv; PostgreSQL como base de datos de los túneles; Node.js no se usa (si hiciera falta, siempre con pnpm)

---

Gracias por ayudar a mantener este proyecto seguro.
