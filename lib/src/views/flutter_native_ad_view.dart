import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/callbacks.dart';
import '../core/url_builder.dart';
import '../core/ad_type.dart';
import '../core/ad_position.dart';

/// Flutter Native Ad View Widget
/// Renders native ads using pure Flutter widgets without native code dependencies
class FlutterNativeAdView extends StatefulWidget {
  /// Placement ID for the ad
  final String placementId;

  /// Ad callback handler
  final AdCallback? callback;

  /// Ad width
  final double width;

  /// Ad height
  final double height;

  /// Base URL for ad requests
  final String baseUrl;

  /// Custom ad template style
  final NativeAdStyle? style;

  /// Ad type
  final AdType adType;

  /// Ad position
  final AdPosition position;

  const FlutterNativeAdView({
    Key? key,
    required this.placementId,
    this.callback,
    this.width = 320,
    this.height = 240,
    this.baseUrl = 'https://api.bidscube.com',
    this.style,
    this.adType = AdType.native,
    this.position = AdPosition.unknown,
  }) : super(key: key);

  @override
  State<FlutterNativeAdView> createState() => _FlutterNativeAdViewState();
}

class _FlutterNativeAdViewState extends State<FlutterNativeAdView> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  NativeAdData? _adData;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  Future<void> _loadNativeAd() async {
    widget.callback?.onAdLoading(widget.placementId);

    try {
      // Request native ad from Bidscube API
      final adData = await _requestNativeAd();

      if (adData != null) {
        setState(() {
          _adData = adData;
          _isLoading = false;
        });

        widget.callback?.onAdLoaded(widget.placementId);
        widget.callback?.onAdDisplayed(widget.placementId);
      } else {
        throw Exception('No native ad available');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
      widget.callback?.onAdFailed(
        widget.placementId,
        'NATIVE_AD_ERROR',
        e.toString(),
      );
    }
  }

  Future<NativeAdData?> _requestNativeAd() async {
    try {
      // Build the proper API URL using URL Builder
      final apiURL = await URLBuilder.buildAdRequestURL(
        placementId: widget.placementId,
        adType: widget.adType,
        position: widget.position,
        baseURL: widget.baseUrl,
      );

      if (apiURL == null) {
        throw Exception('Failed to build API URL');
      }

      final response = await http.get(
        Uri.parse(apiURL),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'BidscubeSDK-Flutter/1.0.0',
        },
      );

      if (response.statusCode == 200) {
        // Check if response is JSON
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('application/json')) {
          try {
            final data = json.decode(response.body);
            return NativeAdData.fromJson(data);
          } catch (e) {
            throw Exception('Invalid JSON response: ${e.toString()}');
          }
        } else {
          // Server returned HTML instead of JSON (likely 404 page)
          throw Exception(
            'Server returned HTML instead of JSON. Content-Type: $contentType',
          );
        }
      } else {
        throw Exception('Failed to load native ad: ${response.statusCode}');
      }
    } catch (e) {
      // For demo purposes, return mock data
      return NativeAdData(
        title: 'Sample Native Ad',
        description:
            'This is a sample native ad with rich content and engaging visuals.',
        imageUrl:
            'https://via.placeholder.com/300x200/2196F3/FFFFFF?text=Ad+Image',
        iconUrl: 'https://via.placeholder.com/50x50/FF9800/FFFFFF?text=Logo',
        callToAction: 'Learn More',
        clickUrl: 'https://example.com',
        advertiser: 'Sample Advertiser',
        rating: 4.5,
        price: '\$29.99',
        store: 'App Store',
      );
    }
  }

  void _onAdClicked() {
    widget.callback?.onAdClicked(widget.placementId);

    if (_adData?.clickUrl != null) {
      // Handle click URL opening
      // In a real implementation, you would use url_launcher
      print('Opening URL: ${_adData!.clickUrl}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Loading native ad...'),
                  ],
                ),
              )
            : _hasError
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage ?? 'Native ad failed to load',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadNativeAd,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _adData != null
            ? _buildNativeAdContent()
            : const Center(child: Text('No ad data available')),
      ),
    );
  }

  Widget _buildNativeAdContent() {
    final style = widget.style ?? NativeAdStyle.defaultStyle();
    final adData = _adData!;

    return GestureDetector(
      onTap: _onAdClicked,
      child: Container(
        decoration: BoxDecoration(
          color: style.backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and advertiser
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Advertiser icon
                  if (adData.iconUrl != null)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: NetworkImage(adData.iconUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Advertiser name
                  Expanded(
                    child: Text(
                      adData.advertiser ?? 'Sponsored',
                      style: TextStyle(
                        fontSize: 12,
                        color: style.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Ad indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: style.accentColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Ad',
                      style: TextStyle(
                        fontSize: 10,
                        color: style.accentTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Text content
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Title
                          Text(
                            adData.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: style.primaryTextColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Description
                          Text(
                            adData.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: style.secondaryTextColor,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Rating and price row
                          Row(
                            children: [
                              if (adData.rating != null) ...[
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: style.accentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  adData.rating!.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: style.secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (adData.price != null)
                                Text(
                                  adData.price!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: style.accentColor,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Image
                    if (adData.imageUrl != null)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(adData.imageUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Call to action button
            if (adData.callToAction != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                child: ElevatedButton(
                  onPressed: _onAdClicked,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: style.accentColor,
                    foregroundColor: style.accentTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    adData.callToAction!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Native ad data structure
class NativeAdData {
  final String title;
  final String description;
  final String? imageUrl;
  final String? iconUrl;
  final String? callToAction;
  final String? clickUrl;
  final String? advertiser;
  final double? rating;
  final String? price;
  final String? store;

  NativeAdData({
    required this.title,
    required this.description,
    this.imageUrl,
    this.iconUrl,
    this.callToAction,
    this.clickUrl,
    this.advertiser,
    this.rating,
    this.price,
    this.store,
  });

  factory NativeAdData.fromJson(Map<String, dynamic> json) {
    return NativeAdData(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      iconUrl: json['iconUrl'],
      callToAction: json['callToAction'],
      clickUrl: json['clickUrl'],
      advertiser: json['advertiser'],
      rating: json['rating']?.toDouble(),
      price: json['price'],
      store: json['store'],
    );
  }
}

/// Native ad style configuration
class NativeAdStyle {
  final Color backgroundColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final Color accentTextColor;

  const NativeAdStyle({
    required this.backgroundColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.accentTextColor,
  });

  factory NativeAdStyle.defaultStyle() {
    return const NativeAdStyle(
      backgroundColor: Colors.white,
      primaryTextColor: Colors.black87,
      secondaryTextColor: Colors.grey,
      accentColor: Colors.blue,
      accentTextColor: Colors.white,
    );
  }

  factory NativeAdStyle.darkStyle() {
    return const NativeAdStyle(
      backgroundColor: Colors.black87,
      primaryTextColor: Colors.white,
      secondaryTextColor: Colors.grey,
      accentColor: Colors.blue,
      accentTextColor: Colors.white,
    );
  }

  factory NativeAdStyle.lightStyle() {
    return NativeAdStyle(
      backgroundColor: Colors.grey[50] ?? Colors.white,
      primaryTextColor: Colors.black87,
      secondaryTextColor: Colors.grey[600]!,
      accentColor: Colors.green,
      accentTextColor: Colors.white,
    );
  }
}
