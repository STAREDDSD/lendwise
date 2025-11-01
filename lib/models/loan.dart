enum LoanStatus { active, completed, overdue }

class Loan {
  final String id;
  final String userId;
  final String borrowerId;
  final String loanCode;
  final double capitalAmount;
  final double processingFee;
  final double currentBalance;
  final double interestRate;
  final DateTime startDate;
  final DateTime dueDate;
  final LoanStatus status;
  final bool interestPaused;
  final List<String> paymentIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Loan({
    required this.id,
    required this.userId,
    required this.borrowerId,
    required this.loanCode,
    required this.capitalAmount,
    required this.processingFee,
    required this.currentBalance,
    required this.interestRate,
    required this.startDate,
    required this.dueDate,
    required this.status,
    required this.interestPaused,
    required this.paymentIds,
    required this.createdAt,
    required this.updatedAt,
  });

  double get actualAmountReceived => capitalAmount - processingFee;

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status != LoanStatus.completed;

  Loan copyWith({
    String? id,
    String? userId,
    String? borrowerId,
    String? loanCode,
    double? capitalAmount,
    double? processingFee,
    double? currentBalance,
    double? interestRate,
    DateTime? startDate,
    DateTime? dueDate,
    LoanStatus? status,
    bool? interestPaused,
    List<String>? paymentIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Loan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      borrowerId: borrowerId ?? this.borrowerId,
      loanCode: loanCode ?? this.loanCode,
      capitalAmount: capitalAmount ?? this.capitalAmount,
      processingFee: processingFee ?? this.processingFee,
      currentBalance: currentBalance ?? this.currentBalance,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      interestPaused: interestPaused ?? this.interestPaused,
      paymentIds: paymentIds ?? List<String>.from(this.paymentIds),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'borrowerId': borrowerId,
      'loanCode': loanCode,
      'capitalAmount': capitalAmount,
      'processingFee': processingFee,
      'currentBalance': currentBalance,
      'interestRate': interestRate,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'interestPaused': interestPaused,
      'paymentIds': paymentIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String,
      userId: json['userId'] as String,
      borrowerId: json['borrowerId'] as String,
      loanCode: json['loanCode'] as String,
      capitalAmount: (json['capitalAmount'] as num).toDouble(),
      processingFee: (json['processingFee'] as num).toDouble(),
      currentBalance: (json['currentBalance'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: LoanStatus.values.firstWhere((e) => e.name == json['status']),
      interestPaused: json['interestPaused'] as bool? ?? false,
      paymentIds: List<String>.from(json['paymentIds'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}