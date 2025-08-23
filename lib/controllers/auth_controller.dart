import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { authenticated, unauthenticated, loading }

class AuthController extends ChangeNotifier {
  AppUser? _currentUser;
  AuthStatus _status = AuthStatus.loading;
  String? _errorMessage;

  // Getters
  AppUser? get currentUser => _currentUser;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get canCreateEvents => _currentUser?.canCreateEvents ?? false;
  bool get canManageFinances => _currentUser?.canManageFinances ?? false;
  bool get canViewReports => _currentUser?.canViewReports ?? false;
  bool get canManageUsers => _currentUser?.canManageUsers ?? false;

  AuthController() {
    _initAuthListener();
  }

  // Inicializar listener de autenticación
  void _initAuthListener() {
    AuthService.authStateChanges.listen((User? user) async {
      if (user != null) {
        await _loadUserData();
      } else {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  // Cargar datos del usuario
  Future<void> _loadUserData() async {
    try {
      final appUser = await AuthService.getCurrentAppUser();
      if (appUser != null) {
        _currentUser = appUser;
        _status = AuthStatus.authenticated;
        _errorMessage = null;
      } else {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Usuario no encontrado';
      }
    } catch (e) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Error cargando usuario: $e';
    }
    notifyListeners();
  }

  // Registrar usuario
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    required String communityCode,
    String? apartment,
    String? phone,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await AuthService.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        communityCode: communityCode,
        apartment: apartment,
        phone: phone,
      );

      _currentUser = user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Error durante el registro: $e';
      notifyListeners();
      return false;
    }
  }

  // Iniciar sesión
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await AuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _currentUser = user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Error durante el login: $e';
      notifyListeners();
      return false;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await AuthService.signOut();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error cerrando sesión: $e';
      notifyListeners();
    }
  }

  // Resetear contraseña
  Future<bool> resetPassword(String email) async {
    try {
      await AuthService.resetPassword(email);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error enviando email de recuperación: $e';
      notifyListeners();
      return false;
    }
  }

  // Promover usuario a admin
  Future<bool> promoteUserToAdmin(String userId) async {
    try {
      await AuthService.promoteUserToAdmin(userId);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error promoviendo usuario: $e';
      notifyListeners();
      return false;
    }
  }

  // Degradar admin a usuario
  Future<bool> demoteAdminToUser(String userId) async {
    try {
      await AuthService.demoteAdminToUser(userId);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error degradando usuario: $e';
      notifyListeners();
      return false;
    }
  }

  // Obtener todos los usuarios
  Future<List<AppUser>> getAllUsers() async {
    try {
      return await AuthService.getAllUsers();
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return [];
    } catch (e) {
      _errorMessage = 'Error obteniendo usuarios: $e';
      notifyListeners();
      return [];
    }
  }

  // Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Recargar datos del usuario
  Future<void> refreshUser() async {
    await _loadUserData();
  }
}
