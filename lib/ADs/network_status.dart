import 'dart:io';

bool? _cachedOnline;
DateTime? _cachedAt;

/// Cached reachability — avoids repeated DNS lookups that stall the UI.
Future<bool> hasInternetConnection({
  Duration timeout = const Duration(seconds: 2),
  bool force = false,
}) async {
  final now = DateTime.now();
  if (!force &&
      _cachedOnline != null &&
      _cachedAt != null &&
      now.difference(_cachedAt!) < const Duration(seconds: 10)) {
    return _cachedOnline!;
  }

  try {
    final result = await InternetAddress.lookup('dns.google').timeout(timeout);
    final online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    _cachedOnline = online;
    _cachedAt = now;
    return online;
  } catch (_) {
    _cachedOnline = false;
    _cachedAt = now;
    return false;
  }
}

/// Call when AdMob reports a network / internal failure so we stop hammering.
void markNetworkOffline() {
  _cachedOnline = false;
  _cachedAt = DateTime.now();
}

void markNetworkOnline() {
  _cachedOnline = true;
  _cachedAt = DateTime.now();
}
