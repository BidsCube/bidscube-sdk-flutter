import 'package:flutter/material.dart';
import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';
import 'package:testapp/core/ad_callback.dart';
import 'package:testapp/widgets/custom_filled_button.dart';

class ConsentTestView extends StatefulWidget {
  const ConsentTestView({super.key});

  @override
  State<ConsentTestView> createState() => _ConsentTestViewState();
}

class _ConsentTestViewState extends State<ConsentTestView> {
  bool _isInitialized = false;
  String _sdkStatus = "SDK Status: Not Initialized";
  String _placementId = "19481";
  String _consentStatus = "";
  Widget? _currentAdView;
  String _logs = "";

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
          .defaultAdTimeout(30000)
          .defaultAdPosition(AdPosition.unknown)
          .build();

      await BidscubeSDK.initialize(config: config);

      setState(() {
        _isInitialized = true;
        _sdkStatus = "SDK Status: Initialized";
      });

      _addLog('SDK initialized successfully');
      _updateConsentStatus();
    } catch (e) {
      setState(() {
        _sdkStatus = "SDK Status: Initialization Failed";
      });
      _addLog('Failed to initialize SDK: $e');
    }
  }

  void _updateConsentStatus() {
    setState(() {
      _consentStatus =
          "Consent Required: ${BidscubeSDK.isConsentRequired()}\n"
          "Ads Consent: ${BidscubeSDK.hasAdsConsent()}\n"
          "Analytics Consent: ${BidscubeSDK.hasAnalyticsConsent()}";
    });
  }

  void _requestConsentInfoUpdate() {
    if (!_isInitialized) return;
    _addLog("Requesting consent info update...");
    // TODO: Add callback handling
    BidscubeSDK.requestConsentInfoUpdate(callback: BidscubeAdCallback(_addLog));
  }

  void _showConsentForm() {
    if (!_isInitialized) return;
    _addLog("Showing consent form...");
    // TODO: Add callback handling
    BidscubeSDK.showConsentForm(callback: BidscubeAdCallback(_addLog));
  }

  void _checkConsentRequired() {
    if (!_isInitialized) return;
    _addLog("Consent required: ${BidscubeSDK.isConsentRequired()}");
  }

  void _checkAdsConsent() {
    if (!_isInitialized) return;
    _addLog("Ads consent: ${BidscubeSDK.hasAdsConsent()}");
  }

  void _checkAnalyticsConsent() {
    if (!_isInitialized) return;
    _addLog("Analytics consent: ${BidscubeSDK.hasAnalyticsConsent()}");
  }

  void _getConsentSummary() {
    if (!_isInitialized) return;
    final summary = BidscubeSDK.getConsentStatusSummary();
    _addLog("Consent Summary: $summary");
  }

  void _enableDebugMode() {
    if (!_isInitialized) return;
    BidscubeSDK.enableConsentDebugMode("test_device_123");
    _addLog("Debug mode enabled for test device");
  }

  void _resetConsent() {
    if (!_isInitialized) return;
    BidscubeSDK.resetConsent();
    _addLog("Consent information reset");
    _updateConsentStatus();
  }

  Future<void> _showImageAdIfConsent() async {
    if (!_isInitialized || !BidscubeSDK.hasAdsConsent()) {
      _addLog("No ads consent. Request consent first.");
      return;
    }
    _addLog("Showing image ad...");
    final callback = BidscubeAdCallback(_addLog);
    final adView = await BidscubeSDK.getImageAdView(
      _placementId,
      callback: callback,
    );
    setState(() {
      _currentAdView = adView;
    });
  }

  Future<void> _showVideoAdIfConsent() async {
    if (!_isInitialized || !BidscubeSDK.hasAdsConsent()) {
      _addLog("No ads consent. Request consent first.");
      return;
    }
    _addLog("Showing video ad...");
    final callback = BidscubeAdCallback(_addLog);
    final adView = await BidscubeSDK.getVideoAdView(
      _placementId,
      callback: callback,
    );
    setState(() {
      _currentAdView = adView;
    });
  }

  Future<void> _showNativeAdIfConsent() async {
    if (!_isInitialized || !BidscubeSDK.hasAdsConsent()) {
      _addLog("No ads consent. Request consent first.");
      return;
    }
    _addLog("Showing native ad...");
    final callback = BidscubeAdCallback(_addLog);
    final adView = await BidscubeSDK.getNativeAdView(
      _placementId,
      callback: callback,
    );
    setState(() {
      _currentAdView = adView;
    });
  }

  void _cleanupSDK() {
    if (_isInitialized) {
      BidscubeSDK.cleanup();
      setState(() {
        _sdkStatus = "SDK Status: Cleaned Up";
        _isInitialized = false;
        _currentAdView = null;
      });
      _addLog("SDK cleaned up");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Consent Test"),
        forceMaterialTransparency: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _sdkStatus,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              CustomFilledButton(
                onPressed: _isInitialized ? null : _initializeSDK,
                label: "Initialize SDK",
                color: Color(0xFF007aff),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: "Placement ID",
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: _placementId),
                onChanged: (v) => _placementId = v,
              ),
              const SizedBox(height: 12),
              Text(_consentStatus, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              if (_isInitialized) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Consent Management",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                CustomFilledButton(
                  onPressed: _requestConsentInfoUpdate,
                  label: "Request Consent Info Update",
                  color: Color(0xFF007aff),
                ),
                CustomFilledButton(
                  onPressed: _showConsentForm,
                  label: "Show Consent Form",
                  color: Color(0xFF34c759),
                ),
                Row(
                  children: [
                    Expanded(
                      child: CustomFilledButton(
                        onPressed: _checkConsentRequired,
                        label: "Check Consent Required",
                        color: Color(0xFFff9500),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomFilledButton(
                        onPressed: _checkAdsConsent,
                        label: "Check Ads Consent",
                        color: Color(0xFF9646be),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: CustomFilledButton(
                        onPressed: _checkAnalyticsConsent,
                        label: "Check Analytics Consent",
                        color: Color(0xFF5856d6),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomFilledButton(
                        onPressed: _getConsentSummary,
                        label: "Get Consent Summary",
                        color: Color(0xFF2eabc2),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: CustomFilledButton(
                        onPressed: _enableDebugMode,
                        label: "Enable Debug Mode",
                        color: Color(0xFFa2845d),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomFilledButton(
                        onPressed: _resetConsent,
                        label: "Reset Consent",
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Ad Testing (requires consent and placementId)",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                CustomFilledButton(
                  onPressed: _showImageAdIfConsent,
                  label: "Show Image Ad (if consent)",
                  color: Color(0xFF34c759),
                ),
                CustomFilledButton(
                  onPressed: _showVideoAdIfConsent,
                  label: "Show Video Ad (if consent)",
                  color: Color(0xFF007aff),
                ),
                CustomFilledButton(
                  onPressed: _showNativeAdIfConsent,
                  label: "Show Native Ad (if consent)",
                  color: Color(0xFFff9500),
                ),
                const SizedBox(height: 16),
                if (_currentAdView != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          const Text(
                            "Ad Display",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _currentAdView!,
                        ],
                      ),
                    ),
                  ),
                CustomFilledButton(
                  onPressed: _cleanupSDK,
                  color: Colors.red,
                  label: "Cleanup SDK",
                ),
              ],
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Logs:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        child: Text(
                          _logs.isEmpty ? "No logs yet..." : _logs,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
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
