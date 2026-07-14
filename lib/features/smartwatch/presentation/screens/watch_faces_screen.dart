import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/watch_face.dart';
import '../providers/smartwatch_provider.dart';
import '../widgets/watch_face_preview.dart';

/// Watch-face selection gallery with a large live preview.
class WatchFacesScreen extends StatelessWidget {
  const WatchFacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackColor,
      appBar: AppBar(
        backgroundColor: AppTheme.blackColor,
        foregroundColor: Colors.white,
        title: const Text('Cadrans'),
      ),
      body: SafeArea(
        child: Consumer<SmartWatchProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                SizedBox(height: ResponsiveUtils.sh(context, 20)),
                WatchFacePreview(
                  face: provider.selectedFace,
                  size: ResponsiveUtils.sw(context, 200),
                ),
                SizedBox(height: ResponsiveUtils.sh(context, 12)),
                Text(
                  provider.selectedFace.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.sf(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  provider.isConnected
                      ? 'Appliqué sur ${provider.connectedDevice!.name}'
                      : 'Aperçu — appairez une montre pour l\'appliquer',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: ResponsiveUtils.sf(context, 12),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.sh(context, 20)),
                Expanded(child: _buildGallery(context, provider)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGallery(BuildContext context, SmartWatchProvider provider) {
    return GridView.builder(
      padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: WatchFace.catalog.length,
      itemBuilder: (context, index) {
        final face = WatchFace.catalog[index];
        final selected = face.id == provider.selectedFace.id;
        return GestureDetector(
          onTap: () {
            provider.selectFace(face);
            if (provider.isConnected) {
              AppSnackBar.success(
                  context, 'Cadran « ${face.name} » appliqué.');
            }
          },
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Colors.white : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: WatchFacePreview(
                  face: face,
                  size: ResponsiveUtils.sw(context, 72),
                  showTime: false,
                ),
              ),
              SizedBox(height: ResponsiveUtils.sh(context, 6)),
              Text(
                face.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey[500],
                  fontSize: ResponsiveUtils.sf(context, 11),
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
