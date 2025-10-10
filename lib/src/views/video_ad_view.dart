import 'package:flutter/material.dart';
import '../core/callbacks.dart';

/// Video Ad View Widget
class VideoAdView extends StatefulWidget {
  /// Placement ID for the ad
  final String placementId;

  /// Ad callback handler
  final AdCallback? callback;

  /// Ad width
  final double width;

  /// Ad height
  final double height;

  const VideoAdView({
    super.key,
    required this.placementId,
    this.callback,
    this.width = 320,
    this.height = 240,
  });

  @override
  State<VideoAdView> createState() => _VideoAdViewState();
}

class _VideoAdViewState extends State<VideoAdView> {
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

    // Simulate ad loading failure to show error placeholder
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Ad not loaded or placement ID does not exist';
        });
        widget.callback?.onAdFailed(
          widget.placementId,
          'LOAD_ERROR',
          'Ad not loaded or placement ID does not exist',
        );
      }
    });
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, color: Colors.grey, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ??
                        'Ad not loaded or placement ID does not exist',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : const Center(child: Text('No ad content available')),
    );
  }
}
