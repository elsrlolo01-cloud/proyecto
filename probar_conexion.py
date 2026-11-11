
from db import probar_conexion

try:
    resultado = probar_conexion()

    print("\nCONEXIÓN EXITOSA")
    print("Base de datos:", resultado["base"])
    print("Usuario:", resultado["usuario"])
    print("Total de tablas:", resultado["tablas"])

except Exception as error:
    print("\nERROR DE CONEXIÓN:")
    print(error)
