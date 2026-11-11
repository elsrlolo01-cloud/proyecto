
from db import (
    guardar_registro,
    buscar_registro,
    listar_registros,
    conectar
)

COLECCION = "__prueba__"

registro = {
    "folio": "PRUEBA-2026-0001",
    "fecha": "2026-11-10",
    "por": "Prueba de conexión",
    "d": {
        "nombre": "Paciente de prueba",
        "especie": "Equino"
    },
    "files": [
        {
            "nombre": "archivo_prueba.txt",
            "bytes": b"Prueba de archivo"
        }
    ],
    "hist": [],
    "versiones": [],
    "val": "Pendiente"
}

try:
    # 1. Guardar
    guardar_registro(COLECCION, registro)
    print("1. GUARDADO: correcto")

    # 2. Buscar
    encontrado = buscar_registro(
        COLECCION,
        registro["folio"]
    )
    print("2. BUSQUEDA:", "correcta" if encontrado else "fallida")

    # 3. Comprobar archivo binario
    archivo = encontrado["files"][0]["bytes"]
    print(
        "3. ARCHIVO:",
        "correcto" if archivo == b"Prueba de archivo" else "fallido"
    )

    # 4. Listar
    registros = listar_registros(COLECCION)
    print("4. LISTADO:", len(registros), "registro(s)")

except Exception as error:
    print("ERROR:", error)

finally:
    # Eliminar únicamente el registro temporal de prueba.
    conexion = conectar()
    try:
        with conexion.cursor() as cursor:
            cursor.execute("""
                DELETE FROM public.app_registros
                WHERE coleccion = %s
                AND folio = %s;
            """, (COLECCION, registro["folio"]))
        conexion.commit()
        print("5. LIMPIEZA: registro de prueba eliminado")
    except Exception:
        conexion.rollback()
        print("AVISO: no se pudo eliminar el registro de prueba")
    finally:
        conexion.close()