# Estado del proyecto

**Fase actual:** vertical slice ejecutable (Hitos 3, 4 y 5.1–5.4) completo. Siguiente: decisiones del usuario sobre integraciones bloqueadas y Hito 6.

## Checklist
- [x] Hito 1 — Documentación (01-PRD, 02-GDD)
- [x] Hito 2 — Arquitectura (03-TRD, 04-UX, 05-esquema, 06-plan)
- [x] 3.1 Proyecto Godot, autoloads, runner de tests
- [x] 3.2–3.6 Datos, dominio, persistencia atómica, servicios núcleo
- [x] 3.7 Mundo isométrico (TileMapLayer, placeholders procedurales, cámara táctil, colocación, animales)
- [x] 4.1–4.5 Temporizador por timestamps, meditación, recompensas, objetivos, logros, simulación 30 días
- [x] 5.1–5.4 HUD y pantallas, tutorial 6 pasos, audio sintetizado con buses, tienda mock
- [ ] 5.5 IAP real — **bloqueado: requiere confirmación (GodotGooglePlayBilling / godot-ios-plugins)**
- [ ] 5.6 Notificaciones locales — **bloqueado: requiere confirmación de plugin** (hoy: NullNotificationBackend)
- [ ] 5.7 Sync Supabase — **bloqueado: requiere proyecto Supabase**
- [ ] 6.1 CI GitHub Actions
- [ ] 6.2 Perfilado en dispositivo
- [ ] 6.3 Checklist de accesibilidad completo
- [ ] 6.4 Export Android (Android SDK + JDK 17 + export templates)
- [ ] 6.5 Export iOS (requiere Mac)
- [ ] 6.6 Publicación (cuentas de desarrollador con costo)

## Verificación actual
- `godot --path . --headless -s res://tests/run_tests.gd`: 152 tests, 0 fallos.
- `godot --path . --headless --quit-after 120`: 0 `SCRIPT ERROR`.

## Desvíos respecto de 03-TRD (aditivos)
- `ParkWorld.adopt_resolved(result)` señal extra para resultado de adopción por toque.
- `FocusService.start` / `MeditationService.start` devuelven `{ok, error}`.
- `player.uid_seq` persistido para que `new_uid` no repita ids.
- Códigos de error extra: `invalid_item`, `invalid_species`, `invalid_expansion`, `invalid_uid`, `invalid_minutes`, `invalid_exercise`, `not_active`, `unknown_product`, `unsupported`.

## Pendiente para exportar
- Incluir `locale/*.json` y `data/*.json` en los filtros de recursos no-importados del preset de exportación.

## Comandos
Ver `README.md`.
