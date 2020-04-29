import 'package:seven_spot_mobile/models/Firing.dart';
import 'package:seven_spot_mobile/services/FiringService.dart';

class FiringRepository {
  FiringService _service;

  FiringRepository(FiringService service) {
    _service = service;
  }

  Future<Iterable<Firing>> getAll() async  {
    var dtos = await _service.getAll();

    return dtos.map((dto) => dto.toModel()).toList();
  }

  Future<Firing> getFiring(String firingId) async {
    var dto = await _service.getFiring(firingId);

    return dto.toModel();
  }
}