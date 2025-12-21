import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class ExerciseTimer extends StatefulWidget {
  final int durationSeconds;

  const ExerciseTimer({super.key, required this.durationSeconds});

  @override
  State<ExerciseTimer> createState() => _ExerciseTimerState();
}

class _ExerciseTimerState extends State<ExerciseTimer> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _timer = null;
          _playSound();
        }
      });
    });
    setState(() {
      _isRunning = true;
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _remainingSeconds = widget.durationSeconds;
      _isRunning = false;
    });
  }

  void _playSound() async {
    await _audioPlayer.play(AssetSource('beep.mp3'));
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _formatTime(_remainingSeconds),
          style: const TextStyle(fontSize: 48),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _startTimer,
              child: const Text('Старт'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: !_isRunning ? null : _pauseTimer,
              child: const Text('Пауза'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _resetTimer,
              child: const Text('Сброс'),
            ),
          ],
        ),
      ],
    );
  }
}