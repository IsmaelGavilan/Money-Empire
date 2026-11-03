# Diseño del juego

## Visión de producto (objetivo, no funciones de esta entrega)

Clicker/tycoon 2D cartoon con ciudad cenital. El jugador pulsa una sede gigante, compra empresas absurdas y construye un imperio económico. Windows primero; PS4 y PS5 son objetivos futuros sujetos a SDKs, port autorizado y pruebas reales.

Objetivos finales: 40 negocios en cuatro distritos y orden fijo de desbloqueo; cuatro minijuegos sencillos; automatización de ingresos exclusivamente durante la sesión; ciudad que evoluciona; efectos de monedas y riqueza; UI horizontal para televisores, navegación completa con mando; tres ranuras de autoguardado; español e inglés; logros locales con adaptación posterior a trofeos. Duración objetivo 2–3 horas y platino fácil de 1–2 horas, sujeto a diseño y requisitos de plataforma. Sin prestigio, reinicios obligatorios, publicidad ni micropagos.

## Fase 1 entregada

Flujo: menú → Jugar → ciudad → Volver al menú. Opciones permite guardar pantalla completa. La ciudad es una maqueta con calles, seis edificios decorativos y una sede dorada. Todos los gráficos son provisionales; no son arte final. El contador refleja el modelo económico inicial (cero).

No hay pulsaciones, compras, negocios, progresión, minijuegos ni autoguardado de partida. El edificio no se presenta como un botón funcional. Sonido, animaciones y traducciones quedan pendientes.

## Preparación para fase 2

Añadir reglas de pulsación dentro de EconomyService, un valor por pulsación definido como dato y una acción de entrada neutral que funcione con ratón y mando. La presentación invocará esa acción y observará `balance_changed`; no modificará el saldo directamente. Definir límites de enteros y formato monetario, probar reglas y conectar la sede. No añadir ingresos offline.
