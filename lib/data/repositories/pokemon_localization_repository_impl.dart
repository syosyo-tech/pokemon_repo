import 'package:test01/domain/entities/pokemon_localized_name.dart';
import 'package:test01/domain/repositories/pokemon_localization_repository.dart';
import 'package:test01/data/datasources/pokemon_species_remote_data_source.dart';

// ローカライズ名リポジトリの実装
class PokemonLocalizationRepositoryImpl implements PokemonLocalizationRepository {
  final PokemonSpeciesRemoteDataSource remote;
  const PokemonLocalizationRepositoryImpl(this.remote);

  @override
  Future<Map<int, PokemonLocalizedName>> getLocalizedNamesByIds(
    List<int> ids, {
    List<String> localePriority = const ['ja-Hrkt', 'ja', 'en'],
    int concurrency = 6,
  }) async {
    if (ids.isEmpty) return {};
    final map = await remote.fetchLocalizedNamesByIds(
      ids,
      localePriority: localePriority,
      concurrency: concurrency,
    );
    // DataSourceはModelを返すが、DomainはEntityとして扱うためそのままMapを返す
    return map;
  }
}

