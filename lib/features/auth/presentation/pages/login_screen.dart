import 'package:blogify/features/auth/presentation/state/auth_state.dart';
import 'package:blogify/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:blogify/features/dashboard/presentation/pages/button_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool showPassword = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- KEEPING YOUR LOGIC UNTOUCHED ---
    final authState = ref.watch(authViewModelProvider);

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BottomNavScreen()),
        );
      } else if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'An error occurred'), backgroundColor: Colors.red),
        );
      }
    });
    // ------------------------------------

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Deep dark background
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C2C2C), Color.fromARGB(255, 2, 126, 168)],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and Brand
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Image.asset("assets/icons/app_icon.png", width: 60, height: 60),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Blogify",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 50),
                      
                      const Text(
                        "Welcome Back",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Sign in to continue your journey",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      
                      const SizedBox(height: 40),

                      // Email Field
                      _buildTextField(
                        label: "Email Address",
                        hint: "yourname@mail.com",
                        controller: _emailController,
                        icon: Icons.alternate_email_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Email is required';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Enter a valid email';
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
                          if (value == null || value.isEmpty) return 'Password is required';
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text("Forgot Password?", style: TextStyle(color: Colors.white38)),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Login Button
                      _buildLoginButton(authState),

                      const SizedBox(height: 30),

                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("New to Blogify? ", style: TextStyle(color: Colors.white54)),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                            child: const Text(
                              "Create Account",
                              style: TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold),
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
                    icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white38, size: 20),
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

  Widget _buildLoginButton(AuthState state) {
    bool isLoading = state.status == AuthStatus.loading;

    return Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: !isLoading 
            ? const LinearGradient(colors: [Color(0xFF4285F4), Color(0xFF34A853)]) // Example brand gradient
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
                  await ref.read(authViewModelProvider.notifier).login(
                        email: _emailController.text.trim(),
                        password: _passwordController.text,
                      );
                }
              },
        child: isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}