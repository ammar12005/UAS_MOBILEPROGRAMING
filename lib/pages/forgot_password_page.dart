import 'package:flutter/material.dart';
// 1. Perbaikan path import agar mengarah ke folder di atasnya
import '../models.dart'; 
import '../database/hive_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Fungsikan variabel yang sebelumnya ditandai kuning (unused)
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _emailVerified = false;
  bool _isLoading = false;
  User? _foundUser;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkEmail() async {
    final emailInput = _emailController.text.trim().toLowerCase();
    if (emailInput.isEmpty) {
      setState(() => _errorMessage = 'Email tidak boleh kosong');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = await HiveService.getUserByEmail(emailInput);
      
      if (mounted) {
        if (user != null) {
          setState(() {
            _foundUser = user;
            _emailVerified = true;
            _successMessage = 'Akun ditemukan: ${user.name}';
          });
        } else {
          setState(() => _errorMessage = 'Email tidak terdaftar');
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Gagal memverifikasi email');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Password tidak cocok!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_foundUser != null) {
        // Buat objek user baru dengan mempertahankan data lama kecuali password
        final updatedUser = User(
          id: _foundUser!.id,
          name: _foundUser!.name,
          email: _foundUser!.email,
          password: _newPasswordController.text.trim(),
          phone: _foundUser!.phone,
          role: _foundUser!.role,
          createdAt: _foundUser!.createdAt,
        );
        
        await HiveService.updateUser(updatedUser);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Gagal mereset password');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _emailVerified = false;
      _foundUser = null;
      _emailController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _errorMessage = null;
      _successMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_errorMessage != null) 
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              if (_successMessage != null) 
                Text(_successMessage!, style: const TextStyle(color: Colors.green)),
              
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                ),
                readOnly: _emailVerified,
              ),
              
              if (!_emailVerified) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkEmail,
                    child: const Text("Verifikasi Email"),
                  ),
                ),
              ],

              if (_emailVerified) ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: "Password Baru",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Konfirmasi Password",
                    prefixIcon: const Icon(Icons.lock_clock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: const Text("Simpan Password Baru"),
                  ),
                ),
                TextButton(onPressed: _resetForm, child: const Text("Cari Email Lain")),
              ]
            ],
          ),
        ),
      ),
    );
  }
}