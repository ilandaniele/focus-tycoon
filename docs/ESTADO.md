# Estado del proyecto

**Fase actual:** Hito 5 completo en código (IAP, notificaciones y sync implementados con tests). Sync en producción en Cloudflare. Lo que queda necesita dinero, un teléfono o una Mac.

## Checklist
- [x] Hito 1 — Documentación (01-PRD, 02-GDD)
- [x] Hito 2 — Arquitectura (03-TRD, 04-UX, 05-esquema, 06-plan)
- [x] 3.1 Proyecto Godot, autoloads, runner de tests
- [x] 3.2–3.6 Datos, dominio, persistencia atómica, servicios núcleo
- [x] 3.7 Mundo isométrico (TileMapLayer, placeholders procedurales, cámara táctil, colocación, animales)
- [x] 3.8 Arte vectorial propio: 28 sprites SVG escritos a mano en `art/` (terreno, caminos, 13 objetos, 4 recintos, 5 animales, marcas y sombra), renderizados a `assets/` con `tools/render_art.gd` (ThorVG de Godot, sin dependencias ni costo). Verificado con captura en juego. Los placeholders procedurales quedan como respaldo para claves sin PNG. Los PNG se renderizan a 2x y se cargan a tamaño lógico (nítidos con zoom); el atlas de suelo usa copia a 1x
- [x] 4.1–4.5 Temporizador por timestamps, meditación, recompensas, objetivos, logros, simulación 30 días
- [x] 5.1–5.4 HUD y pantallas, tutorial 6 pasos, audio sintetizado con buses, tienda mock
- [x] 5.5 IAP Android con `addons/GodotGooglePlayBilling` 3.3.0 (MIT): `GooglePlayStore` con compra asíncrona, acknowledge y restore idempotente. Falta: crear productos `premium` y `cosmetic_pack_garden` en Play Console (cuenta USD 25) y probar en track interno. iOS sin hacer (requiere Mac)
- [x] 5.6 Notificaciones locales Android con `addons/NotificationSchedulerPlugin` 6.0 (MIT): canal propio, permiso POST_NOTIFICATIONS al primer uso, recordatorio diario con intervalo de 24 h, icono monocromo `ic_default_notification`. Falta: probar en teléfono
- [x] 5.7 Sync en Cloudflare (reemplaza Supabase): Worker `focus-tycoon-api` + D1 `focus-tycoon` en `server/`, desplegado en https://focus-tycoon-api.ilandaniele.workers.dev. Jugador anónimo con token aleatorio (solo se guarda el hash SHA-256), subida idempotente del ledger (`UNIQUE(player_id, idem_key)`, `ON CONFLICT DO NOTHING`), saldo por triggers con clamp a 0, rate limit por IP y por jugador, Zod, headers de seguridad, errores genéricos con `request_id`. 25 tests de integración con D1 local (`npm test`). Cliente Godot `SyncApiClient`: alta en el primer push, reintento con las mismas claves, si el token da 401 se borra la sesión y se crea otra. Smoke en producción OK (alta, push, duplicado ignorado, saldo, 401). Fuera de alcance v1: bajar datos a otro dispositivo, sesiones y parque
- [x] 6.1 CI GitHub Actions (`.github/workflows/ci.yml`: import, tests, smoke, y job `server` con typecheck y tests del Worker) verde en `dev`. Repo público: https://github.com/ilandaniele/focus-tycoon
- [ ] 6.2 Perfilado en dispositivo
- [x] 6.3 Checklist de accesibilidad completo. Verificado con capturas a 100 % y 150 %. Supuesto: las etiquetas de la barra inferior no escalan (como la tab bar de iOS) porque a 150 % se cortaban; el resto de la UI sí escala
- [x] 6.4 Export Android con Gradle: APK debug y AAB release (preset `Android AAB`) firmado con keystore de release en `~/.focus-tycoon/` (fuera del repo, contraseña por variables de entorno). Icono propio en `assets/icon/`
- [ ] 6.5 Export iOS (requiere Mac)
- [ ] 6.6 Publicación (cuentas de desarrollador con costo). Textos listos en `docs/store/`: ficha es/en, respuestas de clasificación y seguridad de datos, política de privacidad es/en, publicada en https://github.com/ilandaniele/focus-tycoon/blob/main/docs/store/privacy.es.md y https://github.com/ilandaniele/focus-tycoon/blob/main/docs/store/privacy.en.md. Perfil › Ajustes muestra el ID de jugador (con botón copiar) y "Borrar mis datos del servidor" (`DELETE /v1/players`, borra jugador, saldo y ledger por cascada). Cada alta de jugador borra en el mismo batch de D1 a los jugadores sin actividad en 730 días (sin cron: el plan gratuito permite 5 por cuenta y están usados) (índice `player_resources_updated_at`). Falta: cuentas de desarrollador
- [x] 6.7 Revisión de seguridad del Worker: 0 críticos/altos. Arreglado: `client_at` sin fracciones (evita filas gigantes), límite de push bajado a 6/min por jugador, límite por IP (60/min) antes de tocar D1 en todas las rutas, alta limitada por prefijo IPv6 /64, tamaño del body medido en bytes y rechazo por `Content-Length`, `X-Request-Id` en todas las respuestas y log de errores 4xx. Riesgo aceptado: el token se guarda sin cifrar en `user://sync_session.json` (solo protege un backup, Android con `allowBackup=false`). Riesgo residual: muchos jugadores anónimos desde muchas IPs pueden agotar la cuota diaria gratuita de escrituras de D1 (solo corta el backup ese día); mitigación futura: Play Integrity / App Attest
- [x] 6.8 Pulido: fuente Nunito (OFL) e íconos vectoriales en HUD; juice (pop al colocar, confeti, sonido pop sintetizado, fades de pantalla y modal, flash en contadores; respeta reducir movimiento); animales animados con tiras idle (4 frames) y walk (6 frames) generadas desde los SVG por `tools/animal_strips.gd` (grupos `body`/`head`/`legs_a`/`legs_b`); contenido nuevo: foca, zorro, cebra, tulipanes, roca con musgo y estanque. Desvío del GDD: la caminata usa una tira lateral con `flip_h`, no las cuatro direcciones isométricas
- [x] 6.9 Rediseño de arte: todo el mundo (terreno, caminos, 25 objetos, 8 animales) se renderiza desde modelos 3D de Kenney CC0 ("Nature Kit", "Cube Pets") con cámara isométrica ortográfica (`tools/render_models.gd`, specs en `tools/model_specs.gd`); tiras idle/walk de 8 frames desde las animaciones del modelo. Especies renombradas para usar los modelos disponibles: capybara→beaver, red_panda→panda, seal→polar_bear, zebra→giraffe (mismos costos y niveles). Ocho plantas nuevas: helecho, seto, maceta (nivel 1), girasol, lavanda (2), cactus (3), bambú (4), palmera (5). Los SVG de `art/` quedan solo para UI y FX

## Verificación actual
- `godot --path . --headless -s res://tests/run_tests.gd`: 191 tests, 0 fallos, 0 `SCRIPT ERROR`. El runner cuenta como fallo un script de test que no compila y un test que dispara un error de script en ejecución (un `Logger` registrado con `OS.add_logger` los cuenta).
- `cd server && npm run typecheck && npm test`: 33 tests, 0 fallos.
- `godot --path . --headless --quit-after 120`: 0 `SCRIPT ERROR`.

## Desvíos respecto de 03-TRD (aditivos)
- `ParkWorld.adopt_resolved(result)` señal extra para resultado de adopción por toque.
- `FocusService.start` / `MeditationService.start` devuelven `{ok, error}`.
- `player.uid_seq` persistido para que `new_uid` no repita ids.
- `StoreService.purchased` se emite solo en un otorgamiento nuevo; señal extra `purchase_failed(error)`; compra asíncrona devuelve `{ok: true, pending: true}`.
- `Ledger.entries()` expone el log para el sync. `progress.synced_keys` guarda las claves ya subidas.
- Códigos de error extra: `store_unavailable`, `invalid_item`, `invalid_species`, `invalid_expansion`, `invalid_uid`, `invalid_minutes`, `invalid_exercise`, `not_active`, `unknown_product`, `unsupported`.

## Export Android
- Preset versionado en `export_presets.cfg` (incluye `data/*.json` y `locale/*.json`; excluye `tests/` y `docs/`).
- `project.godot` activa `import_etc2_astc` (requerido por Android).
- Toolchain local: JDK 17 (Microsoft OpenJDK), Android SDK en `%LOCALAPPDATA%/Android/Sdk` (platform-tools, build-tools 36.1.0, android-36), templates 4.7.2, keystore debug en `%APPDATA%/Godot/keystores/debug.keystore`.
- Gradle build activo; `android/` se genera con `--install-android-build-template` y está en `.gitignore`.
- Keystore de release: `~/.focus-tycoon/release.keystore` (alias `focustycoon`) y `~/.focus-tycoon/release.env`. **Hacer backup**: perderla impide actualizar la app en Play.

## Export Web
- Preset "Web" en `export_presets.cfg`: un solo hilo, sin GDExtension, salida en `build/web/` (gitignored). Templates `web_nothreads_debug/release.zip` 4.7.2 instalados en `%APPDATA%/Godot/export_templates/4.7.2.stable`.
- Probado en navegador local: arranque, tutorial, catálogo, colocación y guardado en IndexedDB tras recargar.
- Compras usan `MockStore` y recordatorios `NullNotificationBackend` (no hay plugins en web).
- El Worker responde CORS solo a `ALLOWED_ORIGINS` (`server/wrangler.jsonc`). Publicado en https://focus-tycoon.ilandaniele.workers.dev (Workers static assets, plan gratuito; config en `tools/web/wrangler.jsonc`). `index.wasm` se parte en trozos de 20 MiB por el límite de 25 MiB por archivo.

## Comandos
Ver `README.md`.
