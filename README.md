# PetLink - Panel de Control IoT y Salud de Mascotas

¡Bienvenido a **PetLink**! Este es un proyecto IoT diseñado para el cuidado inteligente de tu mascota (utilizando Arduino Mega, ESP32-CAM, sensor de peso HX711 y un zumbador/botón físico).

El repositorio está compuesto por dos aplicaciones complementarias:
1.  **PetLink Web (React + Vite):** Panel de control web local interactivo, optimizado y responsivo.
2.  **PetLink Mobile (Flutter):** Aplicación móvil para Android enfocada en el monitoreo y las analíticas de salud en tiempo real.

Tanto la app Web como la app Móvil cuentan con el módulo avanzado de **Estadísticas de Ingesta y Diagnóstico de Salud** (velocidad de ingesta, calorías metabólicas, consumo por kilogramo de peso e índice de hidratación diaria).

---

## 🌐 1. Cómo ejecutar la aplicación WEB (Local)

La aplicación web está construida con **React + Vite**. Para correrla localmente sin alterar la configuración global de tu sistema (cero instalaciones pesadas), sigue estos pasos:

### Opción A: Ejecución Directa (Recomendada en Windows)
En la raíz del proyecto encontrarás el script portable **`run.bat`**:
1.  Abre la carpeta del proyecto en tu explorador de archivos.
2.  Haz **doble clic** sobre el archivo **`run.bat`**.
3.  El script configurará automáticamente una versión portable de Node.js v22 y levantará el servidor de desarrollo.
4.  Abre tu navegador en: **[http://localhost:5173/](http://localhost:5173/)**

### Opción B: Ejecución Manual desde la Terminal
Si prefieres correrlo de forma manual en tu PowerShell/CMD, abre una terminal en la raíz del proyecto y ejecuta:
```powershell
# 1. Configurar la ruta temporal hacia la versión portable de Node.js v22
$env:PATH = "c:\Users\marco\Petlink\node-v22.12.0-win-x64;" + $env:PATH

# 2. Levantar el servidor de desarrollo
.\node-v22.12.0-win-x64\npm.cmd run dev
```

---

## 📱 2. Cómo ejecutar y compilar la aplicación MÓVIL (Flutter)

La aplicación móvil está construida con **Flutter**. Gracias a su soporte multiplataforma, puedes compilarla para **Android (APK)** y también para **iOS** (si estás en macOS).

### 📋 Requisitos Previos Generales
1. Instala el SDK de Flutter en tu sistema local siguiendo la [Guía Oficial de Flutter](https://docs.flutter.dev/get-started/install).
2. Asegúrate de agregar la ruta `/bin` de tu instalación de Flutter a las **Variables de Entorno (PATH)** de tu máquina.

---

### 💻 Guía de Compilación en Windows (Android APK)

1. Abre tu terminal de PowerShell en la subcarpeta:
   ```powershell
   cd petlink_flutter
   ```
2. Si es la primera vez, genera los archivos del proyecto Android:
   ```powershell
   flutter create . --platforms=android
   ```
3. Descarga las dependencias del proyecto:
   ```powershell
   flutter pub get
   ```
4. Genera el APK ejecutable inyectando de forma segura la API Key de tu `.env` a nivel raíz:
   ```powershell
   flutter build apk --release --dart-define-from-file=../.env
   ```
   El APK compilado se guardará en: `petlink_flutter/build/app/outputs/flutter-apk/app-release.apk`

---

### 🍎 Guía de Instalación y Compilación en macOS (Mac)

macOS permite compilar y ejecutar tanto para **Android** como para **iOS**:

#### A. Preparación del Entorno en Mac
1. **Instalar Homebrew** (si no está instalado):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
2. **Instalar Flutter SDK:**
   ```bash
   brew install --cask flutter
   ```
3. **Verificar el sistema:**
   ```bash
   flutter doctor
   ```

#### B. Compilar para Android (APK) en Mac
1. Descarga e instala [Android Studio](https://developer.android.com/studio) para Mac.
2. Abre Android Studio > SDK Manager e instala el SDK y las **Android SDK Command-line Tools**.
3. Acepta las licencias en tu terminal:
   ```bash
   flutter doctor --android-licenses
   ```
4. Compila el APK inyectando las credenciales de tu `.env`:
   ```bash
   cd petlink_flutter
   flutter pub get
   flutter build apk --release --dart-define-from-file=../.env
   ```

#### C. Compilar para iOS en Mac (Requiere Xcode)
1. Instala Xcode desde la App Store de Mac.
2. Configura las herramientas CLI de Xcode:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```
3. Instala CocoaPods (gestor de dependencias de iOS):
   ```bash
   brew install cocoapods
   ```
4. Prepara y compila la app móvil para iOS:
   ```bash
   cd petlink_flutter
   flutter pub get
   cd ios
   pod install
   cd ..
   flutter build ios --release --dart-define-from-file=../.env
   ```
   *(Nota: Abre `ios/Runner.xcworkspace` en Xcode para configurar tu cuenta en "Signing & Capabilities" si deseas probarlo en un iPhone físico).*

---


## 📊 Características Destacadas de Estadísticas y Salud
-   **HX711 Ingestion Speed:** Mide la velocidad de alimentación de Max (óptima: 1.5 a 2.5 g/s) para prevenir torsiones estomacales.
-   **Active Hydration Index:** Compara los mL de agua consumidos contra el peso corporal (`mL/kg`) evaluando su hidratación en tiempo real.
-   **Monthly Logs:** Gráfico de barras que compara de forma semestral los kg de comida y L de agua consumidos.
-   **Consejos de Salud por IA:** Recomendaciones dinámicas de alimentación de acuerdo con el peso, actividad e ingesta calórica de tu mascota.
