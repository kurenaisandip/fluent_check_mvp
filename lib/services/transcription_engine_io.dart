import 'dart:async';
import 'dart:io';

import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

class TranscriptionEngine {
  final WhisperController _controller = WhisperController();

  Stream<String> get transcriptUpdates => const Stream<String>.empty();

  bool get isSupported => true;

  Future<void> start({String lang = 'en'}) async {}

  Future<void> resume({String lang = 'en'}) async {}

  Future<void> pause() async {}

  Future<String> stop() async => '';

  Future<String> transcribeFile(String path, {String lang = 'en'}) async {
    await _ensureModel();
    final result = await _controller.transcribe(
      model: WhisperModel.tiny,
      audioPath: path,
      lang: lang,
      convert: false,
    );
    return result?.transcription.text.trim() ?? '';
  }

  Future<void> _ensureModel() async {
    final modelPath = await _controller.getPath(WhisperModel.tiny);
    final exists = await File(modelPath).exists();
    if (!exists) {
      await _controller.downloadModel(WhisperModel.tiny);
    }
  }

  Future<void> dispose() async {
    await _controller.dispose(model: WhisperModel.tiny);
  }
}
