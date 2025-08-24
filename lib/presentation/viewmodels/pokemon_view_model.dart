import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:test01/domain/entities/pokemon.dart';
import 'package:test01/domain/repositories/pokemon_repository.dart';
import 'package:test01/domain/repositories/pokemon_localization_repository.dart';

// PokemonViewModel
// ・UIに表示するための「状態」を持つクラス（ChangeNotifier）
// ・リストのデータ、読み込み中フラグ、エラーなどを保持
// ・Repositoryを使ってデータを取得し、UIへ反映（notifyListeners）
class PokemonViewModel extends ChangeNotifier {
  // 一覧用の状態のみ
  final List<Pokemon> _list = [];
  String? _listError;
  bool _listLoading = false;
  int _offset = 0;
  final int _limit = 30;
  final List<String> preferredLocales = const ['ja-Hrkt', 'ja', 'en'];

  PokemonViewModel();

  List<Pokemon> get list => List.unmodifiable(_list);
  String? get listError => _listError;
  bool get listLoading => _listLoading;

  @override
  void dispose() {
    super.dispose();
  }

  // 一覧のロード（初期表示）
  // 先に保持しているリストをクリアし、最初のページを読み込みます。
  Future<void> loadInitialList(
    PokemonRepository repository,
    PokemonLocalizationRepository localizationRepository,
  ) async {
    _list.clear();
    _offset = 0;
    _listError = null;
    await _loadMoreInternal(repository, localizationRepository);
  }

  // 追加ロード
  // 「もっと読む」押下時に次のページを読み込みます。
  Future<void> loadMore(
    PokemonRepository repository,
    PokemonLocalizationRepository localizationRepository,
  ) async {
    await _loadMoreInternal(repository, localizationRepository);
  }

  // 実際のロード処理（重複リクエストを避けるためにloading中は無視）
  Future<void> _loadMoreInternal(
    PokemonRepository repository,
    PokemonLocalizationRepository localizationRepository,
  ) async {
    if (_listLoading) return;
    _listLoading = true;
    notifyListeners();
    try {
      final page = await repository.getPokemonList(limit: _limit, offset: _offset);
      // 日本語名に差し替え
      final ids = page.map((e) => e.id).toList(growable: false);
      final locMap = await localizationRepository.getLocalizedNamesByIds(
        ids,
        localePriority: preferredLocales,
      );
      final localized = page.map((p) {
        final loc = locMap[p.id];
        final name = (loc != null && loc.name.isNotEmpty) ? loc.name : p.name;
        return Pokemon(id: p.id, name: name, imageUrl: p.imageUrl,
          height: p.height, weight: p.weight, base_experience: p.base_experience,
          types: p.types, moves: p.moves);
      }).toList();
      _list.addAll(localized);
      _offset += _limit;
      _listError = null;
    } catch (e) {
      _listError = '一覧の取得に失敗しました: $e';
    } finally {
      _listLoading = false;
      notifyListeners();
    }
  }
}
