/// Compatibility layer — re-exports domain entities as the legacy type names.
/// Screens continue importing `models/agent.dart` until Phase 9.
library;

export '../core/entities/agent.dart';

import '../core/entities/agent.dart';

/// Type alias so existing code referencing `Agent` compiles.
typedef Agent = AgentEntity;
