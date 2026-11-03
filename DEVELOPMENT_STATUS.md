# Estado — fase 3

Godot 4.6.3.stable.official.7d41c59c4. Se conserva y amplía el proyecto existente.

## Comprobación previa

Antes de modificar la fase 2 se ejecutaron sus suites: 32 pruebas de base y 558 de economía/presentación, cero fallos y sin errores de consola. Se inspeccionaron EconomyService, la composición de servicios, City, BigMoney, controles y escenas.

## Implementado

- Catálogo validado con los 40 nombres y descripciones solicitados, cuatro distritos de diez y precios/pagos/mejoras/contratos/visuales configurables.
- Propiedad y desbloqueo en orden fijo; compra, tres mejoras de producción, dos de velocidad y contrato automático por negocio.
- Ciclos manuales (una producción lista) y automáticos repetidos, indicadores fraccionarios de IPS y detalle de negocio.
- Recompensas únicas por hitos de cinco compras y prima de expansión para mantener útiles los negocios antiguos.
- Pantalla de gestión navegable con mando; detalles, coste, progreso, niveles, estado, rechazo claro y preview reutilizable. Acceso y resumen de IPS en City.
- BusinessCatalog, BusinessState, BusinessMath, BusinessService, BusinessStatistics y presentación separados. No existen 40 scripts duplicados.
- Transacciones de monedero/estado/recompensa coherentes y bloqueo de reentrada; sin commits parciales de producción al fallar un ingreso.
- Driver de tiempo activo: solo ciudad/gestión enfocadas, pausa en menú, sin fechas offline y sin recuperar intervalos suspendidos.
- Los eventos sirven a estadísticas y futuros logros; no se afirma una integración de trofeos o SDKs.

## Resultados verificables

32 comprobaciones de base + 558 de fase 2 + 1.446 de fase 3 = **2.036 comprobaciones**, todas superadas. La suite recorre compras, mejoras, contratos y producción de los 40 negocios, sus límites, costes, hitos y desbloqueos. Ver TEST_PLAN y logs en docs.

Simulaciones con servicios reales: activa 2 h 26 min 35 s; equilibrada 2 h 34 min 44 s; conservadora 2 h 48 min 56 s. Las tres compran los 40 con cero errores y sin dinero añadido. Informes completos JSON/CSV y análisis de pausas en docs/ECONOMY_SIMULATION.md. El primer distrito aporta 27.95 % de los IPS automáticos al final de la referencia equilibrada.

## Correcciones de validación

Se corrigieron tipos inferidos en pruebas, la comparación de arrays numéricos JSON y los enlaces de foco entre filas y detalle. La importación detectó que Godot trataba los CSV de documentación como traducciones: se añadió docs/.gdignore y se retiraron únicamente los artefactos generados por esos informes. La documentación queda fuera del importador de recursos. Una prueba previa de animación dependía de la duración de dos frames y fallaba bajo carga paralela; ahora observa el inicio del efecto en la señal síncrona y mantiene la comprobación posterior de limpieza.

## Riesgos y limitaciones

La mayor pausa entre edificios es de 389 segundos en la política conservadora; la mayor pausa sin inversión es de 362 segundos. No hay bloqueo de progresión, pero el ritmo tardío requiere playtesting y no está certificado como equilibrio final. La referencia automatizada no reproduce decisiones o manejo humanos.

Se valida en Linux headless, con mando sintético; sin inspección visual, ratón real, mando físico, Windows o exportación comercial. El editor registra los errores de socket de depuración del sandbox; las suites y arranques finales no tienen errores ni avisos.

No hay guardado real de partidas: estado solo de sesión y pérdida al cerrar el proceso. Sin negocios offline, apuestas, minijuegos, audio, traducción completa ni SDKs. El casino tiene producción determinista, igual que cualquier otro negocio.

## Preparado para la fase visual

IDs estables y visuales configurables: color, tejado, silueta, huella y slot lógico por distrito. Snapshots de compra/desbloqueo/automatización y señales permiten conectar futuras representaciones de la ciudad. Las fichas usan previews provisionales; el mapa mantiene la maqueta anterior y no se presenta como la ciudad final.

No se ha comenzado la siguiente fase.
