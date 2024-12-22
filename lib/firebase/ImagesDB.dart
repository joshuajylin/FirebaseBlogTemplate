import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_blog_template/util/StringExtension.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/ImageMetadata.dart';


class ImagesDB {
  static late final ImagesDB _instance = ImagesDB._internal();
  static ImagesDB get instance => _instance;
  factory ImagesDB() => _instance;

  static const String _collectionName = 'images';
  static const int _timeoutSeconds = 60 * 10;

  final CollectionReference<Map<String, dynamic>> _defColRef = FirebaseFirestore.instance.collection(_collectionName);
  late QuerySnapshot<Map<String, dynamic>> _snapshot;
  DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  bool _fetching = false;

  ImagesDB._internal() {
    _getUpToDateSnapshot();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getUpToDateSnapshot() async {
    if (!_fetching && (DateTime.now().difference(_lastUpdate).inSeconds > _timeoutSeconds)) {
      _fetching = true;
      _snapshot = await _defColRef.get();
      _lastUpdate = DateTime.now();
      _fetching = false;
    }
    if (_fetching) {
      await Future.doWhile(() => Future.delayed(const Duration(milliseconds: 200)).then((_) => _fetching));
    }
    return _snapshot;
  }

  Future<List<ImageMetadata>> getAll() async {
    final snapshot = await _getUpToDateSnapshot();
    List<ImageMetadata> images = snapshot.docs.map<ImageMetadata>((e) {
      final path = e.reference.path;
      var data = e.data();
      data['path'] = path;
      return ImageMetadata.fromJson(data);
    }).toList();
    return images;
  }

  void Function() upload({required Uint8List imageData, required String fileName, void Function(double)? onProgress, void Function(ImageMetadata)? onSuccess, void Function(bool)? onFailure}) {
    String fileExtension = fileName.split('.').last.toLowerCase();
    if (fileExtension != 'png' && fileExtension != 'jpg' && fileExtension != 'jpeg') {
      throw Exception('Unsupported file format "$fileExtension".');
    }
    final metadata = SettableMetadata(contentType: (fileExtension == 'png') ? 'image/png' : 'image/jpeg');
    final storageRef = FirebaseStorage.instance.ref();
    final docRef = _defColRef.doc();
    final fileRef = storageRef.child('${docRef.path}.$fileExtension');
    final uploadTask = fileRef.putData(imageData, metadata);
    ImageMetadata image = ImageMetadata(fileExtension: fileExtension, bytes: 0, name: fileName, path: docRef.path);
    uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) {
      switch (taskSnapshot.state) {
        case TaskState.running:
          final progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
          'Upload is ${(progress*100).round()}% complete.'.log();
          onProgress?.call(progress);
          break;
        case TaskState.paused:
          uploadTask.cancel();
        case TaskState.canceled:
          docRef.delete();
          onFailure?.call(true);
        case TaskState.error:
          docRef.delete();
          onFailure?.call(false);
        case TaskState.success:
          image.path = docRef.path;
          image.bytes = taskSnapshot.totalBytes;
          fileRef.getDownloadURL().then((value) {
            image.url = value;
          }).catchError((err) {
            '$err'.log();
          }).whenComplete(() {
            docRef.set(image.toJson());
            _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
            onSuccess?.call(image);
          });
      }
    });
    return () => uploadTask.cancel();
  }

  Future<void> delete(ImageMetadata image) async {
    final storageRef = FirebaseStorage.instance.ref();
    final desertRef = storageRef.child('${image.path}.${image.fileExtension}');
    await desertRef.delete();
    if (image.path?.isNotEmpty ?? false) {
      final docName = image.path?.split('/').last;
      final docRef = _defColRef.doc(docName);
      await docRef.delete();
      _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

}