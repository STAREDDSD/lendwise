import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:lendwise/models/borrower.dart';

class BorrowerService {
  static const String _borrowersKey = 'borrowers';
  final _uuid = const Uuid();

  Future<List<Borrower>> _getBorrowers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final borrowersJson = prefs.getString(_borrowersKey) ?? '[]';
      final borrowersList = jsonDecode(borrowersJson) as List;
      return borrowersList.map((json) {
        try {
          return Borrower.fromJson(json);
        } catch (e) {
          return null;
        }
      }).where((borrower) => borrower != null).cast<Borrower>().toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveBorrowers(List<Borrower> borrowers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final borrowersJson = jsonEncode(borrowers.map((borrower) => borrower.toJson()).toList());
      await prefs.setString(_borrowersKey, borrowersJson);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<List<Borrower>> getBorrowersByUserId(String userId) async {
    final borrowers = await _getBorrowers();
    return borrowers.where((borrower) => borrower.userId == userId).toList();
  }

  Future<Borrower?> getBorrowerById(String id) async {
    final borrowers = await _getBorrowers();
    return borrowers.where((borrower) => borrower.id == id).firstOrNull;
  }

  Future<Borrower?> createBorrower({
    required String userId,
    required String name,
    required String phone,
    String? address,
  }) async {
    try {
      final borrowers = await _getBorrowers();
      
      // Check for duplicate phone number within the same user
      if (borrowers.any((borrower) => 
        borrower.userId == userId && borrower.phone == phone)) {
        return null; // Duplicate phone number
      }

      final now = DateTime.now();
      final newBorrower = Borrower(
        id: _uuid.v4(),
        userId: userId,
        name: name,
        phone: phone,
        address: address ?? '',
        loanIds: [],
        createdAt: now,
        updatedAt: now,
      );

      borrowers.add(newBorrower);
      await _saveBorrowers(borrowers);
      
      return newBorrower;
    } catch (e) {
      return null;
    }
  }

  Future<Borrower?> updateBorrower(Borrower borrower) async {
    try {
      final borrowers = await _getBorrowers();
      final index = borrowers.indexWhere((b) => b.id == borrower.id);
      
      if (index != -1) {
        final updatedBorrower = borrower.copyWith(updatedAt: DateTime.now());
        borrowers[index] = updatedBorrower;
        await _saveBorrowers(borrowers);
        return updatedBorrower;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteBorrower(String id) async {
    try {
      final borrowers = await _getBorrowers();
      final initialLength = borrowers.length;
      
      borrowers.removeWhere((borrower) => borrower.id == id);
      
      if (borrowers.length < initialLength) {
        await _saveBorrowers(borrowers);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<Borrower>> searchBorrowers(String userId, String query) async {
    final borrowers = await getBorrowersByUserId(userId);
    
    if (query.isEmpty) return borrowers;
    
    final lowerQuery = query.toLowerCase();
    return borrowers.where((borrower) => 
      borrower.name.toLowerCase().contains(lowerQuery) ||
      borrower.phone.contains(query)
    ).toList();
  }

  Future<Borrower?> addLoanToBorrower(String borrowerId, String loanId) async {
    try {
      final borrower = await getBorrowerById(borrowerId);
      if (borrower == null) return null;

      final updatedLoanIds = List<String>.from(borrower.loanIds);
      if (!updatedLoanIds.contains(loanId)) {
        updatedLoanIds.add(loanId);
        return await updateBorrower(borrower.copyWith(loanIds: updatedLoanIds));
      }
      
      return borrower;
    } catch (e) {
      return null;
    }
  }

  Future<Borrower?> removeLoanFromBorrower(String borrowerId, String loanId) async {
    try {
      final borrower = await getBorrowerById(borrowerId);
      if (borrower == null) return null;

      final updatedLoanIds = List<String>.from(borrower.loanIds);
      updatedLoanIds.remove(loanId);
      
      return await updateBorrower(borrower.copyWith(loanIds: updatedLoanIds));
    } catch (e) {
      return null;
    }
  }
}