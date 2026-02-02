#!/bin/bash
set -e

# Formato esperado de SFTP_USERS: usuario1:pass1;usuario2:pass2
IFS=';' read -ra USERS <<< "$SFTP_USERS"

for USER_DATA in "${USERS[@]}"; do
    IFS=':' read -r USERNAME PASSWORD <<< "$USER_DATA"
    
    if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
        continue
    fi
    
    # Crear usuario si no existe
    if ! id "$USERNAME" &>/dev/null; then
        echo "Creando usuario: $USERNAME"
        # Shell /bin/false para seguridad, grupo sftp_users
        useradd -m -d "/home/$USERNAME" -s /bin/false -G sftp_users "$USERNAME"
    fi
    
    # Establecer contraseña
    echo "$USERNAME:$PASSWORD" | chpasswd
    
    # Configuración de permisos estricta para Chroot SSH
    # El directorio home del usuario DEBE ser propiedad de root y no escribible por el usuario
    chown root:root "/home/$USERNAME"
    chmod 755 "/home/$USERNAME"
    
    # Crear directorio allowtido para escritura (upload)
    UPLOAD_DIR="/home/$USERNAME/upload"
    mkdir -p "$UPLOAD_DIR"
    chown "$USERNAME:sftp_users" "$UPLOAD_DIR"
    chmod 755 "$UPLOAD_DIR"
    
    echo "Configurado usuario $USERNAME con directorio de carga en $UPLOAD_DIR"
done

echo "Iniciando Watcher en segundo plano..."
/usr/local/bin/watcher.sh &

echo "Iniciando servidor SSH..."
exec /usr/sbin/sshd -D -e
