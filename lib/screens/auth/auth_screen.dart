import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    setState(() => _errorMsg = null);
    final isLogin = _tabController.index == 0;

    if (!isLogin && _passwordCtrl.text != _confirmPasswordCtrl.text) {
      setState(() => _errorMsg = 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final firebase = ref.read(firebaseServiceProvider);
      if (isLogin) {
        await firebase.signInWithEmail(_emailCtrl.text, _passwordCtrl.text);
      } else {
        await firebase.registerWithEmail(
            _emailCtrl.text, _passwordCtrl.text, _nameCtrl.text);
      }
    } catch (e) {
      setState(() => _errorMsg = _parseAuthError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final firebase = ref.read(firebaseServiceProvider);
      await firebase.signInWithGoogle();
    } catch (e) {
      setState(() => _errorMsg = 'Google sign-in failed. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Enter your email first');
      return;
    }
    try {
      await ref
          .read(firebaseServiceProvider)
          .sendPasswordReset(_emailCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      setState(() => _errorMsg = 'Failed to send reset email');
    }
  }

  String _parseAuthError(String error) {
    if (error.contains('user-not-found')) return 'No account with this email.';
    if (error.contains('wrong-password')) return 'Incorrect password.';
    if (error.contains('email-already-in-use')) return 'Email already in use.';
    if (error.contains('weak-password')) {
      return 'Password must be 6+ characters.';
    }
    if (error.contains('invalid-email')) return 'Invalid email address.';
    return 'Authentication failed. Try again.';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Left Panel (desktop only) ──────────────────────────────────────
          if (isWide)
            Expanded(
              child: Container(
                color: AppColors.surface,
                child: Stack(
                  children: [
                    // Cinematic pattern
                    Positioned.fill(
                      child: CustomPaint(painter: _CinematicPainter()),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CineMatchLogo(fontSize: 40, showIcon: true),
                            const SizedBox(height: 24),
                            Text(
                              'Discover your next\nfavorite story.',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                      height: 1.3,
                                      color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 40),
                            ...[
                              'AI-powered recommendations',
                              'Movies & TV series',
                              'Personalized for you',
                            ].asMap().entries.map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Text(e.value,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge),
                                      ],
                                    )
                                        .animate(
                                            delay: Duration(
                                                milliseconds:
                                                    300 + e.key * 100))
                                        .fadeIn()
                                        .slideX(begin: -0.1),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Auth Panel ─────────────────────────────────────────────────────
          SizedBox(
            width: isWide ? 480 : size.width,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isWide) ...[
                        const CineMatchLogo(fontSize: 28),
                        const SizedBox(height: 40),
                      ],
                      Text(
                        'Welcome',
                        style: Theme.of(context).textTheme.displaySmall,
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to get personalized recommendations',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 32),

                      // Tab bar
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.textSecondary,
                          labelStyle: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          tabs: const [
                            Tab(text: 'Sign In'),
                            Tab(text: 'Register'),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 28),

                      // Form
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) {
                          final isRegister = _tabController.index == 1;
                          return Column(
                            children: [
                              if (isRegister) ...[
                                CMTextField(
                                  controller: _nameCtrl,
                                  hint: 'Display name',
                                  prefix: const Icon(
                                      Icons.person_outline_rounded,
                                      color: AppColors.textMuted,
                                      size: 20),
                                ),
                                const SizedBox(height: 12),
                              ],
                              CMTextField(
                                controller: _emailCtrl,
                                hint: 'Email address',
                                prefix: const Icon(Icons.email_outlined,
                                    color: AppColors.textMuted, size: 20),
                              ),
                              const SizedBox(height: 12),
                              CMTextField(
                                controller: _passwordCtrl,
                                hint: 'Password',
                                prefix: const Icon(Icons.lock_outline_rounded,
                                    color: AppColors.textMuted, size: 20),
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePass
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePass = !_obscurePass),
                                ),
                              ),
                              if (isRegister) ...[
                                const SizedBox(height: 12),
                                CMTextField(
                                  controller: _confirmPasswordCtrl,
                                  hint: 'Confirm password',
                                  prefix: const Icon(Icons.lock_outline_rounded,
                                      color: AppColors.textMuted, size: 20),
                                ),
                              ],
                            ],
                          );
                        },
                      ),

                      if (!_tabController.index.isNaN)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _handleForgotPassword,
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                  color: AppColors.primary, fontSize: 13),
                            ),
                          ),
                        ),

                      if (_errorMsg != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.primary, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMsg!,
                                  style: const TextStyle(
                                      color: AppColors.accent, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ).animate().shake(),
                      ],

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleEmailAuth,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : AnimatedBuilder(
                                  animation: _tabController,
                                  builder: (_, __) => Text(
                                    _tabController.index == 0
                                        ? 'Sign In'
                                        : 'Create Account',
                                  ),
                                ),
                        ),
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                              child: Divider(color: AppColors.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('or',
                                style: Theme.of(context).textTheme.bodySmall),
                          ),
                          const Expanded(
                              child: Divider(color: AppColors.border)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Google Sign In
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(
                                color: AppColors.border, width: 0.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const _GoogleIcon(),
                          label: const Text('Continue with Google',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ).animate().fadeIn(delay: 350.ms),
                    ],
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

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.57, 3.14,
        true, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 1.57, 1.57,
        true, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 3.14, 0.785,
        true, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 3.93, 0.785,
        true, paint);

    paint.color = AppColors.background;
    canvas.drawCircle(center, radius * 0.6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CinematicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withOpacity(0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
