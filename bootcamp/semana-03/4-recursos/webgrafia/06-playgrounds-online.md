# 🎮 Playgrounds Online

## Entornos de Práctica SSH

![Playgrounds](https://img.shields.io/badge/Tipo-Práctica-green?style=for-the-badge)

---

## 🌐 Plataformas Gratuitas

### Práctica SSH General

| Plataforma                                                       | Descripción              | Acceso |
| ---------------------------------------------------------------- | ------------------------ | ------ |
| [OverTheWire - Bandit](https://overthewire.org/wargames/bandit/) | Juego de práctica SSH    | Gratis |
| [Linux Journey](https://linuxjourney.com/)                       | Curso interactivo        | Gratis |
| [Katacoda](https://www.katacoda.com/)                            | Labs de Linux en browser | Gratis |

### Entornos de Servidores

| Plataforma                                             | Descripción             | Acceso |
| ------------------------------------------------------ | ----------------------- | ------ |
| [Play With Docker](https://labs.play-with-docker.com/) | Contenedores temporales | Gratis |
| [Killercoda](https://killercoda.com/)                  | Escenarios interactivos | Gratis |
| [SadServers](https://sadservers.com/)                  | Debugging de servidores | Gratis |

---

## 💻 Entornos Locales

### Con Docker

```bash
# Servidor SSH simple
docker run -d -p 2222:22 \
  -e USER_NAME=testuser \
  -e USER_PASSWORD=testpass \
  linuxserver/openssh-server

# Conectar
ssh testuser@localhost -p 2222
```

### Con Vagrant

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.network "private_network", ip: "192.168.56.10"
end
```

---

## 🎯 Ejercicios Sugeridos

### Nivel Principiante

1. Conectar a OverTheWire Bandit nivel 0
2. Completar niveles 1-5 de Bandit

### Nivel Intermedio

1. Configurar Docker con múltiples contenedores SSH
2. Practicar ProxyJump entre contenedores

### Nivel Avanzado

1. Crear arquitectura bastion con Docker Compose
2. Implementar multiplexing en escenario multi-host

---

<div align="center">

**🎮 Playgrounds Online**

_Practica SSH sin riesgos_

</div>
