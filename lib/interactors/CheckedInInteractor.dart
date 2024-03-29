import 'package:flutter/material.dart';
import 'package:pottery_studio/usecases/CheckInUseCase.dart';
import 'package:pottery_studio/usecases/CheckOutUseCase.dart';
import 'package:pottery_studio/usecases/GetPresentUsersUseCase.dart';
import 'package:pottery_studio/usecases/GetUserUseCase.dart';

class CheckedInInteractor extends ChangeNotifier {
  GetUserUseCase _getUserUseCase;
  CheckInUseCase _checkInUseCase;
  CheckOutUseCase _checkOutUseCase;
  GetPresentUsersUseCase _getPresentUsersUseCase;

  bool _checkingInOrOut = false;

  bool get checkingInOrOut => _checkingInOrOut;

  bool get loadingPresentUsers =>
      _getPresentUsersUseCase.loading || _getUserUseCase.user == null;

  bool get checkedIn => _getPresentUsersUseCase.presentUsers
      .where((user) => user.id == _getUserUseCase.user?.id)
      .isNotEmpty;

  CheckedInInteractor(
      GetUserUseCase getUserUseCase,
      CheckInUseCase checkInUseCase,
      CheckOutUseCase checkOutUseCase,
      GetPresentUsersUseCase getPresentUsersUseCase) {
    _getUserUseCase = getUserUseCase;
    _checkInUseCase = checkInUseCase;
    _checkOutUseCase = checkOutUseCase;
    _getPresentUsersUseCase = getPresentUsersUseCase;
  }

  void update() {
    notifyListeners();
  }

  Future<void> toggle() async {
    _checkingInOrOut = true;
    notifyListeners();

    try {
      await (checkedIn ? _checkOutUseCase.invoke() : _checkInUseCase.invoke());
      await _getPresentUsersUseCase.invoke();
    } catch (e) {
      throw e;
    } finally {
      _checkingInOrOut = false;
      notifyListeners();
    }
  }
}
