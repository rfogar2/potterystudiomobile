import 'package:seven_spot_mobile/repositories/UserRepository.dart';
import 'package:seven_spot_mobile/services/AuthService.dart';

class CreateUserUseCase {
  UserRepository _repo;
  AuthService _authService;

  CreateUserUseCase(AuthService authService) {
    _repo = UserRepository();
    _authService = authService;
  }

  Future<void> createUser(companySecret) async {
    var success = await _repo.createUser(companySecret);

    if (success) {
      _authService.updateState(AppState.VALIDATED);
    }
  }
}