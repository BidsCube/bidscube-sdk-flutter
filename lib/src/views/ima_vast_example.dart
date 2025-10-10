import 'package:flutter/material.dart';
import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';

/// Example demonstrating IMA VAST Video Ad View
/// Shows how to use the Interactive Media Ads SDK for VAST video ads
class ImaVastExample extends StatefulWidget {
  const ImaVastExample({super.key});

  @override
  State<ImaVastExample> createState() => _ImaVastExampleState();
}

class _ImaVastExampleState extends State<ImaVastExample> {
  bool _isInitialized = false;
  Widget? _currentAdView;

  @override
  void initState() {
    super.initState();
    _initializeSDK();
  }

  Future<void> _initializeSDK() async {
    try {
      await BidscubeSDK.initialize(
        config: SDKConfig(baseURL: 'https://ssp-bcc-ads.com/sdk'),
        useFlutterOnly: true, // Use Flutter-only mode with IMA SDK
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      SDKLogger.error('Failed to initialize SDK', e);
    }
  }

  Future<void> _loadVideoAd() async {
    if (!_isInitialized) return;

    try {
      final callback = TestAdCallback(
        (message) => SDKLogger.info('Ad: $message'),
      );

      final adView = await BidscubeSDK.getVideoAdView(
        '19483', // Your placement ID
        callback: callback,
      );

      setState(() {
        _currentAdView = adView;
      });
    } catch (e) {
      SDKLogger.error('Failed to load video ad', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IMA VAST Video Ad Example'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IMA VAST Video Ad Demo',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This example uses Google\'s Interactive Media Ads SDK to handle VAST video ads.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          _isInitialized ? Icons.check_circle : Icons.error,
                          color: _isInitialized ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isInitialized
                              ? 'SDK Initialized'
                              : 'SDK Not Initialized',
                          style: TextStyle(
                            color: _isInitialized ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isInitialized ? _loadVideoAd : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Load VAST Video Ad',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            if (_currentAdView != null) ...[
              Text(
                'Video Ad Display:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _currentAdView!,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample VAST XML Content:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '''<?xml version="1.0" encoding="UTF-8"?>
<VAST version="3.0">
  <Ad id="1">
    <InLine>
      <AdSystem>Demo VAST</AdSystem>
      <AdTitle>Sample Video 1</AdTitle>
      <Creatives>
        <Creative>
          <Linear>
            <Duration>00:00:10</Duration>
            <MediaFiles>
              <MediaFile delivery="progressive" type="video/mp4" width="640" height="360">
                <![CDATA[https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4]]>
              </MediaFile>
            </MediaFiles>
          </Linear>
        </Creative>
      </Creatives>
    </InLine>
  </Ad>
</VAST>''',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Test Ad Callback for logging
class TestAdCallback implements AdCallback {
  final Function(String) _log;

  TestAdCallback(this._log);

  @override
  void onAdLoading(String placementId) {
    _log('Ad loading: $placementId');
  }

  @override
  void onAdLoaded(String placementId) {
    _log('Ad loaded: $placementId');
  }

  @override
  void onAdDisplayed(String placementId) {
    _log('Ad displayed: $placementId');
  }

  @override
  void onAdFailed(String placementId, String errorCode, String errorMessage) {
    _log('Ad failed: $placementId - $errorMessage (Code: $errorCode)');
  }

  @override
  void onAdClicked(String placementId) {
    _log('Ad clicked: $placementId');
  }

  @override
  void onAdClosed(String placementId) {
    _log('Ad closed: $placementId');
  }

  @override
  void onVideoAdStarted(String placementId) {
    _log('Video ad started: $placementId');
  }

  @override
  void onVideoAdCompleted(String placementId) {
    _log('Video ad completed: $placementId');
  }

  @override
  void onVideoAdSkipped(String placementId) {
    _log('Video ad skipped: $placementId');
  }
}
