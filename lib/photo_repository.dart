import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:photoapp/photo.dart';

class PhotoRepository {
  PhotoRepository(this.user);

  final User user;

  Stream<List<Photo>> getPhotoList() {
    return FirebaseFirestore.instance
        .collection('users/${user.uid}/photos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_queryToPhotoList);
  }

  Future<void> addPhoto(File file) async {
    final int timestamp = DateTime.now().microsecondsSinceEpoch;
    final String name = file.path.split('/').last;
    final String path = '${timestamp}_$name';
    final TaskSnapshot task = await FirebaseStorage.instance
        .ref()
        .child('users/${user.uid}/photos')
        .child(path)
        .putFile(file);

    final String imageURL = await task.ref.getDownloadURL();
    final String imagePath = task.ref.fullPath;
    final Photo photo = Photo(
      imageURL: imageURL,
      imagePath: imagePath,
      isFavorite: false,
    );

    await FirebaseFirestore.instance
        .collection('users/${user.uid}/photos')
        .doc()
        .set(_photoToMap(photo));
  }

  Future<void> deletePhoto(Photo photo) async {
    // Cloud Firestoreのデータを削除
    await FirebaseFirestore.instance
        .collection('users/${user.uid}/photos')
        .doc(photo.id)
        .delete();
    // Storageの画像ファイルを削除
    await FirebaseStorage.instance.ref().child(photo.imagePath).delete();
  }

  Future<void> toggleFavorite(Photo photo) async {
    // お気に入り登録状況のデータを更新
    await FirebaseFirestore.instance
        .collection('users/${user.uid}/photos')
        .doc(photo.id)
        .update(_photoToMap(photo.toggleIsFavorite()));
  }

  List<Photo> _queryToPhotoList(QuerySnapshot query) {
    return query.docs.map((doc) {
      return Photo(
        id: doc.id,
        imageURL: doc.get('imageURL'),
        imagePath: doc.get('imagePath'),
        isFavorite: doc.get('isFavorite'),
        createdAt: (doc.get('createdAt') as Timestamp).toDate(),
      );
    }).toList();
  }

  Map<String, dynamic> _photoToMap(Photo photo) {
    return {
      'imageURL': photo.imageURL,
      'imagePath': photo.imagePath,
      'isFavorite': photo.isFavorite,
      'createdAt': photo.createdAt == null
          ? Timestamp.now()
          : Timestamp.fromDate(photo.createdAt!)
    };
  }
}
