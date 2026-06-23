class RfidLog {
  final String userId;
  final DateTime entryTime;
  final DateTime? exitTime;
  final List<String> zoneAccess;

  RfidLog({
    required this.userId,
    required this.entryTime,
    this.exitTime,
    required this.zoneAccess,
  });
}
