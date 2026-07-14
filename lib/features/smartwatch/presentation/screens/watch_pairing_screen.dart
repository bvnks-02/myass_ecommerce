import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/watch_device.dart';
import '../providers/smartwatch_provider.dart';

/// Mock BLE pairing screen: simulated device discovery + connection.
/// All device I/O is stubbed in [SmartWatchProvider] (marked TODO(BLE)).
class WatchPairingScreen extends StatefulWidget {
  const WatchPairingScreen({super.key});

  @override
  State<WatchPairingScreen> createState() => _WatchPairingScreenState();
}

class _WatchPairingScreenState extends State<WatchPairingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SmartWatchProvider>();
      if (!provider.isConnected) provider.startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackColor,
      appBar: AppBar(
        backgroundColor: AppTheme.blackColor,
        foregroundColor: Colors.white,
        title: const Text('Appairer ma montre'),
      ),
      body: SafeArea(
        child: Consumer<SmartWatchProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                _buildBanner(context, provider),
                Expanded(child: _buildDeviceList(context, provider)),
                _buildScanButton(context, provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context, SmartWatchProvider provider) {
    final connected = provider.connectedDevice;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(ResponsiveUtils.padding(context)),
      padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(
            connected != null ? Icons.watch : Icons.bluetooth_searching,
            color: connected != null ? Colors.greenAccent : Colors.white,
            size: ResponsiveUtils.sf(context, 30),
          ),
          SizedBox(width: ResponsiveUtils.sw(context, 14)),
          Expanded(
            child: Text(
              connected != null
                  ? 'Connectée à ${connected.name}'
                  : provider.status == PairingStatus.scanning
                      ? 'Recherche de montres à proximité…'
                      : 'Activez le Bluetooth et approchez votre montre.',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.sf(context, 14),
              ),
            ),
          ),
          if (provider.status == PairingStatus.scanning)
            const SizedBox(
              width: 18,
              height: 18,
              child:
                  CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context, SmartWatchProvider provider) {
    if (provider.devices.isEmpty) {
      return Center(
        child: Text(
          provider.status == PairingStatus.scanning
              ? 'Recherche en cours…'
              : 'Aucun appareil trouvé.',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.padding(context)),
      itemCount: provider.devices.length,
      itemBuilder: (context, index) {
        final device = provider.devices[index];
        return _buildDeviceTile(context, provider, device);
      },
    );
  }

  Widget _buildDeviceTile(
      BuildContext context, SmartWatchProvider provider, WatchDevice device) {
    final isConnected = provider.connectedDevice?.id == device.id;
    final isConnecting = provider.connectingDeviceId == device.id;
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.sh(context, 10)),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? Colors.greenAccent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: ListTile(
        leading: const Icon(Icons.watch, color: Colors.white),
        title: Text(device.name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            ...List.generate(3, (i) {
              final active = i < device.signalBars;
              return Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Icon(
                  Icons.circle,
                  size: ResponsiveUtils.sf(context, 7),
                  color: active ? Colors.white70 : Colors.white24,
                ),
              );
            }),
            SizedBox(width: ResponsiveUtils.sw(context, 6)),
            Text('${device.rssi} dBm',
                style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: ResponsiveUtils.sf(context, 11))),
          ],
        ),
        trailing: isConnected
            ? const Icon(Icons.check_circle, color: Colors.greenAccent)
            : isConnecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: provider.status == PairingStatus.connecting
                        ? null
                        : () => provider.connect(device),
                    child: const Text('Connecter',
                        style: TextStyle(color: Colors.white)),
                  ),
      ),
    );
  }

  Widget _buildScanButton(BuildContext context, SmartWatchProvider provider) {
    final scanning = provider.status == PairingStatus.scanning;
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: scanning ? provider.stopScan : provider.startScan,
          icon: Icon(scanning ? Icons.stop : Icons.refresh,
              color: Colors.black),
          label: Text(scanning ? 'Arrêter la recherche' : 'Rechercher à nouveau'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding:
                EdgeInsets.symmetric(vertical: ResponsiveUtils.sh(context, 15)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
