import 'package:flutter/material.dart';
import '../../data/datasources/user_Remote_Datasource.dart';

/// Provider para el flujo de recuperación de contraseña.
/// Maneja estados de carga, éxito y error para ambas pantallas.
class ForgotPasswordProvider extends ChangeNotifier {
  final _ds = UserRemoteDatasource();

  bool _loading = false;
  bool _enviado = false;
  String? _error;
  bool _restablecido = false;

  bool get loading => _loading;
  bool get enviado => _enviado;
  String? get error => _error;
  bool get restablecido => _restablecido;

  /// Envía el enlace de recuperación al correo.
  Future<void> enviarEnlace(String correo) async {
    _loading = true; _error = null; notifyListeners();
    try { await _ds.forgotPassword(correo); _enviado = true; }
    catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
    _loading = false; notifyListeners();
  }

  Future<void> restablecerPassword(String token, String password) async {
    _loading = true; _error = null; notifyListeners();
    try { await _ds.resetPassword(token, password); _restablecido = true; }
    catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
    _loading = false; notifyListeners();
  }

  void reset() {
    _loading = false;
    _enviado = false;
    _error = null;
    _restablecido = false;
    notifyListeners();
  }
}
