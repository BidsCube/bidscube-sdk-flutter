import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/callbacks.dart';
import '../core/url_builder.dart';
import '../core/ad_type.dart';
import '../core/ad_position.dart';

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

  /// Base URL for ad requests
  final String baseUrl;

  /// Ad type for URL building
  final AdType adType;

  /// Ad position for URL building
  final AdPosition position;

  const WebViewImageAdView({
    Key? key,
    required this.placementId,
    this.callback,
    this.width = 320,
    this.height = 240,
    this.baseUrl = 'https://api.bidscube.com',
    this.adType = AdType.image,
    this.position = AdPosition.unknown,
  }) : super(key: key);

  @override
  State<WebViewImageAdView> createState() => _WebViewImageAdViewState();
}

class _WebViewImageAdViewState extends State<WebViewImageAdView> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _adClickUrl;

  @override
  void initState() {
    super.initState();
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
              _errorMessage = error.description;
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
      // First, request the actual ad data from the API
      final adData = await _requestAd();

      if (adData != null && adData['adm'] != null) {
        // Create HTML content with the actual ad data
        final htmlContent = _createAdHTML(adData);
        await _controller.loadHtmlString(htmlContent);
      } else {
        // Fallback: Use URL Builder to create a demo ad
        final htmlContent = await URLBuilder.buildWebViewURL(
          placementId: widget.placementId,
          adType: widget.adType,
          position: widget.position,
          baseURL: widget.baseUrl,
        );

        if (htmlContent != null) {
          await _controller.loadHtmlString(htmlContent);
        } else {
          // Final fallback: Show a simple demo ad
          final demoAd = _createDemoAdHTML();
          await _controller.loadHtmlString(demoAd);
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
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
        baseURL: widget.baseUrl,
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
            return json.decode(response.body);
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
      // For demo purposes, return mock data
      return {
        'adm':
            'https://via.placeholder.com/320x240/4CAF50/FFFFFF?text=Image+Ad',
        'clickUrl': 'https://example.com',
        'title': 'Sample Ad',
        'description': 'This is a sample image ad',
      };
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

  String _createDemoAdHTML() {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body {
                margin: 0;
                padding: 0;
                width: 100%;
                height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                font-family: Arial, sans-serif;
            }
            .ad-container {
                width: 100%;
                height: 100%;
                position: relative;
                cursor: pointer;
                border-radius: 8px;
                overflow: hidden;
                box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            }
            .ad-image {
                width: 100%;
                height: 100%;
                object-fit: cover;
                transition: transform 0.3s ease;
            }
            .ad-overlay {
                position: absolute;
                bottom: 0;
                left: 0;
                right: 0;
                background: linear-gradient(transparent, rgba(0,0,0,0.7));
                color: white;
                padding: 20px;
                text-align: center;
            }
            .ad-title {
                font-size: 18px;
                font-weight: bold;
                margin-bottom: 5px;
            }
            .ad-description {
                font-size: 14px;
                opacity: 0.9;
            }
            .ad-container:hover .ad-image {
                transform: scale(1.05);
            }
        </style>
    </head>
    <body>
        <div class="ad-container" onclick="handleAdClick()">
            <img src="https://via.placeholder.com/320x240/4CAF50/FFFFFF?text=Demo+Ad" 
                 alt="Demo Ad" 
                 class="ad-image">
            <div class="ad-overlay">
                <div class="ad-title">Demo Advertisement</div>
                <div class="ad-description">This is a demo ad for testing</div>
            </div>
        </div>
        
        <script>
            function handleAdClick() {
                // Notify Flutter about the click
                if (window.flutter_inappwebview) {
                    window.flutter_inappwebview.callHandler('onAdClick', {
                        placementId: '${widget.placementId}'
                    });
                }
                
                // Open demo URL
                window.open('https://example.com', '_blank');
            }
        </script>
    </body>
    </html>
    ''';
  }

  void _handleAdClick() {
    widget.callback?.onAdClicked(widget.placementId);
    if (_adClickUrl != null) {
      // Handle click URL opening
      _controller.loadRequest(Uri.parse(_adClickUrl!));
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
                    Text('Loading ad...'),
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
                      _errorMessage ?? 'Ad failed to load',
                      style: const TextStyle(color: Colors.red),
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
