import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:photoapp/photo.dart';
import 'package:photoapp/photo_repository.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _initialize();
  }

  User? user;
  List<Photo> photoList = [];
  StreamSubscription<List<Photo>>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();

    super.dispose();
  }

  void _initialize() {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final PhotoRepository repository = PhotoRepository(user!);
      _subscription = repository.getPhotoList().listen((List<Photo> data) {
        photoList = data;
        notifyListeners();
      });
    }
  }

  Future<void> signUp({email: String, password: String}) async {
    await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    _initialize();
  }

  Future<void> signIn({email: String, password: String}) async {
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    _initialize();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _subscription?.cancel();
    _initialize();
  }

  Future<void> addPhoto(File file) async {
    await PhotoRepository(user!).addPhoto(file);
  }

  Future<void> deletePhoto(Photo photo) async {
    await PhotoRepository(user!).deletePhoto(photo);
  }

  List<Photo> getFavoritePhotoList() {
    return photoList.where((photo) => photo.isFavorite).toList();
  }

  Future<void> toggleFavorite(Photo photo) async {
    await PhotoRepository(user!).toggleFavorite(photo);
  }
}
