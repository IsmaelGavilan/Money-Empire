# Validación de fase 3

Godot 4.6.3.stable.official.7d41c59c4, Linux headless. Antes de modificar la fase 2 se ejecutaron sus 590 comprobaciones: correctas.

Validación final sobre una copia limpia sin .godot ni .git, importada desde cero. El proceso de importación reconoce todas las clases y escenas. docs/.gdignore evita que los informes CSV generen recursos de traducción.

| Comprobación | Resultado |
| --- | --- |
| Importación limpia | Código 0, sin errores de scripts |
| Base | 32 comprobaciones, 0 fallos, código 0 |
| Fase 2 | 558 comprobaciones, 0 fallos, código 0 |
| Fase 3 | 1.446 comprobaciones, 0 fallos, código 0 |
| Menú, 120 frames | Código 0 |
| Ciudad, 120 frames | Código 0 |
| Gestión, 120 frames | Código 0 |
| Simulación activa/equilibrada/conservadora | 40 compras y 0 errores cada una |
| Espacios finales, todos los archivos de texto | 0 |
| git diff --check | Correcto |

Las suites y arranques finales se inspeccionaron para detectar ERROR, WARNING y errores Unicode: ninguno. El editor continúa registrando cuatro líneas de error por sus intentos de abrir el socket de depuración que bloquea el sandbox; no corresponden a fallos del proyecto y se conservan en import.log.

Los datos de pruebas se aislaron en /workspace/work/xdg-test. TEST_PLAN y ECONOMY_SIMULATION detallan cobertura, políticas y límites. No se ha probado visualmente, con ratón/mando físicos, en Windows ni con SDKs. La simulación no equivale a una sesión humana y registra esperas tardías que requieren playtesting.
