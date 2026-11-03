# Arquitectura

## Composición y dependencias

`Services` es el único autoload y raíz de composición. Crea servicios `RefCounted`; estos no conocen las escenas, nodos UI ni el autoload. La UI consume servicios y señales. La lógica no depende del renderer ni de SDKs. Cambiar una escena libera sus conexiones de señales a métodos del nodo automáticamente.

```text
MainMenu / City → Services (composición)
                       ├─ BusinessStatistics ← señales de BusinessService
                       ├─ BusinessService → EconomyService
                       ├─ EconomyService
                       ├─ SettingsService → ConfigFile / DisplayServer
                       ├─ SaveService (contrato)
                       ├─ AchievementService (contrato)
                       └─ PlatformAdapter ← Windows / Steam / Console
```

## Contratos

- EconomyService: `get_balance() -> BigMoney`, `get_click_benefit()`, `click() -> Error`, `earn/spend(BigMoney, source) -> Error`, `purchase(id) -> Error`, consulta de niveles/costes y bonus. Saldo inicial cero y contador de clics. Actualiza estados completos antes de emitir señales y rechaza mutaciones reentrantes mientras notifica. No genera ingresos por tiempo.
- EconomyCatalog valida `data/economy.json` y rechaza el catálogo completo si falta o es inválido. Los servicios pueden recibir catálogo y reloj inyectados. BigMoney implementa operaciones exactas acotadas; null señala entrada inválida, underflow u overflow. El servicio convierte esos casos en errores y evita cualquier mutación parcial.
- MoneyFormat separa presentación de aritmética: escalas ES/EN, truncamiento y notación científica sin logaritmos ni floats monetarios. Los valores internos no se redondean.
- SettingsService: `load_settings() -> Error`, `set_fullscreen(bool) -> Error`, señal `settings_changed`. Solo se aplica y anuncia el nuevo ajuste si se pudo escribir. `ERR_FILE_NOT_FOUND` en primera ejecución es normal; otros errores se notifican. Persistencia local de una preferencia, separada de partidas.
- SaveService: tres ranuras indexadas 0–2; `save_slot` y `load_slot` devuelven error explícito. No hay archivos de partida, autoguardado ni recuperación en esta fase.
- AchievementService: `unlock` devuelve `ERR_UNAVAILABLE`. No existe un catálogo ni desbloqueo local todavía.
- PlatformAdapter: capacidades consultables y errores explícitos. WindowsAdapter identifica el escritorio Windows; no añade SDK. SteamAdapter y ConsoleAdapter son puntos de extensión sin inicialización ni enlace a librerías.

El adaptador se elige por OS; Steam nunca se deduce por existir una instalación o variable ambiental. Una futura integración tendrá que inyectarse tras inicialización real. Las consolas requieren módulos/SDK licenciados y validación en hardware; este código no constituye un port.

## Presentación y entrada

Escenas `.tscn` reales con scripts que construyen los controles y dibujan la maqueta. ScreenUI centraliza botones, estilos y enlaces de foco. HeadquartersButton es un Control enfocable que convierte una pulsación física en una activación y consume ecos; City llama una sola vez a EconomyService y observa señales para actualizar la interfaz y los efectos. No se carga ningún recurso inexistente. Acciones UI de Godot para direcciones (cruceta/stick); aceptar/cancelar se fijan explícitamente con teclado y botones sur/este. Foco inicial, vecinos circulares y restauración al cerrar opciones. La ciudad consume cancelar antes de cambiar escena.

Base 1920×1080 con escalado canvas_items y aspecto conservado. Textos grandes y foco visible. La validación física de mando, overscan y cambios de resolución sigue pendiente.

## Evolución prevista

Los datos de balance ya residen en `data/economy.json`. Al extender el catálogo, mantener su validación. El bonus usa un reloj monotónico, consultado por Services y al operar; no se serializa ni se usa para calcular ingresos offline. Antes del guardado real, definir esquema versionado, migraciones, escritura temporal y reemplazo seguro, detección de corrupción y adaptador de almacenamiento adecuado a plataforma. No persistir tiempos para calcular ganancias offline.

Antes de localizar, extraer textos de presentación a claves de traducción y validar longitud en ES/EN. `localization/` solo reserva el espacio: no se afirma que exista soporte bilingüe. No usar rutas `user://` directamente desde economía. La capa de plataformas será la única frontera con Steamworks/trofeos y su detección de capacidades será explícita.

## Contrato numérico y eventos de fase 2

BigMoney es inmutable mediante su API pública. `parse` solo acepta cadenas de dígitos ASCII de hasta 300 posiciones; se normalizan ceros iniciales. `add`, `subtract`, `multiply_small` (factor hasta 1 000 000) y `divide_small_ceil` producen nuevas instancias. Los acumuladores por dígito están acotados muy por debajo de int64. No usar float para dinero, costes, comparaciones o multiplicadores. Los floats de JSON solo se aceptan para parámetros pequeños enteros, finitos y validados; el dinero del JSON siempre es texto decimal.

Los getters de saldo y beneficio devuelven valores nuevos; los eventos no exponen el saldo interno. Ningún consumidor debe modificar campos internos con prefijo `_`. Las señales de ingreso, gasto, clic y compra incluyen cantidad/origen o identificador/nivel; permiten conectar estadísticas y logros sin referencias a City. Un error no cuenta como clic ni genera ingreso.

Los estados se mantienen en el autoload entre escenas. El bonus expira con tiempo de proceso monotónico, incluido el menú; `tick()` emite benefit_changed una vez al expirar. La UI usa tweens ligados al nodo para escala/color y textos, y los elimina al terminar o al liberar la escena. No existe conexión adicional de entrada en EconomyService: todas las fuentes convergen en `click()` y comparten el cooldown configurable.

## Fase 3: negocios

- `BusinessCatalog`: valida las 40 definiciones, orden, cuatro distritos de diez, moneda, tiempos, mejoras, metadatos visuales y posiciones lógicas únicas. El catálogo completo se rechaza si falta un negocio o algún dato es inválido. Las fórmulas no dependen de los nombres.
- `BusinessState`: propiedad, nivel de producción/velocidad, contrato y progreso del ciclo. Solo estado de sesión; sin timestamps, fechas de cierre ni carga offline.
- `BusinessMath`: cálculo puro de pago con prima, ciclo, coste de mejora e IPS. Los IPS se representan en milésimas enteras y son informativos; los pagos reales son unidades enteras exactas.
- `BusinessService`: compra secuencial, mejoras, contratos, recogida manual y avance explícito por milisegundos. Mantiene cache de pagos/ciclos/IPS; publica copias de definiciones y snapshots de estado. El servicio conoce el monedero, no las escenas ni los controles.
- `BusinessStatistics`: consumidor separado de eventos. Cuenta compras, contratos, mejoras, ciclos y dinero producido; no decide desbloqueos ni llama SDKs de logros. Expone `income_at_capacity` si su suma estadística alcanza el límite numérico; no modifica el monedero.
- `BusinessScreen` y `BusinessPreview`: navegación, detalles y siluetas provisionales. La representación consume los datos y el estado sin poseer reglas económicas. `City` solo añade acceso a gestión y un resumen de IPS.

EconomyService añade `exchange(cost, credit, source, commit_state)`: valida saldo, resta y crédito antes de modificar nada, ejecuta un callback interno síncrono de estado y solo después notifica a observadores. El callback es código de dominio de confianza, no puede fallar, esperar ni iniciar otra transacción. Esto evita que una señal vea dinero gastado pero propiedad antigua. Las operaciones de BusinessService tienen su propio bloqueo de reentrada y no comprometen progreso de producción si el monedero no acepta el abono.

Eventos: `business_purchased`, `business_upgraded`, `business_automated`, `production_collected(id, amount, cycles, automatic)`, `expansion_milestone` y `businesses_changed`. Los futuros logros podrán observarlos; el servicio de logros sigue declarando integración no disponible. Los créditos de hitos y el gasto se notifican también en EconomyService con origen `business_purchase`.

Services compone un único BusinessService con el mismo EconomyService usado por la sede. Su driver usa delta del motor exclusivamente, conserva la fracción de milisegundo, pausa en menús y pérdida de foco y descarta el primer frame de reanudación. City y BusinessScreen activan/desactivan producción al entrar/salir. No hay cálculo de diferencias entre fechas, ni ganancias offline, ni lectura de tiempo monotónico dentro de BusinessService. `advance_ms` acotado también permite simulación rápida y reproducible sin UI.

Para fase visual: cada definición tiene `visual.tint`, `roof_tint`, `silhouette`, `footprint` y `district_slot`, además de ID/orden estables. La posición es un slot lógico, no coordenadas de píxeles: el futuro layout debe separar slots según la huella. Se pueden añadir escenas de edificios asociadas a IDs o siluetas sin duplicar scripts económicos. El catálogo ya garantiza slots únicos dentro de cada distrito. No se ha construido todavía esa ciudad evolutiva.

`docs/.gdignore` excluye los informes de la importación de recursos: sus CSV son tablas de balance, no archivos de traducción. No se empaquetan traducciones generadas a partir de esos informes.
