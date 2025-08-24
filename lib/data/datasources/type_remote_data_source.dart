import 'dart:convert';

import 'package:http/http.dart' as http;

class TypeRemoteDataSource {
  final http.Client client;
  TypeRemoteDataSource({http.Client? client}) : client = client ?? http.Client();

  Future<TypeRelations> fetchRelations(String typeName) async {
    final url = Uri.parse('https://pokeapi.co/api/v2/type/$typeName/');
    final res = await client.get(url);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final map = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final damage = map['damage_relations'] as Map<String, dynamic>;
    List<String> pick(String key) => ((damage[key] as List<dynamic>? ?? [])
            .map((e) => (e as Map)['name'] as String)
            .toList())
        .cast<String>();
    return TypeRelations(
      doubleFrom: pick('double_damage_from'),
      halfFrom: pick('half_damage_from'),
      noFrom: pick('no_damage_from'),
    );
  }
}

class TypeRelations {
  final List<String> doubleFrom;
  final List<String> halfFrom;
  final List<String> noFrom;
  const TypeRelations({required this.doubleFrom, required this.halfFrom, required this.noFrom});
}

