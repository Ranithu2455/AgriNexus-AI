import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/l10n/app_localizations.dart';
import '../../shared/routes.dart';
import '../../shared/state/auth_provider.dart';
import '../../shared/state/locale_provider.dart';

class FarmerDashboardScreen extends StatelessWidget {
  const FarmerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final name = auth.currentUser?.farmerProfile?.fullName ?? '';

    final tiles = <_DashboardTile>[
      _DashboardTile(t.myProfile, Icons.person_outline, AppRoutes.profile, Colors.blueGrey),
      _DashboardTile(t.myFarms, Icons.landscape_outlined, AppRoutes.myFarms, Colors.brown),
      _DashboardTile(t.myCrops, Icons.grass_outlined, AppRoutes.myCrops, Colors.green),
      _DashboardTile(t.aiPlantDoctor, Icons.local_hospital_outlined, AppRoutes.aiPlantDoctor, Colors.redAccent),
      _DashboardTile(t.pestIdentification, Icons.bug_report_outlined, AppRoutes.pestIdentification, Colors.deepOrange),
      _DashboardTile(t.cropRecommendation, Icons.eco_outlined, AppRoutes.cropRecommendation, Colors.teal),
      _DashboardTile(t.weather, Icons.wb_cloudy_outlined, AppRoutes.weather, Colors.blue),
      _DashboardTile(t.farmerFeedback, Icons.report_problem_outlined, AppRoutes.farmerFeedback, Colors.orange),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(name.isNotEmpty ? '${t.dashboard} — $name' : t.dashboard),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: (locale) => context.read<LocaleProvider>().setLocale(locale),
            itemBuilder: (_) => kSupportedLocales
                .map((l) => PopupMenuItem(value: l, child: Text(kLanguageNames[l.languageCode]!)))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: t.logout,
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              }
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: tiles.map((tile) => _DashboardCard(tile: tile)).toList(),
      ),
    );
  }
}

class _DashboardTile {
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  _DashboardTile(this.label, this.icon, this.route, this.color);
}

class _DashboardCard extends StatelessWidget {
  final _DashboardTile tile;
  const _DashboardCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pushNamed(tile.route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tile.icon, size: 40, color: tile.color),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                tile.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
