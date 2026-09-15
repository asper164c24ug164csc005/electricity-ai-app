import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Handles Login / Register.
/// NOTE: This is a local-storage mock so the UI works standalone.
/// Replace the TODOs with real calls to your FastAPI backend
/// (POST /auth/register, POST /auth/login) or Firebase Auth.
class AuthService extends ChangeNotifier {
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  static const _usersKey = 'registered_users';
  static const _sessionKey = 'current_user_email';

  Future<bool> register(String name, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final users = _loadUsers(prefs);

    if (users.containsKey(email)) {
      return false; // already registered
    }

    users[email] = {'name': name, 'email': email, 'password': password};
    await prefs.setString(_usersKey, jsonEncode(users));

    _currentUser = AppUser(id: email, name: name, email: email);
    await prefs.setString(_sessionKey, email);
    notifyListeners();

    // TODO: call FastAPI -> POST /auth/register
    return true;
  }

  Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final users = _loadUsers(prefs);

    if (!users.containsKey(email) || users[email]['password'] != password) {
      return false;
    }

    _currentUser = AppUser(
      id: email,
      name: users[email]['name'],
      email: email,
    );
    await prefs.setString(_sessionKey, email);
    notifyListeners();

    // TODO: call FastAPI -> POST /auth/login
    return true;
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_sessionKey);
    if (email == null) return;
    final users = _loadUsers(prefs);
    if (users.containsKey(email)) {
      _currentUser = AppUser(
        id: email,
        name: users[email]['name'],
        email: email,
      );
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _currentUser = null;
    notifyListeners();
  }

  Map<String, dynamic> _loadUsers(SharedPreferences prefs) {
    final raw = prefs.getString(_usersKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw));
  }
}
