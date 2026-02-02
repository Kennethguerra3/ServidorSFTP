#!/bin/bash

WATCH_DIR="/home"
SCRIPT_TO_TRIGGER="/usr/local/bin/loader.sh"

echo "Iniciando monitoreo en $WATCH_DIR..."

# -m: Monitor mode (no exit)
# -r: Recursive
# -e close_write: Solo cuando el archivo termina de escribirse
# --format '%w%f': Ruta completa del archivo
inotifywait -m -r -e close_write --format '%w%f' "$WATCH_DIR" | while read -r FULLPATH; do
    
    # Ignorar si es un directorio (a veces close_write salta en directorios)
    if [ -d "$FULLPATH" ]; then
        continue
    fi

    echo "Detectado nuevo archivo: $FULLPATH"

    # Estructura esperada: /home/{empresa}/upload/{sede}/{archivo}
    # Usando regex para extraer partes
    # Regex explica:
    # ^/home/      -> Inicio fijo
    # ([^/]+)      -> Grupo 1: Empresa (cualquier cosa que no sea /)
    # /upload/     -> Literal fijo
    # ([^/]+)      -> Grupo 2: Sede (cualquier cosa que no sea /)
    # /(.+)$       -> El resto es el archivo (no necesitamos capturar esto especificamente para los args de empresa/sede, pero si para el log)
    
    if [[ "$FULLPATH" =~ ^/home/([^/]+)/upload/([^/]+)/(.*)$ ]]; then
        EMPRESA="${BASH_REMATCH[1]}"
        SEDE="${BASH_REMATCH[2]}"
        
        echo " -> Empresa detectada: $EMPRESA"
        echo " -> Sede detectada: $SEDE"

        # Lógica de Override: Buscar script personalizado del usuario
        USER_SCRIPT="/home/$EMPRESA/scripts/loader.sh"
        TARGET_SCRIPT="$SCRIPT_TO_TRIGGER" # Por defecto el global

        if [ -f "$USER_SCRIPT" ]; then
            echo " -> ¡SCRIPT PERSONALIZADO DETECTADO! Usando: $USER_SCRIPT"
            # Asegurar permisos de ejecución (ya que el usuario lo subió por SFTP y puede no tener +x)
            chmod +x "$USER_SCRIPT"
            TARGET_SCRIPT="$USER_SCRIPT"
        fi
        
        # Verificar permisos de ejecucion del script
        if [ -x "$TARGET_SCRIPT" ]; then
            echo " -> Ejecutando trigger ($TARGET_SCRIPT)..."
            "$TARGET_SCRIPT" --empresa="$EMPRESA" --sede="$SEDE" --file="$FULLPATH"
            EXIT_CODE=$?
            echo " -> Script finalizado con código: $EXIT_CODE"
        else
            echo "ERROR: El script trigger $SCRIPT_TO_TRIGGER no existe o no es ejecutable."
        fi
    else
        echo " -> El archivo no cumple con la estructura de directorios esperada (/home/EMP/upload/SEDE/file)."
    fi

done
