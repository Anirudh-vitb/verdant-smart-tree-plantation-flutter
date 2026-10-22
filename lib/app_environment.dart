/// Facts about how the app started, shared with the UI.
class AppEnvironment {
  const AppEnvironment({this.storageWarning});

  /// Set when device storage could not be opened and data is kept in memory.
  final String? storageWarning;
}
