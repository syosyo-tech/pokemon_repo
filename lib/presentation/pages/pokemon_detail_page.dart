import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:test01/data/datasources/pokemon_remote_data_source.dart';
import 'package:test01/data/datasources/pokemon_species_remote_data_source.dart';
import 'package:test01/data/datasources/type_remote_data_source.dart';
import 'package:test01/data/datasources/ability_remote_data_source.dart';
import 'package:test01/data/repositories/pokemon_detail_repository_impl.dart';
import 'package:test01/domain/entities/pokemon_detail.dart';

class PokemonDetailPage extends StatefulWidget {
  final int id;
  final String initialName;
  final String initialImageUrl;
  const PokemonDetailPage({super.key, required this.id, required this.initialName, required this.initialImageUrl});

  @override
  State<PokemonDetailPage> createState() => _PokemonDetailPageState();
}

class _PokemonDetailPageState extends State<PokemonDetailPage> {
  PokemonDetail? _detail;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ds = PokemonRemoteDataSourceImpl();
      final species = PokemonSpeciesRemoteDataSourceImpl();
      final typeDs = TypeRemoteDataSource();
      final abilityDs = AbilityRemoteDataSource();
      final repo = PokemonDetailRepositoryImpl(ds, species, typeDs, abilityDs);
      final d = await repo.getDetail(widget.id);
      setState(() => _detail = d);
    } catch (e) {
      setState(() => _error = '詳細の取得に失敗しました: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.w900, fontSize: 22);
    return Scaffold(
      appBar: AppBar(title: const Text('詳細')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ヘッダー: 名前を左上、画像をその右斜め下、IDを右上に配置
          Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 画像サイズ
                const double imgSize = 220;
                return Stack(
                  children: [
                    // 名前（左上）。画像分の幅を空けて重なりを回避
                    Positioned(
                      left: 0,
                      top: 0,
                      right: imgSize + 16, // 画像ぶんのスペースを確保
                      child: Text(
                        _detail?.name ?? widget.initialName,
                        style: titleStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 画像（下中央）
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (widget.initialImageUrl.isNotEmpty)
                            ? Image.network(widget.initialImageUrl, width: imgSize, height: imgSize, fit: BoxFit.cover)
                            : Container(width: imgSize, height: imgSize, color: Colors.black12, alignment: Alignment.center, child: const Icon(Icons.image_not_supported)),
                      ),
                    ),
                    // ID（右上）
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Text(
                        '#${widget.id}',
                        style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          if (_detail != null) _buildDetail(context, _detail!),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, PokemonDetail d) {
    // 単位変換（UI表示用）: height(decimeter)→m, weight(hectogram)→kg
    final heightM = (d.height / 10).toStringAsFixed(1);
    final weightKg = (d.weight / 10).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (d.description.isNotEmpty) ...[
          Text(
            '説明',
            style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.w900, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(d.description),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: d.types
              .map((t) {
                final c = _typeColor(t);
                return Chip(
                  label: Text(
                    _typeLabelJa(t),
                    style: TextStyle(color: _onColor(c)),
                  ),
                  backgroundColor: c,
                );
              })
              .toList(),
        ),
        const SizedBox(height: 8),
        // とくせい（タイプタグの直下に表示）
        Text(
          'とくせい',
          style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.w900, fontSize: 20),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        ...d.abilities.map((a) => Text('• $a')).toList(),
        const SizedBox(height: 12),
        Row(children: [
          _infoTile('身長', '$heightM m'),
          const SizedBox(width: 12),
          _infoTile('体重', '$weightKg kg'),
        ]),
        const SizedBox(height: 12),
        Text(
          'ベースステータス',
          style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.w900, fontSize: 20),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        _stats(d.stats),
        const SizedBox(height: 12),
        Text(
          'タイプ相性（被ダメージ倍率）',
          style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.w900, fontSize: 20),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        _typeChart(d.typeChart),
        const SizedBox(height: 12),
        Text(
          '進化チェーン',
          style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.w900, fontSize: 20),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        _evolution(d.evolutionChain),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _stats(Map<String, int> stats) {
    // 時計回り: HP, こうげき, ぼうぎょ, すばやさ, とくぼう, とくこう
    final labels = ['HP', 'こうげき', 'ぼうぎょ', 'すばやさ', 'とくぼう', 'とくこう'];
    final keys = ['hp', 'attack', 'defense', 'speed', 'special-defense', 'special-attack'];
    const maxStat = 180; // 正規化用の最大値（目安）
    final values = keys
        .map((k) => ((stats[k] ?? 0) / maxStat).clamp(0.0, 1.0))
        .cast<double>()
        .toList();

    return SizedBox(
      height: 280,
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              // レーダー本体
              CustomPaint(
                size: Size.infinite,
                painter: _RadarPainter(values: values),
              ),
              // ラベル（外周）
              LayoutBuilder(
                builder: (context, constraints) {
                  final size = math.min(constraints.maxWidth, constraints.maxHeight);
                  final center = Offset(size / 2, size / 2);
                  final radius = size * 0.42; // ラベルの配置半径
                  final angleStep = (2 * math.pi) / 6;
                  final startAngle = -math.pi / 2; // 上から時計回り
                  return Stack(
                    children: [
                      for (int i = 0; i < 6; i++)
                        Positioned(
                          left: center.dx + radius * math.cos(startAngle + angleStep * i) - 40,
                          top: center.dy + radius * math.sin(startAngle + angleStep * i) - 12,
                          width: 80,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                labels[i],
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${(values[i] * maxStat).round()}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

// レーダーチャート描画（トップレベルに配置）
// ignore: unused_element
// _RadarPainter はファイル末尾（Stateクラスの外）に定義します

  Widget _typeChart(PokemonTypeChart chart) {
    Widget row(String label, List<String> items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 64, child: Text(label)),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: items.map((t) {
                  final c = _typeColor(t);
                  return Chip(
                    label: Text(
                      _typeLabelJa(t),
                      style: TextStyle(color: _onColor(c)),
                    ),
                    backgroundColor: c,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        row('x4', chart.x4),
        row('x2', chart.x2),
        row('x0.5', chart.x0_5),
        row('x0.25', chart.x0_25),
        row('x0', chart.x0),
      ],
    );
  }

  String _typeLabelJa(String en) {
    // 英語タイプ名 -> 日本語表示
    const map = {
      'normal': 'ノーマル',
      'fire': 'ほのお',
      'water': 'みず',
      'electric': 'でんき',
      'grass': 'くさ',
      'ice': 'こおり',
      'fighting': 'かくとう',
      'poison': 'どく',
      'ground': 'じめん',
      'flying': 'ひこう',
      'psychic': 'エスパー',
      'bug': 'むし',
      'rock': 'いわ',
      'ghost': 'ゴースト',
      'dragon': 'ドラゴン',
      'dark': 'あく',
      'steel': 'はがね',
      'fairy': 'フェアリー',
    };
    return map[en.toLowerCase()] ?? en.toUpperCase();
  }

  // タイプカラー（PokeAPIコミュニティ準拠の近似色）
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

  // 背景色に応じて読みやすい文字色（白/黒）を選択
  Color _onColor(Color bg) {
    final b = ThemeData.estimateBrightnessForColor(bg);
    return b == Brightness.dark ? Colors.white : Colors.black87;
  }

  Widget _evolution(List<EvolutionEntry> evo) {
    if (evo.isEmpty) return const Text('進化情報なし');
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: evo.map((e) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: e.imageUrl.isNotEmpty
                    ? Image.network(e.imageUrl, width: 96, height: 96, fit: BoxFit.cover)
                    : Container(width: 96, height: 96, color: Colors.black12),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 96,
                child: Text(
                  e.name.isEmpty ? '#${e.id}' : e.name,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
// レーダーチャート描画（トップレベル）
class _RadarPainter extends CustomPainter {
  final List<double> values; // 0..1 の6要素
  _RadarPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black26
      ..strokeWidth = 1;
    final paintAxis = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black38
      ..strokeWidth = 1;
    final paintFill = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blue.withOpacity(0.2);
    final paintStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.blue
      ..strokeWidth = 2;

    final w = size.width, h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = math.min(w, h) * 0.32;
    final angleStep = (2 * math.pi) / 6;
    final startAngle = -math.pi / 2; // 上から時計回り

    Path ring(double r) {
      final path = Path();
      for (int i = 0; i < 6; i++) {
        final a = startAngle + angleStep * i;
        final p = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      return path;
    }

    // グリッド（4段）
    for (int i = 1; i <= 4; i++) {
      final r = radius * (i / 4);
      canvas.drawPath(ring(r), paintGrid);
    }

    // 軸
    for (int i = 0; i < 6; i++) {
      final a = startAngle + angleStep * i;
      final p = Offset(center.dx + radius * math.cos(a), center.dy + radius * math.sin(a));
      canvas.drawLine(center, p, paintAxis);
    }

    // 値ポリゴン
    final poly = Path();
    for (int i = 0; i < 6; i++) {
      final a = startAngle + angleStep * i;
      final r = radius * values[i];
      final p = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      if (i == 0) {
        poly.moveTo(p.dx, p.dy);
      } else {
        poly.lineTo(p.dx, p.dy);
      }
    }
    poly.close();
    canvas.drawPath(poly, paintFill);
    canvas.drawPath(poly, paintStroke);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
