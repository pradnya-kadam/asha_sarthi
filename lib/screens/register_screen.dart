import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final villageController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String selectedRole = 'ASHA Worker';
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    villageController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final result = await ApiService.registerUser(
      name: nameController.text.trim(),
      role: selectedRole,
      email: emailController.text.trim(),
      password: passwordController.text,
      mobile: mobileController.text.trim(),
      village: villageController.text.trim(),
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'registered_email', emailController.text.trim().toLowerCase());
      await prefs.setString('registered_role', selectedRole);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Registration failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.health_and_safety, size: 72),
                const SizedBox(height: 12),
                const Text('AshaSarthi',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Create your account'),
                const SizedBox(height: 28),

                TextFormField(
                  controller: nameController,
                  decoration: decoration('Full Name', Icons.person),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter your name'
                      : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: decoration('Select Role', Icons.badge),
                  items: const [
                    DropdownMenuItem(
                        value: 'ASHA Worker', child: Text('ASHA Worker')),
                    DropdownMenuItem(
                        value: 'ASHA Supervisor',
                        child: Text('ASHA Supervisor')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => selectedRole = v);
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: decoration('Email Address', Icons.email),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Please enter your email';
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: mobileController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: decoration('Mobile Number', Icons.phone),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.length != 10) {
                      return 'Enter 10 digit mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 4),

                TextFormField(
                  controller: villageController,
                  decoration: decoration('Village', Icons.location_on),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter your village'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: decoration('Password', Icons.lock).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(
                          () => obscurePassword = !obscurePassword),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration:
                      decoration('Confirm Password', Icons.lock_outline),
                  validator: (v) => v != passwordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : registerAccount,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Account',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),

                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          ),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
