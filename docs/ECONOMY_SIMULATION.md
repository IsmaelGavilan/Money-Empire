# Simulación económica inicial — fase 3

La simulación ejecuta EconomyService, BusinessService, BusinessMath y los catálogos reales dentro de Godot 4.6.3. No añade dinero ni cambia precios, niveles o estados internamente. Arranca en cero; cada ingreso procede de pulsar, producir o recibir un hito. Tiempo acelerado de pasos explícitos de 1.000 ms, sin esperar horas reales.

La meta medida es **comprar el edificio 40**, no terminar todos sus niveles o contratos. El último edificio recién comprado todavía no está automatizado en la captura final; los demás contratos se adquieren según la política. No se requiere que un jugador real mantenga la misma cadencia para poder jugar.

| Política | Clics/s | Horizonte de inversión | Compra del 40 | Fallos | Mayor intervalo entre edificios | Mayor intervalo sin inversión/compra |
| --- | --- | --- | --- | --- | --- | --- |
| Activa | 3 | 300 s | 2 h 26 min 35 s | 0 | 352 s | 321 s |
| Equilibrada | 2 | 180 s | 2 h 34 min 44 s | 0 | 373 s | 348 s |
| Conservadora | 1 | 120 s | 2 h 48 min 56 s | 0 | 389 s | 362 s |

## Política reproducible

Una vez por segundo se incorporan las pulsaciones a través del servicio real respetando su cooldown, avanza la producción y, cada dos segundos, se recoge cualquier ciclo manual listo. Si se puede pagar el siguiente edificio, se compra antes de otra inversión. En otro caso se consideran contratos y mejoras individuales y de sede (potencia/multiplicador; no se compra el bonus temporal). Solo se invierte en mejoras cuyo coste sea menor que un cuarto del próximo edificio y cuyo ingreso marginal amortice la compra dentro del horizonte indicado. Los contratos tienen prioridad, seguidos de la mejora elegible más barata. Todas las comparaciones de dinero e ingresos son enteras exactas.

Es una política de referencia, no un optimizador ni una garantía de duración para toda estrategia. Cambia tanto la frecuencia de pulsación como el criterio de inversión; las diferencias no pueden atribuirse únicamente a habilidad de pulsación. No simula fatiga, navegación humana, errores o tiempo leyendo fichas.

## Expansión de referencia

| Edificios comprados | Política equilibrada | Precio del edificio |
| --- | --- | --- |
| 10 | 0 h 03 min 26 s | 26214400 |
| 20 | 0 h 41 min 20 s | 27487790694400 |
| 30 | 1 h 39 min 28 s | 28823037615171174400 |
| 40 | 2 h 34 min 44 s | 30223145490365729367654400 |

## Bloqueos y saltos registrados

- Las tres políticas compran los 40 dentro de 2–3 horas simuladas, sin errores, saldo artificial o necesidad de ingresos offline.
- Ninguna registra dos expansiones en el mismo segundo. Los precios crecen ×4, sin un salto especial al cambiar de distrito.
- Hay tramos tardíos de varios minutos sin inversión: el máximo es 362 segundos en la política conservadora; el mayor intervalo entre edificios es 389 segundos. No son bloqueos matemáticos (la producción permite seguir), pero sí un riesgo de ritmo para un prototipo todavía sin minijuegos. Se deben evaluar en playtesting; no se declara el equilibrio comercial terminado.
- La política equilibrada compra los primeros diez edificios en pocos minutos y el resto más despacio. El crecimiento temprano de las mejoras de sede contribuye a esa diferencia. No se han modificado silenciosamente las reglas de fase 2 para corregirla.
- Los diez primeros negocios producen el **27.95 %** del ingreso automático en la captura final equilibrada; la prima de expansión conserva su utilidad.
- Los IPS informativos truncan cada tasa a milésimas. El abono de cada ciclo se calcula con enteros exactos y no depende del indicador redondeado.
- El estado solo vive durante la sesión; la simulación no prueba guardado ni carga.

## Reproducir

Importar primero con `godot --headless --editor --import --path . --quit`. Desde la raíz del proyecto:

```sh
godot --headless --path . --script res://tests/progress_simulation.gd -- clicks=2 horizon=180 output=user://progress-balanced.json
godot --headless --path . --script res://tests/progress_simulation.gd -- clicks=1 horizon=120 output=user://progress-conservative.json
godot --headless --path . --script res://tests/progress_simulation.gd -- clicks=3 horizon=300 output=user://progress-active.json
```

Los JSON y CSV adjuntos contienen cada una de las 40 compras, su segundo, intervalo, precio, saldo y tasa automática. BUSINESS_BALANCE.csv enumera los 40 negocios y costes base. El script termina con código 1 si no alcanza el 40 en cinco horas simuladas o registra una operación inesperadamente fallida. Estos tiempos son resultados medidos por la simulación, no pruebas manuales de sesiones completas.
