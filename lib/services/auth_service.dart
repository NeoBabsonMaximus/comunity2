import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  final String code;

  AuthException(this.message, this.code);

  @override
  String toString() => message;
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream del usuario actual
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual de Firebase
  static User? get currentUser => _auth.currentUser;

  // Obtener datos del usuario actual desde Firestore
  static Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        // Si no existe, crear entrada básica
        final newUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'Usuario',
          role: UserRole.user,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          isActive: true,
        );
        
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
      }

      return AppUser.fromMap(doc.data()!);
    } catch (e) {
      print('Error obteniendo usuario: $e');
      return null;
    }
  }

  // Registrar nuevo usuario
  static Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String communityCode,
    String? apartment,
    String? phone,
  }) async {
    try {
      // Verificar código de comunidad
      if (communityCode != CommunityConstants.communityCode) {
        throw AuthException('Código de comunidad incorrecto', 'invalid-community-code');
      }

      // Verificar que el email no esté vacío y sea válido
      if (email.trim().isEmpty) {
        throw AuthException('El email es requerido', 'email-required');
      }

      if (password.length < 6) {
        throw AuthException('La contraseña debe tener al menos 6 caracteres', 'weak-password');
      }

      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw AuthException('Error creando usuario en Firebase', 'user-creation-failed');
      }

      // Actualizar display name en Firebase Auth
      await user.updateDisplayName(displayName.trim());
      await user.reload(); // Recargar para obtener los datos actualizados

      // Determinar rol: el primer admin o usuario normal
      UserRole role = UserRole.user;
      if (email.trim().toLowerCase() == CommunityConstants.defaultAdminEmail.toLowerCase()) {
        role = UserRole.admin;
      }

      // Crear usuario en Firestore
      final appUser = AppUser(
        uid: user.uid,
        email: email.trim().toLowerCase(),
        displayName: displayName.trim(),
        role: role,
        apartment: apartment?.trim().isEmpty == true ? null : apartment?.trim(),
        phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        isActive: true,
      );

      // Guardar en Firestore con manejo de errores
      await _firestore.collection('users').doc(user.uid).set(appUser.toMap());

      return appUser;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException durante registro: ${e.code} - ${e.message}');
      String message = _getFirebaseAuthErrorMessage(e.code);
      throw AuthException(message, e.code);
    } catch (e) {
      print('Error durante registro: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Error durante el registro: $e', 'registration-failed');
    }
  }

  // Iniciar sesión
  static Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (email.trim().isEmpty) {
        throw AuthException('El email es requerido', 'email-required');
      }

      if (password.isEmpty) {
        throw AuthException('La contraseña es requerida', 'password-required');
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw AuthException('Error de autenticación', 'sign-in-failed');
      }

      // Intentar obtener datos del usuario de Firestore
      final appUser = await getCurrentAppUser();
      if (appUser == null) {
        // Si no existe en Firestore, crear entrada básica
        final newAppUser = AppUser(
          uid: user.uid,
          email: user.email ?? email.trim().toLowerCase(),
          displayName: user.displayName ?? 'Usuario',
          role: UserRole.user,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          isActive: true,
        );
        
        await _firestore.collection('users').doc(user.uid).set(newAppUser.toMap());
        return newAppUser;
      }

      // Verificar si el usuario está activo (no bloqueado)
      if (!appUser.isActive) {
        // Cerrar la sesión inmediatamente
        await _auth.signOut();
        throw AuthException('Tu cuenta ha sido bloqueada. Contacta al administrador.', 'account-blocked');
      }

      // Actualizar último login
      await _firestore.collection('users').doc(user.uid).update({
        'lastLogin': Timestamp.fromDate(DateTime.now()),
      });

      return appUser.copyWith(lastLogin: DateTime.now());
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException durante login: ${e.code} - ${e.message}');
      String message = _getFirebaseAuthErrorMessage(e.code);
      throw AuthException(message, e.code);
    } catch (e) {
      print('Error durante login: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Error durante el login: $e', 'sign-in-failed');
    }
  }

  // Cerrar sesión
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Resetear contraseña
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String message = _getFirebaseAuthErrorMessage(e.code);
      throw AuthException(message, e.code);
    }
  }

  // Promover usuario a admin (solo admin puede hacer esto)
  static Future<void> promoteUserToAdmin(String userId) async {
    try {
      final currentUser = await getCurrentAppUser();
      if (currentUser == null || !currentUser.canManageUsers) {
        throw AuthException('No tienes permisos para realizar esta acción', 'insufficient-permissions');
      }

      await _firestore.collection('users').doc(userId).update({
        'role': UserRole.admin.name,
      });
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Error promoviendo usuario: $e', 'promotion-failed');
    }
  }

  // Degradar admin a usuario (solo admin puede hacer esto)
  static Future<void> demoteAdminToUser(String userId) async {
    try {
      final currentUser = await getCurrentAppUser();
      if (currentUser == null || !currentUser.canManageUsers) {
        throw AuthException('No tienes permisos para realizar esta acción', 'insufficient-permissions');
      }

      await _firestore.collection('users').doc(userId).update({
        'role': UserRole.user.name,
      });
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Error degradando usuario: $e', 'demotion-failed');
    }
  }

  // Obtener todos los usuarios (solo admin)
  static Future<List<AppUser>> getAllUsers() async {
    try {
      final currentUser = await getCurrentAppUser();
      if (currentUser == null || !currentUser.canManageUsers) {
        throw AuthException('No tienes permisos para ver usuarios', 'insufficient-permissions');
      }

      final snapshot = await _firestore.collection('users').orderBy('displayName').get();
      return snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList();
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Error obteniendo usuarios: $e', 'fetch-users-failed');
    }
  }

  // Actualizar estado del usuario (bloquear/desbloquear)
  static Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      final currentUser = await getCurrentAppUser();
      if (currentUser == null || !currentUser.canManageUsers) {
        throw AuthException('No tienes permisos para gestionar usuarios', 'insufficient-permissions');
      }

      if (userId == currentUser.uid) {
        throw AuthException('No puedes bloquear tu propia cuenta', 'self-block-forbidden');
      }

      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
      });
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Error actualizando estado de usuario: $e', 'update-status-failed');
    }
  }

  // Traducir códigos de error de Firebase
  static String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuario no encontrado. Verifica tu email.';
      case 'wrong-password':
        return 'Contraseña incorrecta. Intenta nuevamente.';
      case 'email-already-in-use':
        return 'Este email ya está registrado. Intenta iniciar sesión.';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      case 'invalid-email':
        return 'El formato del email no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Espera unos minutos.';
      case 'operation-not-allowed':
        return 'Operación no permitida. Contacta al administrador.';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet.';
      case 'invalid-credential':
        return 'Credenciales inválidas. Verifica email y contraseña.';
      case 'credential-already-in-use':
        return 'Estas credenciales ya están en uso.';
      case 'invalid-verification-code':
        return 'Código de verificación inválido.';
      case 'invalid-verification-id':
        return 'ID de verificación inválido.';
      case 'missing-email':
        return 'Debes proporcionar un email.';
      case 'missing-password':
        return 'Debes proporcionar una contraseña.';
      case 'email-required':
        return 'El email es requerido.';
      case 'password-required':
        return 'La contraseña es requerida.';
      case 'invalid-community-code':
        return 'Código de comunidad incorrecto.';
      default:
        return 'Error de autenticación. Código: $code';
    }
  }
}
