import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:photoapp/app_state.dart';
import 'package:photoapp/photo.dart';
import 'package:photoapp/photo_repository.dart';
import 'package:photoapp/photo_view_screen.dart';
import 'package:photoapp/sign_in_screen.dart';
import 'package:provider/provider.dart';

class PhotoListScreen extends StatefulWidget {
  @override
  _PhotoListScreenState createState() => _PhotoListScreenState();
}

class _PhotoListScreenState extends State<PhotoListScreen> {
  late int _currentIndex;
  late PageController _controller;

  @override
  void initState() {
    // BottomNavigationBarで現在表示している要素を判別するためのもの
    _currentIndex = 0;

    // PageViewを操作するためのもの
    //   - ページを切り替える処理などに使う
    _controller = PageController(initialPage: _currentIndex);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch<AppState>();
    final List<Photo> photoList = appState.photoList;
    final List<Photo> favoritePhotoList = appState.getFavoritePhotoList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Photo App'),
        actions: [
          // ログアウト用ボタン
          IconButton(
            onPressed: () => _onSignOut(context),
            icon: Icon(Icons.exit_to_app),
          ),
        ],
      ),
      // PageViewを使い「全ての画像」と「お気に入り登録した画像」を別ページで表示する
      body: PageView(
        controller: _controller,
        // ページが切り替わったときの処理
        onPageChanged: (int index) => _onPageChanged(index),
        children: [
          //「全ての画像」を表示する部分
          PhotoGridView(
            // 処理を行う際はモデルを受け渡す
            photoList: photoList,
            onTap: (photo) => _onTapPhoto(context, photo),
            onTapFav: (photo) => _onTapFav(context, photo),
          ),
          //「お気に入り登録した画像」を表示する部分
          PhotoGridView(
            // 処理を行う際はモデルを受け渡す
            photoList: favoritePhotoList,
            onTap: (photo) => _onTapFav(context, photo),
            onTapFav: (photo) => _onTapFav(context, photo),
          ),
        ],
      ),
      // 画像追加用ボタン
      floatingActionButton: FloatingActionButton(
        // 画像追加用ボタンをタップしたときの処理
        onPressed: () => _onAddPhoto(),
        child: Icon(Icons.add),
      ),
      // フッター部分
      bottomNavigationBar: BottomNavigationBar(
        // BottomNavigationBarItemがタップされたときの処理
        //   フォトがタップされた場合 >> index == 0
        //   お気に入りがタップされた場合 >> index == 1
        onTap: (int index) => _onTapBottomNavigationItem(index),
        // 現在表示されているBottomNavigationBarItemのインデックス
        //   - 0 >> フォト
        //   - 1 >> お気に入り
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: 'フォト',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'お気に入り',
          ),
        ],
      ),
    );
  }

  Future<void> _onTapFav(BuildContext context, Photo photo) async {
    final AppState state = context.read<AppState>();
    await state.toggleFavorite(photo);
  }

  Future<void> _onSignOut(BuildContext context) async {
    final AppState appState = context.read<AppState>();
    await appState.signOut();

    // ログアウトに成功したらログイン画面に戻す
    //   - 現在の画面は一旦不要になるのでpushReplacementを使う
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SignInScreen(),
      ),
    );
  }

  void _onPageChanged(int index) {
    // ページが切り替わったらBottomNavigationBarで表示する要素も更新する
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTapBottomNavigationItem(int index) {
    // PageViewで表示しているページを切り替える
    _controller.animateToPage(
      // ページ番号
      //   - 0 >> 全ての画像を表示するページ
      //   - 1 >> お気に入り登録した画像を表示するページ
      index,
      // ページ切替時のアニメーション時間
      duration: Duration(milliseconds: 300),
      // アニメーションの動き方
      //   - この値を変えることで、アニメーションの動きを変えることができる
      //   - https://api.flutter.dev/flutter/animation/Curves-class.html
      curve: Curves.easeIn,
    );
    // 表示に必要な値を変更するため、setState()の中で値を代入する
    //   - setState() の処理が呼ばれるとWidgetが再描画される
    //   - つまり、変更された値をもとに新しいUIが描画できる
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTapPhoto(BuildContext context, Photo photo) {
    // 最初に表示する画像のURLを指定して、画像詳細画面に遷移する
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewScreen(photo: photo),
      ),
    );
  }

  Future<void> _onAddPhoto() async {
    // 画像ファイルを選択
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    // 画像ファイルが選択された場合
    if (result != null) {
      final File file = File(result.files.single.path!);
      final AppState appState = context.read<AppState>();
      await appState.addPhoto(file);
    }
  }
}

// Widgetを新たに定義し再利用できる
class PhotoGridView extends StatelessWidget {
  const PhotoGridView({
    Key? key,
    required this.photoList,
    required this.onTap,
    required this.onTapFav,
  }) : super(key: key);

  final List<Photo> photoList;
  final void Function(Photo photo) onTap;
  final void Function(Photo photo) onTapFav;

  @override
  Widget build(BuildContext context) {
    // GridViewを使いタイル状にWidgetを表示する
    return GridView.count(
      // 1行あたりに表示するWidgetの数
      crossAxisCount: 2,
      // Widget間のスペース（上下）
      mainAxisSpacing: 8,
      // Widget間のスペース（左右）
      crossAxisSpacing: 8,
      padding: const EdgeInsets.all(8),
      // タイル状に表示するWidget一覧
      children: photoList.map((Photo photo) {
        // Stackを使いWidgetを前後に重ねる
        return Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              child: InkWell(
                onTap: () => onTap(photo),
                child: Image.network(
                  photo.imageURL,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // 画像の上にお気に入りアイコンを重ねて表示
            //   - Alignment.topRightを指定し右上部分にアイコンを表示
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => onTapFav(photo),
                color: Colors.white,
                icon: Icon(
                  // お気に入り登録状況に応じてアイコンを切り替え
                  photo.isFavorite == true
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
