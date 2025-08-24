import 'package:test01/domain/entities/pokemon.dart';

// Domain Repository（抽象）
// ・「ポケモン一覧を取得する」というアプリの要求（契約）だけを定義
// ・ここでは実装しません（実装はData層）。
abstract class PokemonRepository {
  Future<List<Pokemon>> getPokemonList({int limit = 30, int offset = 0});
}
