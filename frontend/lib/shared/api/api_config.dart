/// Base URL for Module 1's backend.
///
/// Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
///
/// Defaults below assume `uvicorn` running on localhost:8000:
///  - Android emulator reaches the host machine via 10.0.2.2
///  - iOS simulator / desktop / web can use localhost directly
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    return 'http://127.0.0.1:8000'; // Android emulator default
  }
}
