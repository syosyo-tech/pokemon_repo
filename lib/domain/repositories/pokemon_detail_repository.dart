import 'package:test01/domain/entities/pokemon_detail.dart';

abstract class PokemonDetailRepository {
  Future<PokemonDetail> getDetail(int id);
}

