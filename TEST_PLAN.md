# Plan de pruebas

## Automatizado

Ejecutar los tres comandos del README con Godot 4.6.3. Importar primero para generar la caché de clases globales. La suite termina con código 1 si alguna comprobación falla; leer también la salida para detectar errores del motor.

Resultado en esta entrega: **32 comprobaciones, 0 fallos**, código 0. Incluye saldo inicial; límites de tres ranuras y errores explícitos; capacidades negativas de cuatro adaptadores; ausencia de logros simulados; escritura/recarga de configuración; bindings de mando en seis acciones UI; carga del menú; foco inicial y enlaces de navegación; opciones y restauración del foco; botón Jugar hacia ciudad; contador; foco en ciudad; regreso con cancelar.

Las transiciones se ejercitan emitiendo señales de botones y eventos de acción; esto no equivale a una prueba física de un mando. El renderizador headless no valida la salida gráfica. Arranque adicional: `--quit-after 120`, código 0 sin errores. Importación headless: código 0, sin errores de parser; advertencias/errores de socket del editor por restricciones del entorno.

La primera importación detectó un error de paréntesis y la primera suite detectó bindings incompletos de aceptar/cancelar y acceso al viewport tras cambio de escena. Se corrigieron y la suite final pasa. Se aislaron los directorios XDG para evitar escribir en el home restringido del entorno.

## Manual pendiente

- Windows: abrir proyecto con 4.6.3, F5; verificar menú, opciones, Jugar, regreso y Salir.
- 1920×1080, 1280×720, 960×540, 4:3 y ultrapanorámico: bandas apropiadas, texto legible y sin cortes.
- Solo teclado y solo mando: recorrer todos los botones, activar aceptar, cancelar opciones/ciudad, comprobar foco dorado y restauración; repetir tras alternar pantalla completa.
- Cerrar/reabrir para comprobar persistencia de pantalla completa. Probar carpeta de usuario sin permisos de escritura y comprobar mensaje de error.
- Ratón: activar cada botón y verificar las transiciones.
- TV real: legibilidad y margen seguro. Dispositivos de mando reales: conexión inicial y reconexión.

## Fase 2 pendiente

Validar pulsación única y repetición, límites del saldo, señal de cambio exactamente una vez, formato monetario y equivalencia ratón/mando; comprobar que cambiar de escena no duplica ingresos. Guardado y SDKs requieren planes específicos cuando se implementen.
