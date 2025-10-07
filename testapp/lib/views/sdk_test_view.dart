import 'dart:developer';

import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:testapp/widgets/custom_filled_button.dart';
import 'package:testapp/core/ad_callback.dart';

class SDKTestView extends StatefulWidget {
  const SDKTestView({super.key});

  @override
  State<SDKTestView> createState() => _SDKTestViewState();
}

class _SDKTestViewState extends State<SDKTestView> {
  bool _isInitialized = false;
  bool _useFlutterOnly = false;
  String _placementId = '19483';
  Widget? _currentAdView;
  ValueNotifier<bool> _adPositionOverrideSwitch = ValueNotifier<bool>(false);
  String _urlBuilderDemo = '';
  String _webViewHTML = '';
  bool _loggingEnabled = true;
  AdPosition _selectedPosition = AdPosition.unknown;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _initializeSDK() async {
    try {
      final config = SDKConfig.builder()
          .baseURL(Constants.baseURL)
          .enableLogging(true)
          .enableDebugMode(true)
          .defaultAdTimeout(30000)
          .defaultAdPosition(AdPosition.unknown)
          .enableTestMode(true)
          .build();

      await BidscubeSDK.initialize(
        config: config,
        useFlutterOnly: _useFlutterOnly,
      );

      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });

      _addLog(
        'SDK initialized successfully (${_useFlutterOnly ? "Flutter-only" : "Native"} mode)',
      );
    } catch (e) {
      _addLog('Failed to initialize SDK: $e');
    }
  }

  void _addLog(String message) {
    if (_loggingEnabled) {
      log('${DateTime.now().toString().substring(11, 19)}: $message');
    }
  }

  Future<void> _loadAd(AdType adType) async {
    if (!_isInitialized) {
      _addLog('SDK not initialized');
      return;
    }

    try {
      _addLog('Loading ${adType.name} ad...');

      final callback = BidscubeAdCallback(_addLog);
      final position = _adPositionOverrideSwitch.value
          ? _selectedPosition
          : AdPosition.unknown;

      Widget adView;
      switch (adType) {
        case AdType.image:
          adView = await BidscubeSDK.getImageAdView(
            _placementId,
            callback: callback,
            position: position,
          );
          break;
        case AdType.video:
          adView = await BidscubeSDK.getVideoAdView(
            _placementId,
            callback: callback,
            position: position,
          );
          break;
        case AdType.native:
          adView = await BidscubeSDK.getNativeAdView(
            _placementId,
            callback: callback,
            position: position,
          );
          break;
        case AdType.banner:
          adView = await BidscubeSDK.getBannerAdView(
            _placementId,
            callback: callback,
            position: position,
          );
          break;
      }

      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentAdView = adView;
          });
        }
      });

      _addLog('Ad view created successfully');
    } catch (e) {
      _addLog('Failed to load ad: $e');
    }
  }

  Future<void> _reloadAd(AdType adType) async {
    _addLog('Reloading ${adType.name} ad...');
    await _loadAd(adType);
  }

  void _resetSDK() {
    _addLog('Cleaning up SDK...');

    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _currentAdView = null;
          _urlBuilderDemo = '';
          _webViewHTML = '';
        });
      }
    });

    _addLog('SDK cleaned up - you can now choose a different mode');
  }

  void _toggleLogging() {
    setState(() {
      _loggingEnabled = !_loggingEnabled;
    });
    _addLog('Logging ${_loggingEnabled ? 'enabled' : 'disabled'}');
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
                  child: Column(
                    children: [
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
                      if (!_isInitialized) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Mode: '),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Native'),
                              selected: !_useFlutterOnly,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _useFlutterOnly = false;
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Flutter-Only'),
                              selected: _useFlutterOnly,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _useFlutterOnly = true;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _useFlutterOnly
                              ? 'Using WebView, video_player, and custom widgets (no native code)'
                              : 'Using native iOS/Android implementations',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_isInitialized)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  color: _useFlutterOnly ? Colors.blue[50] : Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _useFlutterOnly ? Icons.web : Icons.phone_android,
                              color: _useFlutterOnly
                                  ? Colors.blue
                                  : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Current Mode: ${_useFlutterOnly ? "Flutter-Only" : "Native"}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _useFlutterOnly
                                      ? Colors.blue[800]
                                      : Colors.green[800],
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _resetSDK,
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Reset SDK to change mode',
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _useFlutterOnly
                              ? 'WebView + Custom Widgets'
                              : 'Native iOS/Android',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

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
                      onPressed: _isInitialized
                          ? () => _reloadAd(AdType.image)
                          : null,
                      label: 'Banner/Image Ads',
                      color: Color(0xFF4CAF50),
                    ),
                    CustomFilledButton(
                      onPressed: _isInitialized
                          ? () => _reloadAd(AdType.video)
                          : null,
                      label: 'Video Ads',
                      color: Color(0xFF2196F3),
                    ),
                    CustomFilledButton(
                      onPressed: _isInitialized
                          ? () => _reloadAd(AdType.native)
                          : null,
                      label: 'Native Ads',
                      color: Color(0xFFFF9800),
                    ),
                  ],
                ),
              ),

            // URL Builder Results
            if (_urlBuilderDemo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'URL Builder Results:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _urlBuilderDemo,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // WebView HTML Results
            if (_webViewHTML.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WebView HTML Generated:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 200,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _webViewHTML,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (_currentAdView != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Ad View:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 250, // Fixed height for ad view
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _currentAdView!,
                      ),
                    ),
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
                      onPressed: _resetSDK,
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
                        onChanged: (value) {
                          _adPositionOverrideSwitch.value = value;
                          setState(() {});
                        },
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
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Select Ad Position:',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.blue[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<AdPosition>(
                                  value: _selectedPosition,
                                  isExpanded: true,
                                  items: AdPosition.values.map((
                                    AdPosition position,
                                  ) {
                                    return DropdownMenuItem<AdPosition>(
                                      value: position,
                                      child: Text(
                                        position.value,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (AdPosition? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedPosition = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Selected: ${_selectedPosition.value}',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
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
