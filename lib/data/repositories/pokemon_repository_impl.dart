import 'package:test01/domain/entities/pokemon.dart';
import 'package:test01/domain/repositories/pokemon_repository.dart';
import 'package:test01/data/datasources/pokemon_remote_data_source.dart';

// Repository実装（Data層）
// ・Domain層が期待する「Repositoryインターフェース」を具体的に実装
// ・DataSource（HTTP呼び出し）へ処理を委譲し、必要に応じて入力検証などを行う
class PokemonRepositoryImpl implements PokemonRepository {
  final PokemonRemoteDataSource remote;
  const PokemonRepositoryImpl(this.remote);

  @override
  Future<List<Pokemon>> getPokemonList({int limit = 30, int offset = 0}) async {
    if (limit <= 0) throw ArgumentError('limit must be positive');
    if (offset < 0) throw ArgumentError('offset must be >= 0');
    return remote.fetchList(limit: limit, offset: offset);
  }
}
