import '../../domain/entities/user_Entity.dart';
import '../../domain/repositories/user_Repository.dart';
import '../datasources/user_Remote_Datasource.dart';

class UserRepositoryImpl implements UserRepository {

  final UserRemoteDatasource remoteDatasource;

  UserRepositoryImpl(this.remoteDatasource);

  @override
  Future<UserEntity> login({
    required String correo,
    required String password
  }) {
    return remoteDatasource.login(correo: correo, password: password);
  }

  @override
  Future<UserEntity> register({
    required String username,
    required String correo,
    required String password
  }) {
    return remoteDatasource.register(username: username, correo: correo, password: password);
  }

}