# PetLink Flutter Migration

Este proyecto contiene la migración de la aplicación React (Panel de Control IoT para Mascotas) a Flutter.

## Requisitos Previos

Para ejecutar esta aplicación, necesitas tener instalado el SDK de Flutter en tu máquina local.
- [Guía de instalación de Flutter](https://docs.flutter.dev/get-started/install)

## Cómo ejecutar el proyecto

1. Descarga o copia la carpeta `petlink_flutter` a tu entorno local donde tienes instalado Flutter.
2. Abre una terminal en la carpeta `petlink_flutter`.
3. Ejecuta el comando para descargar las dependencias:
   ```bash
   flutter pub get
   ```
4. Ejecuta la aplicación en tu dispositivo, emulador o navegador (si tienes habilitado el soporte web):
   ```bash
   flutter run
   ```

## Estructura del Proyecto

- `lib/main.dart`: Punto de entrada, configuración del Provider para estado global, Theme (modo oscuro/claro) y barra de navegación inferior.
- `lib/state/app_state.dart`: Lógica que simula la recepción de eventos MQTT (consumo de comida, alertas) mediante `ChangeNotifier`.
- `lib/screens/`: Contiene las cinco pantallas principales (Dashboard, Cámara, Horarios, Alertas, Configuración).
- `lib/models/`: Clases de datos para Alertas y Horarios.
- `lib/widgets/`: Componentes reutilizables como la barra de progreso.

## Tecnologías Utilizadas

- **Flutter / Dart**
- **provider**: Gestión de estado reactivo.
- **lucide_icons_flutter**: Para mantener consistencia con los íconos usados previamente en React.
- **google_fonts**: Para la fuente Inter.
