import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../database/hive_service.dart'; 
import 'register_page.dart';
import 'dashboard_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key}); 

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();
      
      debugPrint('🔐 Attempting login: $email');
      
      final user = await HiveService.getUserByEmail(email);
      
      if (!mounted) return;
      
      if (user != null && user.password == password) {
        debugPrint('✅ User authenticated: ${user.name}');
        
        // CRITICAL: Save session
        await HiveService.saveCurrentUserEmail(email);
        
        // VERIFY: Check if session is saved
        final savedEmail = HiveService.getCurrentUserEmail();
        debugPrint('🔍 Verification - Saved email: $savedEmail');
        
        if (savedEmail != email) {
          debugPrint('⚠️ WARNING: Session save verification FAILED!');
          debugPrint('   Expected: $email');
          debugPrint('   Got: $savedEmail');
        } else {
          debugPrint('✅ Session save verified successfully');
        }
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selamat datang, ${user.name}!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Navigate to dashboard
        debugPrint('🚀 Navigating to Dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardPage(user: user)),
        );
      } else {
        debugPrint('❌ Authentication failed');
        setState(() => _errorMessage = "Email atau password salah");
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      if (!mounted) return;
      setState(() => _errorMessage = "Terjadi kesalahan: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF581C87), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 20,
                shadowColor: const Color(0xFF9333EA).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _HeaderIcon(),
                        const SizedBox(height: 20),
                        const Text(
                          "Selamat Datang!",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        
                        if (_errorMessage != null) ...[
                          _buildErrorBox(),
                          const SizedBox(height: 16),
                        ],
                        
                        TextFormField(
                          controller: _emailController,
                          enabled: !_isLoading,
                          decoration: _inputStyle("Email", Icons.email),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || v.isEmpty) ? "Email harus diisi" : null,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isLoading,
                          obscureText: !_showPassword,
                          decoration: _inputStyle("Password", Icons.lock).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? "Password harus diisi" : null,
                        ),
                        
                        const _ForgotPasswordLink(),
                        const SizedBox(height: 16),
                        _buildLoginButton(),
                        const SizedBox(height: 16),
                        const _RegisterLink(),
                        
                        if (kDebugMode) const _DebugInfo(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9333EA),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// --- SUB-WIDGETS ---

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF9333EA), Color(0xFF3B82F6)]),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
    );
  }
}

class _ForgotPasswordLink extends StatelessWidget {
  const _ForgotPasswordLink();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
        child: const Text("Lupa Password?", style: TextStyle(color: Color(0xFF9333EA))),
      ),
    );
  }
}

class _RegisterLink extends StatelessWidget {
  const _RegisterLink();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Belum punya akun? "),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
          child: const Text("Daftar", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9333EA))),
        ),
      ],
    );
  }
}

class _DebugInfo extends StatelessWidget {
  const _DebugInfo();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 20),
      child: Text(
        'Akun Test:\nuserS@gmail.com / 123456',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: Colors.blue, fontFamily: 'monospace'),
      ),
    );
  }
}