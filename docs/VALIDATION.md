# Validación de fase 1

Motor: Godot 4.6.3.stable.official.7d41c59c4. Entorno: Linux sin servidor gráfico.

- Importación/editor headless: código 0, sin errores de scripts. El sandbox impide abrir sockets de depuración del editor (ERR_CANT_CREATE); no es una validación gráfica.
- Suite automatizada: código 0; 32 comprobaciones, 0 fallos.
- Arranque de la escena principal: 120 frames headless, código 0, sin errores.
- git diff --check: correcto.
- No se ha validado Windows, mando físico, aspecto visual, Steam ni consolas.

Los registros siguientes son de las ejecuciones finales. Las preferencias de las pruebas se almacenaron bajo /workspace/work/xdg-test; no se incluyeron en el proyecto.
