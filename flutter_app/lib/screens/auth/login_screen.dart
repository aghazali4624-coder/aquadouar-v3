// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false, _showPass = false;
  String? _error;

  late AnimationController _anim;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _anim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() { _anim.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.signIn(_emailCtrl.text, _passCtrl.text);
    } catch (e) {
      setState(() { _error = _friendlyError(e.toString()); _loading = false; });
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found'))        return 'Aucun compte avec cet email';
    if (raw.contains('wrong-password'))        return 'Mot de passe incorrect';
    if (raw.contains('invalid-email'))         return 'Email invalide';
    if (raw.contains('too-many-requests'))     return 'Trop de tentatives. Réessayez plus tard';
    if (raw.contains('network-request-failed'))return 'Pas de connexion internet';
    return 'Erreur de connexion. Vérifiez vos identifiants';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.water_drop, color: Colors.white, size: 52),
                    ),
                    const SizedBox(height: 20),
                    const Text('AquaDouar',
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Connexion agent terrain',
                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
                    const SizedBox(height: 36),
                    Container(
                      decoration: BoxDecoration(color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 24, offset: const Offset(0, 12))]),
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Connexion', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                            validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: !_showPass,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                onPressed: () => setState(() => _showPass = !_showPass),
                              ),
                            ),
                            validator: (v) => v == null || v.length < 6 ? 'Minimum 6 caractères' : null,
                            onFieldSubmitted: (_) => _login(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!,
                                    style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                              ]),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                              child: _loading
                                  ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Se connecter',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: () async {
                                final email = _emailCtrl.text.trim();
                                if (email.isEmpty) { showError(context, 'Entrez votre email'); return; }
                                try {
                                  await AuthService.resetPassword(email);
                                  if (mounted) showSuccess(context, 'Email de réinitialisation envoyé');
                                } catch (e) {
                                  if (mounted) showError(context, e.toString());
                                }
                              },
                              child: const Text('Mot de passe oublié ?',
                                  style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('AquaDouar v3.0', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
