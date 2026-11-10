# Laboratorio de bc-ssh: una sola imagen para todos los roles (client, server,
# bastion, interno). Qué cambia entre roles: solo el comando de arranque en
# compose.yaml. Para qué: mismo OpenSSH para todos los estudiantes, para el
# autograding y para CI. Ubuntu 24.04 trae OpenSSH 9.6 = versión mínima del curso.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    BC_SSH_LAB=1

# postgresql-client (psql) y autossh: túneles a PostgreSQL (semana 08).
# python3: solo para rrsync (semana 06), el script de rsync que restringe una
# llave a una carpeta; lo trae el paquete rsync pero sin su intérprete.
# libpam-google-authenticator y oathtool: segundo factor TOTP (semana 11);
# oathtool calcula los códigos que daría la app del móvil.
# fail2ban y nftables: bloquear IP que fallan al entrar (semana 11).
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      openssh-client openssh-server \
      bash jq git shellcheck rsync sshpass python3 sudo \
      postgresql-client autossh \
      libpam-google-authenticator oathtool fail2ban nftables \
      iproute2 iputils-ping netcat-openbsd tcpdump ca-certificates curl less procps nano \
 && rm -rf /var/lib/apt/lists/*

# Python solo con uv (ssh-audit, Ansible). Versión fijada en docs/stack-versions.md.
COPY --from=ghcr.io/astral-sh/uv:0.12.2 /uv /uvx /usr/local/bin/

# ssh-audit (semana 11) instalado al construir: los labs y el autograding no
# salen a Internet. uv lo aísla en /opt/uv-tools con su propio entorno.
RUN UV_TOOL_DIR=/opt/uv-tools UV_TOOL_BIN_DIR=/usr/local/bin \
    uv tool install --python /usr/bin/python3 ssh-audit==3.3.0

# ubuntu:24.04 trae el usuario "ubuntu" con UID 1000: se renombra para que los
# archivos creados en el volumen pertenezcan al estudiante en el host.
# Contraseña "alumno": SOLO para el laboratorio (semana 01 entra con contraseña;
# en la semana 07 el estudiante la desactiva en sshd_config).
RUN usermod -l alumno -d /home/alumno -m ubuntu \
 && groupmod -n alumno ubuntu \
 && echo 'alumno:alumno' | chpasswd

# Qué: alumno puede usar sudo sin contraseña. SOLO para el laboratorio.
# Para qué: administrar sshd en server como en un servidor real
#   (`ssh server sudo ...`, semana 07) y que los scripts y el autograding
#   lo hagan sin preguntar.
# Impacto: en un servidor real, sudo pide contraseña (y se usa `ssh -t`);
#   nunca des NOPASSWD a una cuenta a la que se entra por SSH.
RUN echo 'alumno ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/alumno \
 && chmod 440 /etc/sudoers.d/alumno

# Las host keys se borran de la imagen y se generan al arrancar cada servidor.
# Impacto: cada contenedor tiene identidad propia, como un servidor real; si se
# recrea, cambia su host key y ssh lo detecta (semana 02, known_hosts).
RUN rm -f /etc/ssh/ssh_host_* && mkdir -p /run/sshd
COPY sshd_config.d/ /etc/ssh/sshd_config.d/
COPY start-sshd.sh /usr/local/bin/start-sshd

WORKDIR /bc-ssh
CMD ["bash", "-l"]
