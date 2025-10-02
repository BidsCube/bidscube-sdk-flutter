import 'package:flutter/material.dart';
import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BidsCube SDK Test App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SDKTestView(),
    );
  }
}

class SDKTestView extends StatefulWidget {
  const SDKTestView({super.key});

  @override
  State<SDKTestView> createState() => _SDKTestViewState();
}

class _SDKTestViewState extends State<SDKTestView> {
  bool _isInitialized = false;
  String _selectedAdType = 'Image';
  String _placementId = '19483';
  String _logs = '';
  Widget? _currentAdView;

  final List<String> _adTypes = ['Image', 'Video', 'Native', 'Banner'];
  final List<String> _testPlacementIds = [
    '19483',
    'test_image',
    'test_native',
    'test_banner',
  ];

  @override
  void initState() {
    super.initState();
    _initializeSDK();
  }

  Future<void> _initializeSDK() async {
    try {
      final config = SDKConfig.builder()
          .baseURL('https://api.bidscube.com')
          .enableLogging(true)
          .enableDebugMode(true)
          .defaultAdTimeout(30000)
          .defaultAdPosition(AdPosition.unknown)
          .enableTestMode(true)
          .build();

      await BidscubeSDK.initialize(config: config);

      setState(() {
        _isInitialized = true;
      });

      _addLog('SDK initialized successfully');
    } catch (e) {
      _addLog('Failed to initialize SDK: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs += '${DateTime.now().toString().substring(11, 19)}: $message\n';
    });
  }

  Future<void> _loadAd() async {
    if (!_isInitialized) {
      _addLog('SDK not initialized');
      return;
    }

    try {
      _addLog('Loading ${_selectedAdType.toLowerCase()} ad...');

      final callback = _TestAdCallback(_addLog);

      Widget adView;
      switch (_selectedAdType) {
        case 'Image':
          adView = await BidscubeSDK.getImageAdView(
            _placementId,
            callback: callback,
          );
          break;
        case 'Video':
          adView = await BidscubeSDK.getVideoAdView(
            _placementId,
            callback: callback,
          );
          break;
        case 'Native':
          adView = await BidscubeSDK.getNativeAdView(
            _placementId,
            callback: callback,
          );
          break;
        case 'Banner':
          adView = await BidscubeSDK.getBannerAdView(
            _placementId,
            callback: callback,
          );
          break;
        default:
          throw Exception('Unknown ad type: $_selectedAdType');
      }

      setState(() {
        _currentAdView = adView;
      });

      _addLog('Ad view created successfully');
    } catch (e) {
      _addLog('Failed to load ad: $e');
    }
  }

  void _clearLogs() {
    setState(() {
      _logs = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Controls
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ad Type:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        value: _selectedAdType,
                        isExpanded: true,
                        items: _adTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedAdType = newValue;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Placement ID:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        value: _placementId,
                        isExpanded: true,
                        items: _testPlacementIds.map((String id) {
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(id),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _placementId = newValue;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: _isInitialized ? _loadAd : null,
                        child: const Text('Load Ad'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Ad View
              if (_currentAdView != null)
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ad View:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Expanded(child: Center(child: _currentAdView!)),
                        ],
                      ),
                    ),
                  ),
                ),

              // Logs
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Logs:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                _logs.isEmpty ? 'No logs yet...' : _logs,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestAdCallback implements AdCallback {
  final Function(String) _addLog;

  _TestAdCallback(this._addLog);

  @override
  void onAdLoading(String placementId) {
    _addLog('Ad loading: $placementId');
  }

  @override
  void onAdLoaded(String placementId) {
    _addLog('Ad loaded: $placementId');
  }

  @override
  void onAdDisplayed(String placementId) {
    _addLog('Ad displayed: $placementId');
  }

  @override
  void onAdFailed(String placementId, int errorCode, String errorMessage) {
    _addLog('Ad failed: $placementId - $errorMessage (Code: $errorCode)');
  }

  @override
  void onAdClicked(String placementId) {
    _addLog('Ad clicked: $placementId');
  }

  @override
  void onAdClosed(String placementId) {
    _addLog('Ad closed: $placementId');
  }

  @override
  void onVideoAdStarted(String placementId) {
    _addLog('Video ad started: $placementId');
  }

  @override
  void onVideoAdCompleted(String placementId) {
    _addLog('Video ad completed: $placementId');
  }

  @override
  void onVideoAdSkipped(String placementId) {
    _addLog('Video ad skipped: $placementId');
  }
}
