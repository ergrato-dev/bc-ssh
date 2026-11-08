# Laboratorio de bc-ssh: una sola imagen para todos los roles (client, server,
# bastion, interno). Qué cambia entre roles: solo el comando de arranque en
# compose.yaml. Para qué: mismo OpenSSH para todos los estudiantes, para el
# autograding y para CI. Ubuntu 24.04 trae OpenSSH 9.6 = versión mínima del curso.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    BC_SSH_LAB=1

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      openssh-client openssh-server \
      bash jq git shellcheck rsync sshpass \
      iproute2 iputils-ping netcat-openbsd tcpdump ca-certificates curl less procps nano \
 && rm -rf /var/lib/apt/lists/*

# Python solo con uv (ssh-audit, Ansible). Versión fijada en docs/stack-versions.md.
COPY --from=ghcr.io/astral-sh/uv:0.12.2 /uv /uvx /usr/local/bin/

# ubuntu:24.04 trae el usuario "ubuntu" con UID 1000: se renombra para que los
# archivos creados en el volumen pertenezcan al estudiante en el host.
# Contraseña "alumno": SOLO para el laboratorio (semana 01 entra con contraseña;
# en la semana 07 el estudiante la desactiva en sshd_config).
RUN usermod -l alumno -d /home/alumno -m ubuntu \
 && groupmod -n alumno ubuntu \
 && echo 'alumno:alumno' | chpasswd

# Las host keys se borran de la imagen y se generan al arrancar cada servidor.
# Impacto: cada contenedor tiene identidad propia, como un servidor real; si se
# recrea, cambia su host key y ssh lo detecta (semana 02, known_hosts).
RUN rm -f /etc/ssh/ssh_host_* && mkdir -p /run/sshd
COPY sshd_config.d/ /etc/ssh/sshd_config.d/
COPY start-sshd.sh /usr/local/bin/start-sshd

WORKDIR /bc-ssh
CMD ["bash", "-l"]
