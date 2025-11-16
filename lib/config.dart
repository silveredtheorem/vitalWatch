class AppConfig {
  // Default to localhost for emulator if no IP is provided
  static const emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );

  // Default to a placeholder if no API key is provided
  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'YOUR_API_KEY_HERE',
  );
}
