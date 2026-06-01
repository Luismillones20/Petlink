class ScheduleModel {
  final int id;
  final String type; // 'food' or 'water'
  final String time;
  String amount; // Portion string (e.g. '80g' or 'Llenar')
  int portionGrams; // Portion quantity in grams (or ml)
  bool active;
  bool validateWithAI; // Trigger ESP32-CAM AI Face detection first

  ScheduleModel({
    required this.id,
    required this.type,
    required this.time,
    required this.amount,
    required this.active,
    this.portionGrams = 80,
    this.validateWithAI = false,
  });
}
