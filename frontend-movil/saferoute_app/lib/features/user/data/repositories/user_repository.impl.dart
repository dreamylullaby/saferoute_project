import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {

  final UserRemoteDatasource remoteDatasource;

  UserRepositoryImpl(this.remoteDatasource);

  @override
  Future<UserEntity> login({

    required String correo,
    required String password

  }) {

    return remoteDatasource.login(

      correo: correo,
      password: password

    );

  }

}