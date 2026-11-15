# 06 — Plan de implementación por hitos

Cada hito termina con: tests headless en verde, smoke boot sin errores, commit convencional y `docs/ESTADO.md` actualizado.

## Hito 1 — Documentación (FASE 1) ✅
PRD + riesgos (01), GDD + core loop + economía + progresión + arte (02).
**Criterio:** docs sin TBD; toda cifra de economía figura en 02 y luego en `data/*.json`.

## Hito 2 — Arquitectura (FASE 2) ✅
TRD + árbol de escenas + carpetas + contratos (03), UX (04), esquema local/remoto + persistencia (05).
**Criterio:** cada tabla del modelo pedido existe en 05; cada autoload de 03 tiene firma.

## Hito 3 — Vertical slice: núcleo + parque (FASE 3)
| # | Tarea | Archivos | Criterio de término |
|---|---|---|---|
| 3.1 | Proyecto Godot, autoload list, runner de tests | `project.godot`, `tests/run_tests.gd`, `tests/test_case.gd` | `godot --headless -s res://tests/run_tests.gd` sale con 0 |
| 3.2 | Datos de balance | `data/*.json` | Valores = tablas de 02 (test `test_config`) |
| 3.3 | Dominio: Ledger, RewardCalculator, Progression, DayKey | `scripts/domain/` | Tests de idempotencia, fondos insuficientes, tope diario, niveles |
| 3.4 | Dominio: ParkModel | `scripts/domain/park_model.gd` | Tests de solape, límites, área bloqueada, recinto con animales |
| 3.5 | SaveCodec + SaveStore | `scripts/domain/save_codec.gd`, `scripts/persistence/save_store.gd` | Tests de roundtrip, checksum corrupto → backup, tmp huérfano |
| 3.6 | Autoloads Config/GameState/Economy/ParkService | `scripts/autoload/` | Test de integración: comprar, colocar, guardar, recargar = idéntico |
| 3.7 | Mundo: TileMapLayer iso, ArtRegistry, cámara, colocación, animales | `scripts/world/`, `scenes/world/` | Smoke boot sin errores; colocar objeto con mouse en escritorio |

## Hito 4 — Temporizador, meditación, recompensas (FASE 4)
| # | Tarea | Criterio |
|---|---|---|
| 4.1 | FocusTimer (timestamps, ciclos, descansos, anomalía de reloj) | Tests: fondo pasado el fin, varios ciclos atrasados, pausa excluida, reloj atrás |
| 4.2 | FocusService + ciclo de vida de la app | Test integración: start → avanzar FakeClock → recompensa una vez tras dos `tick` y una recarga |
| 4.3 | MeditationService + fases de respiración | Tests de `phase_at` y mínimo 60 s |
| 4.4 | Objetivos diarios, logros | Tests de determinismo y reclamo único |
| 4.5 | Simulación de balance 30 días | Test: ingreso diario ≤ tope; nivel 7 no antes del día 7 en perfil medio; sesiones cortas no rinden más por minuto |

## Hito 5 — Integración, tutorial, estadísticas, monetización (FASE 5)
| # | Tarea | Criterio |
|---|---|---|
| 5.1 | HUD + pantallas Foco/Meditación/Catálogo/Stats/Perfil | Flujo manual completo en escritorio; ES/EN conmutables |
| 5.2 | Tutorial 6 pasos | Primer arranque lo muestra; saltar lo cierra; regalo inicial una vez |
| 5.3 | AudioService (ambientes sintetizados, buses) | Volúmenes independientes persisten |
| 5.4 | StoreService mock + pestaña Premium | Comprar mock otorga entitlement `premium`; restaurar funciona |
| 5.5 | Integración IAP real **(requiere confirmación R4)** | Compra sandbox en dispositivo |
| 5.6 | Notificaciones locales **(requiere confirmación R3)** | Aviso al terminar con app en segundo plano |
| 5.7 | Sync Supabase **(requiere confirmación R6)** | Transacción idempotente reintentada no duplica saldo |

## Hito 6 — Calidad y publicación (FASE 6)
| # | Tarea | Criterio |
|---|---|---|
| 6.1 | CI GitHub Actions (import + tests + smoke) | Badge verde en `dev` |
| 6.2 | Perfilado en dispositivo Android gama media | 60 fps con 150 objetos/20 animales; ≤ 5 %/h batería en sesión con pantalla apagada |
| 6.3 | Accesibilidad | Checklist de 04 completo, prueba con escala 150 % |
| 6.4 | Export Android (AAB firmado) | Instala y corre en dispositivo; requiere Android SDK + JDK 17 + export templates 4.7.2 |
| 6.5 | Export iOS | Proyecto Xcode generado; compilación en macOS **(requiere Mac)** |
| 6.6 | Fichas de tienda, política de privacidad, clasificación de contenido | **Cuentas de desarrollador: costo, preguntar** |

## Paralelización
3.3/3.4/3.5 independientes. 3.7 y 5.1 dependen solo de los contratos de 03. 5.5/5.6/5.7 bloqueadas por confirmación del usuario.
