# Plan de pruebas — fase 2

Godot 4.6.3. Importar primero para generar caché de clases:

```sh
godot --headless --editor --import --path . --quit
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/economy_tests.gd
godot --headless --path . --quit-after 120
godot --headless --path . res://scenes/game/city.tscn --quit-after 120
```

Usar perfil de usuario de pruebas: la suite de regresión escribe settings.cfg. En Linux aislar XDG_DATA_HOME, XDG_CONFIG_HOME y XDG_CACHE_HOME en carpetas temporales, sin modificar HOME. En esta validación se usó `/workspace/work/xdg-test`.

## Resultados

- Regresión de base: 32 comprobaciones, cero fallos.
- Economía y presentación: 558 comprobaciones, cero fallos.
- Total: 590 comprobaciones. Ambas suites terminan con código 0 y sin errores/avisos de consola.
- Importación: código 0, sin errores de GDScript. El editor headless registra errores de apertura del socket de depuración en el sandbox.
- Arranque: menú y ciudad por separado, 120 frames, código 0 sin errores ni avisos.
- git diff --check: correcto.

Los registros finales están en docs/; la importación del editor no equivale a una prueba gráfica.

## Cobertura

BigMoney: validación de texto, no negativos/NaN/Infinity/Unicode, normalización, acarreo y préstamo más allá de int64, aritmética exacta de 300 dígitos, factores/divisores inválidos, límites y redondeo de costes. 150 casos deterministas de suma/resta/producto contra enteros nativos seguros (450 aserciones).

Catálogo: campos ausentes, tipos, IDs duplicados, factores no finitos, crecimiento inválido y límites. Compras con overflow en coste y beneficio se rechazan sin saldo o niveles parcialmente modificados.

Economía: saldo inicial, clics, cooldown en sus fronteras, eventos únicos, suma/gasto, compra imposible, tres clics para primera compra, costes progresivos, potencia, multiplicadores compuestos, orden de cálculo, bonus temporal, no acumulación, expiración exacta sin esperar tiempo real, repeticiones, topes y reentrada desde observadores.

Presentación: mando sintético (botones aceptar/cancelar, cruceta y eje del stick) inyectado mediante Input.parse_input_event hasta la GUI. Compra de mejora enfocada, foco inicial y navegación; contador/beneficio inmediatos; mantener un botón; ratón por el manejador GUI y coincidencia ratón/mando; ecos de teclado; textos flotantes, limpieza y restauración de escala; volver y reentrar sin perder mejoras de sesión.

No sustituye una prueba de mando físico, inspección gráfica ni ratón real. Las pruebas automatizadas usan el renderer headless.

## Pruebas manuales pendientes

1. Windows con Godot 4.6.3: F5, menú/opciones/ciudad/salir, pantalla completa y persistencia de esa preferencia.
2. Ratón real: pulsar sede, mantener, arrastrar fuera antes de soltar, volver y pulsar. Comprobar foco, feedback y ausencia de bloqueos.
3. Solo mando: navegar toda la tienda con stick/cruceta, comprar, regresar, volver a sede; mantener aceptar y comprobar que no repite; desconectar/reconectar.
4. Teclado: flechas/Tab, Enter/Espacio y Escape; mantener aceptar; cambiar de aplicación durante una pulsación.
5. 1920×1080, 1280×720, 960×540, 4:3, ultrapanorámico y TV: legibilidad, bandas, márgenes, efectos y ausencia de recortes.
6. Jugar varios minutos y evaluar ritmo/costes de las tres mejoras. La predicción numérica no sustituye playtesting.
7. Comprar fiebre, volver al menú durante más de 10 segundos y regresar: bonus expirado, saldo sin ingresos adicionales. Cerrar/reabrir: sesión a cero (guardado pendiente).

## Fuera de esta fase

Negocios, ingresos automáticos, minijuegos, guardado real, logros, SDKs, localización completa y empaquetado requieren implementación y planes posteriores.
