#!/bin/bash
# ==============================================================================
# Comandos utilizados: configuracion server
# ==============================================================================

echo "=== Actualizando catálogos y paquetes del sistema (Update & Upgrade) ==="
sudo dnf update -y && sudo dnf upgrade -y

echo "=== Identificando y listando servicios activos ==="
echo "Generando reporte de servicios activos en ejecución..."
sudo systemctl list-units --type=service --state=running > servicios_activos_reporte.txt
echo "Reporte guardado en 'servicios_activos_reporte.txt'"

