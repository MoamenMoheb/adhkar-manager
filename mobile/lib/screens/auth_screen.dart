import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../core/constants/constants.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final SupabaseService _service = SupabaseService.instance;
  bool _isSignUp = false;
  String _gender = 'male';
  String _avatarId = 'm1';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        await _service.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _nameController.text.trim(),
          gender: _gender,
          avatarId: _gender == 'female' ? 'f1' : 'm1',
        );
      } else {
        await _service.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? 'إنشاء حساب جديد' : 'تسجيل الدخول', style: GoogleFonts.ibmPlexSansArabic())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
              const SizedBox(height: 16),
            ],
            if (_isSignUp) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'الاسم المعروض للأصدقاء', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 16),
              // Gender selection (Crucial for separated male/female dashboards!)
              Row(
                children: [
                  const Text('الجنس:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: const Text('🚹 رجل'),
                    selected: _gender == 'male',
                    selectedColor: AppConstants.primary,
                    labelStyle: TextStyle(color: _gender == 'male' ? Colors.white : null),
                    onSelected: (_) => setState(() => _gender = 'male'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('🚺 امرأة'),
                    selected: _gender == 'female',
                    selectedColor: AppConstants.secondary,
                    labelStyle: TextStyle(color: _gender == 'female' ? Colors.white : null),
                    onSelected: (_) => setState(() => _gender = 'female'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock)),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primary),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isSignUp ? 'إنشاء حساب والبدء في التنافس' : 'تسجيل الدخول', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(_isSignUp ? 'لديك حساب بالفعل؟ سجل دخولك' : 'ليس لديك حساب؟ أنشئ حساباً جديداً'),
            ),
          ],
        ),
      ),
    );
  }
}
