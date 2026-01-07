import 'package:flutter/material.dart';
import '../models.dart';
import '../storage_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Password tidak cocok");
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final email = _emailController.text.trim().toLowerCase();
      
      // Cek email sudah terdaftar di SQLite
      final existingUser = await StorageService.getUserByEmail(email);
      
      if (existingUser != null) {
        if (!mounted) return;
        setState(() => _errorMessage = "Email sudah terdaftar");
        return;
      }
      
      // Buat user baru
      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch,
        name: _nameController.text.trim(),
        email: email,
        password: _passwordController.text,
      );
      
      // Simpan ke SQLite
      final success = await StorageService.saveUser(newUser);
      
      if (!success) {
        if (!mounted) return;
        setState(() => _errorMessage = "Gagal menyimpan data. Silakan coba lagi.");
        return;
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Registrasi berhasil! Silakan login.'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Kembali ke login page
      Navigator.pop(context);
    } catch (e) {
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
                shadowColor: const Color(0x809333EA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF9333EA), Color(0xFF3B82F6)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_add, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Buat Akun Baru",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Daftar untuk menggunakan Event Manager Pro",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        
                        // Error Message
                        if (_errorMessage != null) ...[
                          Container(
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
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: "Nama Lengkap",
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true) return "Nama harus diisi";
                            if (v!.trim().length < 3) return "Nama minimal 3 karakter";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true) return "Email harus diisi";
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(v!)) return "Email tidak valid";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          obscureText: !_showPassword,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true) return "Password harus diisi";
                            if (v!.length < 6) return "Password minimal 6 karakter";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Confirm Password Field
                        TextFormField(
                          controller: _confirmPasswordController,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: "Konfirmasi Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          obscureText: !_showConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true) return "Konfirmasi password harus diisi";
                            if (v != _passwordController.text) return "Password tidak cocok";
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9333EA),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                              disabledBackgroundColor: Colors.grey[300],
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_add, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        "Daftar",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Sudah punya akun?",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            TextButton(
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9333EA),
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
          ),
        ),
      ),
    );
  }
}