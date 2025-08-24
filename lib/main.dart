// lib/main.dart
// アプリのエントリポイント（最初に実行されるファイル）です。
// ・テーマ（AppBarの色や文字の太さ）を設定
// ・最初に表示する画面として PokemonPage を指定
import 'package:flutter/material.dart';
import 'package:test01/presentation/pages/pokemon_page.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ポケモン図鑑', // 端末のタスク切替などで使われるアプリ名
      theme: ThemeData(
        useMaterial3: true,           // 新しいMaterial3デザイン
        colorSchemeSeed: Colors.red,  // 基本カラー（赤系）
        // アプリ全体のフォントを「M PLUS Rounded 1c」に統一
        // 視覚的に太く見えやすい丸ゴシック体
        textTheme: GoogleFonts.mPlusRounded1cTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.red.shade800, // AppBarの背景色（濃い赤）
          foregroundColor: Colors.white,        // AppBarの文字色・アイコン色
          titleTextStyle: GoogleFonts.mPlusRounded1c(
            fontWeight: FontWeight.w900, // より太く見えるBlack相当
            fontSize: 30,
            color: Colors.white,
          ),
        ),
      ),
      home: const PokemonPage(),      // 最初に表示する画面
      debugShowCheckedModeBanner: false, // デバッグバナー非表示
    );
  }
}
