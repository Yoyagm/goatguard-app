/// Compatibility layer — re-exports domain entities as the legacy type names.
/// Screens continue importing `models/alert.dart` until Phase 9.
library;

export '../core/entities/alert.dart';

import '../core/entities/alert.dart';

/// Type alias so existing code referencing `NetworkAlert` compiles.
typedef NetworkAlert = NetworkAlertEntity;
