@JS('flutter_sound_web')
library flutter_sound_web;

import 'package:js/js.dart';
import 'dart:async';
import 'dart:core';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:audio_recorder_platform_interface/audio_recorder_platform_interface.dart';

@JS()
class Recorder {
  external Recorder(Function onInit, Function onEvent, Function onError,
      Function callback, bool exportRecorded, String workerPath);
  external void record();
  external void stop(bool export);
  external void clear();
  external void initialize();
  external void setBitDepth(int bitDepth);
}


class AudioRecorderWebPlugin extends AudioRecorderPlatform  {

  Recorder _recorder;

  int _sampleRate;

  AudioRecorderWebPlugin([bool useAssetPrefix=false]) {
    _recorder = Recorder(allowInterop((sampleRate) {
      _sampleRate = sampleRate;
      initializedController.add(_sampleRate);
    }), allowInterop((event) {

    }), allowInterop((error) {
      print("Interop error : $error");
      errorController.add(error.toString());
    }), allowInterop((data, done) {
      onRecordedDataAvailableController.add(data);
      if(done)
        onRecordingSuccessfullyCompleteController.add(true);
    }), false, useAssetPrefix ? "assets/packages/audio_recorder_web/js/recorderWorker.js" : "packages/audio_recorder_web/js/recorderWorker.js");
  }

  /// Registers this class as the default instance of [AudioPlayerPlatform].
  static void registerWith(Registrar registrar) {
    AudioRecorderPlatform.instance = AudioRecorderWebPlugin();
  }

  @override
  void initialize() {
    _recorder.initialize();
  }

  // TODO - fix this if permission isn't available in browser
  Future<bool> get hasPermissions async {
    return true;
  }

  bool _recording;

  @override
  Future start(
      {String path, AudioOutputFormat audioOutputFormat}) {
        print("starting");
        if(audioOutputFormat != AudioOutputFormat.WAV)
          throw new Exception("Web recording currently only supports WAV");
      _recorder.record();
      _recording = true;
  }

  Future<Recording> stop([bool export = true]) async {
    _recorder.stop(export);
    _recording = false;
    return Recording(audioOutputFormat: AudioOutputFormat.WAV);
  }

  Future<bool> get isRecording async {
    return _recording;
  }
}