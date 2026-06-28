class MapsConfig {
  // Get your API key at https://console.cloud.google.com/
  // Enable: Maps SDK for Android, Maps SDK for iOS, Geocoding API
  // Then replace this placeholder in:
  //   Android: android/app/src/main/AndroidManifest.xml
  //   iOS:     ios/Runner/AppDelegate.swift
  //   (and below for reverse geocoding calls)
  static const String apiKey = 'AIzaSyDZbvGHPXLZ4zLBV7gjxf9fkfTTrUcKtj8';

  // Default map center: Accra, Ghana
  static const double defaultLat = 5.6037;
  static const double defaultLng = -0.1870;
  static const double defaultZoom = 13.0;

  // Radius used when searching for nearby transporters
  static const double nearbyRadiusKm = 100.0;

  static bool get keyConfigured => apiKey != 'AIzaSyDZbvGHPXLZ4zLBV7gjxf9fkfTTrUcKtj8';
}
