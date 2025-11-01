import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:lendwise/models/loan.dart';

class LoanService {
  static const String _loansKey = 'loans';
  final _uuid = const Uuid();

  Future<List<Loan>> _getLoans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loansJson = prefs.getString(_loansKey) ?? '[]';
      final loansList = jsonDecode(loansJson) as List;
      return loansList.map((json) {
        try {
          return Loan.fromJson(json);
        } catch (e) {
          return null;
        }
      }).where((loan) => loan != null).cast<Loan>().toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveLoans(List<Loan> loans) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loansJson = jsonEncode(loans.map((loan) => loan.toJson()).toList());
      await prefs.setString(_loansKey, loansJson);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Loan>> getLoansByUserId(String userId) async {
    final loans = await _getLoans();
    return loans.where((loan) => loan.userId == userId).toList();
  }

  Future<List<Loan>> getLoansByBorrowerId(String borrowerId) async {
    final loans = await _getLoans();
    return loans.where((loan) => loan.borrowerId == borrowerId).toList();
  }

  Future<Loan?> getLoanById(String id) async {
    final loans = await _getLoans();
    return loans.where((loan) => loan.id == id).firstOrNull;
  }

  Future<Loan?> createLoan({
    required String userId,
    required String borrowerId,
    required String loanCode,
    required double capitalAmount,
    required double processingFee,
    required double interestRate,
    required DateTime startDate,
    required DateTime dueDate,
  }) async {
    try {
      final loans = await _getLoans();
      
      final now = DateTime.now();
      final newLoan = Loan(
        id: _uuid.v4(),
        userId: userId,
        borrowerId: borrowerId,
        loanCode: loanCode,
        capitalAmount: capitalAmount,
        processingFee: processingFee,
        currentBalance: capitalAmount, // Initial balance is the capital amount
        interestRate: interestRate,
        startDate: startDate,
        dueDate: dueDate,
        status: LoanStatus.active,
        interestPaused: false,
        paymentIds: [],
        createdAt: now,
        updatedAt: now,
      );

      loans.add(newLoan);
      await _saveLoans(loans);
      
      return newLoan;
    } catch (e) {
      return null;
    }
  }

  Future<Loan?> updateLoan(Loan loan) async {
    try {
      final loans = await _getLoans();
      final index = loans.indexWhere((l) => l.id == loan.id);
      
      if (index != -1) {
        final updatedLoan = loan.copyWith(updatedAt: DateTime.now());
        loans[index] = updatedLoan;
        await _saveLoans(loans);
        return updatedLoan;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteLoan(String id) async {
    try {
      final loans = await _getLoans();
      final initialLength = loans.length;
      
      loans.removeWhere((loan) => loan.id == id);
      
      if (loans.length < initialLength) {
        await _saveLoans(loans);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Loan?> toggleInterestPause(String loanId) async {
    try {
      final loan = await getLoanById(loanId);
      if (loan == null) return null;
      
      return await updateLoan(loan.copyWith(
        interestPaused: !loan.interestPaused,
      ));
    } catch (e) {
      return null;
    }
  }

  Future<Loan?> applyMonthlyInterest(String loanId) async {
    try {
      final loan = await getLoanById(loanId);
      if (loan == null || loan.interestPaused || loan.status != LoanStatus.active) {
        return loan;
      }
      
      final interestAmount = loan.currentBalance * (loan.interestRate / 100);
      final newBalance = loan.currentBalance + interestAmount;
      
      return await updateLoan(loan.copyWith(
        currentBalance: newBalance,
      ));
    } catch (e) {
      return null;
    }
  }

  Future<void> applyMonthlyInterestToAllLoans(String userId) async {
    try {
      final loans = await getLoansByUserId(userId);
      
      for (final loan in loans) {
        await applyMonthlyInterest(loan.id);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<Loan?> makePayment(String loanId, double paymentAmount) async {
    try {
      final loan = await getLoanById(loanId);
      if (loan == null) return null;
      
      final newBalance = (loan.currentBalance - paymentAmount).clamp(0.0, double.infinity);
      final newStatus = newBalance <= 0.01 ? LoanStatus.completed : loan.status;
      
      return await updateLoan(loan.copyWith(
        currentBalance: newBalance,
        status: newStatus,
      ));
    } catch (e) {
      return null;
    }
  }

  Future<List<Loan>> getOverdueLoans(String userId) async {
    final loans = await getLoansByUserId(userId);
    return loans.where((loan) => loan.isOverdue).toList();
  }

  Future<List<Loan>> getActiveLoans(String userId) async {
    final loans = await getLoansByUserId(userId);
    return loans.where((loan) => loan.status == LoanStatus.active).toList();
  }

  Future<List<Loan>> getCompletedLoans(String userId) async {
    final loans = await getLoansByUserId(userId);
    return loans.where((loan) => loan.status == LoanStatus.completed).toList();
  }

  Future<Map<String, dynamic>> getLoanStatistics(String userId) async {
    final loans = await getLoansByUserId(userId);
    
    final activeLoans = loans.where((loan) => loan.status == LoanStatus.active).toList();
    final overdueLoans = loans.where((loan) => loan.isOverdue).toList();
    final completedLoans = loans.where((loan) => loan.status == LoanStatus.completed).toList();
    
    final totalCapitalGiven = loans.fold<double>(0.0, (sum, loan) => sum + loan.capitalAmount);
    final totalOutstanding = activeLoans.fold<double>(0.0, (sum, loan) => sum + loan.currentBalance);
    final totalProcessingFees = loans.fold<double>(0.0, (sum, loan) => sum + loan.processingFee);
    
    return {
      'totalLoans': loans.length,
      'activeLoans': activeLoans.length,
      'overdueLoans': overdueLoans.length,
      'completedLoans': completedLoans.length,
      'totalCapitalGiven': totalCapitalGiven,
      'totalOutstanding': totalOutstanding,
      'totalProcessingFees': totalProcessingFees,
    };
  }

  Future<List<Loan>> searchLoans(String userId, String query) async {
    final loans = await getLoansByUserId(userId);
    
    if (query.isEmpty) return loans;
    
    final lowerQuery = query.toLowerCase();
    return loans.where((loan) => 
      loan.loanCode.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}