import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:civictrackio_app/features/user/data/datasources/perfil_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'fake-token-test',
      'user_id': '123',
      'token_timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    await dotenv.load(
      fileName: '.env',
      isOptional: true,
      mergeWith: {
        'API_BASE_URL': 'http://localhost:3000',
      },
    );
  });

  group('HU-21 Unitarias Flutter - PerfilDatasource.eliminarCuenta', () {
    test('CP-HU21-F-01 envía DELETE con password', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.toString(), 'http://localhost:3000/api/perfil');
        expect(request.headers['Authorization'], 'Bearer fake-token-test');
        expect(request.headers['Content-Type'], 'application/json');
        expect(jsonDecode(request.body)['password'], 'ClaveValida123');

        return http.Response(jsonEncode({'message': 'ok'}), 200);
      });

      final datasource = PerfilDatasource(client: client);

      await datasource.eliminarCuenta(password: 'ClaveValida123');
    });

    test('CP-HU21-F-02 envía DELETE sin password cuando no aplica', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.toString(), 'http://localhost:3000/api/perfil');
        expect(request.headers['Authorization'], 'Bearer fake-token-test');
        expect(request.headers['Content-Type'], 'application/json');

        final body = jsonDecode(request.body);
        expect(body.containsKey('password'), false);

        return http.Response(jsonEncode({'message': 'ok'}), 200);
      });

      final datasource = PerfilDatasource(client: client);

      await datasource.eliminarCuenta();
    });

    test('CP-HU21-F-03 propaga mensaje de error del backend', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Contraseña incorrecta'}),
          401,
        );
      });

      final datasource = PerfilDatasource(client: client);

      await expectLater(
        datasource.eliminarCuenta(password: 'mala'),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('Contraseña incorrecta'),
          ),
        ),
      );
    });
  });
}