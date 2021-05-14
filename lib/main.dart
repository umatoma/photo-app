import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:photoapp/app_state.dart';
import 'package:photoapp/photo_list_screen.dart';
import 'package:photoapp/sign_in_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  // Flutterの初期化処理を待つ
  WidgetsFlutterBinding.ensureInitialized();

  // アプリ起動前にFirebase初期化処理を入れる
  //   - initializeApp()の返り値がFutureなので非同期処理
  //   - 非同期処理(Future)はawaitで処理が終わるのを待つことができる
  //   - ただし、awaitを使うときは関数にasyncを付ける必要がある
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'Photo App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        // ログイン状態に応じて画面を切り替える
        home: Builder(
          builder: (context) {
            final appState = context.watch<AppState>();
            return appState.user == null ? SignInScreen() : PhotoListScreen();
          },
        ),
      ),
    );
  }
}
