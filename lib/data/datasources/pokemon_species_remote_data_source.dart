import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test01/data/models/pokemon_localized_name_model.dart';

// speciesエンドポイントからローカライズ名を取得するDataSource
abstract class PokemonSpeciesRemoteDataSource {
  Future<Map<int, PokemonLocalizedNameModel>> fetchLocalizedNamesByIds(
    List<int> ids, {
    List<String> localePriority = const ['ja-Hrkt', 'ja', 'en'],
    int concurrency = 6,
  });

  Future<SpeciesDetail> fetchSpeciesDetail(
    int id, {
    List<String> localePriority = const ['ja-Hrkt', 'ja', 'en'],
  });
  Future<List<int>> fetchEvolutionChainIds(int chainId);
  Future<int?> searchIdByLocalizedName(
    String name, {
    List<String> localePriority = const ['ja-Hrkt', 'ja', 'en'],
    int concurrency = 8,
  });
}

class PokemonSpeciesRemoteDataSourceImpl
    implements PokemonSpeciesRemoteDataSource {
  final http.Client client;
  PokemonSpeciesRemoteDataSourceImpl({http.Client? client})
    : client = client ?? http.Client();

  // 共通のヘッダー設定
  Map<String, String> get _headers => {
    'User-Agent': 'PokemonApp/1.0',
    'Accept': 'application/json',
  };

  @override
  Future<Map<int, PokemonLocalizedNameModel>> fetchLocalizedNamesByIds(
    List<int> ids, {
    List<String> localePriority = const ['ja-Hrkt', 'ja', 'en'],
    int concurrency = 6,
  }) async {
    final Map<int, PokemonLocalizedNameModel> result = {};
    for (int i = 0; i < ids.length; i += concurrency) {
      final end = (i + concurrency > ids.length)
          ? ids.length
          : (i + concurrency);
      final futures = <Future<void>>[];
      for (int j = i; j < end; j++) {
        final id = ids[j];
        futures.add(() async {
          final url = Uri.parse(
            'https://pokeapi.co/api/v2/pokemon-species/$id/',
          );
          final res = await client.get(url, headers: _headers);
          if (res.statusCode != 200) return;
          final map =
              jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
          final names = (map['names'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
          final model = PokemonLocalizedNameModel.fromNames(
            id,
            names,
            localePriority,
          );
          if (model.name.isNotEmpty) {
            result[id] = model;
          }
        }());
      }
      await Future.wait(futures);
    }
    return result;
  }

  @override
  Future<SpeciesDetail> fetchSpeciesDetail(
    int id, {
    List<String> localePriority = const ['ja-Hrkt', 'ja', 'en'],
  }) async {
    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon-species/$id/');
    final res = await client.get(url, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final map = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final names = (map['names'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final flavorList = (map['flavor_text_entries'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    String? chooseName() {
      for (final code in localePriority) {
        for (final n in names) {
          final lang =
              (n['language'] as Map<String, dynamic>?)?['name'] as String?;
          if (lang == code) return n['name'] as String?;
        }
      }
      return null;
    }

    String? chooseFlavor() {
      for (final code in localePriority) {
        for (final f in flavorList) {
          final lang =
              (f['language'] as Map<String, dynamic>?)?['name'] as String?;
          if (lang == code) {
            final txt = f['flavor_text'] as String?;
            if (txt != null) {
              return txt.replaceAll('\n', ' ').replaceAll('\f', ' ');
            }
          }
        }
      }
      return null;
    }

    final evoUrl = (map['evolution_chain'] as Map?)?['url'] as String?;
    final evoIdMatch = evoUrl != null
        ? RegExp(r"/evolution-chain/(\d+)/").firstMatch(evoUrl)
        : null;
    final chainId = evoIdMatch != null ? int.parse(evoIdMatch.group(1)!) : null;

    return SpeciesDetail(
      displayName: chooseName() ?? '',
      description: chooseFlavor() ?? '',
      evolutionChainId: chainId,
    );
  }

  @override
  Future<List<int>> fetchEvolutionChainIds(int chainId) async {
    final url = Uri.parse(
      'https://pokeapi.co/api/v2/evolution-chain/$chainId/',
    );
    final res = await client.get(url, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final map = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List<int> ids = [];

    void walk(Map<String, dynamic> node) {
      final species = node['species'] as Map<String, dynamic>?;
      final url = species?['url'] as String?;
      if (url != null) {
        final m = RegExp(r"/pokemon-species/(\d+)/").firstMatch(url);
        if (m != null) ids.add(int.parse(m.group(1)!));
      }
      final evolves = (node['evolves_to'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      for (final e in evolves) {
        walk(e);
      }
    }

    final chain = map['chain'] as Map<String, dynamic>?;
    if (chain != null) walk(chain);
    return ids;
  }

  @override
  Future<int?> searchIdByLocalizedName(
    String name, {
    List<String> localePriority = const ['ja-Hrkt', 'ja', 'en'],
    int concurrency = 8,
  }) async {
    final target = name.trim();
    if (target.isEmpty) return null;
    // 全speciesのURL一覧を取得してIDリスト化
    final listUrl = Uri.parse(
      'https://pokeapi.co/api/v2/pokemon-species?limit=2000&offset=0',
    );
    final listRes = await client.get(listUrl, headers: _headers);
    if (listRes.statusCode != 200) return null;
    final listMap =
        jsonDecode(utf8.decode(listRes.bodyBytes)) as Map<String, dynamic>;
    final results = (listMap['results'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final ids = <int>[];
    for (final r in results) {
      final url = r['url'] as String?;
      if (url == null) continue;
      final m = RegExp(r"/pokemon-species/(\d+)/").firstMatch(url);
      if (m != null) ids.add(int.parse(m.group(1)!));
    }

    int? found;
    for (int i = 0; i < ids.length && found == null; i += concurrency) {
      final end = (i + concurrency > ids.length)
          ? ids.length
          : (i + concurrency);
      final futures = <Future<void>>[];
      for (int j = i; j < end; j++) {
        final id = ids[j];
        futures.add(() async {
          if (found != null) return; // 早期終了
          try {
            final s = await fetchSpeciesDetail(
              id,
              localePriority: localePriority,
            );
            final candidates = <String>[s.displayName];
            // 念のためja-Hrkt/ja両方比較するため再取得せず大文字小文字/全角半角差を無視
            if (candidates.any((n) => n == target)) {
              found = id;
            }
          } catch (_) {}
        }());
      }
      await Future.wait(futures);
      if (found != null) break;
    }
    return found;
  }
}

class SpeciesDetail {
  final String displayName;
  final String description;
  final int? evolutionChainId;
  const SpeciesDetail({
    required this.displayName,
    required this.description,
    required this.evolutionChainId,
  });
}
