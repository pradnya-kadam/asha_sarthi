
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  String selectedRole = 'asha_worker';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.loginUser(
        email: emailController.text.trim(),
        password: passwordController.text,
        role: selectedRole,
      );

      if (!mounted) return;

      print('LOGIN RESULT: $result');

      if (result['success'] != true) {
        throw Exception(result['message']?.toString() ?? 'Login failed');
      }

      final prefs = await SharedPreferences.getInstance();
      final responseData = result['data'];
      final rawUser = responseData is Map && responseData['data'] is Map
          ? responseData['data']
          : responseData;
      final user = rawUser is Map
          ? Map<String, dynamic>.from(rawUser)
          : <String, dynamic>{};
      await prefs.setString('user_role', selectedRole);
      await prefs.setString('user_name', user['name']?.toString() ?? 'User');
      await prefs.setString('user_contact', user['email']?.toString() ?? user['mobile']?.toString() ?? emailController.text.trim());
      final userId = int.tryParse(user['id']?.toString() ?? '');
      if (userId != null) await prefs.setInt('user_id', userId);
      await prefs.setString('user_village', user['village']?.toString() ?? '');
      await prefs.setString('user_mobile', user['mobile']?.toString() ?? '');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful'),
          backgroundColor: Colors.green,
        ),
      );

      // --------------------------------------------------------
      // CHANGE THESE ROUTES IF YOUR PROJECT USES DIFFERENT NAMES
      // --------------------------------------------------------

      if (selectedRole == 'supervisor') {
        Navigator.pushReplacementNamed(
          context,
          '/supervisor-dashboard',
        );
      } else if (selectedRole == 'asha_worker') {
        Navigator.pushReplacementNamed(
          context,
          '/asha-dashboard',
        );
      } else if (selectedRole == 'beneficiary') {
        Navigator.pushReplacementNamed(
          context,
          '/beneficiary-dashboard',
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          '/home',
        );
      }
    } catch (e) {
      if (!mounted) return;

      print('LOGIN ERROR: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login failed: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      appBar: AppBar(
        title: const Text(
          'Login',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                // ==================================================
                // ICON
                // ==================================================

                const SizedBox(height: 25),

                Center(
                  child: Container(
                    width: 90,
                    height: 90,

                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(45),
                    ),

                    child: const Icon(
                      Icons.health_and_safety,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'ASHA Connect',
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Login to your account',
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 35),

                // ==================================================
                // ROLE
                // ==================================================

                const Text(
                  'Select Role',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: selectedRole,

                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.person_outline,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    filled: true,
                    fillColor: Colors.white,
                  ),

                  items: const [
                    DropdownMenuItem(
                      value: 'asha_worker',
                      child: Text('ASHA Worker'),
                    ),

                    DropdownMenuItem(
                      value: 'supervisor',
                      child: Text('Supervisor'),
                    ),

                    DropdownMenuItem(
                      value: 'beneficiary',
                      child: Text('Beneficiary'),
                    ),
                  ],

                  onChanged: isLoading
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              selectedRole = value;
                            });
                          }
                        },
                ),

                const SizedBox(height: 20),

                // ==================================================
                // EMAIL
                // ==================================================

                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter email address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!email.contains('@') || !email.contains('.')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ==================================================
                // PASSWORD
                // ==================================================

                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: passwordController,

                  obscureText: obscurePassword,

                  decoration: InputDecoration(
                    hintText: 'Enter password',

                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),

                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),

                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    filled: true,
                    fillColor: Colors.white,
                  ),

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }

                    if (value.length < 4) {
                      return 'Password is too short';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // ==================================================
                // LOGIN BUTTON
                // ==================================================

                SizedBox(
                  height: 52,

                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    child: isLoading
                        ? const SizedBox(
                            width: 25,
                            height: 25,

                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // REGISTER
                // ==================================================

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.pushNamed(
                                context,
                                '/register',
                              );
                            },

                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
