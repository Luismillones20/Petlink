class AlertModel {
  final int id;
  final String type;
  final String msg;
  final String time;
  String status; // 'pending', 'info', 'resolved', 'denied'

  AlertModel({
    required this.id,
    required this.type,
    required this.msg,
    required this.time,
    required this.status,
  });

  AlertModel copyWith({
    int? id,
    String? type,
    String? msg,
    String? time,
    String? status,
  }) {
    return AlertModel(
      id: id ?? this.id,
      type: type ?? this.type,
      msg: msg ?? this.msg,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }
}
