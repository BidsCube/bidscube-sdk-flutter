import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BidsCube SDK Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _sdkReady = false;
  Widget? _interstitialPreview;
  Widget? _rewardedPreview;

  final _cb = ExampleAdCallback();

  Future<void> _ensureSdk() async {
    if (_sdkReady || BidscubeSDK.isInitialized) {
      _sdkReady = true;
      return;
    }
    final config = SDKConfig.builder().enableLogging(true).build();
    await BidscubeSDK.initialize(config: config, useFlutterOnly: true);
    if (mounted) setState(() => _sdkReady = true);
  }

  Future<void> _loadInterstitial() async {
    await _ensureSdk();
    final widget = await BidscubeSDK.getInterstitialVideoAdView(
      'test-interstitial-placement',
      callback: _cb,
    );
    if (mounted) setState(() => _interstitialPreview = widget);
  }

  Future<void> _loadRewarded() async {
    await _ensureSdk();
    final widget = await BidscubeSDK.getRewardedVideoAdView(
      'test-rewarded-placement',
      callback: _cb,
    );
    if (mounted) setState(() => _rewardedPreview = widget);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BidsCube SDK Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Banner (simulated)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Center(
            child: BannerAdView(
              placementId: 'test-banner-placement',
              width: 320,
              height: 50,
              callback: ExampleAdCallback(),
            ),
          ),
          const Divider(height: 32),
          const Text(
            'Video (Flutter-only IMA)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _loadInterstitial,
                child: const Text('Load interstitial video'),
              ),
              FilledButton(
                onPressed: _loadRewarded,
                child: const Text('Load rewarded video'),
              ),
            ],
          ),
          if (_interstitialPreview != null) ...[
            const SizedBox(height: 16),
            const Text('Interstitial widget'),
            const SizedBox(height: 8),
            SizedBox(height: 240, child: Center(child: _interstitialPreview!)),
          ],
          if (_rewardedPreview != null) ...[
            const SizedBox(height: 16),
            const Text('Rewarded widget'),
            const SizedBox(height: 8),
            SizedBox(height: 240, child: Center(child: _rewardedPreview!)),
          ],
        ],
      ),
    );
  }
}

/// Example implementation of AdCallback to handle ad events.
class ExampleAdCallback implements AdCallback {
  @override
  void Function(String placementId, String adm, AdPosition position)?
  onAdRenderOverride;

  @override
  void onAdLoading(String placementId) {
    debugPrint('Ad is loading: $placementId');
  }

  @override
  void onAdLoaded(String placementId) {
    debugPrint('Ad loaded: $placementId');
  }

  @override
  void onAdDisplayed(String placementId) {
    debugPrint('Ad displayed: $placementId');
  }

  @override
  void onAdFailed(String placementId, String errorCode, String errorMessage) {
    debugPrint('Ad failed: $placementId, $errorCode, $errorMessage');
  }

  @override
  void onAdClicked(String placementId) {
    debugPrint('Ad clicked: $placementId');
  }

  @override
  void onAdClosed(String placementId) {
    debugPrint('Ad closed: $placementId');
  }

  @override
  void onVideoAdStarted(String placementId) {
    debugPrint('Video ad started: $placementId');
  }

  @override
  void onVideoAdCompleted(String placementId) {
    debugPrint('Video ad completed: $placementId');
  }

  @override
  void onVideoAdSkipped(String placementId) {
    debugPrint('Video ad skipped: $placementId');
  }

  @override
  void onUserRewarded(String placementId) {
    debugPrint('User rewarded: $placementId');
  }
}
