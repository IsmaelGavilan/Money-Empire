# Arquitectura

## Composición y dependencias

`Services` es el único autoload y raíz de composición. Crea servicios `RefCounted`; estos no conocen las escenas, nodos UI ni el autoload. La UI consume servicios y señales. La lógica no depende del renderer ni de SDKs. Cambiar una escena libera sus conexiones de señales a métodos del nodo automáticamente.

```text
MainMenu / City → Services (composición)
                       ├─ EconomyService
                       ├─ SettingsService → ConfigFile / DisplayServer
                       ├─ SaveService (contrato)
                       ├─ AchievementService (contrato)
                       └─ PlatformAdapter ← Windows / Steam / Console
```

## Contratos

- EconomyService: `get_balance() -> int`, señal `balance_changed(value: int)` reservada para futuras mutaciones. Estado inicial cero; sin temporizadores ni progreso offline.
- SettingsService: `load_settings() -> Error`, `set_fullscreen(bool) -> Error`, señal `settings_changed`. Solo se aplica y anuncia el nuevo ajuste si se pudo escribir. `ERR_FILE_NOT_FOUND` en primera ejecución es normal; otros errores se notifican. Persistencia local de una preferencia, separada de partidas.
- SaveService: tres ranuras indexadas 0–2; `save_slot` y `load_slot` devuelven error explícito. No hay archivos de partida, autoguardado ni recuperación en esta fase.
- AchievementService: `unlock` devuelve `ERR_UNAVAILABLE`. No existe un catálogo ni desbloqueo local todavía.
- PlatformAdapter: capacidades consultables y errores explícitos. WindowsAdapter identifica el escritorio Windows; no añade SDK. SteamAdapter y ConsoleAdapter son puntos de extensión sin inicialización ni enlace a librerías.

El adaptador se elige por OS; Steam nunca se deduce por existir una instalación o variable ambiental. Una futura integración tendrá que inyectarse tras inicialización real. Las consolas requieren módulos/SDK licenciados y validación en hardware; este código no constituye un port.

## Presentación y entrada

Escenas `.tscn` reales con scripts que construyen los controles y dibujan la maqueta. ScreenUI centraliza botones, estilos y enlaces de foco. No se carga ningún recurso inexistente. Acciones UI de Godot para direcciones (cruceta/stick); aceptar/cancelar se fijan explícitamente con teclado y botones sur/este. Foco inicial, vecinos circulares y restauración al cerrar opciones. La ciudad consume cancelar antes de cambiar escena.

Base 1920×1080 con escalado canvas_items y aspecto conservado. Textos grandes y foco visible. La validación física de mando, overscan y cambios de resolución sigue pendiente.

## Evolución prevista

Datos de balance irán en `data/` como recursos tipados o JSON validado. Antes del guardado real, definir esquema versionado, migraciones, escritura temporal y reemplazo seguro, detección de corrupción y adaptador de almacenamiento adecuado a plataforma. No persistir tiempos para calcular ganancias offline.

Antes de localizar, extraer textos de presentación a claves de traducción y validar longitud en ES/EN. `localization/` solo reserva el espacio: no se afirma que exista soporte bilingüe. No usar rutas `user://` directamente desde economía. La capa de plataformas será la única frontera con Steamworks/trofeos y su detección de capacidades será explícita.
