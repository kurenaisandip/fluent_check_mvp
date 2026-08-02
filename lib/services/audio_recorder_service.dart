import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'record_path.dart'
    if (dart.library.io) 'record_path_io.dart' as record_path;

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  final ValueNotifier<bool> isRecording = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);

  String? _path;

  String? get lastPath => _path;

  Future<bool> start() async {
    if (!await _recorder.hasPermission()) {
      return false;
    }
    final path = kIsWeb ? '' : record_path.generateRecordingPath();
    final config = RecordConfig(
      encoder: kIsWeb ? AudioEncoder.pcm16bits : AudioEncoder.wav,
      numChannels: 1,
      sampleRate: 16000,
    );
    _path = path;
    await _recorder.start(config, path: path);
    isRecording.value = true;
    isPaused.value = false;
    return true;
  }

  Future<void> pause() async {
    await _recorder.pause();
    isPaused.value = true;
  }

  Future<void> resume() async {
    await _recorder.resume();
    isPaused.value = false;
  }

  Future<String?> stop() async {
    final path = await _recorder.stop();
    isRecording.value = false;
    isPaused.value = false;
    if (kIsWeb) {
      _path = path;
    }
    return path;
  }

  Future<void> deleteRecording() async {
    final path = _path;
    if (kIsWeb) {
      _path = null;
      return;
    }
    if (path != null) {
      await record_path.deleteFile(path);
    }
    _path = null;
  }

  Future<double> getAmplitude() async {
    final amp = await _recorder.getAmplitude();
    return amp.current;
  }

  void dispose() {
    _recorder.dispose();
    isRecording.dispose();
    isPaused.dispose();
  }
}
