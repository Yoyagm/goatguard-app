/// Compatibility layer — re-exports domain entities as the legacy type names.
/// Screens continue importing `models/device.dart` until Phase 9 migrates
/// them to import from `core/entities/` directly.
library;

import 'package:flutter/material.dart';
export '../core/entities/device.dart';
export '../core/entities/device_snapshot.dart';
export '../core/entities/device_connection.dart';

import '../core/entities/device.dart';
import '../core/entities/device_snapshot.dart';
import '../core/entities/device_connection.dart';

/// Type alias so existing screen code referencing `Device` compiles.
typedef Device = DeviceEntity;

/// Type alias for DeviceSnapshot.
typedef DeviceSnapshot = DeviceSnapshotEntity;

/// Type alias for DeviceConnection.
typedef DeviceConnection = DeviceConnectionEntity;

/// Presentation-layer extension: maps [DeviceType] to a Material icon.
/// This logic lived in the old `Device` model; it stays accessible here
/// until Phase 9 moves it to a proper presentation helper.
extension DeviceEntityIcon on DeviceEntity {
  IconData get icon {
    switch (type) {
      case DeviceType.desktop:
        return Icons.desktop_windows_rounded;
      case DeviceType.laptop:
        return Icons.laptop_mac_rounded;
      case DeviceType.server:
        return Icons.dns_rounded;
      case DeviceType.phone:
        return Icons.phone_android_rounded;
      case DeviceType.printer:
        return Icons.print_rounded;
      case DeviceType.camera:
        return Icons.videocam_rounded;
      case DeviceType.iot:
        return Icons.sensors_rounded;
      case DeviceType.unknown:
        return Icons.device_unknown_rounded;
    }
  }
}
