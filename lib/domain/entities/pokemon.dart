// Domain Entity（アプリの中心となるデータ構造）
// ・外部ライブラリに依存しない「純粋なデータ」
// ・UIやデータ取得方法が変わっても、この構造は基本的に変わりません
class Pokemon {
  final int id;
  final String name;
  final String imageUrl;
  final String height;
  final String weight;
  final int base_experience;
  final String types;
  final String moves;



  const Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.height,
    required this.weight,
    required this.base_experience,
    required this.types,
    required this.moves,
  });
}
