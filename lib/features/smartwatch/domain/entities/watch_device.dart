/// A discoverable smart-watch device.
///
/// NOTE: This is a mock model. No real Bluetooth/BLE SDK was supplied with the
/// project, so devices are simulated (see SmartWatchProvider). When a real
/// manufacturer SDK is integrated, map its scan results onto this entity.
class WatchDevice {
  final String id;
  final String name;

  /// Simulated signal strength in dBm (closer to 0 = stronger).
  final int rssi;

  const WatchDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });

  /// Signal bars 0..3 derived from the (simulated) RSSI.
  int get signalBars {
    if (rssi >= -55) return 3;
    if (rssi >= -70) return 2;
    if (rssi >= -85) return 1;
    return 0;
  }
}
