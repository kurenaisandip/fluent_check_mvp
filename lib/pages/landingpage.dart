import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/audio_recorder_service.dart';
import '../services/filler_word_detector.dart';
import '../services/transcription_service.dart';
import '../widgets/waveform.dart';

class Landingpage extends StatefulWidget {
  const Landingpage({super.key});

  @override
  State<Landingpage> createState() => _LandingpageState();
}

class _LandingpageState extends State<Landingpage> {
  final _service = AudioRecorderService();
  final _transcription = TranscriptionService();
  final _fillerDetector = FillerWordDetector();
  Timer? _timer;
  StreamSubscription<String>? _transcriptionSub;
  int _elapsedSeconds = 0;
  String _transcript = '';
  List<FillerWord> _fillers = [];
  bool _isTranscribing = false;

  @override
  void initState() {
    super.initState();
    _transcriptionSub = _transcription.transcriptUpdates.listen((text) {
      if (mounted) {
        setState(() {
          _transcript = text;
          _fillers = _fillerDetector.detect(text);
        });
      }
    });
  }

  @override
  void dispose() {
    _transcriptionSub?.cancel();
    _timer?.cancel();
    _service.dispose();
    _transcription.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _startRecording() async {
    final started = await _service.start();
    if (!started) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _elapsedSeconds = 0;
      _transcript = '';
      _fillers = [];
      _isTranscribing = false;
    });
    _startTimer();
    if (kIsWeb && !_transcription.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live words need Chrome or Edge on the web'),
        ),
      );
    }
    await _transcription.start(lang: 'en');
  }

  Future<void> _pauseRecording() async {
    await _service.pause();
    _timer?.cancel();
    if (kIsWeb) {
      await _transcription.pause();
    }
  }

  Future<void> _resumeRecording() async {
    await _service.resume();
    _startTimer();
    if (kIsWeb) {
      await _transcription.resume(lang: 'en');
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _service.stop();
    if (!mounted) {
      return;
    }
    setState(() => _elapsedSeconds = 0);

    if (kIsWeb) {
      final text = await _transcription.stop();
      if (mounted) {
        setState(() {
          _transcript = text;
          _fillers = _fillerDetector.detect(text);
        });
      }
    } else {
      if (path != null) {
        setState(() => _isTranscribing = true);
        try {
          final text = await _transcription.transcribeFile(path, lang: 'en');
          if (mounted) {
            setState(() {
              _transcript = text;
              _fillers = _fillerDetector.detect(text);
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Transcription failed: $e')),
            );
          }
        } finally {
          await _service.deleteRecording();
          if (mounted) {
            setState(() => _isTranscribing = false);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Waveform(service: _service),
                    const SizedBox(height: 32),
                    Text(
                      _formatTime(_elapsedSeconds),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 32),
                    _buildControls(),
                  ],
                ),
              ),
            ),
            _buildFillerWordBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return ValueListenableBuilder<bool>(
      valueListenable: _service.isRecording,
      builder: (context, isRecording, _) {
        if (!isRecording) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _roundButton(
                icon: Icons.mic,
                color: Colors.red,
                tooltip: 'Record',
                onPressed: _startRecording,
              ),
            ],
          );
        }
        return ValueListenableBuilder<bool>(
          valueListenable: _service.isPaused,
          builder: (context, isPaused, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _roundButton(
                  icon: Icons.stop,
                  color: Colors.red,
                  tooltip: 'Stop',
                  onPressed: _stopRecording,
                ),
                const SizedBox(width: 40),
                _roundButton(
                  icon: isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.blue,
                  tooltip: isPaused ? 'Resume' : 'Pause',
                  onPressed: isPaused ? _resumeRecording : _pauseRecording,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _roundButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 40,
      style: IconButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(20),
      ),
      icon: Icon(icon),
    );
  }

  Widget _buildFillerWordBox() {
    final Widget content;
    if (_isTranscribing) {
      content = const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Transcribing…'),
        ],
      );
    } else if (_transcript.isNotEmpty) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Text(_transcript),
            ),
          ),
          if (_fillers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _fillers
                  .map(
                    (f) => Chip(
                      label: Text('${f.word} ×${f.count}'),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      );
    } else {
      content = Text(
        'Filler words will appear here',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey,
            ),
      );
    }

    return Container(
      height: 180,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );
  }
}
