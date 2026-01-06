import 'package:flutter/material.dart';
import '../models.dart';
import '../storage_service.dart';

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

    // Validasi format email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailInput)) {
      setState(() => _errorMessage = 'Format email tidak valid');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final users = await StorageService.getUsers();
      await Future.delayed(const Duration(milliseconds: 600));
      
      final user = users.cast<User?>().firstWhere(
        (u) => u?.email.trim().toLowerCase() == emailInput,
        orElse: () => null,
      );

      if (mounted) {
        if (user != null) {
          setState(() {
            _foundUser = user;
            _emailVerified = true;
            _successMessage = 'Akun ditemukan: ${user.name}';
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Email tidak terdaftar dalam sistem';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan saat memuat data';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Password dan konfirmasi tidak cocok!');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() => _errorMessage = 'Password minimal 6 karakter');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await StorageService.getUsers();
      final index = users.indexWhere((u) => u.id == _foundUser!.id);
      
      if (index != -1) {
        users[index] = User(
          id: _foundUser!.id,
          name: _foundUser!.name,
          email: _foundUser!.email,
          password: _newPasswordController.text.trim(),
        );
        
        await StorageService.saveUsers(users);
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Password berhasil diperbarui! Silakan login.'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Tunggu sebentar sebelum kembali
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } else {
        if (mounted) {
          setState(() => _errorMessage = 'Data user tidak ditemukan');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Gagal mereset password: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF581C87), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9333EA).withOpacity(0.2),
                      const Color(0xFF3B82F6).withOpacity(0.2),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      elevation: 20,
                      shadowColor: const Color(0xFF9333EA).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 450),
                        padding: const EdgeInsets.all(32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF9333EA), Color(0xFF3B82F6)],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF9333EA).withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.lock_reset,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Title
                              Text(
                                _emailVerified ? 'Atur Password Baru' : 'Verifikasi Email',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _emailVerified
                                    ? 'Masukkan password baru untuk akun Anda'
                                    : 'Masukkan email terdaftar untuk mencari akun',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Error Message
                              if (_errorMessage != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Success Message
                              if (_successMessage != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _successMessage!,
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (_foundUser != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                _foundUser!.email,
                                                style: TextStyle(
                                                  color: Colors.green[700],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                enabled: !_emailVerified && !_isLoading,
                                decoration: InputDecoration(
                                  labelText: 'Email Akun',
                                  prefixIcon: const Icon(Icons.email),
                                  suffixIcon: _emailVerified
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: _emailVerified 
                                      ? Colors.grey[200] 
                                      : Colors.grey[50],
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v?.trim().isEmpty ?? true) return 'Email harus diisi';
                                  if (!v!.contains('@')) return 'Email tidak valid';
                                  return null;
                                },
                              ),

                              // Check Email Button
                              if (!_emailVerified) ...[
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _checkEmail,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF9333EA),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
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
                                              Icon(Icons.search),
                                              SizedBox(width: 12),
                                              Text(
                                                'Cari Akun',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],

                              // Password Fields (only show when email verified)
                              if (_emailVerified) ...[
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _newPasswordController,
                                  obscureText: _obscureNewPassword,
                                  enabled: !_isLoading,
                                  decoration: InputDecoration(
                                    labelText: 'Password Baru',
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureNewPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureNewPassword = !_obscureNewPassword,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  validator: (v) {
                                    if (v?.trim().isEmpty ?? true) {
                                      return 'Password harus diisi';
                                    }
                                    if (v!.length < 6) {
                                      return 'Password minimal 6 karakter';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  enabled: !_isLoading,
                                  decoration: InputDecoration(
                                    labelText: 'Konfirmasi Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureConfirmPassword = !_obscureConfirmPassword,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  validator: (v) {
                                    if (v?.trim().isEmpty ?? true) {
                                      return 'Konfirmasi password harus diisi';
                                    }
                                    if (v != _newPasswordController.text) {
                                      return 'Password tidak cocok';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _isLoading ? null : _resetForm,
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          side: BorderSide(
                                            color: _isLoading 
                                                ? Colors.grey 
                                                : const Color(0xFF9333EA),
                                          ),
                                        ),
                                        child: const Text('Batal'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _resetPassword,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
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
                                            : const Text(
                                                'Simpan',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              // Back to Login
                              const SizedBox(height: 24),
                              TextButton.icon(
                                onPressed: _isLoading 
                                    ? null 
                                    : () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Kembali ke Login'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF9333EA),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}