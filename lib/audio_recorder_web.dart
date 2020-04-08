@JS('flutter_sound_web')
library flutter_sound_web;

import 'package:js/js.dart';
import 'dart:async';
import 'dart:core';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

@JS()
class Recorder {
  external Recorder(Function onInit, Function onEvent, Function onError,
      Function callback);
  external void record();
  external void stop(bool export);
  external void clear();
  external void initialize();
  external void setBitDepth(int bitDepth);
}


class AudioRecorderWebPlugin  {

  static Recorder _recorder;

  static MethodChannel _channel;

  static int _sampleRate;

  static void registerWith(Registrar registrar) {
    _channel = MethodChannel(
      'audio_recorder',
      const StandardMethodCodec(),
      registrar.messenger,
    );

    final AudioRecorderWebPlugin instance = AudioRecorderWebPlugin();
    _channel.setMethodCallHandler(instance.handleMethodCall);

    _recorder = Recorder(allowInterop((sampleRate) {
      _sampleRate = sampleRate;
      _channel.invokeMethod("initialized", sampleRate);
    }), allowInterop((event) {

    }), allowInterop((error) {
      _channel.invokeMethod("recordError", error);
    }), allowInterop((data, done) {
      _channel.invokeMethod("recordedData", data);
      if(done)
        _channel.invokeMethod("recordingComplete");
    }));
  }


  Future<dynamic> handleMethodCall(MethodCall call) async {

    final method = call.method;

    switch (method) {
      case 'start':
         _recorder.record();
         return "started";
      case 'stop':
        final bool export = call.arguments;
        _recorder.stop(export);
        return "stopped";
      case 'initialize':
        _recorder.initialize();
        break;
      case 'hasPermissions':
        return true;
      default:
          throw new ArgumentError('Unknown method ${call.method} ');
    }
  }
}