import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photoapp/photo.dart';
import 'package:photoapp/photo_repository.dart';
import 'package:photoapp/photo_view_screen.dart';
import 'package:photoapp/providers.dart';
import 'package:photoapp/sign_in_screen.dart';

class PhotoListScreen extends StatefulWidget {
  @override
  _PhotoListScreenState createState() => _PhotoListScreenState();
}

class _PhotoListScreenState extends State<PhotoListScreen> {
  late PageController _controller;

  @override
  void initState() {
    _controller = PageController(
      // Riverpodを使いデータを受け取る
      initialPage: context.read(photoListIndexProvider).state,
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo App'),
        actions: [
          // ログアウト用ボタン
          IconButton(
            onPressed: () => _onSignOut(),
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
          // 「全ての画像」を表示する部分
          Consumer(builder: (context, watch, child) {
            // 画像データ一覧を受け取る
            final asyncPhotoList = watch(photoListProvider);
            return asyncPhotoList.when(
              data: (List<Photo> photoList) {
                return PhotoGridView(
                  photoList: photoList,
                  onTap: (photo) => _onTapPhoto(photo, photoList),
                  onTapFav: (photo) => _onTapFav(photo),
                );
              },
              loading: () {
                return Center(
                  child: CircularProgressIndicator(),
                );
              },
              error: (e, stackTrace) {
                return Center(
                  child: Text(e.toString()),
                );
              },
            );
          }),
          //「お気に入り登録した画像」を表示する部分
          Consumer(builder: (context, watch, child) {
            // 画像データ一覧を受け取る
            final asyncPhotoList = watch(photoListProvider);
            return asyncPhotoList.when(
              data: (List<Photo> photoList) {
                return PhotoGridView(
                  photoList: photoList,
                  onTap: (photo) => _onTapPhoto(photo, photoList),
                  onTapFav: (photo) => _onTapFav(photo),
                );
              },
              loading: () {
                return Center(
                  child: CircularProgressIndicator(),
                );
              },
              error: (e, stackTrace) {
                return Center(
                  child: Text(e.toString()),
                );
              },
            );
          }),
        ],
      ),
      // 画像追加用ボタン
      floatingActionButton: FloatingActionButton(
        // 画像追加用ボタンをタップしたときの処理
        onPressed: () => _onAddPhoto(),
        child: Icon(Icons.add),
      ),
      // フッター部分
      bottomNavigationBar: Consumer(
        builder: (context, watch, child) {
          // 現在のページを受け取る
          final photoIndex = watch(photoListIndexProvider).state;

          return BottomNavigationBar(
            // BottomNavigationBarItemがタップされたときの処理
            //   フォトがタップされた場合 >> index == 0
            //   お気に入りがタップされた場合 >> index == 1
            onTap: (int index) => _onTapBottomNavigationItem(index),
            // 現在表示されているBottomNavigationBarItemのインデックス
            //   - 0 >> フォト
            //   - 1 >> お気に入り
            currentIndex: photoIndex,
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
          );
        },
      ),
    );
  }

  Future<void> _onSignOut() async {
    // ログアウト処理
    await FirebaseAuth.instance.signOut();

    // ログアウトに成功したらログイン画面に戻す
    //   現在の画面は不要になるのでpushReplacementを使う
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SignInScreen(),
      ),
    );
  }

  void _onPageChanged(int index) {
    // ページの値を更新する
    context.read(photoListIndexProvider).state = index;
  }

  void _onTapBottomNavigationItem(int index) {
    _controller.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
    // ページの値を更新する
    context.read(photoListIndexProvider).state = index;
  }

  void _onTapPhoto(Photo photo, List<Photo> photoList) {
    final initialIndex = photoList.indexOf(photo);

    Navigator.of(context).push(
      MaterialPageRoute(
        // ProviderScopeを使いScopedProviderの値を上書きできる
        // ここでは、最初に表示する画像の番号を指定
        builder: (_) => ProviderScope(
          overrides: [
            photoViewInitialIndexProvider.overrideWithValue(initialIndex)
          ],
          child: PhotoViewScreen(),
        ),
      ),
    );
  }

  Future<void> _onAddPhoto() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      // リポジトリ経由でデータを保存する
      final User user = FirebaseAuth.instance.currentUser!;
      final PhotoRepository repository = PhotoRepository(user);
      final File file = File(result.files.single.path!);
      await repository.addPhoto(file);
    }
  }

  Future<void> _onTapFav(Photo photo) async {
    final photoRepository = context.read(photoRepositoryProvider);
    final toggledPhoto = photo.toggleIsFavorite();
    await photoRepository!.updatePhoto(toggledPhoto);
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
