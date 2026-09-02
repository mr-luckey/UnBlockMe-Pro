import 'package:blocked/core/config/ads_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const config = BlockedAdsConfig(testMode: false);

  test('banner placements resolve to distinct production units', () {
    expect(config.bannerUnitId('home'), isNotNull);
    expect(config.bannerUnitId('play'), isNotNull);
    expect(config.bannerUnitId('home'), isNot(config.bannerUnitId('play')));
  });

  test('rewarded placements map hint and auto_solve separately', () {
    expect(config.rewardedUnitId('hint'), isNotNull);
    expect(config.rewardedUnitId('auto_solve'), isNotNull);
    expect(
      config.rewardedUnitId('hint'),
      isNot(config.rewardedUnitId('auto_solve')),
    );
  });

  test('unknown placement returns null', () {
    expect(config.bannerUnitId('unknown'), isNull);
  });
}
