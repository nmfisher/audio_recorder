import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_audio_recorder.dart';

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

/// The interface that implementations of audio_recorder must implement.
///
/// Platform implementations should extend this class rather than implement it as `audio_recorder`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [UrlLauncherPlatform] methods.
abstract class AudioRecorderPlatform extends PlatformInterface {
  /// Constructs a AudioRecorderPlatform.
  AudioRecorderPlatform() : super(token: _token);

  static final Object _token = Object();

  static AudioRecorderPlatform _instance = MethodChannelAudioRecorder();

  /// The default instance of [AudioRecorderPlatform] to use.
  ///
  /// Defaults to [MethodChannelAudioRecorder].
  static AudioRecorderPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [UrlLauncherPlatform] when they register themselves.
  static set instance(AudioRecorderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  StreamController<Uint8List> onRecordedDataAvailableController =
      StreamController<Uint8List>();
  Stream<Uint8List> get onRecordedDataAvailable =>
      onRecordedDataAvailableController.stream;

  StreamController<bool> onRecordingSuccessfullyCompleteController =
      StreamController<bool>();
  Stream<bool> get onRecordingSuccessfullyComplete =>
      onRecordingSuccessfullyCompleteController.stream;

  StreamController<int> initializedController =
      StreamController<int>.broadcast();
  Stream<int> get initialized => initializedController.stream;

  StreamController<String> errorController =
      StreamController<String>.broadcast();
  Stream<String> get error => errorController.stream;


  void dispose() {
    onRecordingSuccessfullyCompleteController.close();
    onRecordedDataAvailableController.close();
    initializedController.close();
    errorController.close();
  }

  void initialize() {
    throw new UnimplementedError("initialize is not implemented");
  }

  Future start(
      {String path, AudioOutputFormat audioOutputFormat}) {
      throw new UnimplementedError("start is not implemented");
  }

  Future<Recording> stop([bool export = true]) {
    throw new UnimplementedError("start is not implemented");
  }

  Future<bool> get isRecording async {
    throw new UnimplementedError("start is not implemented");
  }

  Future<bool> get hasPermissions async {
    throw new UnimplementedError("hasPermissions is not implemented");
  }
}