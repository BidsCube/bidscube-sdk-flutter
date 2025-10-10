import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// WebView-based Image Ad View Widget
/// Renders image ads using WebView without native code dependencies
class WebViewImageAdView extends StatefulWidget {
  /// Placement ID for the ad
  final String placementId;

  /// Ad callback handler
  final AdCallback? callback;

  /// Ad width
  final double width;

  /// Ad height
  final double height;

  /// Ad type for URL building
  final AdType adType;

  /// Ad position for URL building
  final AdPosition position;

  /// Position change callback
  final Function(AdPosition)? onPositionChanged;

  const WebViewImageAdView({
    super.key,
    required this.placementId,
    this.callback,
    this.width = 320,
    this.height = 240,
    this.adType = AdType.image,
    this.position = AdPosition.unknown,
    this.onPositionChanged,
  });

  @override
  State<WebViewImageAdView> createState() => _WebViewImageAdViewState();
}

class _WebViewImageAdViewState extends State<WebViewImageAdView> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _adClickUrl;
  AdPosition _currentPosition = AdPosition.unknown;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.position;
    _initializeWebView();
    _loadAd();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            widget.callback?.onAdLoaded(widget.placementId);
            widget.callback?.onAdDisplayed(widget.placementId);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
            widget.callback?.onAdFailed(
              widget.placementId,
              'WEBVIEW_ERROR',
              error.description,
            );
          },
        ),
      );
  }

  Future<void> _loadAd() async {
    widget.callback?.onAdLoading(widget.placementId);

    try {
      // Request the actual ad data from the API
      final adData = await _requestAd();

      if (adData != null && adData['adm'] != null) {
        // Create HTML content with the actual ad data
        final htmlContent = _createAdHTML(adData);
        await _controller.loadHtmlString(htmlContent);
      } else {
        // No ad available - show error placeholder
        throw Exception('Ad not loaded or placement ID does not exist');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      widget.callback?.onAdFailed(
        widget.placementId,
        'LOAD_ERROR',
        e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>?> _requestAd() async {
    try {
      // Build the proper API URL using URL Builder
      final apiURL = await URLBuilder.buildAdRequestURL(
        placementId: widget.placementId,
        adType: widget.adType,
        position: widget.position,
      );

      if (apiURL == null) {
        throw Exception('Failed to build API URL');
      }

      final response = await http.get(Uri.parse(apiURL));

      if (response.statusCode == 200) {
        // Check if response is JSON
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('application/json')) {
          try {
            final data = json.decode(response.body);

            // Extract position from server response if available
            if (data['position'] != null) {
              final positionValue = data['position'] as int;
              final serverPosition = AdPositionExtension.fromValue(
                positionValue,
              );
              SDKLogger.info('Position: ${serverPosition.value}');

              // Update current position and trigger re-render
              if (mounted) {
                setState(() {
                  _currentPosition = serverPosition;
                });
              }

              // Notify parent widget about position change
              widget.onPositionChanged?.call(serverPosition);
            }

            return data;
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
        throw Exception('Failed to load ad: ${response.statusCode}');
      }
    } catch (e) {
      SDKLogger.error('Failed to load ad', e);
      // Re-throw the error instead of returning mock data
      rethrow;
    }
  }

  String _createAdHTML(Map<String, dynamic> adData) {
    final adm = adData['adm'] as String? ?? '';
    final clickUrl = adData['clickUrl'] as String? ?? '';
    final title = adData['title'] as String? ?? 'Advertisement';
    final description = adData['description'] as String? ?? '';

    // Check if adm contains HTML content (has HTML tags)
    final hasHtmlTags = adm.contains('<') && adm.contains('>');
    final hasDoctype = adm.toLowerCase().contains('<!doctype');

    if (hasHtmlTags && !hasDoctype) {
      // adm contains HTML without DOCTYPE, wrap it in a basic HTML structure
      return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ad Display</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f5f5f5;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .ad-wrapper {
            display: flex;
            justify-content: center;
            align-items: center;
            width: 100%;
            height: 100vh;
        }
    </style>
</head>
<body>
    <div class="ad-wrapper">
        $adm
    </div>
    <script>
        // Handle clicks
        document.addEventListener('click', function(e) {
            if (e.target.tagName === 'A' && e.target.href) {
                e.preventDefault();
                window.open(e.target.href, '_blank');
            }
        });
    </script>
</body>
</html>
      ''';
    } else if (hasDoctype) {
      // adm already contains full HTML with DOCTYPE, use it directly
      return adm;
    } else {
      // adm is just an image URL or plain text, create full HTML structure
      return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ad Display</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f5f5f5;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .ad-container {
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
            max-width: 100%;
            width: 100%;
        }
        .ad-image {
            width: 100%;
            height: auto;
            display: block;
        }
        .ad-content {
            padding: 16px;
        }
        .ad-title {
            font-size: 18px;
            font-weight: 600;
            color: #333;
            margin: 0 0 8px 0;
        }
        .ad-description {
            font-size: 14px;
            color: #666;
            margin: 0 0 12px 0;
            line-height: 1.4;
        }
        .ad-cta {
            background: #007AFF;
            color: white;
            padding: 8px 16px;
            border-radius: 6px;
            text-decoration: none;
            display: inline-block;
            font-size: 14px;
            font-weight: 500;
        }
        .ad-cta:hover {
            background: #0056CC;
        }
        .ad-label {
            position: absolute;
            top: 8px;
            right: 8px;
            background: rgba(0,0,0,0.7);
            color: white;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="ad-container">
        <div class="ad-label">Ad</div>
        ${adm.isNotEmpty ? '<img src="$adm" alt="Advertisement" class="ad-image" />' : ''}
        <div class="ad-content">
            <h3 class="ad-title">$title</h3>
            ${description.isNotEmpty ? '<p class="ad-description">$description</p>' : ''}
            ${clickUrl.isNotEmpty ? '<a href="$clickUrl" class="ad-cta" target="_blank">Learn More</a>' : ''}
        </div>
    </div>
    <script>
        // Handle clicks
        document.addEventListener('click', function(e) {
            if (e.target.tagName === 'A' && e.target.href) {
                e.preventDefault();
                window.open(e.target.href, '_blank');
            }
        });
    </script>
</body>
</html>
      ''';
    }
  }

  void _handleAdClick() {
    widget.callback?.onAdClicked(widget.placementId);
    if (_adClickUrl != null) {
      // Handle click URL opening
      _controller.loadRequest(Uri.parse(_adClickUrl!));
    }
  }

  BidscubePositionStyle _getPositionBasedStyle() {
    switch (_currentPosition) {
      case AdPosition.unknown:
        return BidscubePositionStyle(
          backgroundColor: Colors.white,
          borderRadius: 8.0,
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        );
      case AdPosition.aboveTheFold:
        return BidscubePositionStyle(
          backgroundColor: Colors.blue[50]!,
          borderRadius: 12.0,
          border: Border.all(color: Colors.blue[200]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withAlpha(51),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case AdPosition.belowTheFold:
        return BidscubePositionStyle(
          backgroundColor: Colors.green[50]!,
          borderRadius: 10.0,
          border: Border.all(color: Colors.green[200]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withAlpha(51),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        );
      case AdPosition.header:
        return BidscubePositionStyle(
          backgroundColor: Colors.orange[50]!,
          borderRadius: 6.0,
          border: Border.all(color: Colors.orange[200]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withAlpha(51),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        );
      case AdPosition.footer:
        return BidscubePositionStyle(
          backgroundColor: Colors.purple[50]!,
          borderRadius: 6.0,
          border: Border.all(color: Colors.purple[200]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withAlpha(51),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        );
      case AdPosition.sidebar:
        return BidscubePositionStyle(
          backgroundColor: Colors.teal[50]!,
          borderRadius: 8.0,
          border: Border.all(color: Colors.teal[200]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withAlpha(51),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        );
      case AdPosition.fullScreen:
        return BidscubePositionStyle(
          backgroundColor: Colors.red[50]!,
          borderRadius: 16.0,
          border: Border.all(color: Colors.red[200]!, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withAlpha(77),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        );
      case AdPosition.dependOnTheScreenSize:
        return BidscubePositionStyle(
          backgroundColor: Colors.amber[50]!,
          borderRadius: 10.0,
          border: Border.all(color: Colors.amber[200]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withAlpha(51),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final positionStyle = _getPositionBasedStyle();

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: positionStyle.backgroundColor,
        border: positionStyle.border,
        borderRadius: BorderRadius.circular(positionStyle.borderRadius),
        boxShadow: positionStyle.boxShadow,
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
                    Text('Loading ad...'),
                  ],
                ),
              )
            : _hasError
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, color: Colors.grey, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'Ad not loaded or placement ID does not exist',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadAd,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : GestureDetector(
                onTap: _handleAdClick,
                child: WebViewWidget(controller: _controller),
              ),
      ),
    );
  }
}
