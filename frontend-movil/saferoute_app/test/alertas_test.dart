import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saferoute_app/services/auth_storage.dart';
import 'package:saferoute_app/features/user/data/models/alerta_config_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HU-07 Frontend - AlertaConfigModel', () {
    test('CP-HU07-01: fromJson mapea valores correctamente', () {

      final json = {
        'id': 'cfg-001',
        'usuario_id': 'user-123',
        'radio_metros': 1200,
        'activo': false,
      };

      final model = AlertaConfigModel.fromJson(json);

      expect(model.id, 'cfg-001');
      expect(model.usuarioId, 'user-123');
      expect(model.radioMetros, 1200);
      expect(model.activo, false);

      print('CP-HU07-01 PASÓ');
    });

    test('CP-HU07-02: fromJson usa valores por defecto si faltan campos', () {

      final json = <String, dynamic>{};

      final model = AlertaConfigModel.fromJson(json);

      expect(model.id, isNull);
      expect(model.usuarioId, '');
      expect(model.radioMetros, 500);
      expect(model.activo, true);

      print('CP-HU07-02 PASÓ');
    });

    test('CP-HU07-03: defaults crea configuración inicial correcta', () {

      final model = AlertaConfigModel.defaults('user-abc');

      expect(model.id, isNull);
      expect(model.usuarioId, 'user-abc');
      expect(model.radioMetros, 500);
      expect(model.activo, true);

      print('CP-HU07-03 PASÓ');
    });
  });

  group('HU-07 Frontend - AuthStorage', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AuthStorage.clear();
    });

    test('CP-HU07-04: saveToken y getToken guardan/leen token', () async {

      await AuthStorage.saveToken('fake-jwt');

      final token = await AuthStorage.getToken();

      expect(token, 'fake-jwt');

      print('CP-HU07-04 PASÓ');
    });

    test('CP-HU07-05: saveUserId y getUserId guardan/leen user id', () async {

      await AuthStorage.saveUserId('user-123');

      final userId = await AuthStorage.getUserId();

      expect(userId, 'user-123');

      print('CP-HU07-05 PASÓ');
    });

    test('CP-HU07-06: getValidToken retorna token si no ha expirado', () async {

      await AuthStorage.saveToken('valid-token');

      final token = await AuthStorage.getValidToken();

      expect(token, 'valid-token');

      print('CP-HU07-06 PASÓ');
    });

    test('CP-HU07-07: getValidToken retorna null si no existe timestamp', () async {

      SharedPreferences.setMockInitialValues({
        'auth_token': 'token-sin-timestamp',
      });

      final token = await AuthStorage.getValidToken();

      expect(token, isNull);
      expect(await AuthStorage.getToken(), isNull);

      print('CP-HU07-07 PASÓ');
    });

    test('CP-HU07-08: getValidToken expira token por inactividad', () async {

      final expiredTimestamp = DateTime.now()
          .subtract(
            Duration(minutes: AuthStorage.inactivityTimeoutMinutes + 1),
          )
          .millisecondsSinceEpoch;

      SharedPreferences.setMockInitialValues({
        'auth_token': 'expired-token',
        'token_timestamp': expiredTimestamp,
        'user_id': 'user-123',
      });

      final token = await AuthStorage.getValidToken();

      expect(token, isNull);
      expect(await AuthStorage.getToken(), isNull);
      expect(await AuthStorage.getUserId(), isNull);

      print('CP-HU07-08 PASÓ');
    });

    test('CP-HU07-09: refreshActivity actualiza timestamp si hay token', () async {

      await AuthStorage.saveToken('refresh-token');

      final prefsBefore = await SharedPreferences.getInstance();
      final before = prefsBefore.getInt('token_timestamp');

      await Future.delayed(const Duration(milliseconds: 5));
      await AuthStorage.refreshActivity();

      final prefsAfter = await SharedPreferences.getInstance();
      final after = prefsAfter.getInt('token_timestamp');

      expect(before, isNotNull);
      expect(after, isNotNull);
      expect(after! >= before!, true);

      print('CP-HU07-09 PASÓ');
    });

    test('CP-HU07-10: clear elimina token, user id y timestamp', () async {

      await AuthStorage.saveToken('token-a-borrar');
      await AuthStorage.saveUserId('user-a-borrar');

      await AuthStorage.clear();

      expect(await AuthStorage.getToken(), isNull);
      expect(await AuthStorage.getUserId(), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('token_timestamp'), isNull);

      print('CP-HU07-10 PASÓ');
    });
  });
}