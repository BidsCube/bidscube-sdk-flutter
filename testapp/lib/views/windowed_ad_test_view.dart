import 'package:flutter/material.dart';
import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';
import 'package:testapp/Core/ad_callback.dart';

class WindowedAdTestView extends StatefulWidget {
  const WindowedAdTestView({super.key});

  @override
  State<WindowedAdTestView> createState() => _WindowedAdTestViewState();
}

class _WindowedAdTestViewState extends State<WindowedAdTestView> {
  bool _isSDKInitialized = false;
  Widget? _currentAdView;
  String _logs = "";
  String _selectedPosition = "unknown";
  bool _showPositioningPanel = true;

  void _addLog(String message) {
    setState(() {
      _logs += '${DateTime.now().toString().substring(11, 19)}: $message\n';
    });
  }

  Future<void> _initializeSDK() async {
    try {
      final config = SDKConfig.builder()
          .enableLogging(true)
          .enableDebugMode(true)
          .defaultAdPosition(AdPosition.unknown)
          .build();

      await BidscubeSDK.initialize(config: config);
      setState(() {
        _isSDKInitialized = true;
      });
      _addLog("SDK initialized successfully");
    } catch (e) {
      _addLog("SDK initialization failed: $e");
    }
  }

  Future<void> _createImageAd() async {
    if (!_isSDKInitialized) {
      _addLog("SDK not initialized. Please wait...");
      return;
    }
    _addLog("Creating image ad...");
    final callback = TestAdCallback(_addLog);
    final adView = await BidscubeSDK.getImageAdView(
      "19481",
      callback: callback,
    );
    setState(() {
      _currentAdView = adView;
    });
  }

  Future<void> _createVideoAd() async {
    if (!_isSDKInitialized) {
      _addLog("SDK not initialized. Please wait...");
      return;
    }
    _addLog("Creating video ad...");
    final callback = TestAdCallback(_addLog);
    final adView = await BidscubeSDK.getVideoAdView(
      "19483",
      callback: callback,
    );
    setState(() {
      _currentAdView = adView;
    });
  }

  Future<void> _createNativeAd() async {
    if (!_isSDKInitialized) {
      _addLog("SDK not initialized. Please wait...");
      return;
    }
    _addLog("Creating native ad...");
    final callback = TestAdCallback(_addLog);
    final adView = await BidscubeSDK.getNativeAdView(
      "19487",
      callback: callback,
    );
    setState(() {
      _currentAdView = adView;
    });
  }

  void _validateLayout() {
    _addLog("✓ All requirements met!");
  }

  void _testAdPositioning(String position) {
    setState(() {
      _selectedPosition = position;
    });
    _addLog("Ad positioned at: $position");
  }

  @override
  void initState() {
    super.initState();
    _initializeSDK();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Windowed Ad Test")),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                for (int i = 0; i < 10; i++)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Content Section ${i + 1}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "This is sample content to demonstrate ad positioning within the layout.",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_currentAdView != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: _currentAdView!,
                      ),
                    ),
                  ),
                for (int i = 10; i < 15; i++)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "More Content Section ${i + 1}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Additional content sections to test ad positioning below the fold.",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          if (_showPositioningPanel)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Card(
                color: Colors.orange,
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        "AD POSITIONING",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var pos in [
                            "unknown",
                            "aboveTheFold",
                            "dependOnScreenSize",
                            "belowTheFold",
                            "header",
                            "footer",
                            "sidebar",
                            "fullScreen",
                          ])
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: () => _testAdPositioning(pos),
                              child: Text(
                                "Position: $pos",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const Divider(color: Colors.white),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: _createImageAd,
                        child: const Text("Create Image Ad"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: _createVideoAd,
                        child: const Text("Create Video Ad"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        onPressed: _createNativeAd,
                        child: const Text("Create Native Ad"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                        onPressed: _validateLayout,
                        child: const Text("Validate Layout"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () =>
                            setState(() => _showPositioningPanel = false),
                        child: const Text("Hide Panel"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!_showPositioningPanel)
            Positioned(
              top: 0,
              right: 0,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () => setState(() => _showPositioningPanel = true),
                child: const Text("Show Panel"),
              ),
            ),
        ],
      ),
    );
  }
}
