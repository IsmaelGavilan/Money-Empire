# MONEY CLICKER EMPIRE

Proyecto en la **fase 3 de 10**, con economía y pulsaciones jugables. Proyecto Godot real; no es una versión comercial terminada.

## Abrir y ejecutar

1. Instalar **Godot 4.6.3 stable estándar** (GDScript, sin .NET).
2. En el gestor de proyectos, elegir **Importar**, seleccionar `project.godot` y abrir.
3. Pulsar **F6** para probar la escena abierta o **F5** para arrancar el menú principal.
4. Seleccionar **Jugar** para visitar la ciudad, **Volver al menú** para regresar y **Salir** para cerrar.

Desde terminal, con el ejecutable Godot en PATH:

```sh
godot --editor --path .
godot --path .
```

En Windows, sustituir `godot` por la ruta al ejecutable, por ejemplo en PowerShell:

```powershell
& "C:\Godot\Godot_v4.6.3-stable_win64.exe" --editor --path .
```

## Controles y pantalla

Ratón: botones y sede. Mantener aceptar o el ratón no repite ingresos; el filtro compartido entre fuentes es de 80 ms por defecto. Teclado: flechas/Tab, Enter/Espacio para aceptar, Escape para volver. Mando: cruceta o stick izquierdo, botón sur para aceptar y este para volver (nomenclatura neutral). Los botones muestran un borde dorado cuando tienen foco. El menú de opciones permite alternar pantalla completa y persiste el ajuste en `user://settings.cfg`; no requiere ratón.

Lienzo base 1920×1080, ventana inicial 1280×720, mínimo 960×540. `canvas_items` conserva nitidez del texto y `aspect=keep` mantiene 16:9 con bandas en otras proporciones. UI dentro del margen del 5 % aproximadamente; validar en televisores reales antes de certificar.

## Alcance

Menú y configuración conservados. Ciudad cenital provisional con sede interactiva: 10 por clic inicial, mejoras de potencia, multiplicadores permanentes y bonus temporal. Primera mejora de sede tras 3 pulsaciones. Además, 40 negocios en cuatro distritos con compras en orden fijo, mejoras individuales, producción manual y contratos automáticos. Accede desde **Negocios y contratos**. Ratón, teclado y mando; respuesta de escala/color y cantidad ganada flotante. La tienda muestra niveles, coste, beneficio actual y tiempo del bonus.

Economía exacta de hasta 300 dígitos, catálogo configurable en `data/economy.json`, formato español/inglés. No hay partidas guardadas: el progreso vive durante el proceso y se conserva al volver al menú. Guardado real, ciudad visual completa, minijuegos, logros, Steamworks, consolas, audio y traducción completa siguen pendientes. Los negocios generan dinero únicamente con ciudad/gestión abiertas y la aplicación enfocada; menú, suspensión y cierre no generan ingresos. Los contratos no implementados devuelven `ERR_UNAVAILABLE`.

Se eligió Godot 4.6.3 porque es la versión estable instalada y permite validar el proyecto con la misma versión fijada. Renderer Compatibility: suficiente para 2D y menor exigencia gráfica en escritorio. No implica soporte ni certificación de consolas. No se garantiza compatibilidad con versiones anteriores de Godot.

## Pruebas

```sh
godot --headless --editor --import --path . --quit
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/economy_tests.gd
godot --headless --path . --script res://tests/business_tests.gd
godot --headless --path . --script res://tests/progress_simulation.gd
godot --headless --path . --quit-after 120
```

Ejecutar las pruebas en un perfil de usuario de pruebas: escriben `settings.cfg`. En Linux se puede aislar con `XDG_DATA_HOME`, `XDG_CONFIG_HOME` y `XDG_CACHE_HOME` apuntando a carpetas temporales; no cambiar HOME. Consultar `TEST_PLAN.md` para resultados y límites.

## Organización

```text
project.godot
scenes/       menu/main_menu.tscn, game/city.tscn, game/businesses.tscn
scripts/      economy/, business/, services/, platform/, ui/
data/         economy.json y businesses.json (catálogos validados)
graphics/     futuro arte (actualmente primitivas en código)
audio/        reservado
ui/           futuros temas y recursos compartidos
localization/ reservado para traducciones ES/EN
tests/        regresión, economía, negocios y simulación de progreso
docs/         informe de validación e inventario
```

`GAME_DESIGN.md`, `ARCHITECTURE.md`, `DEVELOPMENT_STATUS.md` y `TEST_PLAN.md` describen diseño, contratos, alcance y validación. No hay dependencias comerciales, SDKs ni assets de terceros añadidos. Git ya existía; se conserva su historial y se añade `.gitignore`. La entrega del proyecto se publica en el repositorio GitHub del proyecto.

Para exportar a Windows se necesitarán las plantillas de exportación de **la misma versión** y configurar un preset desde Proyecto → Exportar. No se entrega un ejecutable Windows ni se ha validado en ese sistema.

## Economía de negocios

La pantalla de gestión permite navegar los cuatro distritos, examinar cada ficha y comprar, recoger, mejorar o automatizar usando ratón o mando. El primer edificio cuesta 100. Sin contrato, se acumula una sola producción; con contrato se cobra cada ciclo. Los IPS automáticos son una media informativa; el saldo se abona en ciclos exactos. Los valores fraccionarios se muestran con hasta tres decimales.

Hay una prima común de expansión que conserva la utilidad de los negocios antiguos y una recompensa cada cinco compras. Ver GAME_DESIGN y `docs/ECONOMY_SIMULATION.md` para fórmulas, hipótesis y resultados. El juego mantiene la misma precisión monetaria de fase 2.

Para reproducir la simulación desde terminal (la salida va al directorio de usuario de Godot):

```sh
godot --headless --path . --script res://tests/progress_simulation.gd -- clicks=2 horizon=180
```

Se pueden pasar `output=/ruta/escribible/informe.json`, `clicks=1` y `horizon=120`, por ejemplo. Las pulsaciones son sintéticas de la política, pero todas las reglas de dinero y producción son las del servicio real. No se subvenciona el saldo.
