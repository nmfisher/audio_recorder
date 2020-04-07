import 'dart:io';
import 'dart:typed_data';
import 'package:file/local.dart';

import 'audio_recorder.dart';

LocalFileSystem fs = LocalFileSystem();

Future<String> getPath(String path) async {

  File file = fs.file(path);
  if (await file.exists()) {
    throw new Exception("A file already exists at the path :" + path);
  } else if (!await file.parent.exists()) {
    throw new Exception("The specified parent directory does not exist");
  }
  return path;
 }

 Uint8List getAudio(Recording recording) { 
   return fs.file(recording.path).readAsBytesSync();
 }