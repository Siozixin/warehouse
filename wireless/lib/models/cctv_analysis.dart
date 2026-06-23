class CctvAnalysis {
  final DateTime timestamp;
  final double goodPercentage;
  final double partialPercentage;
  final double spoiledPercentage;
  final double healthScore;
  final double spoilageProbability;
  final String healthStatus;
  final String imageAsset;
  final String batchId;

  CctvAnalysis({
    required this.timestamp,
    required this.goodPercentage,
    required this.partialPercentage,
    required this.spoiledPercentage,
    required this.healthScore,
    required this.spoilageProbability,
    required this.healthStatus,
    required this.imageAsset,
    required this.batchId,
  });
}
