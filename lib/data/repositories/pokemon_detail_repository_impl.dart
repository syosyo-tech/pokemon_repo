import 'package:test01/data/datasources/pokemon_remote_data_source.dart';
import 'package:test01/data/datasources/pokemon_species_remote_data_source.dart';
import 'package:test01/data/datasources/type_remote_data_source.dart';
import 'package:test01/data/datasources/ability_remote_data_source.dart';
import 'package:test01/domain/entities/pokemon_detail.dart';
import 'package:test01/domain/repositories/pokemon_detail_repository.dart';
import 'package:test01/data/models/pokemon_model.dart';
import 'package:test01/data/models/pokemon_localized_name_model.dart';
import 'package:test01/data/models/pokemon_detail_model.dart';

class PokemonDetailRepositoryImpl implements PokemonDetailRepository {
  final PokemonRemoteDataSource remote;
  final PokemonSpeciesRemoteDataSource species;
  final TypeRemoteDataSource typeRemote;
  final AbilityRemoteDataSource abilityRemote;
  const PokemonDetailRepositoryImpl(this.remote, this.species, this.typeRemote, this.abilityRemote);

  @override
  Future<PokemonDetail> getDetail(int id) async {
    if (id <= 0) {
      throw ArgumentError('id must be positive');
    }
    var detail = await remote.fetchDetail(id);
    // Species: description + evolution chain id + localized name (optional)
    final s = await species.fetchSpeciesDetail(id);

    // Evolution chain ids
    List<EvolutionEntry> evo = const [];
    if (s.evolutionChainId != null) {
      final ids = await species.fetchEvolutionChainIds(s.evolutionChainId!);
      // 日本語名を取得
      final locMap = await species.fetchLocalizedNamesByIds(ids, localePriority: const ['ja-Hrkt', 'ja', 'en']);
      evo = ids.map((evoId) {
        final img = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$evoId.png';
        final loc = locMap[evoId];
        final name = (loc != null && loc.name.isNotEmpty) ? loc.name : '';
        return EvolutionEntry(id: evoId, name: name, imageUrl: img);
      }).toList();
    }

    // Ability names (Japanese if available)
    if (detail.abilities.isNotEmpty) {
      final abMap = await abilityRemote.fetchLocalizedNames(
        detail.abilities,
        localePriority: const ['ja-Hrkt', 'ja', 'en'],
      );
      // 取得できたものだけ差し替え
      detail = PokemonDetailModel(
        id: detail.id,
        name: detail.name,
        imageUrl: detail.imageUrl,
        height: detail.height,
        weight: detail.weight,
        types: detail.types,
        abilities: detail.abilities.map((a) => abMap[a] ?? a).toList(),
        stats: detail.stats,
        description: detail.description,
        typeChart: detail.typeChart,
        evolutionChain: detail.evolutionChain,
      );
    }

    // Type chart: combine relations for all types
    final Map<String, double> mult = {};
    void applyMult(String type, double m) {
      mult[type] = (mult[type] ?? 1.0) * m;
    }
    for (final t in detail.types) {
      final rel = await typeRemote.fetchRelations(t);
      for (final ty in rel.doubleFrom) applyMult(ty, 2.0);
      for (final ty in rel.halfFrom) applyMult(ty, 0.5);
      for (final ty in rel.noFrom) applyMult(ty, 0.0);
    }
    // categorize
    List<String> x4 = [];
    List<String> x2 = [];
    List<String> x0_5 = [];
    List<String> x0_25 = [];
    List<String> x0 = [];
    mult.forEach((k, v) {
      if (v == 0.0) {
        x0.add(k);
      } else if (v >= 3.5) {
        x4.add(k);
      } else if (v >= 1.5) {
        x2.add(k);
      } else if (v <= 0.26) {
        x0_25.add(k);
      } else if (v <= 0.74) {
        x0_5.add(k);
      }
    });

    return PokemonDetail(
      id: detail.id,
      name: s.displayName.isNotEmpty ? s.displayName : detail.name,
      imageUrl: detail.imageUrl,
      height: detail.height,
      weight: detail.weight,
      types: detail.types,
      abilities: detail.abilities,
      stats: detail.stats,
      description: s.description,
      typeChart: PokemonTypeChart(
        x4: x4..sort(),
        x2: x2..sort(),
        x0_5: x0_5..sort(),
        x0_25: x0_25..sort(),
        x0: x0..sort(),
      ),
      evolutionChain: evo,
    );
  }
}
