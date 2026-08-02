import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/audio_recorder_service.dart';

class Waveform extends StatefulWidget {
  const Waveform({super.key, required this.service});

  final AudioRecorderService service;

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _ampTimer;
  double _amplitude = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    widget.service.isRecording.addListener(_onRecordingChanged);
    _onRecordingChanged();
  }

  void _onRecordingChanged() {
    if (widget.service.isRecording.value) {
      _ampTimer ??= Timer.periodic(
        const Duration(milliseconds: 120),
        (_) => _readAmplitude(),
      );
    } else {
      _ampTimer?.cancel();
      _ampTimer = null;
      if (mounted) {
        setState(() => _amplitude = 0.0);
      }
    }
  }

  Future<void> _readAmplitude() async {
    final amp = await widget.service.getAmplitude();
    if (!mounted) {
      return;
    }
    setState(() => _amplitude = ((amp + 60) / 60).clamp(0.0, 1.0));
  }

  @override
  void dispose() {
    widget.service.isRecording.removeListener(_onRecordingChanged);
    _ampTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(240, 90),
          painter: WaveformPainter(
            animationValue: _controller.value,
            amplitude: _amplitude,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.animationValue,
    required this.amplitude,
    required this.color,
  });

  final double animationValue;
  final double amplitude;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round;

    final barCount = 28;
    final gap = 5.0;
    final barWidth = (size.width - gap * (barCount - 1)) / barCount;
    final minHeight = 6.0;
    final effective = math.max(amplitude, 0.35);

    for (var i = 0; i < barCount; i++) {
      final wave = (math.sin(animationValue * 2 * math.pi + i * 0.45) + 1) / 2;
      final barHeight =
          minHeight + wave * effective * (size.height - minHeight);
      final x = i * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - barHeight) / 2, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.amplitude != amplitude ||
      oldDelegate.color != color;
}
