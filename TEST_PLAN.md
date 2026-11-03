# Plan de pruebas — fase 3

Godot 4.6.3; importar antes de ejecutar scripts. Usar un perfil de pruebas: run_tests.gd guarda settings.cfg. En Linux, aislar XDG_DATA_HOME, XDG_CONFIG_HOME y XDG_CACHE_HOME; no cambiar HOME.

```sh
godot --headless --editor --import --path . --quit
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/economy_tests.gd
godot --headless --path . --script res://tests/business_tests.gd
godot --headless --path . --script res://tests/progress_simulation.gd
godot --headless --path . --quit-after 120
godot --headless --path . res://scenes/game/city.tscn --quit-after 120
godot --headless --path . res://scenes/game/businesses.tscn --quit-after 120
```

## Resultados

- Antes de modificar: 590 comprobaciones de fase 2, cero fallos.
- Después: 32 de base + 558 de economía/sede + 1.446 de negocios = **2.036**, cero fallos. Código 0 y consola sin errores ni avisos en cada suite.
- Simulación: tres políticas compran los 40 con código 0 y cero errores. Datos exactos y tiempos en docs/ECONOMY_SIMULATION.md y JSON/CSV.
- Importación: código 0 y sin errores de GDScript. El sandbox bloquea el socket de depuración del editor y este lo registra como error; se conserva el log.
- Arranque de menú, ciudad y gestión por separado: 120 frames cada uno, código 0 y sin errores ni avisos.
- Verificación de espacios finales en los archivos del proyecto y git diff --check: correctos.

## Cobertura de fase 3

Catálogo de 40: nombres/descripciones, diez por distrito, orden, curva ×4, producción positiva, visuales y slots; rechazo de campos ausentes, dinero inválido/no finito, ID/slot duplicados, recuento incorrecto y tiempos inválidos.

Para cada negocio: desbloqueo siguiente, rechazo de saltos y compras repetidas, precio exacto, recompensa cada cinco, nivel inicial, tres mejoras de producción y su coste, dos de velocidad, límites, contrato y rechazo de contrato duplicado. Producción exacta simultánea de 40 negocios, lote de 30 ciclos y estadísticas independientes (40 compras, 40 contratos y 200 mejoras).

Tiempo: frontera exacta de ciclo, manual no acumula backlog, no doble recogida, pausa mantiene progreso sin ingreso, contrato conserva ciclo parcial, nueva sesión sin estado offline, invariancia al dividir delta, exceso/tiempo negativo rechazados. Driver probado al ir al menú, perder foco y recibir un frame enorme; no recupera la suspensión.

Transacciones: fondos insuficientes, parámetros/índices inválidos, visibilidad de estado ya comprometido al emitir señales, reentrada cruzada rechazada, overflow de ingreso sin avance temporal ni estadísticas parciales. Precisión monetaria de hasta 300 dígitos sigue cubierta por fase 2.

Interfaz: ruta City → gestión, diez filas por distrito, navegación, rechazo por falta de dinero/bloqueo, compras y contratos con eventos de mando sintéticos hasta la GUI, estados visibles y preview, selección por foco, navegación derecha/izquierda entre lista y detalles, regreso a ciudad/menú y continuidad de estado.

## Simulación y alcance de sus conclusiones

Usa los mismos servicios y datos, parte de cero, no inyecta fondos y registra las 40 compras de cada política. Se miden duración, pausas, compras simultáneas e ingreso de los primeros negocios. Finaliza al comprar el 40, no al maximizar todos sus niveles. Una política de referencia no equivale a jugar ni garantiza la duración universal. Los tramos de varios minutos están señalados en el informe.

## Manual pendiente

1. Windows/Godot 4.6.3: F5, menú, opciones, ciudad, gestión de los cuatro distritos, contratos, regreso y Salir.
2. Ratón y mando reales: comprar, recoger, mejorar, contratar, mantener botones y alternar dispositivos; comprobar foco y mensajes. Navegar fichas bloqueadas y nombres largos.
3. 1920×1080, 1280×720, 960×540, 4:3, ultrapanorámico y TV: legibilidad, bandas, texto sin recortes, colores y previews.
4. Dejar un ciclo a medias; ir al menú o cambiar de aplicación durante un minuto y volver: no generar renta por ese intervalo. Cerrar/reabrir reinicia la sesión porque el guardado sigue pendiente.
5. Jugar varios minutos en cada tramo económico; evaluar esperas, coste de automatización y utilidad de los primeros negocios. Revisar el tramo tardío antes de declarar cerrado el equilibrio comercial.
6. Validar ausencia de apuestas/azar: el casino solo compra, produce, mejora y se automatiza como el resto.

No se ha validado salida gráfica, ratón real, mando físico, Windows, Steam ni consolas en este entorno. La siguiente fase visual, persistencia y SDKs necesitan su propia implementación y pruebas.
