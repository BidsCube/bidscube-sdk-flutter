import 'package:flutter/material.dart';
import '../core/callbacks.dart';

/// Banner Ad View Widget
class BannerAdView extends StatefulWidget {
  /// Placement ID for the ad
  final String placementId;
  
  /// Ad callback handler
  final AdCallback? callback;
  
  /// Ad width
  final double width;
  
  /// Ad height
  final double height;

  const BannerAdView({
    Key? key,
    required this.placementId,
    this.callback,
    this.width = 320,
    this.height = 50,
  }) : super(key: key);

  @override
  State<BannerAdView> createState() => _BannerAdViewState();
}

class _BannerAdViewState extends State<BannerAdView> {
  bool _isLoading = true;
  bool _hasError = false;
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
        borderRadius: BorderRadius.circular(4),
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
                    color: Colors.blue[100],
                    child: const Center(
                      child: Text(
                        'Banner Ad',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
