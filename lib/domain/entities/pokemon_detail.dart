// 詳細表示用のドメインエンティティ
class PokemonDetail {
  final int id;
  final String name;
  final String imageUrl;
  final int height; // decimeter 単位（API仕様）
  final int weight; // hectogram 単位（API仕様）
  final List<String> types;
  final List<String> abilities;
  final Map<String, int> stats; // base stats: hp/attack/...
  final String description; // 図鑑説明（日本語優先）
  final PokemonTypeChart typeChart; // 弱点・耐性まとめ
  final List<EvolutionEntry> evolutionChain; // 進化チェーン（左→右）

  const PokemonDetail({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.height,
    required this.weight,
    required this.types,
    required this.abilities,
    required this.stats,
    required this.description,
    required this.typeChart,
    required this.evolutionChain,
  });
}

class PokemonTypeChart {
  final List<String> x4;
  final List<String> x2;
  final List<String> x0_5;
  final List<String> x0_25;
  final List<String> x0;

  const PokemonTypeChart({
    required this.x4,
    required this.x2,
    required this.x0_5,
    required this.x0_25,
    required this.x0,
  });
}

class EvolutionEntry {
  final int id;
  final String name;
  final String imageUrl;

  const EvolutionEntry({required this.id, required this.name, required this.imageUrl});
}
