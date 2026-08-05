import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Last known reachability. Ad widgets listen to this so ad space collapses
/// the moment the device goes offline instead of waiting for a failed load.
final ValueNotifier<bool> networkOnline = ValueNotifier<bool>(true);

/// A resolver can be blocked on some networks, so a single failing host is not
/// enough to declare the device offline.
const _probeHosts = <String>['dns.google', 'cloudflare.com', 'google.com'];

bool? _cachedOnline;
DateTime? _cachedAt;
Future<bool>? _probeInFlight;

/// Cached reachability — avoids repeated DNS lookups that stall the UI.
///
/// While offline the cache is short-lived so ads resume quickly once the user
/// reconnects; while online it is long-lived so ad callbacks stay cheap.
Future<bool> hasInternetConnection({
  Duration timeout = const Duration(seconds: 2),
  bool force = false,
}) async {
  final now = DateTime.now();
  final ttl = (_cachedOnline ?? false)
      ? const Duration(seconds: 10)
      : const Duration(seconds: 3);
  if (!force &&
      _cachedOnline != null &&
      _cachedAt != null &&
      now.difference(_cachedAt!) < ttl) {
    return _cachedOnline!;
  }

  // Several ad callbacks can ask at once — run a single shared probe.
  return _probeInFlight ??=
      _probe(timeout).whenComplete(() => _probeInFlight = null);
}

Future<bool> _probe(Duration timeout) async {
  for (final host in _probeHosts) {
    try {
      final result = await InternetAddress.lookup(host).timeout(timeout);
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        _remember(online: true);
        return true;
      }
    } catch (_) {
      // Try the next host before giving up.
    }
  }
  _remember(online: false);
  return false;
}

void _remember({required bool online}) {
  _cachedOnline = online;
  _cachedAt = DateTime.now();
  if (networkOnline.value != online) {
    networkOnline.value = online;
  }
}

/// Call when AdMob reports a network / internal failure so we stop hammering.
void markNetworkOffline() => _remember(online: false);

void markNetworkOnline() => _remember(online: true);

/// Drops the cache so the next check hits the network (used on app resume).
void invalidateNetworkCache() {
  _cachedAt = null;
  _probeInFlight = null;
}
