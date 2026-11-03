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

## Fase 3: negocios e ingresos

Los 40 negocios solicitados están definidos en `data/businesses.json`: cuatro distritos, diez negocios cada uno y orden fijo de compra. Comprar el negocio N desbloquea N+1; el primero está disponible al comenzar. No hay pago separado por distrito ni requisitos ocultos. Se pueden consultar las fichas de los negocios bloqueados.

Cada definición incluye nombre, descripción, precio, pago base por ciclo, duración, costes y límites de mejora, contrato y datos visuales. El estado de sesión conserva propiedad, nivel de producción, velocidad, automatización y progreso del ciclo. La gestión se abre con **Negocios y contratos** desde la ciudad.

### Producción, mejoras y contratos

- Sin contrato: el ciclo avanza durante el juego hasta una producción lista. Se cobra manualmente y comienza el siguiente ciclo. No se apilan ciclos sin recoger.
- Con contrato: cobra y repite automáticamente, sin gerente visible. El contrato se paga una sola vez; cuesta el 25 % del precio de compra.
- Potencia individual: tres mejoras, cada una ×2 al pago (×8 al máximo). Coste inicial del 50 % del precio del edificio, crecimiento ×3 por compra.
- Velocidad individual: dos mejoras, de 6 a 3 y 2 segundos. Coste inicial del 75 % del precio, crecimiento ×3.
- No se cobran operaciones sin saldo, compras repetidas, negocios bloqueados o mejoras al máximo. Los mensajes explican el motivo.

### Curva y utilidad de los primeros negocios

Precio del negocio i (empezando por 0): `100 × 4^i`. El pago base es `ceil(precio / 300)`, mínimo 1; todos comienzan con ciclos de 6 segundos. Las cifras exactas están materializadas como texto decimal en JSON, sin potencias flotantes en ejecución.

Cada expansión actualiza una prima común: `ceil(pago_base_del_último_negocio / negocios_comprados)`. Pago por ciclo = `(base propia + prima común) × 2^nivel_de_producción`. La prima se aplica también a los edificios antiguos y se beneficia de sus mejoras. Solo los comprados producen; las fichas bloqueadas muestran un potencial, no ingresos reales.

Cada cinco compras se concede automáticamente el 50 % del precio del edificio recién adquirido: hitos 5, 10, 15, 20, 25, 30, 35 y 40. Es un crédito único de expansión, no una compra financiada por adelantado. Gastos, recompensa y estado se comprometen en una sola operación.

La sede y sus mejoras de fase 2 conservan sus reglas. No se añadió una nueva escala de pulsación ni se redujeron sus límites.

### Tiempo activo y ausencia de ingresos offline

La producción de negocios solo avanza con la ciudad o la pantalla de gestión abiertas y la aplicación enfocada. El menú pausa la producción. El driver usa delta de frames, conserva fracciones de milisegundo y descarta intervalos de suspensión: máximo 250 ms por frame y un frame sin producción al reanudar. No usa fechas del sistema ni instantes guardados. El servicio admite pasos acotados de hasta 60 segundos para pruebas y simulación explícita; el juego no los obtiene de tiempo offline.

No existe todavía guardado de partidas: al cerrar el proceso desaparece el estado de sesión. Esto no se presenta como un sistema de persistencia terminado. El bonus temporal de la sede mantiene su reloj monotónico de fase 2, independiente de producción; su expiración nunca genera dinero.

### Presentación provisional

Listado por distrito, fichas con descripción, producción potencial y automática total, nivel, progreso y estado del contrato; botones de compra, recogida y mejoras. Las fichas siguen accesibles con mando aunque no se pueda comprar. Hay cuatro siluetas genéricas reutilizables con color, tejado, huella y posición lógica configurables. Gris/borde y etiquetas distinguen bloqueado, disponible, comprado y automatizado.

El casino es únicamente una fábrica temática de producción fija: no hay apuestas, dinero real, sorteos, probabilidades ni azar. La Corporación del Dinero Infinito también produce cantidades finitas.

### Medición inicial

Ver `docs/ECONOMY_SIMULATION.md` y sus JSON/CSV reproducibles. Se ejecutan los mismos servicios que el juego, desde cero, sin fondos de prueba. La política mantiene pulsaciones regulares, recoge ciclos manuales y reinvierte en contratos y mejoras rentables. Su resultado sirve para evaluar la curva; no sustituye jugar ni demuestra que todos los jugadores terminen en el mismo tiempo. Se registran tanto pausas largas como posibles compras encadenadas.

## Pendiente, fuera de fase 3

Representación completa de los 40 edificios sobre la ciudad, evolución artística, minijuegos, guardado real, catálogo de logros, SDKs, traducción completa, audio y arte final. Los eventos y datos de esta entrega preparan la fase visual sin implementarla. No se ha avanzado automáticamente.
