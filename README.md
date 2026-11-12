# Hospital de Equinos

Aplicacion web de gestion hospitalaria veterinaria desarrollada con Streamlit.

## Probar en este equipo

Requiere Python 3.12. En la carpeta del proyecto:

```powershell
python -m pip install -r requirements.txt
python -m streamlit run app.py
```

Streamlit mostrara una direccion local para abrir en el navegador.

## Publicar con HTTPS para compartir

Streamlit Community Cloud proporciona una direccion HTTPS publica (`*.streamlit.app`); no es necesario configurar certificados ni abrir puertos en la computadora.

1. Manten privado el repositorio de GitHub: contiene `usuarios.json` con datos de cuenta y verificadores de contrasenas. El archivo ya esta bajo seguimiento de Git; `.gitignore` no lo quita del historial. Si el codigo debe ser publico, primero retira el archivo del seguimiento, limpia su historial y cambia la contrasena de esa cuenta.
2. Entra a [share.streamlit.io](https://share.streamlit.io/) e inicia sesion con GitHub.
3. Crea una aplicacion y selecciona el repositorio, la rama `main` y el archivo principal `app.py`.
4. Selecciona Python 3.12 y despliega. Streamlit Cloud instalara las dependencias de `requirements.txt` y asignara la URL HTTPS.
5. Comparte la URL de la aplicacion. Para que cualquiera pueda abrirla, configura el acceso de la app como publico; el codigo fuente puede permanecer en un repositorio privado.

## Limitaciones importantes antes de usarla

- La URL permite abrir la app desde otros navegadores, pero **los expedientes, catalogos y bitacoras se guardan en la sesion de cada usuario**. No se comparten entre personas y se pueden perder al cerrar la sesion o reiniciar la app.
- Las cuentas se guardan en `usuarios.json`, dentro del almacenamiento local del despliegue. Ese almacenamiento no es una base de datos compartida ni persistente en Streamlit Cloud.
- Por lo anterior, esta publicacion sirve para demostraciones, no para operar un hospital ni para guardar informacion clinica, personal o confidencial. Para uso real se necesita conectar una base de datos compartida y persistente, configurar autenticacion y revisar privacidad y seguridad antes de publicarla.
- El repositorio estaba publico al preparar esta guia. Cambiarlo a privado limita el acceso futuro, pero no garantiza borrar copias que alguien ya haya descargado; cambia la contrasena de la cuenta que estaba en `usuarios.json`.
