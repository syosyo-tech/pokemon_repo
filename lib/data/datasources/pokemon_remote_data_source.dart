import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test01/data/models/pokemon_model.dart';
import 'package:test01/data/models/pokemon_detail_model.dart';

// DataSource（リモート）
// ・HTTP経由でPokeAPIからデータを取得
// ・この層は「外部との通信」を担当し、Domain層には依存しません
abstract class PokemonRemoteDataSource {
  Future<List<PokemonModel>> fetchList({int limit = 30, int offset = 0});
  Future<PokemonDetailModel> fetchDetail(int id);
  Future<PokemonDetailModel> fetchDetailByKey(String key);
}

class PokemonRemoteDataSourceImpl implements PokemonRemoteDataSource {
  final http.Client client;
  PokemonRemoteDataSourceImpl({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<List<PokemonModel>> fetchList({int limit = 30, int offset = 0}) async {
    // PokeAPIの一覧エンドポイントを叩いて、「名前」と「詳細URL」のリストを取得
    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=$limit&offset=$offset');
    final res = await client.get(url);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final map = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final results = (map['results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    // 詳細URLからIDを抽出し、公式アートの画像URLを組み立てます
    List<PokemonModel> list = [];
    for (final item in results) {
      final name = item['name'] as String? ?? '';
      final detailUrl = item['url'] as String? ?? '';
      // URL末尾のIDを抽出（例: .../pokemon/25/）
      final idMatch = RegExp(r"/pokemon/(\d+)/?").firstMatch(detailUrl);
      if (name.isEmpty || idMatch == null) continue;
      final id = int.parse(idMatch.group(1)!);
      final imageUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
      list.add(PokemonModel(id: id, name: name, imageUrl: imageUrl,
        height: '', weight: '', base_experience: 0, types: '', moves: ''));
    }
    return list;
  }

  @override
  Future<PokemonDetailModel> fetchDetail(int id) async {
    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon/$id/');
    final res = await client.get(url);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final map = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return PokemonDetailModel.fromJson(map);
  }

  @override
  Future<PokemonDetailModel> fetchDetailByKey(String key) async {
    final k = key.trim().toLowerCase();
    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon/$k/');
    final res = await client.get(url);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final map = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return PokemonDetailModel.fromJson(map);
  }
}
