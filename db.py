
# -*- coding: utf-8 -*-
"""
Conexión PostgreSQL - Hospital de Equinos
"""

import os
import tomllib
from pathlib import Path

import psycopg2
from psycopg2.extras import RealDictCursor

BASE_DIR = Path(__file__).resolve().parent
SECRETS_FILE = BASE_DIR / ".streamlit" / "secrets.toml"


def obtener_configuracion():
    # Primero intenta leer las variables de entorno.
    config = {
        "host": os.getenv("PGHOST", "::1"),
        "port": os.getenv("PGPORT", "5432"),
        "dbname": os.getenv("PGDATABASE", "hospital_equinos"),
        "user": os.getenv("PGUSER", "postgres"),
        "password": os.getenv("PGPASSWORD"),
    }

    # Si no hay contraseña en el entorno, consulta secrets.toml.
    if not config["password"] and SECRETS_FILE.exists():
        with SECRETS_FILE.open("rb") as archivo:
            secretos = tomllib.load(archivo)
        config.update(secretos.get("postgres", {}))

    if not config["password"]:
        raise RuntimeError(
            "No se encontró la contraseña. Revisa .streamlit/secrets.toml."
        )

    return config


def conectar():
    """Abre una conexión nueva con PostgreSQL."""
    config = obtener_configuracion()
    return psycopg2.connect(
        **config,
        cursor_factory=RealDictCursor,
        connect_timeout=10
    )


def probar_conexion():
    """Comprueba conexión, base y número de tablas."""
    conexion = conectar()

    try:
        with conexion.cursor() as cursor:
            cursor.execute("""
                SELECT current_database() AS base,
                       current_user AS usuario,
                       COUNT(*) AS tablas
                FROM information_schema.tables
                WHERE table_schema = 'public'
                  AND table_type = 'BASE TABLE';
            """)
            return cursor.fetchone()
    finally:
        conexion.close()

# ───────────── Operaciones de persistencia ─────────────

import json
import base64
from datetime import date, datetime

def _convertir_json(obj):
    """Convierte tipos especiales para almacenarlos en JSONB."""
    if isinstance(obj, bytes):
        return {
            "__tipo__": "bytes",
            "contenido": base64.b64encode(obj).decode("ascii")
        }

    if isinstance(obj, (date, datetime)):
        return obj.isoformat()

    raise TypeError(f"Tipo no compatible con JSON: {type(obj).__name__}")

def _recuperar_json(obj):
    """Restaura archivos binarios almacenados en JSONB."""
    if obj.get("__tipo__") == "bytes":
        return base64.b64decode(obj["contenido"])

    return obj

def guardar_registro(coleccion, registro):
    """Inserta o actualiza un registro completo."""
    datos = json.dumps(
        registro,
        default=_convertir_json,
        ensure_ascii=False
    )

    conexion = conectar()

    try:
        with conexion.cursor() as cursor:
            cursor.execute("""
                INSERT INTO public.app_registros
                    (coleccion, folio, datos)
                VALUES (%s, %s, %s::jsonb)
                ON CONFLICT (coleccion, folio)
                DO UPDATE SET
                    datos = EXCLUDED.datos,
                    fecha_actualizacion = CURRENT_TIMESTAMP;
            """, (coleccion, registro["folio"], datos))

        conexion.commit()

    except Exception:
        conexion.rollback()
        raise

    finally:
        conexion.close()

def listar_registros(coleccion):
    """Devuelve todos los registros de una colección."""
    conexion = conectar()

    try:
        with conexion.cursor() as cursor:
            cursor.execute("""
                SELECT datos
                FROM public.app_registros
                WHERE coleccion = %s
                ORDER BY id_registro;
            """, (coleccion,))

            resultados = cursor.fetchall()

            return [
                json.loads(
                    json.dumps(fila["datos"]),
                    object_hook=_recuperar_json
                )
                for fila in resultados
            ]

    finally:
        conexion.close()

def buscar_registro(coleccion, folio):
    """Busca un registro por colección y folio."""
    conexion = conectar()

    try:
        with conexion.cursor() as cursor:
            cursor.execute("""
                SELECT datos
                FROM public.app_registros
                WHERE coleccion = %s AND folio = %s;
            """, (coleccion, folio))

            resultado = cursor.fetchone()

            if resultado is None:
                return None

            return json.loads(
                json.dumps(resultado["datos"]),
                object_hook=_recuperar_json
            )

    finally:
        conexion.close()