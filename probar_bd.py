
import psycopg2
import getpass

try:
    password = getpass.getpass("Contraseña de PostgreSQL: ")

    conn = psycopg2.connect(
        host="::1",
        port=5432,
        database="hospital_equinos",
        user="postgres",
        password=password
    )

    cursor = conn.cursor()

    cursor.execute("""
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_type = 'BASE TABLE'
        ORDER BY table_name;
    """)

    tablas = cursor.fetchall()

    print("\nCONEXIÓN EXITOSA")
    print("Base de datos: hospital_equinos")
    print("Total de tablas:", len(tablas))
    print("\nTABLAS ENCONTRADAS:")

    for tabla in tablas:
        print("-", tabla[0])

    cursor.close()
    conn.close()

except Exception as error:
    print("\nERROR DE CONEXIÓN:")
    print(error)
