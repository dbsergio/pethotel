import 'package:uuid/uuid.dart';

enum CustomerStatus { waiting, arriving, staying, readyForPickup, pickingUp, completed }

class Customer {
  final String id;
  String name;
  CustomerStatus status;

  Customer({
    String? id,
    required this.name,
    this.status = CustomerStatus.waiting,
  }) : id = id ?? const Uuid().v4();

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      status: CustomerStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CustomerStatus.waiting,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status.name,
    };
  }
}
