import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:testapp/Core/ad_callback.dart';
import 'package:testapp/widgets/custom_filled_button.dart';

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
  ValueNotifier<bool> _adPositionOverrideSwitch = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
  }

  Future<void> _initializeSDK() async {
    try {
      final config = SDKConfig.builder()
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

      final callback = TestAdCallback(_addLog);

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
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text(
          'SDK Test',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
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
                      const Spacer(),
                      if (!_isInitialized)
                        FilledButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              const Color(0xFF006ee6),
                            ),
                          ),
                          onPressed: () {
                            _initializeSDK();
                          },
                          child: const Text('Initialize'),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_isInitialized)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Placement ID Input:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Enter Placement ID',
                        filled: true,
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: _placementId),
                      onChanged: (value) {
                        _placementId = value;
                      },
                    ),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Ad Types',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    CustomFilledButton(
                      onPressed: _isInitialized ? _loadAd : null,
                      label: 'Banner/Image Ads',
                      color: Color(0xFF4CAF50),
                    ),
                    CustomFilledButton(
                      onPressed: _isInitialized ? _loadAd : null,
                      label: 'Video Ads',
                      color: Color(0xFF2196F3),
                    ),
                    CustomFilledButton(
                      onPressed: _isInitialized ? _loadAd : null,
                      label: 'Native Ads',
                      color: Color(0xFFFF9800),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            if (_currentAdView != null)
              Padding(
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
            if (_isInitialized)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Logging Control'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Flexible(
                          child: CustomFilledButton(
                            label: 'Enable Logging',
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 12),
                        Flexible(
                          child: CustomFilledButton(
                            label: 'Disable Logging',
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    CustomFilledButton(
                      label: 'Test Logging',
                      color: Colors.grey,
                    ),
                    CustomFilledButton(label: 'Cleanup SDK', color: Colors.red),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ad Position Selection: (Testing Only):',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Override Ad Position for Testing '),
                      Switch(
                        value: _adPositionOverrideSwitch.value,
                        onChanged: (value) {},
                      ),
                    ],
                  ),

                  (!_adPositionOverrideSwitch.value)
                      ? Text(
                          'Position will be determined from server response',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        )
                      : SizedBox.shrink(),
                ],
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
