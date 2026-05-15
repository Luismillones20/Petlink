import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../models/schedule.dart';

class AppState extends ChangeNotifier {
  // Sensor Data
  double foodLevel = 65.0; // %
  double waterLevel = 40.0; // %
  double foodWeight = 120.0; // g
  String lastFed = 'Hoy, 08:30 AM';
  bool isConnected = true;
  bool isDarkMode = false;

  // Alerts
  List<AlertModel> alerts = [
    AlertModel(id: 1, type: 'food_req', msg: 'Mascota pidió comida', time: '10:45 AM', status: 'pending'),
    AlertModel(id: 2, type: 'bark', msg: 'Ladrido detectado', time: '10:12 AM', status: 'info'),
  ];

  // Schedules
  List<ScheduleModel> schedules = [
    ScheduleModel(id: 1, type: 'food', time: '08:00 AM', amount: '80g', active: true),
    ScheduleModel(id: 2, type: 'water', time: '09:00 AM', amount: 'Llenar', active: true),
    ScheduleModel(id: 3, type: 'food', time: '18:30 PM', amount: '80g', active: false),
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

  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!isConnected) return;
      
      final random = Random();
      
      // Decrease levels
      if (random.nextDouble() > 0.7) {
        waterLevel = max(0, waterLevel - 1);
      }
      if (random.nextDouble() > 0.8) {
        foodWeight = max(0, foodWeight - 5);
      }

      // Random events
      if (random.nextDouble() > 0.98) {
        final isWater = random.nextBool();
        final now = DateTime.now();
        final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        
        final newAlert = AlertModel(
          id: DateTime.now().millisecondsSinceEpoch,
          type: isWater ? 'water_req' : 'bark',
          msg: isWater ? 'Mascota pidió agua' : 'Ladrido detectado',
          time: timeStr,
          status: random.nextBool() ? 'pending' : 'info',
        );
        alerts.insert(0, newAlert);
      }

      notifyListeners();
    });
  }

  void toggleDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }

  void manualFeed() {
    foodLevel = min(100, foodLevel + 10);
    foodWeight += 50;
    final now = DateTime.now();
    lastFed = 'Hoy, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    notifyListeners();
  }

  void manualWater() {
    waterLevel = min(100, waterLevel + 25);
    notifyListeners();
  }

  void resolveAlert(int id, String action) {
    final index = alerts.indexWhere((a) => a.id == id);
    if (index != -1) {
      alerts[index].status = action;
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

  int get pendingAlertsCount {
    return alerts.where((a) => a.status == 'pending').length;
  }
}
