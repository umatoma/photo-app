import 'package:flutter/material.dart';
import 'package:photoapp/app_state.dart';
import 'package:photoapp/photo.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

class PhotoViewScreen extends StatefulWidget {
  const PhotoViewScreen({
    Key? key,
    required this.photo,
  }) : super(key: key);

  final Photo photo;

  @override
  _PhotoViewScreenState createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  late PageController _controller;
  late int _currentPage;

  @override
  void initState() {
    super.initState();

    final AppState appState = context.read<AppState>();
    final int initialPage = appState.photoList.indexOf(widget.photo);

    _controller = PageController(
      initialPage: initialPage,
    );
    _currentPage = initialPage;
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch<AppState>();
    final List<Photo> photoList = appState.photoList;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (int index) => _onPageChanged(index),
            children: photoList.map((Photo photo) {
              return Image.network(
                photo.imageURL,
                fit: BoxFit.cover,
              );
            }).toList(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              // フッター部分にグラデーションを入れてみる
              decoration: BoxDecoration(
                // 線形グラデーション
                gradient: LinearGradient(
                  // 下方向から上方向に向かってグラデーションさせる
                  begin: FractionalOffset.bottomCenter,
                  end: FractionalOffset.topCenter,
                  // 半透明の黒から透明にグラデーションさせる
                  colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                  stops: [0.0, 1.0],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () => _onTapShare(context),
                    color: Colors.white,
                    icon: Icon(Icons.share),
                  ),
                  IconButton(
                    onPressed: () => _onTapDelete(context),
                    color: Colors.white,
                    icon: Icon(Icons.delete),
                  ),
                  IconButton(
                    onPressed: () => _onTapFav(context),
                    color: Colors.white,
                    icon: Icon(Icons.favorite_border),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _onTapDelete(BuildContext context) async {
    final AppState appState = context.read<AppState>();
    final List<Photo> photoList = appState.photoList;
    final Photo photo = photoList[_currentPage];

    if (photoList.length == 1) {
      Navigator.of(context).pop();
    } else if (photoList.last == photo) {
      await _controller.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    await appState.deletePhoto(photo);
  }

  Future<void> _onTapFav(BuildContext context) async {
    final AppState state = context.read<AppState>();
    final Photo photo = state.photoList[_currentPage];

    await state.toggleFavorite(photo);
  }

  Future<void> _onTapShare(BuildContext context) async {
    final AppState state = context.read<AppState>();
    final Photo photo = state.photoList[_currentPage];

    // 画像のURLを共有する
    await Share.share(photo.imageURL);
  }
}
