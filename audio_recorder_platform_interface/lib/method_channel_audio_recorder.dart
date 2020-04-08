import 'dart:async';
import 'dart:typed_data';
import 'package:audio_recorder_platform_interface/audio_recorder_platform_interface.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;

/// An implementation of [AudioRecorderPlatform] that uses method channels.
class MethodChannelAudioRecorder extends AudioRecorderPlatform {
  
  MethodChannel _channel;

  MethodChannelAudioRecorder() {
    _channel = MethodChannel('audio_recorder')
      ..setMethodCallHandler(platformCallHandler);
      print("Using method channel instance");
  }

  Future<void> platformCallHandler(MethodCall call) async {
    try {
      _doHandlePlatformCall(call);
    } catch (ex) {
      print('Unexpected error: $ex');
    }
  }

  Future<dynamic> _doHandlePlatformCall(MethodCall call) async {
    final method = call.method;
    switch (method) {
      case 'initialized':
        initializedController.sink.add(call.arguments);
        break;
      case 'recordedData':
        onRecordedDataAvailableController.sink.add(call.arguments);
        break;
      case 'recordingComplete':
        onRecordingSuccessfullyCompleteController.sink.add(call.arguments);
        break;
      case 'recordError':
        errorController.sink.add(call.arguments);
        break;
      default:
        throw new ArgumentError('Unknown method ${call.method} ');
    }
  }

  Future start({String path, AudioOutputFormat audioOutputFormat}) async {
    String extension;
    if (path != null) {
      if (audioOutputFormat != null) {
        if (_convertStringInAudioOutputFormat(p.extension(path)) !=
            audioOutputFormat) {
          extension = _convertAudioOutputFormatInString(audioOutputFormat);
          path += extension;
        } else {
          extension = p.extension(path);
        }
      } else {
        if (_isAudioOutputFormat(p.extension(path))) {
          extension = p.extension(path);
        } else {
          extension = ".m4a"; // default value
          path += extension;
        }
      }
      path = await getPath(path);
    } else {
      switch (audioOutputFormat) {
        case AudioOutputFormat.WAV:
          extension = ".wav";
          break;
        default:
          extension = ".m4a"; // default value
      }
    }
    return _channel
        .invokeMethod('start', {"path": path, "extension": extension});
  }

  Future<Recording> stop([bool export = true]) async {
    var resp = await _channel.invokeMethod('stop', export);
    Map<String, Object> response = Map.from(resp);
    Recording recording = new Recording(
        duration: new Duration(milliseconds: response['duration']),
        path: response['path'],
        audioOutputFormat:
            _convertStringInAudioOutputFormat(response['audioOutputFormat']),
        extension: response['audioOutputFormat']);
    Uint8List audio = getAudio(recording);
    onRecordedDataAvailableController.sink.add(audio);
    onRecordingSuccessfullyCompleteController.sink.add(true);
    return recording;
  }

  static AudioOutputFormat _convertStringInAudioOutputFormat(String extension) {
    switch (extension) {
      case ".wav":
        return AudioOutputFormat.WAV;
      case ".mp4":
      case ".aac":
      case ".m4a":
        return AudioOutputFormat.AAC;
      default:
        return null;
    }
  }

  static bool _isAudioOutputFormat(String extension) {
    switch (extension) {
      case ".wav":
      case ".mp4":
      case ".aac":
      case ".m4a":
        return true;
      default:
        return false;
    }
  }

  void initialize() {
    _channel.invokeMethod("initialize");
  }

  String _convertAudioOutputFormatInString(AudioOutputFormat outputFormat) {
    switch (outputFormat) {
      case AudioOutputFormat.WAV:
        return ".wav";
      case AudioOutputFormat.AAC:
        return ".m4a";
      default:
        return ".m4a";
    }
  }

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

  Future<bool> get isRecording async {
    bool isRecording = await _channel.invokeMethod('isRecording');
    return isRecording;
  }

  Future<bool> get hasPermissions async {
    var micStatus = await Permission.microphone.request();
    var fileStatus = await Permission.storage.request();
    if (micStatus.isDenied || fileStatus.isDenied)
      throw Exception(
          "Please allow access to the microphone and file storage. This is needed to properly analyse your pronunciation.");
    return true;
  }
}
