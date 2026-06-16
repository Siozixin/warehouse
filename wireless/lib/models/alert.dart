enum AlertType { temperature, humidity, system, security }

enum AlertSeverity { info, warning, critical }

class Alert {
  final String id;
  final String title;
  final String message;
  final AlertType type;
  final AlertSeverity severity;
  final DateTime timestamp;
  final String? zoneId;
  bool isRead;

  Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.severity,
    required this.timestamp,
    this.zoneId,
    this.isRead = false,
  });
}
