import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/providers.dart';
import '../../core/responsive.dart';
import '../../services/customer_auth_api.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../widgets/brand_logo.dart';

/// Email OTP auth matching `new_frontend-dev/app/(customer)`:
///   Login  → email → OTP
///   Signup → email → name + phone + OTP
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final r = AppResponsive.of(context);
    final pad = r.isTablet ? 40.0 : 26.0;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final compact = keyboard > 0;
    final logoWidth = compact
        ? (r.isTablet ? 200.0 : 160.0)
        : (r.isTablet ? 280.0 : 220.0);

    return Container(
      color: const Color(0xFFFBF4E8),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(pad, compact ? 12 : 20, pad, 24 + keyboard),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        SizedBox(height: compact ? 8 : 28),
                        BrandLogo.customer(
                          width: logoWidth,
                          blendBackground: const Color(0xFFFBF4E8),
                        ),
                        if (app.authReturnTarget == 'cart') ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.dashedBookingBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.dashedBookingBorder),
                            ),
                            child: Text(
                              'Sign in or create an account to place your order.',
                              textAlign: TextAlign.center,
                              style: AppText.body(
                                size: 13,
                                weight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                        if (!compact) ...[
                          const SizedBox(height: 10),
                          Text(
                            'TAP · EAT · REPEAT',
                            style: AppText.body(
                              size: r.isTablet ? 14 : 12,
                              weight: FontWeight.w700,
                              color: AppColors.onboardingKicker,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                        SizedBox(height: compact ? 16 : 28),
                      ],
                    ),
                    if (!app.otpSent)
                      const _EmailStep()
                    else if (app.authMode == 'signup')
                      const _SignupDetailsStep()
                    else
                      const _LoginOtpStep(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Step 1 for both login & signup — email only (same as customer web).
class _EmailStep extends ConsumerStatefulWidget {
  const _EmailStep();

  @override
  ConsumerState<_EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends ConsumerState<_EmailStep> {
  late final TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: ref.read(appControllerProvider).authEmail ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  Future<void> _sendOtp() async {
    final app = ref.read(appControllerProvider);
    final email = _emailController.text.trim();
    final isSignup = app.authMode == 'signup';

    if (email.isEmpty || !_isValidEmail(email)) {
      app.setAuthError('Please enter a valid email');
      return;
    }

    setState(() => _isLoading = true);
    app.clearAuthError();
    app.setAuthEmail(email);

    try {
      await CustomerAuthApi.sendOtp(
        email: email,
        purpose: isSignup ? 'SIGNUP' : 'LOGIN',
      );
      app.markOtpSent();
    } on ApiException catch (e) {
      app.setAuthError(e.message);
    } catch (_) {
      app.setAuthError('Failed to send OTP. Check your email and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final isSignup = app.authMode == 'signup';

    return Column(
      children: [
        const _DividerRow(),
        const SizedBox(height: 14),
        Text(
          isSignup ? 'Create account' : 'Sign in',
          style: AppText.body(size: 16, weight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _LabeledField(
          label: 'Email address',
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
            autofillHints: const [AutofillHints.email],
            style: AppText.body(size: 15, weight: FontWeight.w600),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: 'you@example.com',
              hintStyle: AppText.body(
                  size: 15, weight: FontWeight.w500, color: AppColors.lightGreyText),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            isSignup
                ? 'An OTP will be sent to this email.'
                : 'OTP is sent to your registered mobile number.',
            style: AppText.body(
                size: 12, weight: FontWeight.w500, color: AppColors.lightGreyText),
          ),
        ),
        if (app.authError != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(message: app.authError!),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _ContinueButton(
            onTap: _sendOtp,
            isLoading: _isLoading,
            label: 'Send OTP',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isSignup ? 'Already have an account? ' : 'New customer? ',
              style: AppText.body(
                  size: 13, weight: FontWeight.w500, color: AppColors.lightGreyText),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading
                    ? null
                    : () => app.setAuthMode(isSignup ? 'login' : 'signup'),
                child: Text(
                  isSignup ? 'Sign in' : 'Sign up',
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : () => app.continueAsGuest(),
            child: Text(
              'Continue as guest',
              style: AppText.body(
                size: 13,
                weight: FontWeight.w600,
                color: AppColors.lightGreyText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Login step 2 — OTP only (customer login page).
class _LoginOtpStep extends ConsumerStatefulWidget {
  const _LoginOtpStep();

  @override
  ConsumerState<_LoginOtpStep> createState() => _LoginOtpStepState();
}

class _LoginOtpStepState extends ConsumerState<_LoginOtpStep> {
  late final TextEditingController _otpController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final app = ref.read(appControllerProvider);
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      app.setAuthError('Enter a valid OTP');
      return;
    }

    setState(() => _isLoading = true);
    app.clearAuthError();

    try {
      await CustomerAuthApi.login(email: app.authEmail!, otp: otp);
      await app.refreshAfterAuth();
      app.finishAuthNavigation();
    } on ApiException catch (e) {
      app.setAuthError(e.message);
    } catch (_) {
      app.setAuthError('Invalid OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    final app = ref.read(appControllerProvider);
    setState(() => _isLoading = true);
    app.clearAuthError();
    try {
      await CustomerAuthApi.sendOtp(email: app.authEmail!, purpose: 'LOGIN');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent')),
        );
      }
    } on ApiException catch (e) {
      app.setAuthError(e.message);
    } catch (_) {
      app.setAuthError('Failed to resend OTP');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);

    return Column(
      children: [
        const _DividerRow(),
        const SizedBox(height: 14),
        Text(
          'OTP sent to the mobile number linked to',
          textAlign: TextAlign.center,
          style: AppText.body(
              size: 13, weight: FontWeight.w500, color: AppColors.lightGreyText),
        ),
        const SizedBox(height: 4),
        Text(
          app.authEmail ?? '',
          style: AppText.body(size: 14, weight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _LabeledField(
          label: 'One-time password',
          child: TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            enabled: !_isLoading,
            maxLength: 6,
            style: AppText.body(size: 15, weight: FontWeight.w600),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              counterText: '',
              hintText: 'Enter OTP',
              hintStyle: AppText.body(
                  size: 15, weight: FontWeight.w500, color: AppColors.lightGreyText),
            ),
          ),
        ),
        if (app.authError != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(message: app.authError!),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _ContinueButton(
            onTap: _login,
            isLoading: _isLoading,
            label: 'Sign in',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive OTP? ",
              style: AppText.body(
                  size: 13, weight: FontWeight.w500, color: AppColors.lightGreyText),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _resend,
                child: Text(
                  'Resend',
                  style: AppText.body(
                      size: 13, weight: FontWeight.w700, color: AppColors.accent),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : () => app.backToCredentials(),
            child: Text(
              'Change email',
              style: AppText.body(
                  size: 13, weight: FontWeight.w600, color: AppColors.lightGreyText),
            ),
          ),
        ),
      ],
    );
  }
}

/// Signup step 2 — name + phone + OTP (customer signup page).
class _SignupDetailsStep extends ConsumerStatefulWidget {
  const _SignupDetailsStep();

  @override
  ConsumerState<_SignupDetailsStep> createState() => _SignupDetailsStepState();
}

class _SignupDetailsStepState extends ConsumerState<_SignupDetailsStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _otpController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final app = ref.read(appControllerProvider);
    _nameController = TextEditingController(text: app.authName ?? '');
    _phoneController = TextEditingController(
      text: (app.authPhone ?? '').replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^91'), ''),
    );
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '+91$digits';
    if (digits.startsWith('91') && digits.length == 12) return '+$digits';
    if (raw.trim().startsWith('+')) return raw.trim();
    return digits.isEmpty ? raw.trim() : '+$digits';
  }

  Future<void> _signup() async {
    final app = ref.read(appControllerProvider);
    final name = _nameController.text.trim();
    final phone = _normalizePhone(_phoneController.text.trim());
    final otp = _otpController.text.trim();

    if (name.isEmpty) {
      app.setAuthError('Please enter your name');
      return;
    }
    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      app.setAuthError('Please enter a valid mobile number');
      return;
    }
    if (otp.length < 4) {
      app.setAuthError('Enter the OTP from your email');
      return;
    }

    setState(() => _isLoading = true);
    app.clearAuthError();
    app.setAuthName(name);
    app.setAuthPhone(phone);

    try {
      await CustomerAuthApi.signup(
        email: app.authEmail!,
        phone: phone,
        otp: otp,
        name: name,
      );
      await app.refreshAfterAuth();
      app.finishAuthNavigation();
    } on ApiException catch (e) {
      app.setAuthError(e.message);
    } catch (_) {
      app.setAuthError('Signup failed. Check your OTP or try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);

    return Column(
      children: [
        const _DividerRow(),
        const SizedBox(height: 14),
        Text(
          'OTP sent to ${app.authEmail ?? 'your email'}',
          textAlign: TextAlign.center,
          style: AppText.body(
              size: 13, weight: FontWeight.w500, color: AppColors.lightGreyText),
        ),
        const SizedBox(height: 12),
        _LabeledField(
          label: 'Full name',
          child: TextField(
            controller: _nameController,
            enabled: !_isLoading,
            textCapitalization: TextCapitalization.words,
            style: AppText.body(size: 15, weight: FontWeight.w600),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: 'Your name',
              hintStyle: AppText.body(
                  size: 15, weight: FontWeight.w500, color: AppColors.lightGreyText),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE4DCE0), width: 1.5),
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mobile number',
                style: AppText.body(
                    size: 12, weight: FontWeight.w600, color: AppColors.lightGreyText),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('🇮🇳 +91',
                      style: AppText.body(size: 15, weight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  Container(width: 1, height: 20, color: const Color(0xFFE4DCE0)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_isLoading,
                      style: AppText.body(size: 15, weight: FontWeight.w600),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: '9876543210',
                        hintStyle: AppText.body(
                            size: 15,
                            weight: FontWeight.w500,
                            color: AppColors.lightGreyText),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'One-time password',
          child: TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            enabled: !_isLoading,
            maxLength: 6,
            style: AppText.body(size: 15, weight: FontWeight.w600),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              counterText: '',
              hintText: 'Enter OTP from email',
              hintStyle: AppText.body(
                  size: 15, weight: FontWeight.w500, color: AppColors.lightGreyText),
            ),
          ),
        ),
        if (app.authError != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(message: app.authError!),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _ContinueButton(
            onTap: _signup,
            isLoading: _isLoading,
            label: 'Create account',
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : () => app.backToCredentials(),
            child: Text(
              'Change email',
              style: AppText.body(
                  size: 13, weight: FontWeight.w600, color: AppColors.lightGreyText),
            ),
          ),
        ),
      ],
    );
  }
}

class _DividerRow extends StatelessWidget {
  const _DividerRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFFEFEAE6))),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: const Color(0xFFEFEAE6))),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE4DCE0), width: 1.5),
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.body(
                size: 12, weight: FontWeight.w600, color: AppColors.lightGreyText),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppText.body(
                  size: 13, weight: FontWeight.w500, color: const Color(0xFFC62828)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  final String label;

  const _ContinueButton({
    required this.onTap,
    this.isLoading = false,
    this.label = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            gradient: isLoading ? null : AppColors.accentGradient,
            color: isLoading ? const Color(0xFFE0E0E0) : null,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isLoading
                ? null
                : [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                )
              : Text(label,
                  style: AppText.body(
                      size: 16, weight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}
