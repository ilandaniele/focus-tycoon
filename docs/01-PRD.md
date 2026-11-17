# 01 — PRD: Focus Tycoon

## Resumen
Focus Tycoon es un juego móvil (iOS/Android) que combina un temporizador de concentración y ejercicios breves de meditación con la construcción de un zoológico isométrico cozy. El tiempo real dedicado a sesiones se convierte en recursos para construir, decorar y adoptar animales. El juego premia la constancia sin castigar descansos, ausencias ni sesiones interrumpidas.

## Problema
Las apps de productividad tipo Pomodoro pierden al usuario cuando la motivación inicial baja. Los juegos de gestión, en cambio, suelen fomentar el uso compulsivo. Focus Tycoon usa la progresión del parque como recompensa visible del hábito, con límites diarios que desincentivan el exceso.

## Objetivos y métricas de éxito (post-lanzamiento)
| Métrica | Objetivo MVP |
|---|---|
| Retención D7 | ≥ 25 % |
| Sesiones de foco completadas por usuario activo/semana | ≥ 5 |
| % usuarios que inician su primera sesión en el primer uso | ≥ 70 % |
| Tiempo desde abrir la app hasta iniciar sesión (usuario recurrente) | ≤ 3 toques, ≤ 5 s |
| Crash-free sessions | ≥ 99.5 % |
| Conversión a premium | 2–4 % (referencia de mercado, no compromiso) |

## Usuarios
- **Estudiante** (16–25): bloques de estudio de 25–50 min, quiere ver progreso.
- **Profesional remoto** (25–45): bloques de trabajo profundo de 45–90 min, valora estadísticas.
- **Buscador de bienestar**: pausas conscientes y respiración de 1–5 min.

No hay roles: un único jugador por dispositivo. La cuenta online (Cloudflare Worker + D1, anónima) es opcional y posterior al MVP jugable.

## Funciones MVP

Prioridad: P0 = sin esto no hay producto; P1 = entra en MVP pero puede llegar en el último hito.

### Productividad
| # | Función | Prio | Criterio de aceptación (dado / cuando / entonces) |
|---|---|---|---|
| P1 | Presets 15/25/45/50/90 min | P0 | Dado el parque, cuando toco Foco y un preset, entonces el temporizador arranca con esa duración en ≤ 2 toques más. |
| P2 | Sesión personalizada | P0 | Dado el selector, cuando elijo entre 5 y 180 min, entonces la sesión usa esa duración; valores fuera de rango se ajustan al límite. |
| P3 | Modos estudio/trabajo/lectura/proyecto | P0 | Cada sesión guarda su modo; las estadísticas se pueden filtrar por modo. |
| P4 | Pausas programables | P1 | Dado un plan de N ciclos con descanso de X min, cuando termina un ciclo, entonces empieza el descanso y luego el siguiente ciclo sin tocar nada. La pausa manual congela el tiempo y no cuenta como foco. |
| P5 | Sonidos ambientales opcionales | P1 | Puedo elegir lluvia, bosque, ruido marrón o silencio; volumen independiente de efectos y música. |
| P6 | Registro completadas/interrumpidas | P0 | Cada sesión termina en `completed` o `interrupted` con minutos efectivos; ambas quedan en historial. |
| P7 | Estadísticas diarias y semanales | P0 | Veo minutos de foco por día de los últimos 7 días, total semanal, sesiones completadas y desglose por modo. |
| P8 | Persistencia por timestamps | P0 | Dado un temporizador corriendo, cuando la app pasa a segundo plano o se cierra y vuelvo después del fin, entonces la sesión figura completada con la hora de fin correcta y la recompensa se acredita una sola vez. |
| P9 | Meditación y respiración | P0 | Puedo hacer respiración 4-4 (caja), 4-7-8, coherente 5-5 y atención plena guiada de 3/5/10 min con animación de respiración. |
| P10 | Recordatorios opcionales | P1 | Desactivados por defecto; si los activo, recibo un aviso al terminar la sesión y un recordatorio diario a la hora elegida. Requiere plugin (ver riesgos R3). |

### Juego
| # | Función | Prio | Criterio |
|---|---|---|---|
| G1 | Mapa isométrico 24×24 con área inicial 12×12 | P0 | El parque carga con el área inicial desbloqueada y el resto visible como terreno bloqueado. |
| G2 | Cuadrícula y colocación | P0 | Con un objeto elegido, el fantasma sigue al dedo, se pinta verde/rojo según validez y se confirma con un toque. |
| G3 | Caminos, árboles, decoraciones, recintos | P0 | Catálogo con al menos 3 caminos/suelos, 4 árboles/plantas, 4 decoraciones, 4 recintos (uno por bioma). |
| G4 | Cinco especies | P0 | Conejo, pingüino, capibara, panda rojo, elefante; cada una requiere un recinto de su bioma. |
| G5 | Animación idle y desplazamiento | P0 | Cada animal alterna idle (respiración/rebote) y paseo hacia puntos aleatorios dentro de su recinto. |
| G6 | Cámara táctil | P0 | Arrastrar con un dedo desplaza, pellizcar hace zoom entre 0.5× y 2×, con límites del mapa. Rueda y arrastre con mouse en escritorio. |
| G7 | Monedas, puntos de naturaleza, XP | P0 | Visibles en el HUD y actualizados al instante tras cada transacción. |
| G8 | Tienda interna | P0 | Ítems bloqueados muestran el nivel requerido; comprar descuenta recursos exactamente una vez. |
| G9 | Niveles y desbloqueos | P0 | Subir de nivel muestra los ítems desbloqueados. 15 niveles en MVP. |
| G10 | Guardado y restauración | P0 | Cerrar y abrir la app restaura objetos, animales, recursos y sesión activa idénticos. |
| G11 | Tutorial interactivo | P0 | Primer uso: guía de 6 pasos (bienvenida, primera sesión o regalo inicial, abrir catálogo, plantar árbol, construir recinto, adoptar conejo). Se puede saltar. |
| G12 | Evolución del zoológico | P1 | Pantalla de perfil con nivel, especies adoptadas (colección), objetos colocados y una línea de tiempo de hitos. |

### Monetización
| # | Función | Prio | Criterio |
|---|---|---|---|
| M1 | Premium (pago único) | P1 | Desbloquea bioma cosmético extra, sonidos adicionales y estadísticas extendidas. Nunca recursos ni velocidad. |
| M2 | Packs cosméticos | P1 | Decoraciones exclusivas sin efecto en economía. |
| M3 | Restaurar compras | P1 | Botón visible en Perfil. |

## Fuera de alcance (MVP)
Biomas adicionales, visitantes con navegación, edificios comerciales, reputación, eventos estacionales, misiones encadenadas, personalización avanzada, colecciones extendidas, sincronización multiplataforma, cuentas online obligatorias, anuncios, social/rankings, widgets, Apple Watch/Wear OS, Live Activities.

## Requisitos no funcionales
- **Rendimiento:** 60 fps en gama media (Snapdragon 6xx / iPhone 11) con 150 objetos y 20 animales; ≤ 30 fps en reposo del parque (`low_processor_mode` en pantallas de UI); arranque en frío ≤ 3 s.
- **Batería:** durante una sesión de foco la pantalla del parque baja a render bajo demanda; el temporizador no depende de `_process` para medir tiempo.
- **Persistencia:** escritura atómica; nunca se pierde más que la última acción ante un cierre forzado.
- **Accesibilidad:** tamaños táctiles ≥ 48 dp, textos escalables (100–150 %), contraste AA en UI, sin depender solo del color (fantasma válido/inválido con ícono), vibración opcional, reducir movimiento.
- **Idiomas:** español e inglés, detectado del sistema, cambiable en Perfil.
- **Privacidad:** sin cuenta ni datos personales por defecto. Todo local. Sin SDK de tracking en MVP.
- **Bienestar:** sin textos médicos; la meditación se presenta como bienestar general. La app nunca afirma verificar concentración real.

## Supuestos (decididos sin entrevista)
1. Motor: Godot 4.7.2 estable (último disponible en winget al 2026-11-15), GDScript tipado, renderer Compatibility (mejor soporte móvil gama baja).
2. Orientación vertical (portrait), resolución base 720×1280, stretch `canvas_items` + aspect `expand`.
3. Un jugador local por dispositivo; el sync en la nube llega después del vertical slice y es opcional.
4. Moneda premium inexistente: el premium es pago único + cosméticos, para evitar pay-to-win.
5. Especies originales con diseño propio (no inspiradas en franquicias).
6. Desarrollo en Windows: Android se compila aquí; **iOS requiere macOS con Xcode** (riesgo R5).

## Riesgos
| ID | Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|---|
| R1 | Manipulación del reloj del dispositivo para acelerar sesiones | Media | Medio | Recompensa limitada a duración planificada; detección de reloj hacia atrás; tope diario con rendimiento decreciente; validación server-side cuando el servidor tenga autoridad (hoy solo respalda el ledger). Se documenta que offline no es 100 % evitable. |
| R2 | El SO mata la app en segundo plano | Alta | Alto | Todo el estado del temporizador se deriva de timestamps persistidos al iniciar/pausar; reconciliación al volver. |
| R3 | Notificaciones locales no son nativas en Godot | Alta | Medio | Requiere plugin no confirmado para 4.7 (Android: plugin AAR propio o comunitario; iOS: plugin `UNUserNotificationCenter`). MVP usa interfaz `NotificationService` con backend nulo en escritorio. **No se instala nada sin confirmación.** |
| R4 | IAP: plugins oficiales `GodotGooglePlayBilling` (Android) y `godot-ios-plugins/inappstore` (iOS) pueden no estar actualizados a 4.7 | Media | Medio | Interfaz `StoreService` con backend mock; verificar compatibilidad antes de integrar. Cuentas de desarrollador cuestan dinero (Apple USD 99/año, Google USD 25 único): **PARAR y preguntar**. |
| R5 | iOS no se puede compilar en Windows | Cierta | Alto | Exportar proyecto Xcode desde Godot y compilar en Mac propio o servicio CI con macOS (costo: preguntar). |
| R6 | Backend remoto sin SDK GDScript oficial | Alta | Bajo | API REST propia en Cloudflare Worker + D1, llamada con `HTTPRequest`; sincronización opcional. |
| R7 | Inflación de recursos | Media | Alto | Economía en JSON + simulación automatizada de 30 días en tests. |
| R8 | Uso compulsivo | Baja | Alto | Tope diario (240 min a tasa completa, luego 50 %, sin recompensa después de 480 min), mensajes de descanso, sin rachas punitivas. |
| R9 | Arte final inexistente | Cierta | Medio | Placeholders procedurales generados en runtime; arte se reemplaza por convención de nombres sin tocar lógica. |
