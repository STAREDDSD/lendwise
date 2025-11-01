import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:lendwise/models/payment.dart';

class PaymentService {
  static const String _paymentsKey = 'payments';
  final _uuid = const Uuid();

  Future<List<Payment>> _getPayments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paymentsJson = prefs.getString(_paymentsKey) ?? '[]';
      final paymentsList = jsonDecode(paymentsJson) as List;
      return paymentsList.map((json) {
        try {
          return Payment.fromJson(json);
        } catch (e) {
          return null;
        }
      }).where((payment) => payment != null).cast<Payment>().toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _savePayments(List<Payment> payments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paymentsJson = jsonEncode(payments.map((payment) => payment.toJson()).toList());
      await prefs.setString(_paymentsKey, paymentsJson);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Payment>> getPaymentsByLoanId(String loanId) async {
    final payments = await _getPayments();
    return payments.where((payment) => payment.loanId == loanId)
        .toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate)); // Latest first
  }

  Future<Payment?> getPaymentById(String id) async {
    final payments = await _getPayments();
    return payments.where((payment) => payment.id == id).firstOrNull;
  }

  Future<Payment?> createPayment({
    required String loanId,
    required double amount,
    required DateTime paymentDate,
    required PaymentType type,
    String? notes,
  }) async {
    try {
      final payments = await _getPayments();
      
      final now = DateTime.now();
      final newPayment = Payment(
        id: _uuid.v4(),
        loanId: loanId,
        amount: amount,
        paymentDate: paymentDate,
        type: type,
        notes: notes ?? '',
        createdAt: now,
      );

      payments.add(newPayment);
      await _savePayments(payments);
      
      return newPayment;
    } catch (e) {
      return null;
    }
  }

  Future<Payment?> updatePayment(Payment payment) async {
    try {
      final payments = await _getPayments();
      final index = payments.indexWhere((p) => p.id == payment.id);
      
      if (index != -1) {
        payments[index] = payment;
        await _savePayments(payments);
        return payment;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deletePayment(String id) async {
    try {
      final payments = await _getPayments();
      final initialLength = payments.length;
      
      payments.removeWhere((payment) => payment.id == id);
      
      if (payments.length < initialLength) {
        await _savePayments(payments);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<double> getTotalPaymentsForLoan(String loanId) async {
    final payments = await getPaymentsByLoanId(loanId);
    return payments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
  }

  Future<List<Payment>> getPaymentsInDateRange(
    String loanId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final payments = await getPaymentsByLoanId(loanId);
    return payments.where((payment) => 
      payment.paymentDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
      payment.paymentDate.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  Future<Map<String, dynamic>> getPaymentStatistics(String loanId) async {
    final payments = await getPaymentsByLoanId(loanId);
    
    final totalPayments = payments.length;
    final totalAmount = payments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
    
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    
    final thisMonthPayments = payments.where((payment) => 
      payment.paymentDate.isAfter(thisMonth.subtract(const Duration(days: 1))) &&
      payment.paymentDate.isBefore(nextMonth)
    ).toList();
    
    final thisMonthAmount = thisMonthPayments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
    
    return {
      'totalPayments': totalPayments,
      'totalAmount': totalAmount,
      'thisMonthPayments': thisMonthPayments.length,
      'thisMonthAmount': thisMonthAmount,
      'lastPaymentDate': payments.isNotEmpty ? payments.first.paymentDate : null,
    };
  }

  Future<List<Payment>> getAllPaymentsForUser(String userId, List<String> loanIds) async {
    final allPayments = await _getPayments();
    return allPayments.where((payment) => loanIds.contains(payment.loanId))
        .toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
  }
}