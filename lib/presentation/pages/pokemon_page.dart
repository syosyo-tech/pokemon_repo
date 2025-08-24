import 'package:flutter/material.dart';
import 'package:test01/data/datasources/pokemon_remote_data_source.dart';
import 'package:test01/data/repositories/pokemon_repository_impl.dart';
import 'package:test01/data/datasources/pokemon_species_remote_data_source.dart';
import 'package:test01/data/repositories/pokemon_localization_repository_impl.dart';
import 'package:test01/presentation/viewmodels/pokemon_view_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test01/presentation/pages/pokemon_detail_page.dart';

// PokemonPage
// ・この画面は「一覧表示のみ」を行います
// ・起動時に一覧を読み込み、下部の「もっと読む」で追加読み込み
// ・左に画像、右に名前のシンプルなリスト
class PokemonPage extends StatefulWidget {
  const PokemonPage({super.key});

  @override
  State<PokemonPage> createState() => _PokemonPageState();
}

class _PokemonPageState extends State<PokemonPage> {
  late final PokemonViewModel vm;
  late final PokemonRepositoryImpl repo;
  late final PokemonLocalizationRepositoryImpl locRepo;
  late final PokemonRemoteDataSourceImpl remoteDs;
  late final PokemonSpeciesRemoteDataSourceImpl speciesDs;
  final Map<int, List<String>> _typesById = {};

  @override
  void initState() {
    super.initState();
    // 簡易DI（依存関係の組み立て）
    // 本来は Provider/Riverpod などで分離するのがベターですが、
    // サンプルとして画面内で完結させています。
    remoteDs = PokemonRemoteDataSourceImpl();
    final ds = remoteDs;
    repo = PokemonRepositoryImpl(ds);
    speciesDs = PokemonSpeciesRemoteDataSourceImpl();
    locRepo = PokemonLocalizationRepositoryImpl(speciesDs);
    vm = PokemonViewModel();
    vm.loadInitialList(repo, locRepo).then((_) => _ensureTypesLoaded()); // 一覧読み込み後にタイプも取得
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  Future<void> _ensureTypesLoaded() async {
    final ids = vm.list.map((e) => e.id).where((id) => !_typesById.containsKey(id)).toList();
    if (ids.isEmpty) return;
    const concurrency = 6;
    for (int i = 0; i < ids.length; i += concurrency) {
      final end = (i + concurrency > ids.length) ? ids.length : (i + concurrency);
      final futures = <Future<void>>[];
      for (int j = i; j < end; j++) {
        final id = ids[j];
        futures.add(() async {
          try {
            final detail = await remoteDs.fetchDetail(id);
            _typesById[id] = detail.types;
          } catch (_) {}
        }());
      }
      await Future.wait(futures);
      if (mounted) setState(() {});
    }
  }

  Color _typeColor(String en) {
    switch (en.toLowerCase()) {
      case 'normal':
        return const Color(0xFFA8A77A);
      case 'fire':
        return const Color(0xFFEE8130);
      case 'water':
        return const Color(0xFF6390F0);
      case 'electric':
        return const Color(0xFFF7D02C);
      case 'grass':
        return const Color(0xFF7AC74C);
      case 'ice':
        return const Color(0xFF96D9D6);
      case 'fighting':
        return const Color(0xFFC22E28);
      case 'poison':
        return const Color(0xFFA33EA1);
      case 'ground':
        return const Color(0xFFE2BF65);
      case 'flying':
        return const Color(0xFFA98FF3);
      case 'psychic':
        return const Color(0xFFF95587);
      case 'bug':
        return const Color(0xFFA6B91A);
      case 'rock':
        return const Color(0xFFB6A136);
      case 'ghost':
        return const Color(0xFF735797);
      case 'dragon':
        return const Color(0xFF6F35FC);
      case 'dark':
        return const Color(0xFF705746);
      case 'steel':
        return const Color(0xFFB7B7CE);
      case 'fairy':
        return const Color(0xFFD685AD);
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ポケモン図鑑')),
      body: AnimatedBuilder(
        animation: vm, // ViewModel（ChangeNotifier）の変更を監視して再描画
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              if (vm.listError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(vm.listError!, style: const TextStyle(color: Colors.red)),
                ),
              // 親ListViewの中にさらにListViewを置くため、
              // shrinkWrap + NeverScrollableScrollPhysics で内側リストを独立スクロールさせない
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vm.list.length,
                // 区切り線ではなく間隔（余白）でタイルを区切る
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final p = vm.list[index];
                  final t = _typesById[p.id];
                  final bg = (t != null && t.isNotEmpty)
                      ? Color.alphaBlend(
                          _typeColor(t.first).withOpacity(0.08),
                          Theme.of(context).colorScheme.surface,
                        )
                      : null;
                  // タイル風のカード。縦幅を大きく（タイプ背景）
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PokemonDetailPage(
                            id: p.id,
                            initialName: p.name,
                            initialImageUrl: p.imageUrl,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 2,
                      color: bg,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        height: 96,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: p.imageUrl.isNotEmpty
                                ? Image.network(
                                    p.imageUrl,
                                    width: 92,
                                    height: 92,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 72,
                                    height: 72,
                                    color: Colors.black12,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          // 中央に名前（伸縮領域）
                          Expanded(
                            child: Text(
                              p.name,
                              style: GoogleFonts.mPlusRounded1c(
                                fontWeight: FontWeight.w900,
                                fontSize: 25,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 右端に太字のIDを表示（例: #25）
                          Text(
                            '${p.id}',
                            style: GoogleFonts.mPlusRounded1c(
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.shade700,
                              fontSize: 30,
                            ),
                          ),
                        ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              if (vm.listLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (!vm.listLoading)
                Center(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await vm.loadMore(repo, locRepo); // 追加ページを読み込み（日本語名適用）
                      await _ensureTypesLoaded(); // 追加分のタイプも取得
                    },
                    icon: const Icon(Icons.expand_more),
                    label: const Text('もっと読む'),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openSearch,
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        child: const Icon(Icons.search),
      ),
    );
  }

  void _openSearch() {
    final controller = TextEditingController();
    bool loading = false;
    String? error;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              Future<void> doSearch() async {
                final key = controller.text.trim();
                if (key.isEmpty) {
                  setState(() => error = '名前または図鑑番号を入力してください');
                  return;
                }
                setState(() {
                  loading = true;
                  error = null;
                });
                try {
                  // まず英名/IDで検索
                  late final int foundId;
                  try {
                    final detail = await remoteDs.fetchDetailByKey(key);
                    foundId = detail.id;
                  } catch (_) {
                    // 失敗した場合は日本語名でspeciesから検索
                    final id = await speciesDs.searchIdByLocalizedName(key);
                    if (id == null) throw Exception('該当なし');
                    foundId = id;
                  }
                  final species = await speciesDs.fetchSpeciesDetail(foundId);
                  final detail = await remoteDs.fetchDetail(foundId);
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  Navigator.of(this.context).push(
                    MaterialPageRoute(
                      builder: (_) => PokemonDetailPage(
                        id: detail.id,
                        initialName: (species.displayName.isNotEmpty) ? species.displayName : detail.name,
                        initialImageUrl: detail.imageUrl,
                      ),
                    ),
                  );
                } catch (e) {
                  setState(() => error = '見つかりませんでした: $e');
                } finally {
                  setState(() => loading = false);
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '検索',
                    style: GoogleFonts.mPlusRounded1c(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      labelText: '名前 または 図鑑No.',
                      hintText: '例: ピカチュウ / 25',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => doSearch(),
                  ),
                  const SizedBox(height: 12),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(error!, style: const TextStyle(color: Colors.red)),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: loading ? null : doSearch,
                          icon: const Icon(Icons.search),
                          label: const Text('検索'),
                        ),
                      ),
                    ],
                  ),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
