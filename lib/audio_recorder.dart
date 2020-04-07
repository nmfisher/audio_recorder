import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_recorder/path_helper_stub.dart'
    // ignore: uri_does_not_exist
    if (dart.library.io) 'package:audio_recorder/io_path_helper.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'package:audio_recorder/html_path_helper.dart';

class AudioRecorder {
  
  static final MethodChannel _channel = const MethodChannel('audio_recorder')
    ..setMethodCallHandler(platformCallHandler);

  static StreamController<Uint8List> _onRecordedDataAvailableController =
      StreamController<Uint8List>();
  static Stream<Uint8List> get onRecordedDataAvailable =>
      _onRecordedDataAvailableController.stream;

  static StreamController<bool> _onRecordingSuccessfullyCompleteController =
      StreamController<bool>();
  static Stream<bool> get onRecordingSuccessfullyComplete =>
      _onRecordingSuccessfullyCompleteController.stream;

  static StreamController<int> _initializedController =
      StreamController<int>.broadcast();
  static Stream<int> get initialized => _initializedController.stream;

  static StreamController<String> _errorController =
      StreamController<String>.broadcast();
  static Stream<String> get error => _errorController.stream;


  static Future<void> platformCallHandler(MethodCall call) async {
    try {
      _doHandlePlatformCall(call);
    } catch (ex) {
      print('Unexpected error: $ex');
    }
  }

  static Future<dynamic> _doHandlePlatformCall(MethodCall call) async {
    final method = call.method;
    switch (method) {
      case 'initialized':
        _initializedController.sink.add(call.arguments);
        break;
      case 'recordedData':
        _onRecordedDataAvailableController.sink.add(call.arguments);
        break;
      case 'recordingComplete':
        _onRecordingSuccessfullyCompleteController.sink.add(call.arguments);
        break;
      case 'recordError':
        _errorController.sink.add(call.arguments);
        break;
      default:
        throw new ArgumentError('Unknown method ${call.method} ');
    }
  }

  static void initialize() {
    _channel.invokeMethod("initialize");
  }

  static Future start(
      {String path, AudioOutputFormat audioOutputFormat}) async {
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

  static Future<Recording> stop([bool export = true]) async {
    var resp = await _channel.invokeMethod('stop', export);

    if (!kIsWeb) {
      Map<String, Object> response = Map.from(resp);
      Recording recording = new Recording(
          duration: new Duration(milliseconds: response['duration']),
          path: response['path'],
          audioOutputFormat:
              _convertStringInAudioOutputFormat(response['audioOutputFormat']),
          extension: response['audioOutputFormat']);
      Uint8List audio = getAudio(recording);
      _onRecordedDataAvailableController.sink.add(audio);
      _onRecordingSuccessfullyCompleteController.sink.add(true);
      print("Dispatched raw audio");
      return recording;
    }
  }

  static Future<bool> get isRecording async {
    bool isRecording = await _channel.invokeMethod('isRecording');
    return isRecording;
  }

  static Future<bool> get hasPermissions async {
    var micStatus = await Permission.microphone.request();
    var fileStatus = await Permission.storage.request();
    if (micStatus.isDenied || fileStatus.isDenied)
      throw Exception(
          "Please allow access to the microphone and file storage. This is needed to properly analyse your pronunciation.");
    return true;
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

  static String _convertAudioOutputFormatInString(
      AudioOutputFormat outputFormat) {
    switch (outputFormat) {
      case AudioOutputFormat.WAV:
        return ".wav";
      case AudioOutputFormat.AAC:
        return ".m4a";
      default:
        return ".m4a";
    }
  }
}

enum AudioOutputFormat { AAC, WAV }

class Recording {
  // File path
  String path;
  // File extension
  String extension;
  // Audio duration in milliseconds
  Duration duration;
  // Audio output format
  AudioOutputFormat audioOutputFormat;

  Recording({this.duration, this.path, this.audioOutputFormat, this.extension});
}
