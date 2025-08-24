import 'package:test01/domain/entities/pokemon_detail.dart';

class PokemonDetailModel extends PokemonDetail {
  const PokemonDetailModel({
    required super.id,
    required super.name,
    required super.imageUrl,
    required super.height,
    required super.weight,
    required super.types,
    required super.abilities,
    required super.stats,
    required super.description,
    required super.typeChart,
    required super.evolutionChain,
  });

  factory PokemonDetailModel.fromJson(Map<String, dynamic> json) {
    final sprites = json['sprites'] ?? {};
    final other = sprites['other'] ?? {};
    final officialArtwork =
        (other is Map) ? other['official-artwork'] as Map<String, dynamic>? : null;

    final imageUrl = (officialArtwork != null && officialArtwork['front_default'] != null)
        ? officialArtwork['front_default'] as String
        : (sprites['front_default'] as String? ?? '');

    final types = ((json['types'] as List<dynamic>? ?? [])
            .map((e) => ((e as Map)['type'] as Map?)?['name'] as String? ?? '')
            .where((e) => e.isNotEmpty))
        .cast<String>()
        .toList(growable: false);

    final abilities = ((json['abilities'] as List<dynamic>? ?? [])
            .map((e) => ((e as Map)['ability'] as Map?)?['name'] as String? ?? '')
            .where((e) => e.isNotEmpty))
        .cast<String>()
        .toList(growable: false);

    // base stats
    final statsList = (json['stats'] as List<dynamic>? ?? []);
    final Map<String, int> stats = {};
    for (final s in statsList) {
      final m = (s as Map<String, dynamic>);
      final statName = (m['stat'] as Map?)?['name'] as String? ?? '';
      final base = m['base_stat'] as int? ?? 0;
      if (statName.isNotEmpty) stats[statName] = base;
    }

    return PokemonDetailModel(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: imageUrl,
      height: json['height'] as int? ?? 0,
      weight: json['weight'] as int? ?? 0,
      types: types,
      abilities: abilities,
      stats: stats,
      description: '',
      typeChart: const PokemonTypeChart(x4: [], x2: [], x0_5: [], x0_25: [], x0: []),
      evolutionChain: const [],
    );
  }
}
