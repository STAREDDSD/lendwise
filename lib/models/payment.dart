enum PaymentType { full, partial, custom }

class Payment {
  final String id;
  final String loanId;
  final double amount;
  final DateTime paymentDate;
  final PaymentType type;
  final String notes;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.paymentDate,
    required this.type,
    required this.notes,
    required this.createdAt,
  });

  Payment copyWith({
    String? id,
    String? loanId,
    double? amount,
    DateTime? paymentDate,
    PaymentType? type,
    String? notes,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loanId': loanId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'type': type.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      loanId: json['loanId'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      type: PaymentType.values.firstWhere((e) => e.name == json['type']),
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}