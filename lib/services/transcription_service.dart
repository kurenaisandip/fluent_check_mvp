import 'transcription_engine.dart'
    if (dart.library.io) 'transcription_engine_io.dart' as engine;

class TranscriptionService {
  final engine.TranscriptionEngine _engine = engine.TranscriptionEngine();

  Stream<String> get transcriptUpdates => _engine.transcriptUpdates;

  bool get isSupported => _engine.isSupported;

  Future<void> start({String lang = 'en'}) => _engine.start(lang: lang);

  Future<void> pause() => _engine.pause();

  Future<void> resume({String lang = 'en'}) => _engine.resume(lang: lang);

  Future<String> stop() => _engine.stop();

  Future<String> transcribeFile(String path, {String lang = 'en'}) =>
      _engine.transcribeFile(path, lang: lang);

  Future<void> dispose() => _engine.dispose();
}
