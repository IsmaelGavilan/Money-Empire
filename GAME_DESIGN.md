# Diseño del juego

## Visión de producto (objetivo, no funciones de esta entrega)

Clicker/tycoon 2D cartoon con ciudad cenital. El jugador pulsa una sede gigante, compra empresas absurdas y construye un imperio económico. Windows primero; PS4 y PS5 son objetivos futuros sujetos a SDKs, port autorizado y pruebas reales.

Objetivos finales: 40 negocios en cuatro distritos y orden fijo de desbloqueo; cuatro minijuegos sencillos; automatización de ingresos exclusivamente durante la sesión; ciudad que evoluciona; efectos de monedas y riqueza; UI horizontal para televisores, navegación completa con mando; tres ranuras de autoguardado; español e inglés; logros locales con adaptación posterior a trofeos. Duración objetivo 2–3 horas y platino fácil de 1–2 horas, sujeto a diseño y requisitos de plataforma. Sin prestigio, reinicios obligatorios, publicidad ni micropagos.

## Fase 1 conservada

Menú → Jugar → ciudad → Volver al menú. Opciones guarda pantalla completa. Ciudad provisional con calles, seis edificios decorativos y sede dorada. Ninguna primitiva se presenta como arte final.

## Fase 2: economía y pulsaciones

Saldo inicial cero. Cada activación aceptada de la sede concede 10 unidades antes de mejorarla. Tres pulsaciones permiten comprar la primera potencia. Sin ingresos automáticos ni offline.

| Mejora | Efecto | Coste inicial | Crecimiento por compra | Límite |
| --- | --- | --- | --- | --- |
| Potencia | +10 al beneficio base | 30 | ×1,5, redondeo hacia arriba por nivel | 50 |
| Multiplicador | ×2 permanente por nivel | 100 | ×3 | 20 |
| Fiebre del oro | ×3 durante 10 segundos | 80 | ×2 | 50 compras |

Fórmula: `(base + suma de potencia) × producto de multiplicadores permanentes × bonus activo`. Por ejemplo, una potencia y un multiplicador producen 40 por pulsación; con fiebre, 120. La fiebre no se acumula ni renueva mientras está activa. Cada nueva compra tras expirar cuesta más. Tiempo monotónico de sesión: sigue corriendo en el menú y nunca concede dinero por el tiempo transcurrido. Al cerrar el proceso se pierde la sesión, incluidas las mejoras; el guardado de partidas sigue pendiente.

Todos estos valores están en `data/economy.json`, validado por EconomyCatalog. Son balance provisional: primera compra tras 3 pulsaciones; con 2 pulsaciones por segundo, aproximadamente 1,5 segundos de interacción. El límite de 80 ms es un filtro de duplicados compartido entre dispositivos, no una cadencia recomendada. El equilibrio de varios minutos debe revisarse con jugadores reales.

## Respuesta y controles

Sede enfocada al entrar. Ratón izquierdo o aceptar con teclado/mando activan una pulsación. Mantener un botón y repetir eventos no genera ingresos adicionales. Flechas, cruceta o stick navegan por sede, mejoras y regreso; los controles de compra siguen enfocados aunque falte dinero, para mostrar el motivo de rechazo. Cancelar devuelve al menú.

Cada éxito actualiza el saldo de inmediato, muestra un texto ascendente con la cantidad y anima escala/color de la sede. Se emiten eventos de ingreso, clic y compras utilizables por futuros sistemas de estadísticas y logros. La UI muestra el beneficio actual, niveles, costes y tiempo restante de bonus. No se añadió audio en esta fase.

## Dinero y nomenclatura

Unidades monetarias enteras exactas, hasta 300 dígitos. No existen valores monetarios flotantes, negativos, infinitos ni NaN. Se rechazan operaciones fuera del rango sin alterar el saldo o la compra. Las abreviaturas solo afectan la presentación y truncan a dos decimales.

Español: mil (10³), M (10⁶), mil M (10⁹), B = billón (10¹²), mil B (10¹⁵), T = trillón (10¹⁸). Inglés: K, M, B = billion (10⁹), T = trillion (10¹²), Qa y Qi. Desde 10²¹, notación científica decimal. Coma decimal en español, punto en inglés. El formateador admite ambas escalas; la interfaz completa sigue en español.

## Fuera de fase 2

Negocios, distritos desbloqueables, ingresos automáticos, minijuegos, guardado real, catálogo de logros, SDKs, localización completa, audio y arte final. No se ha avanzado a la siguiente fase.
