import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../models/schedule.dart';

class AppState extends ChangeNotifier {
  // Sensor Data (Arduino Mega & Load Cell)
  double foodLevel = 65.0; // %
  double waterLevel = 40.0; // %
  double foodWeight = 120.0; // g (Weight Sensor reading)
  String lastFed = 'Hoy, 08:30 AM';
  bool isConnected = true;
  bool isDarkMode = false;

  // --- HEALTH & STATS ENGINE VARIABLES ---
  double petWeight = 25.0; // kg (Max is a Golden Retriever)
  double eatingSpeed = 1.8; // g/s (HX711 dynamic intake rate)
  double dailyCaloricTarget = 900.0; // kcal
  double dailyWaterTarget = 600.0; // mL
  double dailyFoodTarget = 240.0; // g

  // Real-time calculated properties for today
  double get todayFoodIntake => foodConsumptionHistory.last;
  double get todayWaterIntake => waterConsumptionHistory.last;
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
    return '';
  }

  Future<void> fetchAIRecommendations() async {
    loadingAiRecommendations = true;
    notifyListeners();

    try {
      final apiKey = _getApiKey();
      if (apiKey.isEmpty) return;
      
      final client = HttpClient();
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');
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
      
      request.write(json.encode(body));
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
  String brokerUrl = 'mqtt://broker.hivemq.com:1883';
  String deviceId = 'ESP8266_UTEC_2026';
  String arduinoIP = '192.168.1.150';
  String esp32CamIP = '192.168.1.151';
  int wifiSignal = -56; // dBm (RSSI)
  int activeSolenoids = 0; // Simulated pin controls on Arduino Mega
  
  // Real-time analytics / Weight history
  List<double> weightHistory = [120.0, 110.0, 95.0, 70.0, 50.0, 130.0, 120.0, 112.0, 105.0, 120.0];
  List<double> foodConsumptionHistory = [75.0, 85.0, 60.0, 90.0, 80.0, 95.0, 80.0]; // Last 7 days in grams
  List<double> waterConsumptionHistory = [250.0, 300.0, 280.0, 310.0, 290.0, 350.0, 270.0]; // Last 7 days in mL
  // AI & ESP32-CAM Configurations
  bool isAIEnabled = true;
  double aiConfidenceThreshold = 85.0; // %
  bool aiOnlyFeeding = false; 
  bool boundingBoxOverlay = true;
  String aiStatus = 'Max detectado'; // Current video scanner target
  double currentConfidence = 96.0;
  bool infraredLight = false;

  // AI Snapshots Gallery (ESP32-CAM triggered)
  List<Map<String, String>> aiSnapshots = [
    {'time': '08:30 AM', 'label': 'Max (Identificado)', 'confidence': '98%', 'status': 'Alimentado'},
    {'time': '10:12 AM', 'label': 'Desconocido', 'confidence': '42%', 'status': 'Alerta emitida'},
    {'time': '10:45 AM', 'label': 'Max (Identificado)', 'confidence': '96%', 'status': 'Petición botón'},
  ];

  // Alerts
  List<AlertModel> alerts = [
    AlertModel(id: 1, type: 'food_req', msg: 'Mascota pidió comida (Botón Físico)', time: '10:45 AM', status: 'pending'),
    AlertModel(id: 2, type: 'bark', msg: 'Ladrido detectado (MAX9814)', time: '10:12 AM', status: 'info'),
  ];

  // Schedules (Synchronized with Arduino EEPROM via MQTT)
  List<ScheduleModel> schedules = [
    ScheduleModel(id: 1, type: 'food', time: '08:00 AM', amount: '80g', portionGrams: 80, active: true, validateWithAI: true),
    ScheduleModel(id: 2, type: 'water', time: '09:00 AM', amount: 'Llenar', portionGrams: 200, active: true, validateWithAI: false),
    ScheduleModel(id: 3, type: 'food', time: '18:30 PM', amount: '80g', portionGrams: 80, active: false, validateWithAI: true),
  ];

  Timer? _simulationTimer;

  AppState() {
    _startSimulation();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  // MQTT / Sensor simulation
  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!isConnected) return;
      
      final random = Random();
      
      // Pet slowly consumes food and water
      if (random.nextDouble() > 0.7) {
        waterLevel = max(0.0, waterLevel - 0.5);
      }
      if (random.nextDouble() > 0.8) {
        // Decrease food weight to simulate eating
        double oldWeight = foodWeight;
        foodWeight = max(0.0, foodWeight - random.nextInt(4).toDouble());
        if (oldWeight != foodWeight) {
          // Update the last reading in our graph
          if (weightHistory.isNotEmpty) {
            weightHistory[weightHistory.length - 1] = foodWeight;
          }
        }
      }

      // Fluctuations in Wi-Fi and stats
      wifiSignal = -50 - random.nextInt(15);

      // Random spontaneous events (ladridos o detección de IA)
      if (random.nextDouble() > 0.985) {
        final isBark = random.nextBool();
        final now = DateTime.now();
        final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        
        if (isBark) {
          final newAlert = AlertModel(
            id: DateTime.now().millisecondsSinceEpoch,
            type: 'bark',
            msg: 'Ladrido detectado (MAX9814)',
            time: timeStr,
            status: 'info',
          );
          alerts.insert(0, newAlert);
        } else {
          // AI camera motion detection event
          final intruder = random.nextBool();
          final label = intruder ? 'Intruso (Desconocido)' : 'Max (Identificado)';
          final conf = intruder ? (30 + random.nextInt(30)) : (85 + random.nextInt(12));
          
          aiStatus = label;
          currentConfidence = conf.toDouble();
          
          aiSnapshots.insert(0, {
            'time': timeStr,
            'label': label,
            'confidence': '$conf%',
            'status': intruder ? 'Alerta de movimiento' : 'Activo en zona',
          });
          
          if (intruder) {
            alerts.insert(0, AlertModel(
              id: DateTime.now().millisecondsSinceEpoch,
              type: 'ai_alert',
              msg: 'Presencia sospechosa detectada: $label ($conf%)',
              time: timeStr,
              status: 'info',
            ));
          }
        }
        notifyListeners();
      }
    });
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
    activeSolenoids = 1;
    notifyListeners();
    
    // Simulate Arduino Servo opening and closing
    Timer(const Duration(milliseconds: 1500), () {
      foodLevel = min(100.0, foodLevel + 8.0);
      foodWeight = min(300.0, foodWeight + grams);
      
      // Update stats
      final now = DateTime.now();
      lastFed = 'Hoy, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      weightHistory.add(foodWeight);
      if (weightHistory.length > 12) weightHistory.removeAt(0);
      
      foodConsumptionHistory[foodConsumptionHistory.length - 1] += grams;
      
      // Add to today's hourly logs
      final nowStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      todayFeedingLogs.add({'time': nowStr, 'amount': grams, 'type': 'Manual'});

      activeSolenoids = 0;
      
      notifyListeners();
    });
  }

  void _dispenseWater(int ml) {
    activeSolenoids = 2;
    notifyListeners();
    
    Timer(const Duration(milliseconds: 1500), () {
      waterLevel = min(100.0, waterLevel + 25.0);
      waterConsumptionHistory[waterConsumptionHistory.length - 1] += ml;
      activeSolenoids = 0;
      notifyListeners();
    });
  }

  void resolveAlert(int id, String action) {
    final index = alerts.indexWhere((a) => a.id == id);
    if (index != -1) {
      alerts[index].status = action;
      
      // If action is authorization, command Arduino to dispense!
      if (action == 'resolved') {
        _dispenseFood(80); // Solicitudes aprobadas sirven 80g
        
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
