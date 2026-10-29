
#!/bin/bash

# 1. Validar que se reciban exactamente dos argumentos
if [ "$#" -ne 2 ]; then
    echo "Uso: ./organizer.sh <archivo.zip> <directorio_destino>"
    exit 1
fi

zip_file="$1"
destino="$2"

# 2. Verificar que el archivo ZIP exista
if [ ! -f "$zip_file" ]; then
    echo "Error: el archivo ZIP no existe."
    exit 1
fi

# 3. Verificar que unzip esté instalado
if ! command -v unzip >/dev/null 2>&1; then
    echo "Error: necesitas instalar unzip."
    exit 1
fi

# 4. Crear el directorio destino y una carpeta temporal
mkdir -p "$destino" || exit 1
temporal=$(mktemp -d) || exit 1

# Eliminar la carpeta temporal al terminar
trap 'rm -rf "$temporal"' EXIT

# 5. Descomprimir el archivo
if ! unzip -q "$zip_file" -d "$temporal"; then
    echo "Error: no se pudo descomprimir el archivo ZIP."
    exit 1
fi

# 6. Organizar los archivos por categoría y extensión
total=0
py_side6=0

while IFS= read -r -d '' archivo; do
    nombre=$(basename "$archivo")

    # Identificar la extensión
    if [[ "$nombre" == *.* && "$nombre" != .* ]]; then
        extension="${nombre##*.}"
        extension=$(printf '%s' "$extension" | tr '[:upper:]' '[:lower:]')
    else
        extension="sin_extension"
    fi

    # Clasificar según el tipo de archivo
    case "$extension" in
        pdf|txt|doc|docx|odt|rtf|md|csv)
            categoria="documentos"
            ;;
        png|jpg|jpeg|gif|bmp|svg|webp|tif|tiff)
            categoria="imagenes"
            ;;
        py)
            categoria="codigo"
            ;;
        sh|js|html|css|java|c|cpp|h|hpp|php|rb|go|rs)
            categoria="codigo"
            ;;
        *)
            categoria="otros"
            ;;
    esac

    # Clasificar directamente los archivos Python
    if [ "$extension" = "py" ]; then
        echo
        echo "Archivo Python: $nombre"

        if grep -niE 'PySide6' "$archivo"; then
            echo "Resultado: contiene PySide6."
            subcarpeta="con_PySide6"
            py_side6=$((py_side6 + 1))
        else
            echo "Resultado: no contiene PySide6."
            subcarpeta="sin_PySide6"
        fi

        total=$((total + 1))
        carpeta="$destino/codigo/py/$subcarpeta"
    else
        # Organizar los archivos no Python por extensión
        carpeta="$destino/$categoria/$extension"
    fi

    # Crear las carpetas necesarias
    mkdir -p "$carpeta"

    # Evitar sobrescribir archivos con el mismo nombre
    destino_archivo="$carpeta/$nombre"

    if [ -e "$destino_archivo" ]; then
        echo "Aviso: archivo duplicado, se omite: $nombre"
    else
        cp -p "$archivo" "$destino_archivo"
    fi

done < <(find "$temporal" -type f -print0)

echo
echo "Organización de archivos completada."

# 7. Mostrar resumen final
echo
echo "===== RESUMEN FINAL ====="
echo "Archivos Python analizados: $total"
echo "Archivos que contienen PySide6: $py_side6"
echo "Archivos sin coincidencias: $((total - py_side6))"

