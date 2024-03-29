import 'package:flutter/widgets.dart';
import 'package:pottery_studio/models/Opening.dart';
import 'package:pottery_studio/repositories/OpeningRepository.dart';

class GetOpeningUseCase extends ChangeNotifier {
  Opening _opening;

  Opening get opening => _opening;

  OpeningRepository _repo;

  GetOpeningUseCase(OpeningRepository repo) {
    _repo = repo;
  }

  Future invoke(String openingId) async {
    _opening = await _repo.getOpening(openingId);

    notifyListeners();
  }

  void clear() {
    _opening = null;

    notifyListeners();
  }
}
