import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _taglineSlide;
  late final Animation<double> _loaderOpacity;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _logoOpacity = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.0, 0.48, curve: Curves.easeIn),
    );
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.0, 0.68, curve: Curves.elasticOut),
      ),
    );
    _logoSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.0, 0.48, curve: Curves.easeOut),
      ),
    );
    _taglineOpacity = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.54, 0.82, curve: Curves.easeIn),
    );
    _taglineSlide = Tween<double>(begin: 14.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.54, 0.82, curve: Curves.easeOut),
      ),
    );
    _loaderOpacity = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.82, 1.0, curve: Curves.easeIn),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _introCtrl.forward();
    });
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    if (!onboardingDone) {
      context.go('/onboarding');
    } else if (user != null) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Cercle décoratif coin haut-droite (bleu marque)
          Positioned(
            top: -size.width * 0.30,
            right: -size.width * 0.30,
            child: AnimatedBuilder(
              animation: _logoOpacity,
              builder: (_, __) => Opacity(
                opacity: (_logoOpacity.value * 0.13).clamp(0.0, 1.0),
                child: Container(
                  width: size.width * 0.68,
                  height: size.width * 0.68,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1565C0),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // Cercle décoratif coin bas-gauche (teal marque)
          Positioned(
            bottom: -size.width * 0.24,
            left: -size.width * 0.24,
            child: AnimatedBuilder(
              animation: _logoOpacity,
              builder: (_, __) => Opacity(
                opacity: (_logoOpacity.value * 0.10).clamp(0.0, 1.0),
                child: Container(
                  width: size.width * 0.62,
                  height: size.width * 0.62,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00BFA5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // Contenu centré
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_introCtrl, _pulseCtrl]),
              builder: (_, __) {
                final introScale = _logoScale.value;
                // Le pulse démarre seulement après la fin du bounce (interval 0.68)
                final pulseScale =
                    _introCtrl.value >= 0.68 ? _pulse.value : 1.0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo avec ratio préservé
                    Opacity(
                      opacity: _logoOpacity.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, _logoSlide.value),
                        child: Transform.scale(
                          scale: introScale * pulseScale,
                          child: Image.asset(
                            'assets/icons/app_icon_foreground.png',
                            width: 260,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Tagline avec lignes d'accent
                    Opacity(
                      opacity: _taglineOpacity.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, _taglineSlide.value),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 22,
                              height: 1.5,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00BFA5),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Gestion de facturation simplifiée',
                              style: TextStyle(
                                color: Color(0xFF78909C),
                                fontSize: 13,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 22,
                              height: 1.5,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00BFA5),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Indicateur de chargement
          Positioned(
            bottom: 52,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _loaderOpacity,
              builder: (_, __) => Opacity(
                opacity: _loaderOpacity.value.clamp(0.0, 1.0),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00BFA5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
