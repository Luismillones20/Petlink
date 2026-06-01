## Problemas detectados al compilar APK Flutter

### Contexto

* Flutter: 3.44.1 (stable)
* Android SDK configurado correctamente.
* Gradle y Android Toolchain ya funcionan.
* El fallo actual proviene del código fuente de la aplicación.

### Error 1: Incompatibilidad de lucide_icons_flutter

Error:

The class 'IconData' can't be extended outside of its library because it's a final class.

Archivo afectado:

../../AppData/Local/Pub/Cache/hosted/pub.dev/lucide_icons_flutter-1.3.0/lib/src/icon_data.dart

Posible causa:

* La versión de `lucide_icons_flutter` utilizada no es compatible con Flutter 3.44.
* Flutter ahora trata `IconData` como clase final y el paquete intenta extenderla.

Acción:

* Revisar la dependencia `lucide_icons_flutter` en pubspec.yaml.
* Actualizar a una versión compatible o migrar a otro paquete de iconos Lucide.

---

### Error 2: Iconos Lucide inexistentes

Errores:

LucideIcons.home
LucideIcons.alertTriangle

Archivos afectados:

* lib/main.dart
* lib/screens/schedule_screen.dart

Posible causa:

* Cambio de nombres en versiones recientes del paquete Lucide.

Acción:

* Verificar los nombres correctos de los iconos en la versión instalada.
* Reemplazar referencias obsoletas.

---

### Error 3: FontWeight.black no encontrado

Errores múltiples:

Member not found: 'black'

Archivos afectados:

* lib/screens/camera_screen.dart
* lib/screens/schedule_screen.dart
* lib/screens/alerts_screen.dart
* lib/screens/statistics_screen.dart

Acción:

* Reemplazar todas las apariciones de:

FontWeight.black

por:

FontWeight.w900

o el peso equivalente recomendado por la versión actual de Flutter.

---

### Error 4: Uso incorrecto de const con variable

Error:

Not a constant expression.

Archivo:

lib/screens/camera_screen.dart

Código problemático:

const Offset(len, size.height)

Causa:

* `len` es una variable y no puede utilizarse dentro de una expresión const.

Acción:

* Cambiar a:

Offset(len, size.height)

---

### Resultado actual

La compilación falla en:

:app:compileFlutterBuildRelease

Mensaje final:

Target kernel_snapshot_program failed: Exception

BUILD FAILED

El problema ya no está relacionado con Android SDK, Gradle ni Flutter Toolchain. Los errores restantes son incompatibilidades de código y dependencias con Flutter 3.44.
