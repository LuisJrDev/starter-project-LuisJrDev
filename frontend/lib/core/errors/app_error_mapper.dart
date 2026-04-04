import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppErrorMapper {
  static String authMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'El correo no tiene un formato válido.';
        case 'user-disabled':
          return 'Este usuario ha sido deshabilitado.';
        case 'user-not-found':
          return 'No existe una cuenta con ese correo.';
        case 'wrong-password':
          return 'Contraseña incorrecta.';
        case 'invalid-credential':
          return 'Credenciales inválidas. Revisa tu correo y contraseña.';
        case 'email-already-in-use':
          return 'Ese correo ya está registrado.';
        case 'weak-password':
          return 'La contraseña es muy débil (mínimo 6 caracteres).';
        case 'network-request-failed':
          return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
        case 'too-many-requests':
          return 'Demasiados intentos. Espera un momento y vuelve a intentar.';
        default:
          return 'Ocurrió un error de autenticación. Intenta nuevamente.';
      }
    }
    return 'Ocurrió un error inesperado. Intenta nuevamente.';
  }

  static String message(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'La conexión está tardando demasiado. Intenta nuevamente.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Sin conexión. Verifica tu internet e intenta de nuevo.';
      }

      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }

      return 'Error de red. Intenta nuevamente.';
    }

    return 'Ocurrió un error inesperado. Intenta nuevamente.';
  }
}
