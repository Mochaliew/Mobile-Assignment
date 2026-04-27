// --- Purchase Success Overlay ------------------------------------------------
import 'dart:math';
import 'package:flutter/material.dart';

class PurchaseSuccessOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  const PurchaseSuccessOverlay({super.key, required this.onComplete});

  @override
  State<PurchaseSuccessOverlay> createState() => _PurchaseSuccessOverlayState();
}

class _PurchaseSuccessOverlayState extends State<PurchaseSuccessOverlay>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;

  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    _checkOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _checkController, curve: Curves.easeOut));

    _generateParticles();

    Future.delayed(const Duration(milliseconds: 100), () {
      _checkController.forward();
    });

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) widget.onComplete();
    });
  }

  void _generateParticles() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.yellow,
      Colors.cyan,
    ];

    for (int i = 0; i < 40; i++) {
      _particles.add(
        _ConfettiParticle(
          color: colors[_random.nextInt(colors.length)],
          x: _random.nextDouble() * 300 - 150,
          delay: _random.nextDouble() * 0.3,
          speed: 150 + _random.nextDouble() * 200,
          size: 6 + _random.nextDouble() * 6,
          angle: _random.nextDouble() * pi * 2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Material(
        color: Colors.black.withOpacity(0.6),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Confetti particles
            ..._particles.map((p) => _ConfettiWidget(particle: p)),

            // Checkmark and text
            FadeTransition(
              opacity: _checkOpacity,
              child: ScaleTransition(
                scale: _checkScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Color(0xFF5B6FF5),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Payment Successful',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  final Color color;
  final double x;
  final double delay;
  final double speed;
  final double size;
  final double angle;

  _ConfettiParticle({
    required this.color,
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.angle,
  });
}

class _ConfettiWidget extends StatefulWidget {
  final _ConfettiParticle particle;
  const _ConfettiWidget({required this.particle});

  @override
  State<_ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<_ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    Future.delayed(
      Duration(milliseconds: (widget.particle.delay * 1000).toInt()),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final y = -200 + t * widget.particle.speed;
        final opacity = t < 0.8 ? 1.0 : 1.0 - (t - 0.8) * 5;

        return Positioned(
          top: MediaQuery.of(context).size.height / 2 + y,
          left:
              MediaQuery.of(context).size.width / 2 +
              widget.particle.x +
              sin(t * pi * 2 + widget.particle.angle) * 50 * t,
          child: Opacity(
            opacity: opacity.clamp(0, 1),
            child: Transform.rotate(
              angle: t * pi * 4 + widget.particle.angle,
              child: Container(
                width: widget.particle.size,
                height: widget.particle.size,
                decoration: BoxDecoration(
                  color: widget.particle.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
