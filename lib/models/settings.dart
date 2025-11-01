import 'package:flutter/material.dart';

class Settings {
  final String userId;
  final double defaultInterestRate;
  final double defaultProcessingFeePercentage;
  final double defaultProcessingFeeFixed;
  final String messageTemplate;
  final String bankDetails;
  final bool notificationsEnabled;
  final ThemeMode themeMode;
  final DateTime updatedAt;

  Settings({
    required this.userId,
    required this.defaultInterestRate,
    required this.defaultProcessingFeePercentage,
    required this.defaultProcessingFeeFixed,
    required this.messageTemplate,
    required this.bankDetails,
    required this.notificationsEnabled,
    required this.themeMode,
    required this.updatedAt,
  });

  factory Settings.defaultSettings(String userId) {
    return Settings(
      userId: userId,
      defaultInterestRate: 20.0,
      defaultProcessingFeePercentage: 10.0,
      defaultProcessingFeeFixed: 5000.0,
      messageTemplate: 'Dear {Name}. Your {LoanCode} loan as at {Month} {Year}, is ₦{Balance}. Please pay into {BankDetails}. Pay before {DueDate} to avoid {InterestRate}% interest. Thank you.',
      bankDetails: 'GTB - 0700158769 - Loan Manager',
      notificationsEnabled: true,
      themeMode: ThemeMode.system,
      updatedAt: DateTime.now(),
    );
  }

  Settings copyWith({
    String? userId,
    double? defaultInterestRate,
    double? defaultProcessingFeePercentage,
    double? defaultProcessingFeeFixed,
    String? messageTemplate,
    String? bankDetails,
    bool? notificationsEnabled,
    ThemeMode? themeMode,
    DateTime? updatedAt,
  }) {
    return Settings(
      userId: userId ?? this.userId,
      defaultInterestRate: defaultInterestRate ?? this.defaultInterestRate,
      defaultProcessingFeePercentage: defaultProcessingFeePercentage ?? this.defaultProcessingFeePercentage,
      defaultProcessingFeeFixed: defaultProcessingFeeFixed ?? this.defaultProcessingFeeFixed,
      messageTemplate: messageTemplate ?? this.messageTemplate,
      bankDetails: bankDetails ?? this.bankDetails,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'defaultInterestRate': defaultInterestRate,
      'defaultProcessingFeePercentage': defaultProcessingFeePercentage,
      'defaultProcessingFeeFixed': defaultProcessingFeeFixed,
      'messageTemplate': messageTemplate,
      'bankDetails': bankDetails,
      'notificationsEnabled': notificationsEnabled,
      'themeMode': themeMode.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      userId: json['userId'] as String,
      defaultInterestRate: (json['defaultInterestRate'] as num).toDouble(),
      defaultProcessingFeePercentage: (json['defaultProcessingFeePercentage'] as num).toDouble(),
      defaultProcessingFeeFixed: (json['defaultProcessingFeeFixed'] as num).toDouble(),
      messageTemplate: json['messageTemplate'] as String,
      bankDetails: json['bankDetails'] as String,
      notificationsEnabled: json['notificationsEnabled'] as bool,
      themeMode: ThemeMode.values.firstWhere((e) => e.name == json['themeMode']),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}