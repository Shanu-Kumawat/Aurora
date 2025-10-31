/// Represents a user command intent
enum IntentType {
  startNavigation,
  stopNavigation,
  getCurrentLocation,
  getTripStatus,
  triggerEmergency,
  cancelEmergency,
  queryAI,
  unknown,
}

/// Intent model for parsed voice commands
class Intent {
  final IntentType type;
  final Map<String, dynamic> entities;

  Intent({required this.type, this.entities = const {}});

  String? get destination => entities['destination'] as String?;
  String? get query => entities['query'] as String?;

  @override
  String toString() {
    return 'Intent(type: $type, entities: $entities)';
  }
}
