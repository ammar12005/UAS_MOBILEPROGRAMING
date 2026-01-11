import 'package:flutter/material.dart';
import '../database/hive_service.dart'; 
import '../models.dart';

class RegisterPage extends StatefulWidget {
  // PERBAIKAN BIRU: Gunakan super parameter
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
  final _phoneController = TextEditingController();
  
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
    _phoneController.dispose();
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
      final existingUser = await HiveService.getUserByEmail(email);
      
      if (existingUser != null) {
        if (!mounted) return;
        setState(() => _errorMessage = "Email sudah terdaftar");
        return;
      }
      
      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch,
        name: _nameController.text.trim(),
        email: email,
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        role: 'user',
        createdAt: DateTime.now(),
      );
      
      await HiveService.createUser(newUser);
      await HiveService.saveCurrentUserEmail(email);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Registrasi berhasil! Selamat datang.')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      
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
                        const _RegisterHeader(), 
                        const SizedBox(height: 24),
                        if (_errorMessage != null) _buildErrorBox(),
                        _buildTextFields(),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                        const SizedBox(height: 16),
                        const _LoginLink(),
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

  Widget _buildErrorBox() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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

  Widget _buildTextFields() {
    return Column(
      children: [
        _buildInput(controller: _nameController, label: "Nama Lengkap", icon: Icons.person),
        const SizedBox(height: 16),
        _buildInput(controller: _emailController, label: "Email", icon: Icons.email, type: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildInput(controller: _phoneController, label: "No. Telepon", icon: Icons.phone, type: TextInputType.phone),
        const SizedBox(height: 16),
        _buildInput(
          controller: _passwordController, 
          label: "Password", 
          icon: Icons.lock, 
          isPassword: true, 
          show: _showPassword,
          toggle: () => setState(() => _showPassword = !_showPassword)
        ),
        const SizedBox(height: 16),
        _buildInput(
          controller: _confirmPasswordController, 
          label: "Konfirmasi Password", 
          icon: Icons.lock_outline, 
          isPassword: true, 
          show: _showConfirmPassword,
          toggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword)
        ),
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool? show,
    VoidCallback? toggle,
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? !(show ?? false) : false,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword ? IconButton(icon: Icon((show ?? false) ? Icons.visibility_off : Icons.visibility), onPressed: toggle) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Bidang ini wajib diisi" : null,
    );
  }

  Widget _buildSubmitButton() {
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
            : const Text("Daftar Sekarang"),
      ),
    );
  }
}

// --- SUB-WIDGETS UNTUK OPTIMASI ---

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();
  @override
  Widget build(BuildContext context) {
    // PERBAIKAN MERAH: Hapus keyword 'const' dari Column karena memiliki Container dinamis
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF9333EA), Color(0xFF3B82F6)]),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_add, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        const Text("Buat Akun", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _LoginLink extends StatelessWidget {
  const _LoginLink();
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text("Sudah punya akun? Login di sini"),
    );
  }
}