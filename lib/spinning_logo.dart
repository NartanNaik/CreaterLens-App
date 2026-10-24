import 'package:flutter/material.dart';

/// The CreatorLens hexagon, slowly rotating (same idea as the animated logo on the website).
class SpinningLogo extends StatefulWidget {
  const SpinningLogo({super.key, this.size = 64});

  final double size;

  @override
  State<SpinningLogo> createState() => _SpinningLogoState();
}

class _SpinningLogoState extends State<SpinningLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) _controller.stop();

    return RotationTransition(
      turns: _controller,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.hexagon_outlined, size: widget.size, color: color),
          Icon(Icons.diamond_outlined, size: widget.size * 0.55, color: color),
          Icon(Icons.circle, size: widget.size * 0.12, color: color),
        ],
      ),
    );
  }
}