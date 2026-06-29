import 'dart:math' as math;

import 'package:contact_app/model/contact_entry.dart';
import 'package:contact_app/service/contact_service.dart';
import 'package:contact_app/service/excel_export_service.dart';
import 'package:contact_app/service/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design tokens ──────────────────────────────────────────────────────────
const _kBg      = Color(0xFF0A0A1A);
const _kCard    = Color(0xFF1A1A35);
const _kPrimary = Color(0xFF7C6FFF);
const _kTeal    = Color(0xFF4ECDC4);
const _kGreen   = Color(0xFF43E97B);
const _kError   = Color(0xFFFF6584);

const _primaryGrad = LinearGradient(
  colors: [Color(0xFF7C6FFF), Color(0xFF4ECDC4)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const _greenGrad = LinearGradient(
  colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ── HomeScreen ─────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _Status { idle, requestingPermission, fetching, exporting, done, error }

class _HomeScreenState extends State<HomeScreen> {
  _Status _status = _Status.idle;
  double _progress = 0.0;
  String? _errorMessage;
  List<ContactEntry> _contacts = [];
  String? _exportedFilePath;

  Future<void> _runImportAndExport() async {
    setState(() {
      _status = _Status.requestingPermission;
      _errorMessage = null;
      _progress = 0.0;
    });

    // 1. Permission
    final permResult = await PermissionService.requestContactsPermission();
    if (!mounted) return;

    switch (permResult) {
      case ContactPermissionResult.granted:
        break;
      case ContactPermissionResult.denied:
        _setError('Contacts permission denied. Please allow access to import.');
        return;
      case ContactPermissionResult.permanentlyDenied:
        _showPermanentlyDeniedDialog();
        setState(() => _status = _Status.idle);
        return;
      case ContactPermissionResult.restricted:
        _setError('Contacts access is restricted on this device.');
        return;
    }

    // 2. Fetch
    setState(() => _status = _Status.fetching);
    List<ContactEntry> contacts;
    try {
      contacts = await ContactService.fetchMobileContacts(
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
    } catch (e) {
      _setError('Failed to read contacts: $e');
      return;
    }

    if (!mounted) return;
    if (contacts.isEmpty) {
      _setError('No valid mobile numbers found in your contacts.');
      return;
    }

    // 3. Export
    setState(() {
      _status = _Status.exporting;
      _contacts = contacts;
    });

    try {
      final path = await ExcelExportService.exportToFile(contacts);
      if (!mounted) return;
      setState(() {
        _exportedFilePath = path;
        _status = _Status.done;
      });
    } catch (e) {
      _setError('Failed to export Excel file: $e');
    }
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _status = _Status.error;
      _errorMessage = msg;
    });
  }

  Future<void> _showPermanentlyDeniedDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Permission required',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Contacts access has been permanently denied. '
          'Please enable it from Settings to continue.',
          style: GoogleFonts.poppins(color: Colors.white60, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white38)),
          ),
          _GradientButton(
            onTap: () async {
              Navigator.of(ctx).pop();
              await PermissionService.openSettings();
            },
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text('Open Settings',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Future<void> _share() async {
    if (_exportedFilePath == null) return;
    try {
      await ExcelExportService.shareFile(
        _exportedFilePath!,
        subject: 'Contacts Export (${_contacts.length} contacts)',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share file: $e')),
      );
    }
  }

  void _reset() {
    setState(() {
      _status = _Status.idle;
      _progress = 0;
      _contacts = [];
      _exportedFilePath = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Animated ambient background orbs
          const _AmbientOrbs(),
          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
                  child: Row(
                    children: [
                      if (_status == _Status.done || _status == _Status.error)
                        IconButton(
                          onPressed: _reset,
                          tooltip: 'Back to home',
                          icon: ShaderMask(
                            shaderCallback: (b) => _primaryGrad.createShader(b),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: _GradientIcon(
                              icon: Icons.contacts_rounded, size: 26),
                        ),
                      const SizedBox(width: 6),
                      ShaderMask(
                        shaderCallback: (b) => _primaryGrad.createShader(b),
                        child: Text(
                          'ContactsXL',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Body (animated state switch) ──
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.06),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: anim, curve: Curves.easeOut)),
                        child: child,
                      ),
                    ),
                    child: _buildBody(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _Status.idle:
        return _IdleView(key: const ValueKey('idle'), onTap: _runImportAndExport);
      case _Status.requestingPermission:
        return _LoadingView(
          key: const ValueKey('perm'),
          step: 0,
          label: 'Requesting permission…',
        );
      case _Status.fetching:
        return _LoadingView(
          key: const ValueKey('fetch'),
          step: 1,
          label: 'Reading contacts…',
          progress: _progress > 0 ? _progress : null,
        );
      case _Status.exporting:
        return _LoadingView(
          key: const ValueKey('export'),
          step: 2,
          label: 'Building Excel file…',
        );
      case _Status.done:
        return _DoneView(
          key: const ValueKey('done'),
          count: _contacts.length,
          onShare: _share,
          onReset: _reset,
        );
      case _Status.error:
        return _ErrorView(
          key: const ValueKey('error'),
          message: _errorMessage ?? 'Something went wrong.',
          onRetry: _runImportAndExport,
          onReset: _reset,
        );
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Ambient background
// ══════════════════════════════════════════════════════════════════════════════

class _AmbientOrbs extends StatefulWidget {
  const _AmbientOrbs();
  @override
  State<_AmbientOrbs> createState() => _AmbientOrbsState();
}

class _AmbientOrbsState extends State<_AmbientOrbs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _OrbPainter(_ctrl.value),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double t;
  _OrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final dy = math.sin(t * math.pi) * 40.0;

    void drawOrb(Offset center, double radius, Color color, double opacity) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    drawOrb(Offset(size.width * 0.85, -size.height * 0.02 + dy),
        size.width * 0.55, const Color(0xFF7C6FFF), 0.40);
    drawOrb(Offset(-size.width * 0.1, size.height * 0.98 - dy),
        size.width * 0.60, const Color(0xFF4ECDC4), 0.28);
    drawOrb(Offset(size.width * 0.5, size.height * 0.45 + dy * 0.3),
        size.width * 0.35, const Color(0xFF7C6FFF), 0.08);
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared widgets
// ══════════════════════════════════════════════════════════════════════════════

class _GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  const _GradientIcon({required this.icon, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (b) => _primaryGrad.createShader(b),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}

class _GradientButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;
  final LinearGradient? gradient;

  const _GradientButton({
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
    this.gradient,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grad = widget.gradient ?? _primaryGrad;
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: grad,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: (grad.colors.first).withOpacity(0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _kCard.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: borderColor ?? _kPrimary.withOpacity(0.2), width: 1),
      ),
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Idle view
// ══════════════════════════════════════════════════════════════════════════════

class _IdleView extends StatefulWidget {
  final VoidCallback onTap;
  const _IdleView({super.key, required this.onTap});
  @override
  State<_IdleView> createState() => _IdleViewState();
}

class _IdleViewState extends State<_IdleView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          // Floating icon with glow
          AnimatedBuilder(
            animation: _float,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, -10 * _float.value + 5),
              child: child,
            ),
            child: Container(
              width: 136,
              height: 136,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _primaryGrad,
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.55),
                    blurRadius: 48,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.contacts_rounded,
                  size: 66, color: Colors.white),
            ),
          ),
          const SizedBox(height: 36),
          // Headline
          ShaderMask(
            shaderCallback: (b) => _primaryGrad.createShader(b),
            child: Text(
              'Export Contacts',
              style: GoogleFonts.poppins(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Instantly export mobile contacts\nto a clean, shareable Excel file.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.white54,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 28),
          // Feature chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: const [
              _FeatureChip(
                  icon: Icons.phone_android_rounded, label: 'Mobile only'),
              _FeatureChip(
                  icon: Icons.merge_type_rounded, label: 'Auto-dedupe'),
              _FeatureChip(icon: Icons.share_rounded, label: 'One-tap share'),
              _FeatureChip(icon: Icons.sort_by_alpha_rounded, label: 'Sorted A–Z'),
            ],
          ),
          const SizedBox(height: 44),
          // CTA
          _GradientButton(
            onTap: widget.onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Export Now',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Bottom info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 13, color: Colors.white30),
              const SizedBox(width: 5),
              Text(
                'Contacts stay on your device — never uploaded',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.white30),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _kPrimary.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _kTeal),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Loading view — 3-step pipeline indicator
// ══════════════════════════════════════════════════════════════════════════════

class _LoadingView extends StatefulWidget {
  final int step;
  final String label;
  final double? progress;
  const _LoadingView(
      {super.key, required this.step, required this.label, this.progress});
  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  static const _steps = [
    (icon: Icons.security_rounded, label: 'Permission'),
    (icon: Icons.contacts_rounded, label: 'Contacts'),
    (icon: Icons.table_chart_rounded, label: 'Excel'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Step pipeline row
          Row(
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                _StepCircle(
                  icon: _steps[i].icon,
                  isActive: i == widget.step,
                  isDone: i < widget.step,
                  pulseAnim: _pulse,
                ),
                if (i < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: i < widget.step ? _primaryGrad : null,
                        color: i < widget.step ? null : Colors.white12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Labels perfectly aligned under each circle
          Row(
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                SizedBox(
                  width: 60,
                  child: Text(
                    _steps[i].label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: i == widget.step
                          ? _kPrimary
                          : i < widget.step
                              ? _kTeal
                              : Colors.white30,
                      fontWeight: i == widget.step
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (i < _steps.length - 1) const Expanded(child: SizedBox()),
              ],
            ],
          ),
          const SizedBox(height: 56),
          // Progress indicator
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background track
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 6,
                  color: Colors.white10,
                ),
                // Progress
                CircularProgressIndicator(
                  value: widget.progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation(_kPrimary),
                  strokeCap: StrokeCap.round,
                ),
                if (widget.progress != null)
                  Text(
                    '${(widget.progress! * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(Icons.hourglass_top_rounded,
                      color: _kPrimary, size: 28),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            widget.label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please keep the app open',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white30),
          ),
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isDone;
  final Animation<double> pulseAnim;

  const _StepCircle({
    required this.icon,
    required this.isActive,
    required this.isDone,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, __) {
        final glowOpacity =
            isActive ? 0.25 + 0.25 * pulseAnim.value : 0.0;
        final glowRadius = isActive ? 18.0 + 12.0 * pulseAnim.value : 0.0;
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: (isActive || isDone) ? _primaryGrad : null,
            color: (isActive || isDone) ? null : Colors.white10,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _kPrimary.withOpacity(glowOpacity),
                      blurRadius: glowRadius,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Icon(
            isDone ? Icons.check_rounded : icon,
            color: (isActive || isDone) ? Colors.white : Colors.white30,
            size: 26,
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Done view
// ══════════════════════════════════════════════════════════════════════════════

class _DoneView extends StatefulWidget {
  final int count;
  final VoidCallback onShare;
  final VoidCallback onReset;
  const _DoneView(
      {super.key,
      required this.count,
      required this.onShare,
      required this.onReset});
  @override
  State<_DoneView> createState() => _DoneViewState();
}

class _DoneViewState extends State<_DoneView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Animated success icon
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _greenGrad,
                  boxShadow: [
                    BoxShadow(
                      color: _kGreen.withOpacity(0.45),
                      blurRadius: 50,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    size: 68, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'All Done! 🎉',
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your contacts have been exported successfully.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54),
            ),
            const SizedBox(height: 30),
            // Stats card
            _GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => _primaryGrad.createShader(b),
                    child: Text(
                      '${widget.count}',
                      style: GoogleFonts.poppins(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mobile',
                          style: GoogleFonts.poppins(
                              color: Colors.white60, fontSize: 14)),
                      Text('Contacts',
                          style: GoogleFonts.poppins(
                              color: Colors.white60, fontSize: 14)),
                      Text('Exported ✓',
                          style: GoogleFonts.poppins(
                              color: _kTeal,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Share button
            _GradientButton(
              onTap: widget.onShare,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.share_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Share / Save File',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: widget.onReset,
              child: Text(
                'Export Again',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Error view
// ══════════════════════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onReset;

  const _ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Error icon
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kError.withOpacity(0.12),
              border: Border.all(color: _kError.withOpacity(0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _kError.withOpacity(0.18),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.error_outline_rounded, size: 54, color: _kError),
          ),
          const SizedBox(height: 28),
          Text(
            'Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            borderColor: _kError.withOpacity(0.3),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: Colors.white60, height: 1.6),
            ),
          ),
          const SizedBox(height: 36),
          _GradientButton(
            onTap: onRetry,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Try Again',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onReset,
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }
}