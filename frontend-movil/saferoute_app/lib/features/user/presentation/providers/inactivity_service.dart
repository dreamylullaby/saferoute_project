import 'dart:async';

/// Servicio de detección de inactividad del usuario.
class InactivityService {
  InactivityService({
    required this.timeout,
    required this.onTimeout,
  }) {
    reset();
  }

  final Duration timeout;
  final VoidCallback onTimeout;
  Timer? _timer;

  void reset() {
    _timer?.cancel();
    _timer = Timer(timeout, onTimeout);
  }

  void dispose() {
    _timer?.cancel();
  }
}

typedef VoidCallback = void Function();
