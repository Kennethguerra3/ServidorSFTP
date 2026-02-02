#!/bin/bash
# Este es un script de ejemplo (MOCK) que simula el loader.sh real.

echo "=========================================="
echo "LOADER.SH EJECUTADO: $(date)"
echo "Argumentos recibidos: $@"

# Parsear argumentos para demostración
for i in "$@"; do
  case $i in
    --empresa=*)
      EMPRESA="${i#*=}"
      ;;
    --sede=*)
      SEDE="${i#*=}"
      ;;
    --file=*)
      FILE="${i#*=}"
      ;;
  esac
done

echo "Procesando archivo para empresa: $EMPRESA"
echo "Origen (Sede): $SEDE"
echo "Ruta Archivo: $FILE"
echo "Simulando carga a SQL Server..."
sleep 1
echo "Carga completada exitosamente."
echo "=========================================="
