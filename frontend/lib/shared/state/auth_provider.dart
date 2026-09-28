import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// App-wide auth state. Wrapped around AuthService so screens don't talk to
/// the API layer directly for login state.
class AuthProvider extends ChangeNotifier {
  final _authService = AuthService.instance;

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;

  Future<void> bootstrap() async {
    final loggedIn = await _authService.isLoggedIn();
    if (!loggedIn) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      currentUser = await _authService.getCurrentUser();
      status = AuthStatus.authenticated;
    } catch (_) {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _authService.login(email: email, password: password);
    currentUser = await _authService.getCurrentUser();
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    await _authService.register(email: email, password: password, fullName: fullName, phone: phone);
    await login(email, password);
  }

  Future<void> refreshCurrentUser() async {
    currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
