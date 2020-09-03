enum SettingsKeys {
  /// [bool]: Using fully dark mode or not
  TrueDark,

  /// [bool]: If user wants to reduce smearing if [TrueDark] is true
  ReduceSmearing,

  /// [bool]: If user wants to use tablet mode (layout) even if size is not optimal
  EnforceTabletMode,

  /// [List<String>]: All entered twitch usernames by the user
  TwitchUsernames,

  /// [String]: The currently selected twitch username to use for the twitch chat
  SelectedTwitchUsername,

  /// Internally used properties which won't be changeable / seeable for the user

  /// [bool]: If the user already saw the intro - will be set after being in landing
  /// of Home Tab and will prevent the user from seeing the intro slides again
  HasUserSeenIntro,
}

extension SettingsKeysFunctions on SettingsKeys {
  String get name => const {
        SettingsKeys.TrueDark: 'true-dark',
        SettingsKeys.ReduceSmearing: 'reduce-smearing',
        SettingsKeys.EnforceTabletMode: 'enforce-tablet-mode',
        SettingsKeys.TwitchUsernames: 'twitch-usernames',
        SettingsKeys.SelectedTwitchUsername: 'selected-twitch-username',
        SettingsKeys.HasUserSeenIntro: 'has-user-seen-intro',
      }[this];
}
