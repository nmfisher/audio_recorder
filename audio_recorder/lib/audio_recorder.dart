import 'dart:async';
import 'dart:typed_data';
import 'package:audio_recorder_platform_interface/audio_recorder_platform_interface.dart';


class AudioRecorder {
  
  Stream<Uint8List> get onRecordedDataAvailable => AudioRecorderPlatform.instance.onRecordedDataAvailable;
  Stream<bool> get onRecordingSuccessfullyComplete => AudioRecorderPlatform.instance.onRecordingSuccessfullyComplete;
  Stream<int> get initialized => AudioRecorderPlatform.instance.initialized;
  Stream<String> get error => AudioRecorderPlatform.instance.error;

  get initialize => AudioRecorderPlatform.instance.initialize;
  get start => AudioRecorderPlatform.instance.start;
  get stop => AudioRecorderPlatform.instance.stop;

  get isRecording => AudioRecorderPlatform.instance.isRecording;

  get hasPermissions => AudioRecorderPlatform.instance.hasPermissions;

}