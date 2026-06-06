import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/alert.dart';
import '../models/schedule.dart';

class AppState extends ChangeNotifier {
  // MQTT Client
  MqttServerClient? _mqttClient;

  // Sensor Data (Arduino Mega & Load Cell)
  double foodLevel = -1.0; // % (-1 means no data / error)
  double waterLevel = -1.0; // %
  double foodWeight = -1.0; // g
  String lastFed = 'Sin registros';
  bool isConnected = false;
  bool isDarkMode = false;

  // --- HEALTH & STATS ENGINE VARIABLES ---
  double petWeight = 25.0; // kg (Max is a Golden Retriever)
  double eatingSpeed = 1.8; // g/s (HX711 dynamic intake rate)
  double dailyCaloricTarget = 900.0; // kcal
  double dailyWaterTarget = 600.0; // mL
  double dailyFoodTarget = 240.0; // g

  // Real-time calculated properties for today
  double get todayFoodIntake => foodConsumptionHistory.isEmpty ? 0.0 : foodConsumptionHistory.last;
  double get todayWaterIntake => waterConsumptionHistory.isEmpty ? 0.0 : waterConsumptionHistory.last;
  double get todayCalorieIntake => todayFoodIntake * 3.75; // 1g of dry food = ~3.75 kcal

  // Monthly History (Last 6 months)
  List<double> monthlyFoodHistory = [22.0, 24.5, 21.0, 25.8, 23.4, 24.0]; // in kg
  List<double> monthlyWaterHistory = [7.5, 8.2, 7.0, 8.8, 8.1, 8.3]; // in Liters
  List<String> monthLabels = ['Dic', 'Ene', 'Feb', 'Mar', 'Abr', 'May'];

  // Detail hourly logs for today
  List<Map<String, dynamic>> todayFeedingLogs = [
    {'time': '08:00 AM', 'amount': 80, 'type': 'Programado'},
  ];

  // Dynamic AI Recommendations state
  List<String> aiRecommendations = [
    "⏱️ Ritmo de alimentación óptimo registrado en la balanza HX711.",
    "💧 Max mantiene un consumo de agua excelente de acuerdo a su peso corporal.",
    "🍖 El balance calórico diario es correcto para su nivel de actividad física."
  ];
  bool loadingAiRecommendations = false;

  String customApiKey = '';

  String get activeApiKey {
    if (customApiKey.trim().isNotEmpty) {
      return customApiKey.trim();
    }
    return _getApiKey();
  }

  void updateApiKey(String key) {
    customApiKey = key;
    notifyListeners();
  }

  String _getApiKey() {
    // 1. Try compile-time environment variable (e.g. from --dart-define or --dart-define-from-file)
    const compileTimeKey = String.fromEnvironment('VITE_GEMINI_API_KEY');
    if (compileTimeKey.isNotEmpty) {
      return compileTimeKey;
    }

    // 2. Fallback to local file reading for dev environments
    try {
      final file = File('../.env');
      if (file.existsSync()) {
        final lines = file.readAsLinesSync();
        for (var line in lines) {
          if (line.startsWith('VITE_GEMINI_API_KEY=')) {
            return line.replaceFirst('VITE_GEMINI_API_KEY=', '').trim();
          }
        }
      }
    } catch (_) {}

    // 3. Hardcoded fallback key for APK installations
    return '';
  }

  Future<void> fetchAIRecommendations() async {
    loadingAiRecommendations = true;
    notifyListeners();

    try {
      final apiKey = activeApiKey;
      if (apiKey.isEmpty) return;
      
      final client = HttpClient();
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');
      final request = await client.postUrl(uri);
      request.headers.set('content-type', 'application/json');
      
      final body = {
        'contents': [
          {
            'parts': [
              {
                'text': 'Genera exactamente 3 recomendaciones médicas de salud cortas y útiles de 1 línea cada una, con base en estos datos reales de un perro Golden Retriever de 25 kg llamado Max hoy:\n'
                    '- Comida consumida hoy: ${todayFoodIntake.round()}g (meta 240g)\n'
                    '- Agua consumida hoy: ${todayWaterIntake.round()}ml (meta 600ml)\n'
                    '- Velocidad de ingesta: $eatingSpeed g/s (rango óptimo: 1.5 - 2.5 g/s)\n\n'
                    'Devuelve una lista separada por saltos de línea con los 3 consejos (sin títulos, sin marcas de negrita, sin números, solo el texto del consejo directamente). Comienza cada uno con un emoji correspondiente (por ejemplo, ⏱️, 💧, 🍖).'
              }
            ]
          }
        ]
      };
      
      request.add(utf8.encode(json.encode(body)));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = json.decode(responseBody);
        final String text = data['candidates'][0]['content']['parts'][0]['text'];
        final list = text.split('\n').where((l) => l.trim().isNotEmpty).take(3).toList();
        if (list.length >= 2) {
          aiRecommendations = list;
        }
      }
    } catch (e) {
      // Fallback
    } finally {
      loadingAiRecommendations = false;
      notifyListeners();
    }
  }

  // Connection Info (IoT Broker & Devices)
  String brokerUrl = 'mqtt://18.225.238.184:1883';
  String deviceId = 'esp8266_dispensador_01';
  String arduinoIP = '192.168.1.150';
  String esp32CamIP = '192.168.1.151';
  int wifiSignal = 0; // dBm (RSSI)
  int activeSolenoids = 0; // Actual pin controls on Arduino Mega
  
  // Real-time analytics / Weight history
  List<double> weightHistory = [];
  List<double> foodConsumptionHistory = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]; // Last 7 days in grams
  List<double> waterConsumptionHistory = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]; // Last 7 days in mL
  // AI & ESP32-CAM Configurations
  bool isAIEnabled = true;
  double aiConfidenceThreshold = 85.0; // %
  bool aiOnlyFeeding = false; 
  bool boundingBoxOverlay = true;
  String aiStatus = 'Buscando mascota...'; // Current video scanner target
  double currentConfidence = 0.0;
  bool infraredLight = false;

  // AI Snapshots Gallery (ESP32-CAM triggered)
  List<Map<String, String>> aiSnapshots = [];

  // Alerts
  List<AlertModel> alerts = [];

  // Schedules (Synchronized with Arduino EEPROM via MQTT)
  List<ScheduleModel> schedules = [
    ScheduleModel(id: 1, type: 'food', time: '08:00 AM', amount: '80g', portionGrams: 80, active: true, validateWithAI: true),
    ScheduleModel(id: 2, type: 'water', time: '09:00 AM', amount: 'Llenar', portionGrams: 200, active: true, validateWithAI: false),
    ScheduleModel(id: 3, type: 'food', time: '18:30 PM', amount: '80g', portionGrams: 80, active: false, validateWithAI: true),
  ];

  AppState() {
    _initMqtt();
  }

  @override
  void dispose() {
    _mqttClient?.disconnect();
    super.dispose();
  }

  Future<void> _initMqtt() async {
    // Extract host and port from brokerUrl
    String host = brokerUrl;
    if (host.startsWith('mqtt://')) {
      host = host.replaceFirst('mqtt://', '');
    }
    int port = 1883;
    if (host.contains(':')) {
      final parts = host.split(':');
      host = parts[0];
      port = int.tryParse(parts[1]) ?? 1883;
    }

    final String clientId = 'petlink_flutter_app_${DateTime.now().millisecondsSinceEpoch % 10000}';
    _mqttClient = MqttServerClient(host, clientId);
    _mqttClient!.port = port;
    _mqttClient!.keepAlivePeriod = 20;
    _mqttClient!.onDisconnected = _onMqttDisconnected;
    _mqttClient!.onConnected = _onMqttConnected;
    _mqttClient!.onSubscribed = _onMqttSubscribed;
    
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        ..withWillQos(MqttQos.atMostOnce);
    _mqttClient!.connectionMessage = connMessage;

    try {
      print('Connecting to MQTT broker $host:$port ...');
      await _mqttClient!.connect();
    } catch (e) {
      print('MQTT connection failed: $e');
      isConnected = false;
      notifyListeners();
      // Retry connection after 5 seconds
      Timer(const Duration(seconds: 5), _initMqtt);
    }
  }

  void _onMqttConnected() {
    print('MQTT Connected!');
    isConnected = true;
    notifyListeners();
    _subscribeToTopics();
  }

  void _onMqttDisconnected() {
    print('MQTT Disconnected!');
    isConnected = false;
    notifyListeners();
    // Retry connection after 5 seconds
    Timer(const Duration(seconds: 5), _initMqtt);
  }

  void _onMqttSubscribed(String topic) {
    print('MQTT Subscribed to: $topic');
  }

  void _subscribeToTopics() {
    if (_mqttClient == null || _mqttClient!.connectionStatus!.state != MqttConnectionState.connected) return;

    _mqttClient!.subscribe('mascotas/g4/comida/distancia', MqttQos.atMostOnce);
    _mqttClient!.subscribe('mascotas/g4/comida/peso', MqttQos.atMostOnce);
    _mqttClient!.subscribe('mascotas/g4/agua/nivel', MqttQos.atMostOnce);
    _mqttClient!.subscribe('mascotas/g4/comida/servo', MqttQos.atMostOnce);
    _mqttClient!.subscribe('mascotas/g4/agua/bomba', MqttQos.atMostOnce);
    _mqttClient!.subscribe('mascotas/g4/alertas', MqttQos.atMostOnce);
    _mqttClient!.subscribe('mascotas/g4/botones', MqttQos.atMostOnce);
    _mqttClient!.subscribe('mascotas/g4/wifi/rssi', MqttQos.atMostOnce);

    _mqttClient!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      if (c == null) return;
      final recMess = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final topic = c[0].topic;

      _handleIncomingMqttMessage(topic, payload);
    });
  }

  void _handleIncomingMqttMessage(String topic, String payload) {
    print('MQTT Msg received: [$topic] -> $payload');

    if (topic == 'mascotas/g4/comida/distancia') {
      final double? val = double.tryParse(payload);
      if (val != null) {
        // Convierte la distancia en cm a porcentaje de contenedor de comida.
        // Asumiendo 18cm como vacío (0%) y 3cm como lleno (100%).
        if (val <= 0 || val > 30) {
          foodLevel = -1.0; // Sensor error
        } else {
          foodLevel = ((18.0 - val) / 15.0 * 100.0).clamp(0.0, 100.0);
        }
        notifyListeners();
      }
    } else if (topic == 'mascotas/g4/comida/peso') {
      final double? val = double.tryParse(payload);
      if (val != null) {
        if (val < 0) {
          foodWeight = -1.0; // Sensor error
        } else {
          // Detect actual consumption if the weight drops (only when it drops by > 2g)
          if (foodWeight > 0 && val < foodWeight) {
            double difference = foodWeight - val;
            if (difference > 2.0) {
              if (foodConsumptionHistory.isEmpty) {
                foodConsumptionHistory = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
              }
              foodConsumptionHistory[foodConsumptionHistory.length - 1] += difference;
              
              final now = DateTime.now();
              final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
              todayFeedingLogs.add({
                'time': timeStr,
                'amount': difference.round(),
                'type': 'Consumo'
              });
            }
          }
          foodWeight = val;
          weightHistory.add(foodWeight);
          if (weightHistory.length > 12) weightHistory.removeAt(0);
        }
        notifyListeners();
      }
    } else if (topic == 'mascotas/g4/agua/nivel') {
      final double? val = double.tryParse(payload);
      if (val != null) {
        if (val < 0) {
          waterLevel = -1.0; // Sensor error
        } else {
          // Detect water consumption (e.g. from level drop in container, 1% ≈ 10ml)
          if (waterLevel > 0 && val < waterLevel) {
            double diffPct = waterLevel - val;
            double mlConsumed = diffPct * 10.0;
            if (mlConsumed > 0) {
              if (waterConsumptionHistory.isEmpty) {
                waterConsumptionHistory = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
              }
              waterConsumptionHistory[waterConsumptionHistory.length - 1] += mlConsumed;
            }
          }
          waterLevel = val;
        }
        notifyListeners();
      }
    } else if (topic == 'mascotas/g4/wifi/rssi') {
      final int? val = int.tryParse(payload);
      if (val != null) {
        wifiSignal = val;
        notifyListeners();
      }
    } else if (topic == 'mascotas/g4/comida/servo') {
      if (payload == 'ABIERTO') {
        activeSolenoids = 1;
      } else {
        activeSolenoids = 0;
      }
      notifyListeners();
    } else if (topic == 'mascotas/g4/agua/bomba') {
      if (payload == 'ACTIVA') {
        activeSolenoids = 2;
      } else {
        activeSolenoids = 0;
      }
      notifyListeners();
    } else if (topic == 'mascotas/g4/botones') {
      if (payload == 'COMIDA') {
        triggerPetButtonRequest();
      } else if (payload == 'AGUA') {
        final now = DateTime.now();
        final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        final newAlert = AlertModel(
          id: DateTime.now().millisecondsSinceEpoch,
          type: 'water_req',
          msg: 'Mascota pidió agua (Botón Físico)',
          time: timeStr,
          status: 'pending',
        );
        alerts.insert(0, newAlert);
        notifyListeners();
      }
    } else if (topic == 'mascotas/g4/alertas') {
      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      if (payload == 'COMIDA_BAJA') {
        final newAlert = AlertModel(
          id: DateTime.now().millisecondsSinceEpoch,
          type: 'food_low',
          msg: '¡Contenedor de comida bajo! (Sensor de distancia)',
          time: timeStr,
          status: 'info',
        );
        alerts.insert(0, newAlert);
        notifyListeners();
      } else if (payload == 'DISPENSANDO' || payload == 'BOMBA_ON') {
        activeSolenoids = payload == 'DISPENSANDO' ? 1 : 2;
        notifyListeners();
      } else if (payload == 'DISPENSADOR_CERRADO' || payload == 'BOMBA_OFF') {
        activeSolenoids = 0;
        notifyListeners();
      } else {
        // Alerta genérica
        final newAlert = AlertModel(
          id: DateTime.now().millisecondsSinceEpoch,
          type: 'iot_alert',
          msg: 'Alerta IoT: $payload',
          time: timeStr,
          status: 'info',
        );
        alerts.insert(0, newAlert);
        notifyListeners();
      }
    }
  }

  void _publishMqtt(String topic, String message) {
    if (_mqttClient == null || _mqttClient!.connectionStatus!.state != MqttConnectionState.connected) {
      print('Cannot publish, MQTT not connected');
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _mqttClient!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    print('MQTT Published to [$topic]: $message');
  }

  void addSchedule(ScheduleModel schedule) {
    schedules.add(schedule);
    notifyListeners();
  }

  void deleteSchedule(int id) {
    schedules.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void toggleDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }

  void toggleAIEnabled(bool value) {
    isAIEnabled = value;
    notifyListeners();
  }

  void toggleAIOnlyFeeding(bool value) {
    aiOnlyFeeding = value;
    notifyListeners();
  }

  void toggleBoundingBoxOverlay(bool value) {
    boundingBoxOverlay = value;
    notifyListeners();
  }

  void toggleInfraredLight(bool value) {
    infraredLight = value;
    notifyListeners();
  }

  void setConfidenceThreshold(double value) {
    aiConfidenceThreshold = value;
    notifyListeners();
  }

  // Dynamic simulation of the Physical Button on the Pet Dispenser
  void triggerPetButtonRequest() {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final id = DateTime.now().millisecondsSinceEpoch;
    
    // Add to alerts
    final newAlert = AlertModel(
      id: id,
      type: 'food_req',
      msg: 'Mascota pidió comida (Botón Físico)',
      time: timeStr,
      status: 'pending',
    );
    alerts.insert(0, newAlert);
    
    // Simulate camera snapshot
    if (isAIEnabled) {
      aiStatus = 'Max (Identificado)';
      currentConfidence = 96.0;
      aiSnapshots.insert(0, {
        'time': timeStr,
        'label': 'Max (Identificado)',
        'confidence': '96%',
        'status': 'Petición botón',
      });
    }
    
    notifyListeners();
  }

  void manualFeed() {
    _dispenseFood(50); // Dispense 50g
  }

  void manualWater() {
    _dispenseWater(150); // Dispense 150ml
  }

  void _dispenseFood(int grams) {
    // Solo enviar el comando por MQTT. La confirmación del servo abierto/cerrado 
    // y el peso se recibirán mediante telemetría MQTT real.
    _publishMqtt('mascotas/g4/cmd/comida', 'DISPENSAR');
    final now = DateTime.now();
    lastFed = 'Hoy, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    notifyListeners();
  }

  void _dispenseWater(int ml) {
    // Enviar comando para encender bomba por MQTT. 
    // El apagado se maneja en el Arduino Mega por sensores o tiempo.
    _publishMqtt('mascotas/g4/cmd/agua', 'ON');
    notifyListeners();
  }

  void resolveAlert(int id, String action) {
    final index = alerts.indexWhere((a) => a.id == id);
    if (index != -1) {
      alerts[index].status = action;
      
      // Si la acción es autorización, manda el comando por MQTT
      if (action == 'resolved') {
        if (alerts[index].type == 'water_req') {
          _dispenseWater(150);
        } else {
          _dispenseFood(80); // Solicitudes aprobadas sirven 80g
        }
        
        if (aiSnapshots.isNotEmpty && aiSnapshots[0]['status'] == 'Petición botón') {
          aiSnapshots[0]['status'] = 'Aprobado y Servido';
        }
      } else if (action == 'denied') {
        if (aiSnapshots.isNotEmpty && aiSnapshots[0]['status'] == 'Petición botón') {
          aiSnapshots[0]['status'] = 'Denegado por usuario';
        }
      }
      
      notifyListeners();
    }
  }

  void toggleSchedule(int id) {
    final index = schedules.indexWhere((s) => s.id == id);
    if (index != -1) {
      schedules[index].active = !schedules[index].active;
      notifyListeners();
    }
  }

  void toggleScheduleAI(int id, bool value) {
    final index = schedules.indexWhere((s) => s.id == id);
    if (index != -1) {
      schedules[index].validateWithAI = value;
      notifyListeners();
    }
  }

  void updateSchedulePortion(int id, int grams) {
    final index = schedules.indexWhere((s) => s.id == id);
    if (index != -1) {
      schedules[index].portionGrams = grams;
      schedules[index].amount = '${grams}g';
      notifyListeners();
    }
  }

  int get pendingAlertsCount {
    return alerts.where((a) => a.status == 'pending').length;
  }
}
