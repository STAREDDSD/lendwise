import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:lendwise/models/user.dart';

class AuthService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';
  
  final _uuid = const Uuid();

  Future<List<User>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey) ?? '[]';
    final usersList = jsonDecode(usersJson) as List;
    return usersList.map((json) => User.fromJson(json)).toList();
  }

  Future<void> _saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = jsonEncode(users.map((user) => user.toJson()).toList());
    await prefs.setString(_usersKey, usersJson);
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<User?> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final users = await _getUsers();
      
      // Check if user already exists
      if (users.any((user) => user.email == email || user.phone == phone)) {
        return null;
      }

      final hashedPassword = _hashPassword(password);
      final now = DateTime.now();
      
      final newUser = User(
        id: _uuid.v4(),
        name: name,
        email: email,
        phone: phone,
        passwordHash: hashedPassword,
        createdAt: now,
        updatedAt: now,
      );

      users.add(newUser);
      await _saveUsers(users);
      
      return newUser;
    } catch (e) {
      return null;
    }
  }

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final users = await _getUsers();
      final hashedPassword = _hashPassword(password);
      
      final user = users.where((user) => 
        user.email == email && user.passwordHash == hashedPassword
      ).firstOrNull;

      if (user != null) {
        await _setCurrentUser(user);
      }
      
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<User?> loginWithPhone(String phone, String password) async {
    try {
      final users = await _getUsers();
      final hashedPassword = _hashPassword(password);
      
      final user = users.where((user) => 
        user.phone == phone && user.passwordHash == hashedPassword
      ).firstOrNull;

      if (user != null) {
        await _setCurrentUser(user);
      }
      
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<void> _setCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
    await prefs.setBool(_isLoggedInKey, true);
  }

  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (!isLoggedIn) return null;
      
      final userJson = prefs.getString(_currentUserKey);
      if (userJson == null) return null;
      
      return User.fromJson(jsonDecode(userJson));
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return false;

      final users = await _getUsers();
      final hashedOldPassword = _hashPassword(oldPassword);
      
      if (currentUser.passwordHash != hashedOldPassword) {
        return false;
      }

      final hashedNewPassword = _hashPassword(newPassword);
      final updatedUser = currentUser.copyWith(
        passwordHash: hashedNewPassword,
        updatedAt: DateTime.now(),
      );

      final userIndex = users.indexWhere((user) => user.id == currentUser.id);
      if (userIndex != -1) {
        users[userIndex] = updatedUser;
        await _saveUsers(users);
        await _setCurrentUser(updatedUser);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
}