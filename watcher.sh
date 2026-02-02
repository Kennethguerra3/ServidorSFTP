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
        
        # Verificar permisos de ejecucion del script
        if [ -x "$SCRIPT_TO_TRIGGER" ]; then
            echo " -> Ejecutando trigger..."
            "$SCRIPT_TO_TRIGGER" --empresa="$EMPRESA" --sede="$SEDE" --file="$FULLPATH"
            EXIT_CODE=$?
            echo " -> Script finalizado con código: $EXIT_CODE"
        else
            echo "ERROR: El script trigger $SCRIPT_TO_TRIGGER no existe o no es ejecutable."
        fi
    else
        echo " -> El archivo no cumple con la estructura de directorios esperada (/home/EMP/upload/SEDE/file)."
    fi

done
