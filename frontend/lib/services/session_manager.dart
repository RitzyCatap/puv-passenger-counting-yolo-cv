import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_model.dart';

class SessionManager extends ChangeNotifier {
  SessionManager();

  static final SessionManager instance = SessionManager();

  AuthSession? _session;
  Timer? _expirationTimer;

  bool get isAuthenticated {
    final session = _session;

    return session != null && !session.isExpired;
  }

  AuthUser? get user => isAuthenticated ? _session?.user : null;

  String? get accessToken => isAuthenticated ? _session?.accessToken : null;

  bool get isAdmin => user?.isAdmin ?? false;

  bool get isOperator => user?.isOperator ?? false;

  void startSession(AuthSession session) {
    if (session.isExpired) {
      clearSession();

      throw StateError('Cannot start an expired session.');
    }

    _expirationTimer?.cancel();

    _session = session;

    final remaining = session.expiresAt.difference(DateTime.now());

    _expirationTimer = Timer(
      remaining.isNegative ? Duration.zero : remaining,
      clearSession,
    );

    notifyListeners();
  }

  void clearSession() {
    _expirationTimer?.cancel();
    _expirationTimer = null;

    final hadSession = _session != null;

    _session = null;

    if (hadSession) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    _session = null;

    super.dispose();
  }
}
