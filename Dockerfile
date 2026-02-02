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
    curl \
    gnupg2 \
    unixodbc \
    unixodbc-dev \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# --- SOPORTE SQL SERVER (Driver ODBC 18) ---
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && curl https://packages.microsoft.com/config/debian/12/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18 \
    && rm -rf /var/lib/apt/lists/*

# --- LIBRERÍAS PYTHON COMUNES ---
# Se instalan globalmente para que los scripts de usuario las encuentren fácil
RUN pip3 install --break-system-packages \
    pyodbc \
    psycopg2-binary \
    mysql-connector-python \
    pymssql \
    sqlalchemy \
    pandas \
    requests

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
COPY loader.sh /usr/local/bin/loader.sh

# Dar permisos de ejecución
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/watcher.sh /usr/local/bin/loader.sh

# Exponer puerto SSH
EXPOSE 22

# Definir Entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
