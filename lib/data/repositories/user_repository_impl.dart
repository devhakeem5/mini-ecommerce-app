import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  @override
  Future<User> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    return const UserModel(
      id: '1',
      name: 'عبدالحكيم النجار',
      email: 'hakeem@example.com',
      avatarUrl: null,
      role: 'Senior Flutter Developer',
    );
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
