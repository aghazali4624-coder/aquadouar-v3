// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/db_service.dart';
import '../widgets/common_widgets.dart';
import 'readings/readings_screen.dart';
import 'payments/payments_screen.dart';
import 'beneficiaries/beneficiaries_screen.dart';
import 'anomalies/anomalies_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'profile/profile_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _anomalyCount = 0;

  @override
  void initState() { super.initState(); _loadAnomalyCount(); }

  Future<void> _loadAnomalyCount() async {
    try {
      final count = await DbService.getActiveAnomalyCount();
      if (mounted) setState(() => _anomalyCount = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: [
        _MainMenu(anomalyCount: _anomalyCount),
        const ProfileScreen(),
        const SettingsScreen(),
      ]),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _MainMenu extends StatelessWidget {
  final int anomalyCount;
  const _MainMenu({required this.anomalyCount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.water_drop, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('AquaDouar', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('Bonjour 👋  ${FirebaseAuth.instance.currentUser?.email?.split('@').first ?? ''}',
                        style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  ]),
                ]),
                IconButton(
                  onPressed: () => _confirmLogout(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.logout, color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // RELEVÉS full width
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadingsScreen())),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppColors.blueGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 8))],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.speed_outlined, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('RELEVÉS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                      SizedBox(height: 4),
                      Text('Saisir les index des compteurs', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ])),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              // Grid 2x2
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.0,
                children: [
                  NavCard(label: 'Paiement\n& Retard', icon: Icons.payments_outlined, gradient: AppColors.greenGradient,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsScreen()))),
                  NavCard(label: 'Bénéficiaires', icon: Icons.people_outline, gradient: AppColors.purpleGradient,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BeneficiariesScreen()))),
                  NavCard(label: 'Anomalies', icon: Icons.warning_amber_outlined, gradient: AppColors.redGradient,
                      badge: anomalyCount,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnomaliesScreen()))),
                  NavCard(label: 'Dashboard', icon: Icons.bar_chart_outlined, gradient: AppColors.orangeGradient,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardScreen()))),
                ],
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Déconnexion'),
      content: const Text('Voulez-vous vous déconnecter ?'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async { Navigator.pop(ctx); await FirebaseAuth.instance.signOut(); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Déconnexion'),
        ),
      ],
    ));
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))]),
      child: BottomNavigationBar(
        currentIndex: currentIndex, onTap: onTap,
        backgroundColor: Colors.transparent, elevation: 0,
        selectedItemColor: AppColors.primaryBlue, unselectedItemColor: AppColors.textGrey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Paramètres'),
        ],
      ),
    );
  }
}
