import 'package:blogify/features/auth/presentation/state/auth_state.dart';
import 'package:blogify/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:blogify/features/dashboard/presentation/pages/button_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool showRegistrationSuccessPopup;

  const LoginScreen({super.key, this.showRegistrationSuccessPopup = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool showPassword = false;
  bool _showBiometricLogin = false;
  bool _showBiometricSetupHint = false;
  bool _isBiometricLoading = false;

  String? _pendingEmail;
  String? _pendingPassword;

  final LocalAuthentication _localAuth = LocalAuthentication();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadBiometricLoginAvailability);

    if (widget.showRegistrationSuccessPopup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        BuildContext? successDialogContext;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            successDialogContext = dialogContext;
            return const AlertDialog(
              title: Text('Success'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 48),
                  SizedBox(height: 12),
                  Text('Registration successful! Please login.'),
                ],
              ),
            );
          },
        ).then((_) {
          successDialogContext = null;
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          final dialogContext = successDialogContext;
          if (dialogContext != null &&
              dialogContext.mounted &&
              Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext).pop();
          }
        });
      });
    }
  }

  Future<void> _loadBiometricLoginAvailability() async {
    final session = ref.read(userSessionServiceProvider);

    if (!session.isBiometricEnabled()) {
      if (!mounted) return;
      setState(() {
        _showBiometricLogin = false;
        _showBiometricSetupHint = false;
      });
      return;
    }

    final credentials = await session.getBiometricCredentials();
    final hasQuickLoginData = await session.hasBiometricQuickLoginData();
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();

    if (!mounted) return;
    setState(() {
      _showBiometricLogin =
          (credentials != null || hasQuickLoginData) && canCheck && isSupported;
      _showBiometricSetupHint =
          credentials == null && !hasQuickLoginData && canCheck && isSupported;
    });
  }

  Future<void> _loginWithBiometric() async {
    if (_isBiometricLoading) return;

    final session = ref.read(userSessionServiceProvider);
    final credentials = await session.getBiometricCredentials();
    final hasQuickLoginData = await session.hasBiometricQuickLoginData();

    if (credentials == null && !hasQuickLoginData) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No biometric login data found.')),
      );
      return;
    }

    setState(() {
      _isBiometricLoading = true;
    });

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to login with fingerprint',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!authenticated) return;

      if (credentials == null && hasQuickLoginData) {
        await session.restoreSessionFromBiometric();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BottomNavScreen()),
        );
        return;
      }

      if (credentials == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No biometric login data found.')),
        );
        return;
      }

      _emailController.text = credentials.email;
      _passwordController.text = credentials.password;
      _pendingEmail = credentials.email;
      _pendingPassword = credentials.password;

      await ref
          .read(authViewModelProvider.notifier)
          .login(email: credentials.email, password: credentials.password);
    } on PlatformException catch (error) {
      if (!mounted) return;

      String message;
      switch (error.code) {
        case 'NotAvailable':
        case 'PasscodeNotSet':
          message = 'Biometric is not available on this device.';
          break;
        case 'NotEnrolled':
          message =
              'No biometric enrolled. Add fingerprint/face in device settings.';
          break;
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          message = 'Biometric is locked. Unlock device and try again.';
          break;
        default:
          message = 'Biometric authentication failed. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication failed.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBiometricLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    // --- KEEPING YOUR LOGIC ---
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        if (previous?.status == AuthStatus.authenticated) return;

        final session = ref.read(userSessionServiceProvider);
        final pendingEmail = _pendingEmail;
        final pendingPassword = _pendingPassword;

        if (session.isBiometricEnabled() &&
            pendingEmail != null &&
            pendingEmail.isNotEmpty &&
            pendingPassword != null &&
            pendingPassword.isNotEmpty) {
          session.saveBiometricCredentials(
            email: pendingEmail,
            password: pendingPassword,
          );
        }

        if (!mounted) return;
        final navigator = Navigator.of(context);
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => const BottomNavScreen(showLoginSuccessPopup: true),
          ),
        );
      } else if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
    // -------------------------

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2ED),
      body: Stack(
        children: [
          // Yellow header background
          Container(
            height: MediaQuery.of(context).size.height * 0.42,
            width: double.infinity,
            color: const Color(0xFFF5B63A),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 18),

                    // Header
                    const Text(
                      "Hello",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // White card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 4),
                              const Center(
                                child: Text(
                                  "Login Account",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Sign in to continue",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 18),

                              _label("Email Address"),
                              _field(
                                controller: _emailController,
                                hint: "yourname@mail.com",
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return "Email is required";
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(v.trim())) {
                                    return "Enter a valid email";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 14),

                              _label("Password"),
                              _field(
                                controller: _passwordController,
                                hint: "••••••••",
                                icon: Icons.lock_outline,
                                isPassword: true,
                                obscure: !showPassword,
                                onToggle: () => setState(
                                  () => showPassword = !showPassword,
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return "Password is required";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 10),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // TODO: implement forgot password screen
                                  },
                                  child: const Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              _loginButton(authState),

                              if (_showBiometricLogin) ...[
                                const SizedBox(height: 10),
                                TextButton.icon(
                                  onPressed: _isBiometricLoading
                                      ? null
                                      : _loginWithBiometric,
                                  icon: _isBiometricLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.fingerprint),
                                  label: const Text(
                                    'Tap to login with fingerprint',
                                  ),
                                ),
                              ],

                              if (_showBiometricSetupHint) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F7F7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.fingerprint, size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Biometric is enabled. Login once with email/password to setup fingerprint login.',
                                          style: TextStyle(fontSize: 12.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 14),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "New to Blogify? ",
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const SignupScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Create Account",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- UI HELPERS ----------

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: Colors.black87, fontSize: 14.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        prefixIcon: Icon(icon, color: Colors.black45, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.black45,
                  size: 20,
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF5B63A), width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
        ),
      ),
    );
  }

  Widget _loginButton(AuthState state) {
    final isLoading = state.status == AuthStatus.loading;

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF5B63A),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: isLoading
            ? null
            : () async {
                if (_formKey.currentState!.validate()) {
                  _pendingEmail = _emailController.text.trim();
                  _pendingPassword = _passwordController.text;

                  await ref
                      .read(authViewModelProvider.notifier)
                      .login(
                        email: _emailController.text.trim(),
                        password: _passwordController.text,
                      );
                }
              },
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : const Text(
                "Login Account",
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}
