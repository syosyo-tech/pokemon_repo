import 'package:test01/domain/entities/pokemon_localized_name.dart';

// Data層のModel（DomainのEntityを拡張）
class PokemonLocalizedNameModel extends PokemonLocalizedName {
  const PokemonLocalizedNameModel({
    required super.id,
    required super.name,
    required super.language,
  });

  // speciesエンドポイントのnames配列から、優先順で最適な名前を選ぶ
  factory PokemonLocalizedNameModel.fromNames(
    int id,
    List<Map<String, dynamic>> names,
    List<String> localePriority,
  ) {
    String? chosenName;
    String chosenLang = 'en';
    for (final code in localePriority) {
      for (final n in names) {
        final lang = (n['language'] as Map<String, dynamic>?)?['name'] as String?;
        if (lang == code) {
          chosenName = n['name'] as String?;
          chosenLang = code;
          break;
        }
      }
      if (chosenName != null && chosenName!.isNotEmpty) break;
    }
    return PokemonLocalizedNameModel(
      id: id,
      name: chosenName ?? '',
      language: chosenLang,
    );
  }
}
