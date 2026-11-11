# Labs — Semana 14: Proyecto integrador

| # | Lab | Objetivo | Tiempo |
|---|-----|----------|--------|
| 1 | [lab-01-un-equipo-nuevo](lab-01-un-equipo-nuevo/) | El kit en un portátil vacío: `kit-link`, llave con frase, host keys comprobadas, y la trampa del master con contraseña | ~60 min |
| 2 | [lab-02-un-servidor-nuevo](lab-02-un-servidor-nuevo/) | Dos servidores recién instalados llevados al repositorio con el playbook, hasta `changed=0`, `cumple` y `postcuántico` | ~60 min |
| 3 | [lab-03-alta-con-certificado](lab-03-alta-con-certificado/) | Ana entra sin `authorized_keys`: CA, certificado de host, `principals/` y su certificado de 8 h | ~60 min |
| 4 | [lab-04-una-llave-perdida](lab-04-una-llave-perdida/) | Revocar a Ana, ver que su master sigue dentro y cortarlo | ~60 min |
| 5 | [lab-05-atacar-tu-servidor](lab-05-atacar-tu-servidor/) | El modelo de amenazas en la práctica: cada control falla para el atacante, y lo que el kit no para | ~60 min |
| 6 | [lab-06-reconstruir-un-servidor](lab-06-reconstruir-un-servidor/) | La prueba del extraño: `server` reinstalado, de vuelta siguiendo el RUNBOOK | ~60 min |
| 7 | [lab-07-la-defensa](lab-07-la-defensa/) | El guion de la demo y seis averías al azar con `romper.sh` | ~60 min |

**Total labs: 7 horas**

## Antes de cada lab

- Esta semana el cliente es **tu portátil**: el volumen `bc-ssh-portatil` guarda tu home entre labs. El [lab 01](lab-01-un-equipo-nuevo/README.md) lo crea vacío; los demás empiezan por el paso 0 del [lab 02](lab-02-un-servidor-nuevo/README.md): `docker compose run --rm -v bc-ssh-portatil:/home/alumno client`, el agente y `ssh-add`.
- Los labs van **en orden**: cada uno sigue donde lo dejó el anterior (el 03 necesita el playbook del 02; el 04, a Ana del 03). Para volver a empezar, el paso 0 del lab 01.
- Ten **otra terminal en tu equipo** en la raíz del repositorio: si te quedas fuera de `server` (los labs 05 y 07 lo buscan), entras por la consola con `docker compose exec server bash`.
- Los labs usan **tu kit**: el `starter` de esta semana, copiado en `~/ssh-infra-kit`. Los fallos de integración que encuentras en los labs 03, 05 y 06 son los que arreglas en el proyecto.
- Las contraseñas y las llaves sin frase de estos labs son **solo para el laboratorio**.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — La defensa](../1-teoria/03-la-defensa.md) | [Lab 01 — Un equipo nuevo](lab-01-un-equipo-nuevo/README.md) → |

[↑ Semana 14](../README.md)
