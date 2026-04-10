import 'package:flutter/material.dart';
import '../../core/entities/device.dart';

/// Maps DeviceType to its Material icon.
///
/// Extracted from the old Device.icon getter to keep the domain
/// layer free of Flutter dependencies.
IconData deviceTypeIcon(DeviceType type) {
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
