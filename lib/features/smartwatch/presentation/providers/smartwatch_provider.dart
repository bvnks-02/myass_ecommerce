import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/entities/watch_device.dart';
import '../../domain/entities/watch_face.dart';

/// Connection state for the (mocked) pairing flow.
enum PairingStatus { idle, scanning, connecting, connected }

/// Holds smart-watch pairing + selected-face state.
///
/// ⚠️ MOCK IMPLEMENTATION. No BLE SDK was provided with the project, so the
/// scan/connect logic here is entirely simulated. Every place that would call
/// into a real Bluetooth stack is marked with `TODO(BLE)`. Swap those bodies
/// for real SDK calls (e.g. flutter_blue_plus) without changing this API.
class SmartWatchProvider extends ChangeNotifier {
  PairingStatus _status = PairingStatus.idle;
  final List<WatchDevice> _devices = [];
  WatchDevice? _connectedDevice;
  String? _connectingDeviceId;
  WatchFace _selectedFace = WatchFace.catalog.first;

  Timer? _scanTimer;

  PairingStatus get status => _status;
  List<WatchDevice> get devices => List.unmodifiable(_devices);
  WatchDevice? get connectedDevice => _connectedDevice;
  String? get connectingDeviceId => _connectingDeviceId;
  WatchFace get selectedFace => _selectedFace;
  bool get isConnected => _connectedDevice != null;

  /// Simulated nearby devices revealed progressively during a scan.
  static const List<WatchDevice> _mockCatalog = [
    WatchDevice(id: 'myazz-pro-01', name: 'Myazz Watch Pro', rssi: -48),
    WatchDevice(id: 'myazz-lite-02', name: 'Myazz Watch Lite', rssi: -66),
    WatchDevice(id: 'myazz-active-03', name: 'Myazz Active', rssi: -79),
    WatchDevice(id: 'myazz-classic-04', name: 'Myazz Classic', rssi: -88),
  ];

  /// Starts a (mocked) BLE scan. Devices appear one by one, as they would when
  /// discovered over the air.
  void startScan() {
    // TODO(BLE): replace with real adapter scan, e.g.
    //   FlutterBluePlus.startScan(timeout: ...);
    //   FlutterBluePlus.scanResults.listen(...)
    _scanTimer?.cancel();
    _devices.clear();
    _status = PairingStatus.scanning;
    notifyListeners();

    var index = 0;
    _scanTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (index >= _mockCatalog.length) {
        timer.cancel();
        AppLogger.debug('Mock scan complete: ${_devices.length} devices',
            tag: 'SmartWatch');
        return;
      }
      // Jitter the RSSI a little so it feels live.
      final base = _mockCatalog[index];
      final jitter = Random().nextInt(6) - 3;
      _devices.add(WatchDevice(
        id: base.id,
        name: base.name,
        rssi: base.rssi + jitter,
      ));
      index++;
      notifyListeners();
    });
  }

  void stopScan() {
    // TODO(BLE): FlutterBluePlus.stopScan();
    _scanTimer?.cancel();
    if (_status == PairingStatus.scanning) {
      _status = _connectedDevice != null
          ? PairingStatus.connected
          : PairingStatus.idle;
      notifyListeners();
    }
  }

  /// Simulates connecting to [device].
  Future<void> connect(WatchDevice device) async {
    // TODO(BLE): device.connect(); discover services; subscribe to characteristics.
    _scanTimer?.cancel();
    _connectingDeviceId = device.id;
    _status = PairingStatus.connecting;
    notifyListeners();

    await Future<void>.delayed(const Duration(seconds: 2));

    _connectedDevice = device;
    _connectingDeviceId = null;
    _status = PairingStatus.connected;
    AppLogger.info('Mock connected to ${device.name}', tag: 'SmartWatch');
    notifyListeners();
  }

  void disconnect() {
    // TODO(BLE): device.disconnect();
    _connectedDevice = null;
    _status = PairingStatus.idle;
    notifyListeners();
  }

  /// Selects a watch face. On real hardware this would push the face to the
  /// paired device.
  void selectFace(WatchFace face) {
    // TODO(BLE): write the selected face id to the device's config characteristic.
    _selectedFace = face;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }
}
