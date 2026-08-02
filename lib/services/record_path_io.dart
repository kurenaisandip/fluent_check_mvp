import 'dart:io';

String generateRecordingPath() =>
    '${Directory.systemTemp.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

Future<void> deleteFile(String path) async {
  if (path.isEmpty) {
    return;
  }
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}
