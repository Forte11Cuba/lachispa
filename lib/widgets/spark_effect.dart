import 'package:flutter/material.dart';
import 'dart:math' as math;

class SparkEffect extends StatefulWidget {
  final AnimationController animation;
  
  const SparkEffect({
    super.key,
    required this.animation,
  });

  @override
  State<SparkEffect> createState() => _SparkEffectState();
}

class _SparkEffectState extends State<SparkEffect> {
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  int _lastSparkTime = 0;
  
  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_updateParticles);
  }

  @override
  void dispose() {
    widget.animation.removeListener(_updateParticles);
    super.dispose();
  }

  void _updateParticles() {
    if (!mounted) return;
    
    // Create sparks every 3 seconds (approximately 180 frames at 60 FPS)
    final currentTime = widget.animation.value * 1000; // Convert to ms-like value
    if (currentTime - _lastSparkTime > 50) { // Adjust frequency
      _createRandomSpark();
      _lastSparkTime = currentTime.toInt();
    }
    
    setState(() {
      // Particle updates are handled in the painter
    });
  }

  void _createRandomSpark() {
    final sparkCount = _random.nextInt(3) + 2; // 2-4 sparks
    
    for (int spark = 0; spark < sparkCount; spark++) {
      final context = this.context;
      if (context.mounted) {
        final screenSize = MediaQuery.of(context).size;
        final x = _random.nextDouble() * screenSize.width;
        final y = _random.nextDouble() * screenSize.height;
        final particleCount = _random.nextInt(20) + 10; // 10-30 particles
        
        for (int i = 0; i < particleCount; i++) {
          _particles.add(Particle(x, y, _random));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SparkPainter(_particles),
      size: Size.infinite,
    );
  }
}

class Particle {
  double x;
  double y;
  final double size;
  double speedX;
  double speedY;
  double life;
  final double decay;

  Particle(this.x, this.y, math.Random random) :
    size = (random.nextDouble() * 3 + 1.0), // 1-4px
    speedX = _generateOrganicVelocity(random),
    speedY = _generateOrganicVelocity(random),
    life = 100,
    decay = random.nextDouble() * 1.5 + 0.5; // 0.5-2

  static double _generateOrganicVelocity(math.Random random) {
    // More organic radial distribution
    final angle = random.nextDouble() * 2 * math.pi;
    final intensity = random.nextDouble() * 4 + 2; // 2-6 intensidad
    final direction = random.nextBool() ? 1 : -1;
    return math.cos(angle) * intensity * direction;
  }

  void update() {
    x += speedX;
    y += speedY;
    life -= decay;
    speedX *= 0.99; // Deceleration
    speedY *= 0.99;
  }

  bool get isAlive => life > 0;
  
  // Use smooth curve for fading
  double get opacity {
    final normalizedLife = life / 100;
    // Apply easeOutQuart curve for smoothness
    return 1 - math.pow(1 - normalizedLife, 4).toDouble();
  }
}

class SparkPainter extends CustomPainter {
  final List<Particle> particles;

  SparkPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    // Update particles
    particles.removeWhere((particle) {
      particle.update();
      return !particle.isAlive;
    });

    // Draw particles
    for (final particle in particles) {
      final alpha = particle.opacity;
      if (alpha <= 0) continue;

      final center = Offset(particle.x, particle.y);
      final scaledSize = particle.size;
      
      // More saturated and brighter colors
      const primaryColor = Color(0xFF5B73FF); // Brighter
      const secondaryColor = Color(0xFF4C63F7); // Original

      // 1. Outer glow (more subtle)
      final glowPaint2 = Paint()
        ..color = primaryColor.withValues(alpha: alpha * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      
      canvas.drawCircle(center, scaledSize * 2, glowPaint2);

      // 2. Inner glow (smaller)
      final glowPaint1 = Paint()
        ..color = secondaryColor.withValues(alpha: alpha * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      
      canvas.drawCircle(center, scaledSize * 1.5, glowPaint1);

      // 3. Main particle (solid, brighter)
      final particlePaint = Paint()
        ..color = primaryColor.withValues(alpha: alpha * 0.9);
      
      canvas.drawCircle(center, scaledSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}