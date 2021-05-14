import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:photoapp/app_state.dart';
import 'package:photoapp/photo_list_screen.dart';
import 'package:provider/provider.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // バリデーション処理を行うために必要なもの
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // TextFormFieldの入力内容を参照したり制御したりできる
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();

    // 変数を初期化する
    //   - Widgetが作成された初回のみ動作させたい処理はinitState()に記述する
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey, // Formのkeyに指定する
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Photo App',
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'メールアドレス',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (String? value) {
                    if (value?.isEmpty == true) {
                      // 問題があるときはメッセージを返す
                      return 'メールアドレスを入力して下さい';
                    }
                    // 問題ないときはnullを返す
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                  ),
                  keyboardType: TextInputType.visiblePassword,
                  validator: (String? value) {
                    if (value?.isEmpty == true) {
                      return 'パスワードを入力して下さい';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _onSignIn(context),
                    child: Text('ログイン'),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _onSignUp(context),
                    child: Text('新規登録'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSignIn(BuildContext context) async {
    try {
      if (_formKey.currentState?.validate() != true) {
        return;
      }

      final String email = _emailController.text;
      final String password = _passwordController.text;
      // ボタンをタップしたときは context.read() を使う
      final AppState appState = context.read<AppState>();
      await appState.signIn(email: email, password: password);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PhotoListScreen(),
        ),
      );
    } catch (e) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('エラー'),
            content: Text(e.toString()),
          );
        },
      );
    }
  }

  // 内部で非同期処理(Future)を扱っているのでasyncを付ける
  //    - この関数自体も非同期処理となるので返り値もFutureとする
  Future<void> _onSignUp(BuildContext context) async {
    try {
      if (_formKey.currentState?.validate() != true) {
        return;
      }

      // メールアドレス・パスワードをもとに新規登録する
      //   - TextEditingControllerから入力フォームの文字列を取得できる
      //   - 面倒くさいログイン状態を維持するための処理はFirebaseが勝手にやってくれる
      final String email = _emailController.text;
      final String password = _passwordController.text;
      final AppState appState = context.read<AppState>();
      await appState.signUp(email: email, password: password);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PhotoListScreen(),
        ),
      );
    } catch (e) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('エラー'),
            content: Text(e.toString()),
          );
        },
      );
    }
  }
}
