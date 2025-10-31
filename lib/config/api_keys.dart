/// API Keys configuration for Aurora
///
/// IMPORTANT: Replace these placeholder values with your actual API keys
///
/// 1. Porcupine Access Key (Required for wake word detection)
///    - Get it from: https://console.picovoice.ai/
///    - Free tier available
///
/// 2. OpenRouteService API Key (Optional, for online routing fallback)
///    - Get it from: https://openrouteservice.org/dev/#/signup
///    - Free tier: 2,000 requests/day

class ApiKeys {
  /// Porcupine wake word detection access key
  /// Replace with your actual key from https://console.picovoice.ai/
  static const String porcupineAccessKey =
      'IkLo/Ii4xMrlYoq69R/QN9yfFMI5H3DU9KpROJgFnQGBN5ZvRDj0UQ==';

  /// OpenRouteService API key for online routing fallback
  /// Replace with your actual key from https://openrouteservice.org/
  static const String openRouteServiceKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImQzNTQyM2ZjNGMwMTI0MjUwZDczZjIwMjM5NzlkODVhNjMyYjljYjUwZGZiZTJmNWRjNmQyYmJhIiwiaCI6Im11cm11cjY0In0=';
}
