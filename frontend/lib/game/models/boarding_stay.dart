import 'package:uuid/uuid.dart';
import 'customer.dart';

enum StayStatus { active, readyForPickup, pickingUp, completed }

class BoardingStay {
  final String id;
  final Customer customer;
  final String petId;
  final String request;
  final DateTime startedAt;
  final int expectedDurationSeconds;
  
  StayStatus status;
  int? satisfaction; // 1 to 5 stars
  int? rewardCoins;

  BoardingStay({
    String? id,
    required this.customer,
    required this.petId,
    required this.request,
    DateTime? startedAt,
    this.expectedDurationSeconds = 60, // Short default for testing
    this.status = StayStatus.active,
    this.satisfaction,
    this.rewardCoins,
  })  : id = id ?? const Uuid().v4(),
        startedAt = startedAt ?? DateTime.now();

  bool get isReady => DateTime.now().difference(startedAt).inSeconds >= expectedDurationSeconds;

  factory BoardingStay.fromJson(Map<String, dynamic> json) {
    return BoardingStay(
      id: json['id'] as String,
      customer: Customer.fromJson(json['customer'] as Map<String, dynamic>),
      petId: json['petId'] as String,
      request: json['request'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      expectedDurationSeconds: json['expectedDurationSeconds'] as int? ?? 60,
      status: StayStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => StayStatus.active,
      ),
      satisfaction: json['satisfaction'] as int?,
      rewardCoins: json['rewardCoins'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer': customer.toJson(),
      'petId': petId,
      'request': request,
      'startedAt': startedAt.toIso8601String(),
      'expectedDurationSeconds': expectedDurationSeconds,
      'status': status.name,
      if (satisfaction != null) 'satisfaction': satisfaction,
      if (rewardCoins != null) 'rewardCoins': rewardCoins,
    };
  }
}
