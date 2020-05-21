import 'package:seven_spot_mobile/models/User.dart';
import 'package:seven_spot_mobile/services/UserService.dart';

class UserRepository {
  UserService _service;

  UserRepository() {
    _service = UserService();
  }

  Future<bool> createUser(String studioCode, String displayName) async {
    return await _service.createUser(studioCode, displayName);
  }

  Future<User> getUser() async {
    var userDto = await _service.getUser();

    return userDto.toModel();
  }

  Future<void> deleteUser() async {
    return await _service.deleteUser();
  }
}
