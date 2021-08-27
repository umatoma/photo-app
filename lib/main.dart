import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photoapp/photo_list_screen.dart';
import 'package:photoapp/providers.dart';
import 'package:photoapp/sign_in_screen.dart';

void main() async {
  // Flutterの初期化処理を待つ
  WidgetsFlutterBinding.ensureInitialized();

  // アプリ起動前にFirebase初期化処理を入れる
  //   - initializeApp()の返り値がFutureなので非同期処理
  //   - 非同期処理(Future)はawaitで処理が終わるのを待つことができる
  //   - ただし、awaitを使うときは関数にasyncを付ける必要がある
  await Firebase.initializeApp();

  runApp(
    // Providerで定義したデータを渡せるようにする
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Consumerを使うことでもデータを受け取れる
      home: Consumer(builder: (context, watch, child) {
        // ユーザー情報を取得
        final asyncUser = watch(userProvider);

        return asyncUser.when(
          data: (User? data) {
            return data == null ? SignInScreen() : PhotoListScreen();
          },
          loading: () {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
          error: (e, stackTrace) {
            return Scaffold(
              body: Center(
                child: Text(e.toString()),
              ),
            );
          },
        );
      }),
    );
  }
}
