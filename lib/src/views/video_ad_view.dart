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
    Key? key,
    required this.placementId,
    this.callback,
    this.width = 320,
    this.height = 240,
  }) : super(key: key);

  @override
  State<VideoAdView> createState() => _VideoAdViewState();
}

class _VideoAdViewState extends State<VideoAdView> {
  bool _isLoading = true;
  bool _hasError = false;
  bool _isPlaying = false;
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

  void _playVideo() {
    setState(() {
      _isPlaying = true;
    });
    widget.callback?.onVideoAdStarted(widget.placementId);
    
    // Simulate video completion
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        widget.callback?.onVideoAdCompleted(widget.placementId);
      }
    });
  }

  void _skipVideo() {
    widget.callback?.onVideoAdSkipped(widget.placementId);
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
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isPlaying ? Icons.play_circle : Icons.video_library,
                                size: 48,
                                color: Colors.purple,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isPlaying ? 'Playing Video Ad' : 'Video Ad',
                                style: const TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isPlaying)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.play_arrow),
                                  onPressed: _playVideo,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.skip_next),
                                  onPressed: _skipVideo,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
