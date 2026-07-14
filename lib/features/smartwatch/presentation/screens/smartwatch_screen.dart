import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../theme/app_theme.dart';
import '../providers/smartwatch_provider.dart';
import '../widgets/watch_face_preview.dart';
import 'watch_faces_screen.dart';
import 'watch_pairing_screen.dart';

/// Tab 5 — Smart Watch hub: connection status, current face preview, and entry
/// points to pairing and the faces gallery.
class SmartWatchScreen extends StatelessWidget {
  const SmartWatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackColor,
      body: SafeArea(
        child: Consumer<SmartWatchProvider>(
          builder: (context, provider, _) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.padding(context),
                vertical: ResponsiveUtils.sh(context, 20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ma Montre',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveUtils.sf(context, 26),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.sh(context, 4)),
                  Text(
                    'Appairez votre montre et personnalisez son cadran.',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: ResponsiveUtils.sf(context, 13),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.sh(context, 30)),
                  Center(
                    child: WatchFacePreview(
                      face: provider.selectedFace,
                      size: ResponsiveUtils.sw(context, 200),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.sh(context, 24)),
                  _buildStatusCard(context, provider),
                  SizedBox(height: ResponsiveUtils.sh(context, 16)),
                  _buildActionCard(
                    context,
                    icon: Icons.bluetooth,
                    title: provider.isConnected
                        ? 'Gérer l\'appairage'
                        : 'Appairer ma montre',
                    subtitle: provider.isConnected
                        ? 'Voir ou changer l\'appareil connecté'
                        : 'Rechercher les montres à proximité',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WatchPairingScreen()),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.sh(context, 12)),
                  _buildActionCard(
                    context,
                    icon: Icons.palette_outlined,
                    title: 'Choisir un cadran',
                    subtitle: 'Galerie de cadrans avec aperçu',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WatchFacesScreen()),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.sh(context, 100)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, SmartWatchProvider provider) {
    final connected = provider.connectedDevice;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: connected != null
              ? Colors.greenAccent.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(
            connected != null ? Icons.watch : Icons.watch_off_outlined,
            color: connected != null ? Colors.greenAccent : Colors.white54,
            size: ResponsiveUtils.sf(context, 28),
          ),
          SizedBox(width: ResponsiveUtils.sw(context, 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected != null ? connected.name : 'Aucune montre appairée',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.sf(context, 15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  connected != null ? 'Connectée' : 'Non connectée',
                  style: TextStyle(
                    color: connected != null
                        ? Colors.greenAccent
                        : Colors.grey[500],
                    fontSize: ResponsiveUtils.sf(context, 12),
                  ),
                ),
              ],
            ),
          ),
          if (connected != null)
            TextButton(
              onPressed: provider.disconnect,
              child: const Text('Déconnecter',
                  style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: ResponsiveUtils.sf(context, 26)),
            SizedBox(width: ResponsiveUtils.sw(context, 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveUtils.sf(context, 15),
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: ResponsiveUtils.sh(context, 2)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: ResponsiveUtils.sf(context, 12))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: ResponsiveUtils.sf(context, 14)),
          ],
        ),
      ),
    );
  }
}
