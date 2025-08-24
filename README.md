# test01 (Pokemon App)

Flutter で PokeAPI からポケモン情報を取得して表示する最小アプリです。アプリはクリーンアーキテクチャで層分割されており、UI・ドメイン・データの責務を分離しています。

## Architecture (Clean Architecture)

層は次の3つで、依存は一方向（Presentation → Domain ← Data）です。

```
Presentation (UI / ViewModel)
        │
        ▼
Domain (Entity / Repository Abstraction / UseCase)
        ▲
        │
Data (Model / DataSource / Repository Impl)
```

- Presentation: 画面や状態管理（UIロジック）。UseCase を呼び出すだけで、HTTP などの詳細は知りません。
- Domain: ビジネスルールの中心。純粋な Dart（外部依存なし）で、Entity・抽象Repository・UseCaseを定義します。
- Data: 具体的な実装層。HTTP 通信や JSON パースなど詳細実装を担い、Domain の抽象Repositoryを実装します。

この分割により、UI を変えても Domain は影響を受けず、データ取得手段（REST→GraphQL→ローカルDB）を切り替えても Domain/Presentation を最小変更で保てます。

## Folder Structure

```
lib/
├─ main.dart                               # アプリ起動。画面を表示するだけ
├─ presentation/
│  ├─ pages/pokemon_page.dart              # 画面。ViewModel を監視して描画
│  └─ viewmodels/pokemon_view_model.dart   # 状態管理と入力検証、UseCase呼び出し
├─ domain/
│  ├─ entities/pokemon.dart                # ドメインエンティティ（純粋データ）
│  ├─ repositories/pokemon_repository.dart # 抽象リポジトリ（契約）
│  └─ usecases/get_pokemon_by_id.dart      # ユースケース（アプリケーションルール）
└─ data/
   ├─ models/pokemon_model.dart            # JSON→Model（Entityを拡張）
   ├─ datasources/pokemon_remote_data_source.dart # HTTPで取得・デコード
   └─ repositories/pokemon_repository_impl.dart   # 抽象Repoの実装
```

## File Roles

- `lib/main.dart`: MaterialApp のセットアップと初期画面の表示のみ。
- `presentation/pages/pokemon_page.dart`: テキスト入力・ボタン・結果表示。`PokemonViewModel` を `AnimatedBuilder` で監視。
- `presentation/viewmodels/pokemon_view_model.dart`: `ChangeNotifier` で状態管理。ID検証、ローディング/エラー管理、`GetPokemonById` を呼び出す。
- `domain/entities/pokemon.dart`: アプリが扱う純粋なデータ構造。外部ライブラリに依存しません。
- `domain/repositories/pokemon_repository.dart`: Domain が期待する取得インターフェイス（契約）。
- `domain/usecases/get_pokemon_by_id.dart`: 単一責務のユースケース。Repository 抽象に依存して取得を実行。
- `data/models/pokemon_model.dart`: PokeAPI の JSON をパースして Entity へ写像。
- `data/datasources/pokemon_remote_data_source.dart`: `http` でAPI呼び出し。`utf8.decode` で文字化け対策後に JSON デコード。
- `data/repositories/pokemon_repository_impl.dart`: Domain の抽象Repositoryを実装。引数検証などの薄いポリシーもここで実施。

## Data Flow

1. ユーザーが ID を入力して「取得」を押下
2. Presentation 層の `PokemonViewModel.fetch()` が `GetPokemonById` を実行
3. Domain 層の UseCase が Repository 抽象を呼び出し
4. Data 層の Repository 実装が RemoteDataSource で HTTP 取得・パース
5. 取得結果 `Pokemon` を Presentation へ返却し、UI を更新

## Run

- 実行: `flutter run`
- 依存: `http` パッケージ（Data層のみで使用）

注意: 初期テンプレートの `test/widget_test.dart` はカウンタ用のため、このアプリでは失敗します（必要なら後で更新してください）。

## Extend (次の一歩)

- DI 導入: `provider` / `riverpod` / `get_it` で依存組み立てを画面から分離
- エラーハンドリング: `Failure` 型やリトライ・タイムアウトポリシーの導入
- キャッシュ: ローカルDBやメモリキャッシュ DataSource を追加し、Repository で切替
- テスト: UseCase/Repository/DataSource のユニットテストを追加（Domain は純Dartでテスト容易）
