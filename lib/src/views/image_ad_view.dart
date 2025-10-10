import 'package:flutter/material.dart';
import '../core/callbacks.dart';

/// Image Ad View Widget
class ImageAdView extends StatefulWidget {
  /// Placement ID for the ad
  final String placementId;

  /// Ad callback handler
  final AdCallback? callback;

  /// Ad width
  final double width;

  /// Ad height
  final double height;

  const ImageAdView({
    super.key,
    required this.placementId,
    this.callback,
    this.width = 320,
    this.height = 240,
  });

  @override
  State<ImageAdView> createState() => _ImageAdViewState();
}

class _ImageAdViewState extends State<ImageAdView> {
  bool _isLoading = true;
  final bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    widget.callback?.onAdLoading(widget.placementId);

    // Simulate ad loading
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        widget.callback?.onAdLoaded(widget.placementId);
        widget.callback?.onAdDisplayed(widget.placementId);
      }
    });
  }

  void _handleAdClick() {
    widget.callback?.onAdClicked(widget.placementId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(
              child: Text(
                _errorMessage ?? 'Ad failed to load',
                style: const TextStyle(color: Colors.red),
              ),
            )
          : GestureDetector(
              onTap: _handleAdClick,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 48, color: Colors.green),
                      SizedBox(height: 8),
                      Text(
                        'Image Ad',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
