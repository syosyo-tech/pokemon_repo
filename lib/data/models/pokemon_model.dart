import 'package:test01/domain/entities/pokemon.dart';

// Model（Data層の表現）
// ・APIレスポンス（JSON）からアプリ内で扱う型へ変換
// ・DomainのEntityを拡張して使っています
class PokemonModel extends Pokemon {
  const PokemonModel({
    required super.id,
    required super.name,
    required super.imageUrl,
    required super.height,
    required super.weight,
    required super.base_experience,
    required super.types,
    required super.moves,
  });

  // 詳細APIのJSONからModelを作るコンストラクタ
  factory PokemonModel.fromJson(Map<String, dynamic> json) {
    final sprites = json['sprites'] ?? {};
    final other = sprites['other'] ?? {};
    final officialArtwork =
        (other is Map) ? other['official-artwork'] as Map<String, dynamic>? : null;

    final imageUrl = (officialArtwork != null && officialArtwork['front_default'] != null)
        ? officialArtwork['front_default'] as String
        : (sprites['front_default'] as String? ?? '');

    return PokemonModel(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: imageUrl,
      height: (json['height'] as int).toString(),
      weight: (json['weight'] as int).toString(),
      base_experience: (json['base_experience'] as int),
      types: (json['types'] as List)
          .map((t) => t['type']['name'] as String)
          .join(', '),
      moves: (json['moves'] as List)
          .map((m) => m['move']['name'] as String)
          .join(', '),
    );
  }
}
