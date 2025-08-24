import 'package:test01/domain/entities/pokemon_localized_name.dart';

// Domain Repository（抽象）: 日本語などローカライズ名を扱う
abstract class PokemonLocalizationRepository {
  // 指定ID群のローカライズ名をまとめて取得
  // localePriority: 優先順（例: ['ja-Hrkt', 'ja', 'en']）
  Future<Map<int, PokemonLocalizedName>> getLocalizedNamesByIds(
    List<int> ids, {
    List<String> localePriority = const ['ja-Hrkt', 'ja', 'en'],
    int concurrency = 6,
  });
}

