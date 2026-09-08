import 'dart:math' as math;
import 'package:flutter/material.dart';

class AudioWaveformVisualizer extends StatefulWidget {
  final bool isListening;
  final double soundLevel;
  final Color color;

  const AudioWaveformVisualizer({
    super.key,
    required this.isListening,
    required this.soundLevel,
    this.color = const Color(0xFF6366F1),
  });

  @override
  State<AudioWaveformVisualizer> createState() => _AudioWaveformVisualizerState();
}

class _AudioWaveformVisualizerState extends State<AudioWaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isListening) {
      return SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            15,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 4,
              height: 8,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(15, (index) {
              final phase = (index / 15) * 2 * math.pi;
              final sinValue = math.sin(_controller.value * 2 * math.pi + phase);
              final normalizedLevel = math.max(0.2, (widget.soundLevel / 10).clamp(0.2, 1.0));
              final height = 10 + (sinValue.abs() * 28 * normalizedLevel);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
