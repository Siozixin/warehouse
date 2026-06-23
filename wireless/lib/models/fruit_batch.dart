import 'cctv_analysis.dart';

enum BatchStatus { good, risk, spoiled }

class FruitBatch {
  final String batchId;
  final DateTime arrivalTime;
  DateTime firstInspectionTime;
  BatchStatus status;
  DateTime expiryDate;
  String notes;
  List<CctvAnalysis> history;

  FruitBatch({
    required this.batchId,
    required this.arrivalTime,
    required this.firstInspectionTime,
    required this.status,
    required this.expiryDate,
    this.notes = '',
    List<CctvAnalysis>? history,
  }) : history = history ?? [];
}
