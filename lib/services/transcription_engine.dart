import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

@JS('webkitSpeechRecognition')
extension type SpeechRecognition._(JSObject _) implements JSObject {
  external factory SpeechRecognition();
  external void start();
  external void stop();
  external void abort();
  external set lang(String value);
  external set continuous(bool value);
  external set interimResults(bool value);
  external set onresult(JSFunction value);
  external set onend(JSFunction value);
  external set onerror(JSFunction value);
}

extension type SpeechRecognitionEvent(JSObject _) implements JSObject {
  external SpeechRecognitionResultList get results;
}

extension type SpeechRecognitionResultList(JSObject _) implements JSObject {
  external int get length;
  external SpeechRecognitionResult item(int index);
}

extension type SpeechRecognitionResult(JSObject _) implements JSObject {
  external bool get isFinal;
  external int get length;
  external SpeechRecognitionResultAlternative item(int index);
}

extension type SpeechRecognitionResultAlternative(JSObject _)
    implements JSObject {
  external String get transcript;
}

class TranscriptionEngine {
  SpeechRecognition? _recognition;
  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  final List<String> _finalParts = [];
  String _interim = '';
  bool _running = false;

  Stream<String> get transcriptUpdates => _controller.stream;

  bool get isSupported =>
      web.window.hasProperty('webkitSpeechRecognition'.toJS).toDart;

  String get currentTranscript {
    final parts = [..._finalParts];
    if (_interim.isNotEmpty) {
      parts.add(_interim);
    }
    return parts.join(' ').trim();
  }

  Future<void> start({String lang = 'en'}) async {
    _finalParts.clear();
    _interim = '';
    _begin(lang);
  }

  Future<void> resume({String lang = 'en'}) async {
    _begin(lang);
  }

  void _begin(String lang) {
    if (!isSupported) {
      return;
    }
    _recognition?.stop();
    final recognition = SpeechRecognition()
      ..lang = lang
      ..continuous = true
      ..interimResults = true;
    recognition.onresult = ((JSAny event) {
      _handleResult(SpeechRecognitionEvent(event as JSObject));
    }).toJS;
    recognition.onend = (() {
      _running = false;
    }).toJS;
    recognition.onerror = ((JSAny _) {
      _running = false;
    }).toJS;
    _recognition = recognition;
    _running = true;
    recognition.start();
  }

  void _handleResult(SpeechRecognitionEvent event) {
    if (!_running) {
      return;
    }
    final results = event.results;
    _interim = '';
    for (var i = 0; i < results.length; i++) {
      final result = results.item(i);
      final text = result.length > 0 ? result.item(0).transcript.trim() : '';
      if (text.isEmpty) {
        continue;
      }
      if (result.isFinal) {
        _finalParts.add(text);
      } else {
        _interim = text;
      }
    }
    if (!_controller.isClosed) {
      _controller.add(currentTranscript);
    }
  }

  Future<void> pause() async {
    _running = false;
    _recognition?.stop();
    _recognition = null;
    if (!_controller.isClosed) {
      _controller.add(currentTranscript);
    }
  }

  Future<String> stop() async {
    final recognition = _recognition;
    if (recognition == null) {
      final text = currentTranscript;
      if (!_controller.isClosed) {
        _controller.add(text);
      }
      return text;
    }
    final completer = Completer<String>();
    recognition.onend = (() {
      _running = false;
      if (_recognition == recognition) {
        _recognition = null;
      }
      final text = currentTranscript;
      if (!_controller.isClosed) {
        _controller.add(text);
      }
      if (!completer.isCompleted) {
        completer.complete(text);
      }
    }).toJS;
    recognition.stop();
    return completer.future;
  }

  Future<String> transcribeFile(String path, {String lang = 'en'}) async {
    throw UnsupportedError('File transcription is not available on web');
  }

  Future<void> dispose() async {
    _running = false;
    _recognition?.abort();
    _recognition = null;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
