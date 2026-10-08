class CareMinigameResult {
  final bool success;
  final bool cancelled;
  final double quality; // 0.0 to 1.0 (e.g. 1.0 = perfect score, 0.5 = okay)
  final Map<String, double> statChanges; // e.g. {'hunger': 20.0, 'happiness': 5.0}

  CareMinigameResult({
    required this.success,
    this.cancelled = false,
    this.quality = 1.0,
    this.statChanges = const {},
  });

  factory CareMinigameResult.cancelled() {
    return CareMinigameResult(success: false, cancelled: true);
  }
}
