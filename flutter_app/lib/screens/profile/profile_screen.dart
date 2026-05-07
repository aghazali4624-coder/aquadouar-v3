// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(children: [
                Container(width: 80, height: 80,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 14),
                Text(user?.displayName ?? user?.email?.split('@').first ?? 'Agent',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                Text(user?.email ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Agent terrain', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            WhiteCard(child: Column(children: [
              _ProfileTile(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? '—'),
              const Divider(height: 1),
              _ProfileTile(icon: Icons.verified_user_outlined, label: 'Rôle', value: 'Agent terrain'),
              const Divider(height: 1),
              _ProfileTile(icon: Icons.access_time, label: 'Dernière connexion',
                  value: user?.metadata.lastSignInTime != null
                      ? formatDateTime(user!.metadata.lastSignInTime!)
                      : '—'),
            ])),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () => _changePassword(context),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Changer le mot de passe'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )),
          ]),
        ),
      ]),
    );
  }

  void _changePassword(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (context.mounted) showSuccess(context, 'Email de réinitialisation envoyé à $email');
    } catch (e) {
      if (context.mounted) showError(context, '$e');
    }
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon; final String label, value;
  const _ProfileTile({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(children: [
      Icon(icon, color: AppColors.primaryBlue, size: 20),
      const SizedBox(width: 14),
      Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
      const Spacer(),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );
}
