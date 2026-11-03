# Estado — fase 2

Motor: Godot 4.6.3.stable.official.7d41c59c4. Se amplió el proyecto de fase 1 sin reconstruirlo.

## Implementado

- Menú, opciones persistentes, ciudad y adaptadores previos conservados.
- BigMoney: enteros decimales exactos no negativos de hasta 300 dígitos, suma, resta, producto por entero acotado y división con redondeo hacia arriba. Sin conversión monetaria a float.
- Catálogo económico validado en JSON: base, costes, progresión, límites, cooldown y efectos configurables.
- Economía transaccional: ganar, gastar, pulsar, comprar; comprobación de fondos y límites antes de mutar; bloqueo de transacciones reentrantes durante señales.
- Potencia, multiplicador permanente y bonus temporal; reloj monotónico inyectable para pruebas, sin ganancias offline.
- Contador, beneficio, tienda de mejoras, niveles y costes, mensajes de rechazo y temporizador de bonus.
- Sede interactiva con ratón, teclado y mando, control de mantener/repetir entrada, filtro compartido entre dispositivos, pulso visual y cantidad flotante con limpieza al terminar.
- Eventos balance_changed, money_earned, money_spent, click_registered, upgrade_purchased y benefit_changed para consumidores futuros. Contador de clics aceptados de sesión.
- Formato español/inglés con escalas larga/corta explícitas.

## Validación

558 comprobaciones de fase 2 y 32 de regresión de la base: 590 en total, cero fallos. Incluyen aritmética de referencia, 300 dígitos, rechazo de datos inválidos y no finitos, costes, compras, multiplicadores compuestos, expiración exacta del bonus, rechazo atómico de desbordamientos, señales, mando sintético, cruceta/stick, animación/limpieza y continuidad al cambiar de escena.

Importación headless sin errores de scripts. Arranque headless de menú y ciudad durante 120 frames sin errores. El editor registra errores al abrir su socket de depuración por restricciones del entorno; las suites y ejecuciones del juego no presentan errores ni avisos. Detalles en TEST_PLAN y docs/VALIDATION.md.

## Límites y pendientes

No hay pantalla gráfica ni mando físico en este entorno: se validó el circuito GUI con eventos sintéticos, no aspecto visual ni hardware. Windows y exportación comercial siguen pendientes. Steam y PlayStation siguen sin SDKs ni integración.

No hay guardado de partidas: saldo, niveles y bonus permanecen solo en la sesión. Las tres ranuras siguen siendo contrato. No hay negocios, automatización, contenido de fases posteriores ni logros desbloqueables. La localización completa sigue pendiente; solo el formateador monetario soporta ES/EN.

Balance inicial definido y probado numéricamente, pendiente de playtesting real de varios minutos. El límite de 300 dígitos es explícito; overflow devuelve ERR_OUT_OF_MEMORY como error de capacidad numérica sin consumir dinero. Al calcular costes se valida también cada resultado intermedio de multiplicación.

## Correcciones durante esta fase

Se adaptó el contrato de saldo entero nativo a BigMoney y las pruebas existentes a ese contrato. Las pruebas nuevas detectaron una asignación de array tipado incompatible en el formateador y un aviso al convertir Unicode inválido a ASCII; ambos se corrigieron. Una referencia circular exclusiva de la prueba de reentrada se eliminó desconectando su callback. Las ejecuciones finales están limpias.

No se ha iniciado ninguna función de la siguiente fase.
