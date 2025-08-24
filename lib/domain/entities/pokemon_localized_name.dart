// Domain Entity: ローカライズされたポケモン名
// ・特定の言語コードにおける表示名を表します
class PokemonLocalizedName {
  final int id;            // 図鑑番号
  final String name;       // ローカライズ名
  final String language;   // 言語コード（例: ja-Hrkt, ja, en）

  const PokemonLocalizedName({
    required this.id,
    required this.name,
    required this.language,
  });
}

