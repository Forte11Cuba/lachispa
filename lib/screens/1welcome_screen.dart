import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';
import '2start_screen.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/language_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late AnimationController _sparkController;
  late Animation<double> _titleAnimation;
  late Animation<double> _subtitleAnimation;
  late Animation<double> _card1Animation;
  late Animation<double> _card2Animation;
  late Animation<double> _card3Animation;
  late Animation<double> _buttonAnimation;
  
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  late Timer _sparkTimer;
  Size? _screenSize; // Screen size cache

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save safe reference to MediaQuery
    _screenSize = MediaQuery.of(context).size;
    // Configure timer only after having the reference
    if (_screenSize != null) {
      _setupSparkTimer();
    }
  }

  void _setupAnimations() {
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _sparkController = AnimationController(
      duration: const Duration(milliseconds: 16), // 60 FPS
      vsync: this,
    )..repeat();

    _titleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.2, curve: Curves.easeOutCubic),
    ));

    _subtitleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.2, 0.4, curve: Curves.easeOutCubic),
    ));

    _card1Animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.4, 0.6, curve: Curves.easeOutCubic),
    ));

    _card2Animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.5, 0.7, curve: Curves.easeOutCubic),
    ));

    _card3Animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.6, 0.8, curve: Curves.easeOutCubic),
    ));

    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.8, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  void _startAnimations() {
    _staggerController.forward();
  }

  void _setupSparkTimer() {
    // Create spark effects every 3 seconds
    _sparkTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _createRandomSpark();
    });
  }

  void _createRandomSpark() {
    if (!mounted || _screenSize == null) return;
    
    final sparkCount = _random.nextInt(3) + 2; // 2-4 sparks per cycle
    
    for (int spark = 0; spark < sparkCount; spark++) {
      // Use cached reference instead of MediaQuery.of(context) to avoid context issues
      final x = _random.nextDouble() * _screenSize!.width;
      final y = _random.nextDouble() * _screenSize!.height;
      final particleCount = _random.nextInt(20) + 10; // 10-30 particles per spark
      
      for (int i = 0; i < particleCount; i++) {
        _particles.add(Particle(x, y, _random));
      }
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _sparkController.dispose();
    _sparkTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F1419),
              Color(0xFF1A1D47),
              Color(0xFF2D3FE7),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated spark effects
            AnimatedBuilder(
              animation: _sparkController,
              builder: (context, child) {
                return CustomPaint(
                  painter: SparkPainter(_particles),
                  size: Size.infinite,
                );
              },
            ),
            
            // Main content
            SafeArea(
              child: Stack(
                children: [
                  // Language selector in top right corner
                  Positioned(
                    top: 16,
                    right: 24,
                    child: _buildLanguageSelector(),
                  ),
                  
                  // Main content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),
                    
                    // Logo and Title with animation
                    AnimatedBuilder(
                      animation: _titleAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * (1 - _titleAnimation.value)),
                          child: Opacity(
                            opacity: _titleAnimation.value,
                            child: Column(
                              children: [
                                // Logo
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2D3FE7).withValues(alpha: 0.5),
                                        blurRadius: 25,
                                        offset: const Offset(0, 10),
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFF5B73FF).withValues(alpha: 0.3),
                                        blurRadius: 40,
                                        offset: const Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.asset(
                                      'Logo/chispabordesredondos.png',
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Title
                                Text(
                                  'LaChispa',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(0, 4),
                                        blurRadius: 8,
                                        color: const Color(0xFF2D3FE7).withValues(alpha: 0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Subtitle with animation
                    AnimatedBuilder(
                      animation: _subtitleAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - _subtitleAnimation.value)),
                          child: Opacity(
                            opacity: _subtitleAnimation.value,
                            child: Text(
                              AppLocalizations.of(context)!.welcome_subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                    
                    // Feature cards with glassmorphism
                    AnimatedBuilder(
                      animation: _card1Animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - _card1Animation.value)),
                          child: Opacity(
                            opacity: _card1Animation.value,
                            child: _buildGlassmorphismCard(
                              Icons.electric_bolt_outlined,
                              AppLocalizations.of(context)!.tap_to_start_hint,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    AnimatedBuilder(
                      animation: _card2Animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - _card2Animation.value)),
                          child: Opacity(
                            opacity: _card2Animation.value,
                            child: _buildGlassmorphismCard(
                              Icons.timer,
                              AppLocalizations.of(context)!.instant_payments_feature,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    AnimatedBuilder(
                      animation: _card3Animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - _card3Animation.value)),
                          child: Opacity(
                            opacity: _card3Animation.value,
                            child: _buildGlassmorphismCard(
                              Icons.cloud,
                              AppLocalizations.of(context)!.favorite_server_feature,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const Spacer(flex: 2),
                    
                    // Continue button with animation
                    AnimatedBuilder(
                      animation: _buttonAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - _buttonAnimation.value)),
                          child: Opacity(
                            opacity: _buttonAnimation.value,
                            child: _buildGradientButton(),
                          ),
                        );
                      },
                    ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassmorphismCard(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF2D3FE7),
            Color(0xFF4C63F7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D3FE7).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StartScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.get_started_button,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return GestureDetector(
          onTap: () => _showLanguageSelector(context, languageProvider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  languageProvider.getCurrentLanguageFlag(),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageSelector(BuildContext context, LanguageProvider languageProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1D47),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(
                    Icons.language,
                    color: Color(0xFF4C63F7),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.language_selector_title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Language options
            ...languageProvider.getAvailableLanguages().map((language) {
              final isSelected = languageProvider.currentLocale.languageCode == language['code'];
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? const Color(0xFF2D3FE7).withValues(alpha: 0.2)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected 
                    ? Border.all(color: const Color(0xFF2D3FE7), width: 1)
                    : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Text(
                    language['flag']!,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    language['name']!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                  trailing: isSelected 
                    ? const Icon(
                        Icons.check,
                        color: Color(0xFF4C63F7),
                        size: 20,
                      )
                    : null,
                  onTap: () async {
                    await languageProvider.changeLanguage(
                      Locale(language['code']!, ''),
                    );
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              );
            }).toList(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
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
  
  // Use smooth curve for fade out
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
    // Update particle positions and lifecycle
    particles.removeWhere((particle) {
      particle.update();
      return !particle.isAlive;
    });

    // Get devicePixelRatio for high density screens
    final devicePixelRatio = 1.0; // Can be obtained from context if needed
    
    // Render particles with layered glow effects
    for (final particle in particles) {
      final alpha = particle.opacity;
      if (alpha <= 0) continue;

      final center = Offset(particle.x, particle.y);
      final scaledSize = particle.size * devicePixelRatio;
      
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