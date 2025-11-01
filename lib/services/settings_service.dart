import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lendwise/models/settings.dart';

class SettingsService {
  static const String _settingsKey = 'settings';

  Future<Settings?> getSettingsByUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('${_settingsKey}_$userId');
      
      if (settingsJson == null) {
        // Return default settings for new users
        return Settings.defaultSettings(userId);
      }
      
      return Settings.fromJson(jsonDecode(settingsJson));
    } catch (e) {
      return Settings.defaultSettings(userId);
    }
  }

  Future<Settings?> updateSettings(Settings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedSettings = settings.copyWith(updatedAt: DateTime.now());
      
      await prefs.setString(
        '${_settingsKey}_${settings.userId}',
        jsonEncode(updatedSettings.toJson()),
      );
      
      return updatedSettings;
    } catch (e) {
      return null;
    }
  }

  Future<Settings?> updateInterestRate(String userId, double newRate) async {
    try {
      final settings = await getSettingsByUserId(userId);
      if (settings == null) return null;
      
      return await updateSettings(settings.copyWith(
        defaultInterestRate: newRate,
      ));
    } catch (e) {
      return null;
    }
  }

  Future<Settings?> updateProcessingFee({
    required String userId,
    double? percentage,
    double? fixedAmount,
  }) async {
    try {
      final settings = await getSettingsByUserId(userId);
      if (settings == null) return null;
      
      return await updateSettings(settings.copyWith(
        defaultProcessingFeePercentage: percentage ?? settings.defaultProcessingFeePercentage,
        defaultProcessingFeeFixed: fixedAmount ?? settings.defaultProcessingFeeFixed,
      ));
    } catch (e) {
      return null;
    }
  }

  Future<Settings?> updateMessageTemplate(String userId, String template) async {
    try {
      final settings = await getSettingsByUserId(userId);
      if (settings == null) return null;
      
      return await updateSettings(settings.copyWith(
        messageTemplate: template,
      ));
    } catch (e) {
      return null;
    }
  }

  Future<Settings?> updateBankDetails(String userId, String bankDetails) async {
    try {
      final settings = await getSettingsByUserId(userId);
      if (settings == null) return null;
      
      return await updateSettings(settings.copyWith(
        bankDetails: bankDetails,
      ));
    } catch (e) {
      return null;
    }
  }

  Future<Settings?> toggleNotifications(String userId) async {
    try {
      final settings = await getSettingsByUserId(userId);
      if (settings == null) return null;
      
      return await updateSettings(settings.copyWith(
        notificationsEnabled: !settings.notificationsEnabled,
      ));
    } catch (e) {
      return null;
    }
  }

  Future<Settings?> updateThemeMode(String userId, ThemeMode themeMode) async {
    try {
      final settings = await getSettingsByUserId(userId);
      if (settings == null) return null;
      
      return await updateSettings(settings.copyWith(
        themeMode: themeMode,
      ));
    } catch (e) {
      return null;
    }
  }

  String generateMessage({
    required Settings settings,
    required String borrowerName,
    required String loanCode,
    required double balance,
    required double interestRate,
    required DateTime dueDate,
  }) {
    final now = DateTime.now();
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return settings.messageTemplate
        .replaceAll('{Name}', borrowerName)
        .replaceAll('{LoanCode}', loanCode)
        .replaceAll('{Month}', monthNames[now.month - 1])
        .replaceAll('{Year}', now.year.toString())
        .replaceAll('{Balance}', balance.toStringAsFixed(2))
        .replaceAll('{BankDetails}', settings.bankDetails)
        .replaceAll('{InterestRate}', interestRate.toStringAsFixed(1))
        .replaceAll('{DueDate}', '${dueDate.day}/${dueDate.month}/${dueDate.year}');
  }

  double calculateProcessingFee(Settings settings, double capitalAmount) {
    // Use percentage-based calculation, but can be overridden with fixed amount
    return (capitalAmount * settings.defaultProcessingFeePercentage / 100)
        .clamp(0.0, settings.defaultProcessingFeeFixed);
  }
}