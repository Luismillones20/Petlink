# PetLink Mobile (Flutter)

Este proyecto contiene la aplicación móvil de **PetLink** (Panel de Control IoT y Salud de Mascotas) migrada a Flutter. Permite el monitoreo de telemetría del dispensador inteligente en tiempo real y la interacción con la cámara ESP32-CAM y la IA de Gemini.

---

## 📋 Requisitos Previos Generales

Para ejecutar y compilar esta aplicación en cualquier sistema operativo, necesitas tener instalado el SDK de Flutter.
- [Guía Oficial de Instalación de Flutter](https://docs.flutter.dev/get-started/install)

---

## 🍎 Guía de Instalación y Compilación para macOS (Mac)

macOS te permite compilar la aplicación tanto para **Android (APK)** como para **iOS**. Sigue estos pasos detallados desde tu terminal en Mac:

### 1. Preparación del Entorno en Mac

1. **Instalar Homebrew** (si no lo tienes):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Instalar Flutter SDK:**
   Descarga el SDK desde la web oficial de Flutter para tu procesador (Intel o Apple Silicon M1/M2/M3) o usa Homebrew:
   ```bash
   brew install --cask flutter
   ```

3. **Verificar dependencias de Flutter:**
   Ejecuta el doctor para verificar qué componentes del sistema te faltan:
   ```bash
   flutter doctor
   ```

---

### 🤖 Compilar para Android (APK) en macOS

1. **Instalar las herramientas de Android:**
   - Descarga e instala [Android Studio para Mac](https://developer.android.com/studio).
   - Abre Android Studio > SDK Manager y asegúrate de tener instalado el SDK de Android y las **Android SDK Command-line Tools**.
   
2. **Aceptar las licencias en Mac:**
   ```bash
   flutter doctor --android-licenses
   ```

3. **Compilar el APK de producción:**
   Asegúrate de estar en la carpeta `petlink_flutter` y ejecuta:
   ```bash
   # 1. Obtener dependencias
   flutter pub get

   # 2. Compilar APK inyectando las credenciales de tu archivo .env seguro
   flutter build apk --release --dart-define-from-file=../.env
   ```
   El APK compilado se guardará en:
   `build/app/outputs/flutter-apk/app-release.apk`

---

### 🍏 Ejecutar y Compilar para iOS en macOS

Para poder compilar y probar la aplicación en iOS (emulador o iPhone físico), necesitas una Mac con Xcode instalado.

1. **Instalar Xcode y herramientas CLI:**
   - Descarga Xcode desde la Mac App Store.
   - Configura las herramientas CLI ejecutando en tu terminal:
     ```bash
     sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
     sudo xcodebuild -runFirstLaunch
     ```

2. **Instalar CocoaPods (gestor de dependencias de iOS):**
   ```bash
   brew install cocoapods
   ```

3. **Preparar y compilar para iOS:**
   Ejecuta los siguientes comandos desde la carpeta `petlink_flutter`:
   ```bash
   # 1. Descargar dependencias de Flutter
   flutter pub get

   # 2. Descargar y compilar las dependencias nativas de iOS (Podfile)
   cd ios
   pod install
   cd ..

   # 3. Compilar la aplicación para iOS de producción inyectando el .env
   flutter build ios --release --dart-define-from-file=../.env
   ```
   *(Nota: Para instalarlo en un iPhone físico de pruebas, requerirás abrir la carpeta `ios/Runner.xcworkspace` en Xcode y configurar tu cuenta de Apple Developer en la sección "Signing & Capabilities").*

---

## 🛠️ Estructura del Proyecto

- `lib/main.dart`: Punto de entrada, configuración del Provider para estado global, Theme (modo oscuro/claro) y barra de navegación inferior.
- `lib/state/app_state.dart`: Lógica que simula la recepción de eventos MQTT (consumo de comida, alertas) mediante `ChangeNotifier`.
- `lib/screens/`: Contiene las cinco pantallas principales (Dashboard, Cámara, Horarios, Alertas, Configuración).
- `lib/models/`: Clases de datos para Alertas y Horarios.
- `lib/widgets/`: Componentes reutilizables como la barra de progreso y el chat de IA.
