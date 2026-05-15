class ScheduleModel {
  final int id;
  final String type; // 'food' or 'water'
  final String time;
  final String amount;
  bool active;

  ScheduleModel({
    required this.id,
    required this.type,
    required this.time,
    required this.amount,
    required this.active,
  });
}
