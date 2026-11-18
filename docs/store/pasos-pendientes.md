# Pasos pendientes

Todo lo que se puede hacer sin dinero, teléfono ni Mac ya está hecho (ver `docs/ESTADO.md`). Lo que sigue necesita al dueño de la cuenta. Orden recomendado:

## 1. Backup de la keystore (gratis, antes que nada)
Copiar `~/.focus-tycoon/release.keystore` y `~/.focus-tycoon/release.env` a un lugar seguro fuera de esta PC (gestor de contraseñas o disco externo). Sin esa clave no se puede actualizar la app en Play.

## 2. Perfilado en teléfono real (6.2, gratis)
1. En el teléfono: Ajustes › Acerca del teléfono › tocar 7 veces "Número de compilación". Luego Opciones de desarrollador › Depuración USB.
2. Conectar por USB y aceptar la huella de la PC.
3. Instalar y medir:
   ```bash
   adb install -r build/android/focus-tycoon-debug.apk
   adb shell dumpsys meminfo com.focustycoon.game
   adb shell dumpsys gfxinfo com.focustycoon.game
   ```
4. Jugar 5 minutos (mover cámara, colocar objetos, sesión de foco) y anotar PSS total y fps en `docs/ESTADO.md` 6.2.
5. Probar la notificación de fin de foco con el teléfono bloqueado.

## 3. Google Play (6.6 Android, USD 25 una vez)
1. Crear cuenta en https://play.google.com/console (verificación de identidad; cuentas personales nuevas deben hacer una prueba cerrada con 12 testers durante 14 días antes de producción).
2. Crear app "Focus Tycoon", paquete `com.focustycoon.game`.
3. Ficha: copiar `docs/store/listing.es.md` y `docs/store/listing.en.md`. Capturas: sacar del juego en teléfono.
4. Política de privacidad: https://github.com/ilandaniele/focus-tycoon/blob/main/docs/store/privacy.es.md
5. Clasificación de contenido y seguridad de datos: respuestas en `docs/store/listing.*.md`.
6. Subir `build/android/focus-tycoon-release.aab` a Pruebas internas. Aceptar Play App Signing.
7. Monetizar › Productos integrados: crear `premium` y `cosmetic_pack_garden` (no consumibles), con precio.
8. Agregar tu cuenta como tester de licencias y probar compra y restaurar desde el track interno.
9. Para cada versión nueva: subir `version/code` en `export_presets.cfg` (preset "Android AAB") y volver a exportar.

## 4. iOS (6.5, USD 99 por año para publicar)
1. Sin Mac: el workflow "iOS simulator" de GitHub Actions compila y corre el juego en el simulador en cada push a `dev` o `main`. La captura queda en el artifact `ios-simulator` de cada corrida.
2. Para publicar: cuenta Apple Developer, poner el Team ID real en el preset "iOS" de `export_presets.cfg` y firmar. Se puede firmar en CI con certificados guardados como secrets de GitHub, sin Mac propia.
3. Falta código: compras con StoreKit, notificaciones locales para iOS (hoy solo hay Android) y margen de safe area para el HUD bajo la Dynamic Island.

## 5. Opcional
- El email de contacto es público en `docs/store/`. Si preferís, usar una dirección solo para soporte.
