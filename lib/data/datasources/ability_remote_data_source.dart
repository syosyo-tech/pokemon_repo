import 'dart:convert';

import 'package:http/http.dart' as http;

class AbilityRemoteDataSource {
  final http.Client client;
  AbilityRemoteDataSource({http.Client? client}) : client = client ?? http.Client();

  Future<Map<String, String>> fetchLocalizedNames(
    List<String> abilitySlugs, {
    List<String> localePriority = const ['ja-Hrkt', 'ja', 'en'],
    int concurrency = 6,
  }) async {
    final Map<String, String> map = {};
    for (int i = 0; i < abilitySlugs.length; i += concurrency) {
      final end = (i + concurrency > abilitySlugs.length) ? abilitySlugs.length : (i + concurrency);
      final futures = <Future<void>>[];
      for (int j = i; j < end; j++) {
        final slug = abilitySlugs[j];
        futures.add(() async {
          final url = Uri.parse('https://pokeapi.co/api/v2/ability/$slug/');
          final res = await client.get(url);
          if (res.statusCode != 200) return;
          final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
          final names = (body['names'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
          String? chosen;
          for (final code in localePriority) {
            for (final n in names) {
              final lang = (n['language'] as Map<String, dynamic>?)?['name'] as String?;
              if (lang == code) {
                chosen = n['name'] as String?;
                break;
              }
            }
            if (chosen != null && chosen!.isNotEmpty) break;
          }
          if (chosen != null && chosen!.isNotEmpty) {
            map[slug] = chosen!;
          }
        }());
      }
      await Future.wait(futures);
    }
    return map;
  }
}

