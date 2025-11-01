class Borrower {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String address;
  final List<String> loanIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Borrower({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.address,
    required this.loanIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Borrower copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? address,
    List<String>? loanIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Borrower(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      loanIds: loanIds ?? List<String>.from(this.loanIds),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'address': address,
      'loanIds': loanIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Borrower.fromJson(Map<String, dynamic> json) {
    return Borrower(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String? ?? '',
      loanIds: List<String>.from(json['loanIds'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}