import 'package:blogify/features/auth/presentation/state/auth_state.dart';
import 'package:blogify/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  bool showPassword = false;
  bool showConfirmPassword = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- KEEPING YOUR LOGIC UNTOUCHED ---
    final authState = ref.watch(authViewModelProvider);

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.registered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
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
    // ------------------------------------

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C2C2C), Color.fromARGB(255, 2, 126, 168)])
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section
                      Column(
                        children: [
                          Image.asset(
                            "assets/icons/app_icon.png",
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Create Account",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Join the Blogify community today",
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Name Field
                      _buildTextField(
                        label: "Full Name",
                        hint: "John Doe",
                        controller: _nameController,
                        icon: Icons.person_outline_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your name';
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Email Field
                      _buildTextField(
                        label: "Email Address",
                        hint: "name@example.com",
                        controller: _emailController,
                        icon: Icons.alternate_email_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your email';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Password Field
                      _buildTextField(
                        label: "Password",
                        hint: "••••••••",
                        controller: _passwordController,
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscure: !showPassword,
                        onToggle: () => setState(() => showPassword = !showPassword),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter a password';
                          if (value.length < 6) return 'At least 6 characters required';
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Confirm Password Field
                      _buildTextField(
                        label: "Confirm Password",
                        hint: "••••••••",
                        controller: _confirmPasswordController,
                        icon: Icons.verified_user_outlined,
                        isPassword: true,
                        obscure: !showConfirmPassword,
                        onToggle: () => setState(() => showConfirmPassword = !showConfirmPassword),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please confirm your password';
                          if (value != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),

                      const SizedBox(height: 40),

                      // Register Button
                      _buildRegisterButton(authState),

                      const SizedBox(height: 25),

                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? ", style: TextStyle(color: Colors.white54)),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            ),
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                color: Color.fromARGB(255, 215, 215, 215),
                                fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(icon, color: Colors.white38, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white38,
                      size: 20,
                    ),
                    onPressed: onToggle,
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(AuthState state) {
    bool isLoading = state.status == AuthStatus.loading;

    return Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: !isLoading
            ? const LinearGradient(colors: [Color(0xFF4285F4), Color(0xFF34A853)])
            : null,
        color: isLoading ? Colors.white10 : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: isLoading
            ? null
            : () async {
                if (_formKey.currentState!.validate()) {
                  await ref.read(authViewModelProvider.notifier).register(
                        fullName: _nameController.text.trim(),
                        email: _emailController.text.trim(),
                        phoneNumber: '', // Keeping your logic for phone empty
                        password: _passwordController.text,
                      );
                }
              },
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Text(
                "Create Account",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    );
  }
}