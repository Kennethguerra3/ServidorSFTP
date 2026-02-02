FROM debian:bookworm-slim

# Instalar dependencias
# openssh-server: Para el servidor SFTP
# inotify-tools: Para el watcher (inotifywait)
# procps: Para herramientas de procesos si son necesarias
# locales: Para configurar el idioma si es necesario
RUN apt-get update && apt-get install -y \
    openssh-server \
    inotify-tools \
    procps \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Configurar SSHD
RUN mkdir -p /run/sshd
# Copiar configuración custom de SSHD o modificar la existente
# Configuración básica para SFTP forzado y Chroot
RUN echo "\n\
Match Group sftp_users\n\
    ChrootDirectory /home/%u\n\
    ForceCommand internal-sftp\n\
    X11Forwarding no\n\
    AllowTcpForwarding no\n\
    PasswordAuthentication yes\n" >> /etc/ssh/sshd_config

# Crear grupo para usuarios SFTP
RUN groupadd sftp_users

# Copiar scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY watcher.sh /usr/local/bin/watcher.sh

# Dar permisos de ejecución
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/watcher.sh

# Exponer puerto SSH
EXPOSE 22

# Definir Entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
