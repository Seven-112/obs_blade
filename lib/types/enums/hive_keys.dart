enum HiveKeys {
  /// Returns a List of [Connection]
  SavedConnections,

  /// Returns a List of [PastStreamData]
  PastStreamData,

  /// Returns the box containing app settings - refer to [SettingsKeys]
  /// to see which key-value pairs are available
  Settings,

  /// Returns a List of [CustomTheme]
  CustomTheme,
}

extension HiveKeysFunctions on HiveKeys {
  String get name => const {
        HiveKeys.SavedConnections: 'saved-connections',
        HiveKeys.PastStreamData: 'past-stream-data',
        HiveKeys.Settings: 'settings',
        HiveKeys.CustomTheme: 'custom-theme',
      }[this];
}
