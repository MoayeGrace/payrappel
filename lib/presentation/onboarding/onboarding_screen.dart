import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Données des pages ──────────────────────────────────────────────────────────
typedef _PageData = ({
  String title,
  String description,
  IconData icon,
  List<Color> colors,
});

const List<_PageData> _pages = [
  (
    title: 'Gérez vos clients',
    description:
        'Centralisez toutes vos informations clients et suivez leur historique de paiement en un seul endroit.',
    icon: Icons.people_outlined,
    colors: [Color(0xFF0D47A1), Color(0xFF1A73E8)],
  ),
  (
    title: 'Suivez vos factures',
    description:
        'Créez des factures professionnelles, enregistrez des paiements partiels et visualisez l\'avancement en temps réel.',
    icon: Icons.receipt_long_outlined,
    colors: [Color(0xFF004D40), Color(0xFF00BFA5)],
  ),
  (
    title: 'Rappels automatiques',
    description:
        'Programmez des rappels de paiement et ne manquez plus jamais une échéance. Exportez vos données en un clic.',
    icon: Icons.notifications_active_outlined,
    colors: [Color(0xFF4527A0), Color(0xFF7C4DFF)],
  ),
];

// ── Écran onboarding ───────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _current = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_current < _pages.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _current == _pages.length - 1;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // ── Pages ─────────────────────────────────────────────────────────
          PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _OnboardingPage(page: _pages[i]),
          ),

          // ── Bouton passer ──────────────────────────────────────────────────
          if (!isLast)
            Positioned(
              top: safeTop + 8,
              right: 12,
              child: TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text(
                  'Passer',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),

          // ── Contrôles bas ──────────────────────────────────────────────────
          Positioned(
            bottom: safeBottom + 36,
            left: 28,
            right: 28,
            child: Column(
              children: [
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _current ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _current
                            ? Colors.white
                            : Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Bouton principal
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _pages[_current].colors.last,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        isLast ? 'Commencer' : 'Suivant',
                        key: ValueKey(isLast),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                // Lien login (dernière page seulement)
                if (isLast) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _finish,
                    child: const Text(
                      'J\'ai déjà un compte',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page individuelle ──────────────────────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final _PageData page;
  const _OnboardingPage({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: page.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Cercles décoratifs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -80,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 160,
            right: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Contenu
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(36, 80, 36, 180),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      page.icon,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 52),

                  // Titre
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Description
                  Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
