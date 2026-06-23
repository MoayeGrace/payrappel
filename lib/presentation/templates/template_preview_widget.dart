import 'package:flutter/material.dart';
import '../../data/models/invoice_template_model.dart';

/// Widget de prévisualisation miniature d'un template de facture.
/// Utilisé dans la grille des templates et dans l'éditeur (live preview).
class TemplateMiniPreview extends StatelessWidget {
  final InvoiceTemplateModel template;

  const TemplateMiniPreview({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    final accent = Color(template.accentColor);
    final headerBg = template.headerBgColor != null
        ? Color(template.headerBgColor!)
        : accent;

    return switch (template.layout) {
      TemplateLayout.classic => _ClassicPreview(accent: accent),
      TemplateLayout.modern  => _ModernPreview(accent: accent, headerBg: headerBg),
      TemplateLayout.minimal => _MinimalPreview(accent: accent),
      TemplateLayout.bold    => _BoldPreview(accent: accent, headerBg: headerBg),
    };
  }
}

// ── Classic ───────────────────────────────────────────────────────────────────

class _ClassicPreview extends StatelessWidget {
  final Color accent;
  const _ClassicPreview({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 2),
                    Container(
                        width: 28,
                        height: 3,
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(2))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                    color: accent, borderRadius: BorderRadius.circular(3)),
                child: const Text('FACTURE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 5,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(height: 0.5, color: Colors.grey[200]),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(child: _fakeBox(accent.withOpacity(0.08), double.infinity, 28)),
              const SizedBox(width: 4),
              Expanded(child: _fakeBox(Colors.grey[50]!, double.infinity, 28)),
              const SizedBox(width: 4),
              Expanded(child: _fakeBox(Colors.grey[50]!, double.infinity, 28)),
            ],
          ),
          const SizedBox(height: 6),
          _fakeBox(Colors.grey[50]!, double.infinity, 22),
          const SizedBox(height: 5),
          ...List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Container(height: 3, color: Colors.grey[100]),
          )),
        ],
      ),
    );
  }
}

// ── Modern ────────────────────────────────────────────────────────────────────

class _ModernPreview extends StatelessWidget {
  final Color accent;
  final Color headerBg;
  const _ModernPreview({required this.accent, required this.headerBg});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 40,
          color: headerBg,
          padding: const EdgeInsets.all(7),
          child: Row(
            children: [
              Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 30, height: 3, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(height: 2),
                    Container(width: 22, height: 2, color: Colors.white.withOpacity(0.5)),
                  ],
                ),
              ),
              Text('FACTURE',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 6,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _fakeBox(Colors.grey[50]!, double.infinity, 22)),
                    const SizedBox(width: 4),
                    Expanded(child: _fakeBox(Colors.grey[50]!, double.infinity, 22)),
                  ],
                ),
                const SizedBox(height: 6),
                _fakeBox(Colors.grey[50]!, double.infinity, 18),
                const SizedBox(height: 4),
                ...List.generate(3, (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Container(height: 3, color: Colors.grey[100]),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Minimal ───────────────────────────────────────────────────────────────────

class _MinimalPreview extends StatelessWidget {
  final Color accent;
  const _MinimalPreview({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 36, height: 4, color: Colors.grey[300]),
                    const SizedBox(height: 2),
                    Container(width: 24, height: 3, color: Colors.grey[200]),
                  ],
                ),
              ),
              Text('FACTURE',
                  style: TextStyle(
                      color: accent,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 5),
          Container(height: 1.5, color: accent),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(children: [
                  Container(width: double.infinity, height: 3, color: Colors.grey[200]),
                  const SizedBox(height: 2),
                  Container(width: double.infinity, height: 3, color: Colors.grey[150]),
                ]),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(children: [
                  Container(width: double.infinity, height: 3, color: Colors.grey[200]),
                  const SizedBox(height: 2),
                  Container(width: double.infinity, height: 3, color: Colors.grey[150]),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 0.5, color: Colors.grey[200]),
          const SizedBox(height: 5),
          _fakeBox(Colors.grey[50]!, double.infinity, 18),
          const SizedBox(height: 4),
          ...List.generate(2, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Container(height: 3, color: Colors.grey[100]),
          )),
        ],
      ),
    );
  }
}

// ── Bold ──────────────────────────────────────────────────────────────────────

class _BoldPreview extends StatelessWidget {
  final Color accent;
  final Color headerBg;
  const _BoldPreview({required this.accent, required this.headerBg});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 36,
          color: headerBg,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Expanded(
                child: Text('FACTURE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2)),
              ),
            ],
          ),
        ),
        Container(height: 2, color: accent.withOpacity(0.5)),
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _fakeBox(accent.withOpacity(0.08), double.infinity, 24)),
                    const SizedBox(width: 4),
                    Expanded(child: _fakeBox(Colors.grey[50]!, double.infinity, 24)),
                  ],
                ),
                const SizedBox(height: 6),
                _fakeBox(Colors.grey[50]!, double.infinity, 18),
                const SizedBox(height: 4),
                ...List.generate(2, (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Container(height: 3, color: Colors.grey[100]),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _fakeBox(Color color, double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    );
