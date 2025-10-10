import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import '../core/callbacks.dart';
import '../core/vast_parser.dart';
import '../core/url_builder.dart';
import '../core/ad_type.dart';
import '../core/ad_position.dart';
import '../core/logger.dart';

/// VAST Video Ad View Widget
/// Handles VAST video ads without native code dependencies
class VastVideoAdView extends StatefulWidget {
  /// Placement ID for the ad
  final String placementId;

  /// Ad callback handler
  final AdCallback? callback;

  /// Ad width
  final double width;

  /// Ad height
  final double height;

  /// Ad type
  final AdType adType;

  /// Ad position
  final AdPosition position;

  const VastVideoAdView({
    super.key,
    required this.placementId,
    this.callback,
    this.width = 320,
    this.height = 240,
    this.adType = AdType.video,
    this.position = AdPosition.unknown,
  });

  @override
  State<VastVideoAdView> createState() => _VastVideoAdViewState();
}

class _VastVideoAdViewState extends State<VastVideoAdView> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  VastAd? _vastAd;
  final int _currentMediaFileIndex = 0;
  bool _isPlaying = false;
  bool _isCompleted = false;
  bool _isSkipped = false;

  @override
  void initState() {
    super.initState();
    _loadVastAd();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadVastAd() async {
    widget.callback?.onAdLoading(widget.placementId);

    try {
      // Request VAST XML from Bidscube API
      final vastXml = await _requestVastXml();

      if (vastXml != null) {
        // Parse VAST XML
        _vastAd = await VastParser.parseVast(vastXml);

        if (_vastAd != null && _vastAd!.creatives.isNotEmpty) {
          final linearCreative = _vastAd!.creatives
              .whereType<VastLinearCreative>()
              .firstOrNull;

          if (linearCreative != null && linearCreative.mediaFiles.isNotEmpty) {
            await _initializeVideoPlayer(linearCreative);
          } else {
            throw Exception('No linear creative found in VAST');
          }
        } else {
          throw Exception('No creatives found in VAST');
        }
      } else {
        throw Exception('No VAST XML received');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
      widget.callback?.onAdFailed(
        widget.placementId,
        'VAST_LOAD_ERROR',
        e.toString(),
      );
    }
  }

  Future<String?> _requestVastXml() async {
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

      final response = await http.get(
        Uri.parse(apiURL),
        headers: {
          'Content-Type': 'application/xml',
          'User-Agent': 'BidscubeSDK-Flutter/1.0.0',
        },
      );

      if (response.statusCode == 200) {
        // Check if response is XML
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('application/xml') ||
            contentType.contains('text/xml') ||
            response.body.trim().startsWith('<?xml')) {
          return response.body;
        } else {
          // Server returned HTML instead of XML (likely 404 page)
          throw Exception(
            'Server returned HTML instead of XML. Content-Type: $contentType',
          );
        }
      } else {
        throw Exception('Failed to load VAST: ${response.statusCode}');
      }
    } catch (e) {
      // For demo purposes, return mock VAST XML
      return _getMockVastXml();
    }
  }

  String _getMockVastXml() {
    return '''
    <?xml version="1.0" encoding="UTF-8"?>
    <VAST version="3.0">
      <Ad id="1">
        <InLine>
          <AdSystem>BidsCube</AdSystem>
          <AdTitle>Sample Video Ad</AdTitle>
          <Description>This is a sample video ad</Description>
          <Creative>
            <Linear>
              <Duration>00:00:15</Duration>
              <MediaFiles>
                <MediaFile type="video/mp4" delivery="progressive" width="320" height="240">
                  https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4
                </MediaFile>
              </MediaFiles>
              <TrackingEvents>
                <Tracking event="start">https://example.com/track/start</Tracking>
                <Tracking event="firstQuartile">https://example.com/track/firstQuartile</Tracking>
                <Tracking event="midpoint">https://example.com/track/midpoint</Tracking>
                <Tracking event="thirdQuartile">https://example.com/track/thirdQuartile</Tracking>
                <Tracking event="complete">https://example.com/track/complete</Tracking>
              </TrackingEvents>
              <VideoClicks>
                <ClickThrough>https://example.com/click</ClickThrough>
                <ClickTracking>https://example.com/track/click</ClickTracking>
              </VideoClicks>
            </Linear>
          </Creative>
        </InLine>
      </Ad>
    </VAST>
    ''';
  }

  Future<void> _initializeVideoPlayer(VastLinearCreative linearCreative) async {
    try {
      final mediaFile = linearCreative.mediaFiles[_currentMediaFileIndex];

      _controller = VideoPlayerController.networkUrl(Uri.parse(mediaFile.url));

      await _controller!.initialize();

      _controller!.addListener(_onVideoPlayerUpdate);

      setState(() {
        _isLoading = false;
      });

      widget.callback?.onAdLoaded(widget.placementId);
      widget.callback?.onAdDisplayed(widget.placementId);

      // Start playing automatically
      await _playVideo();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
      widget.callback?.onAdFailed(
        widget.placementId,
        'VIDEO_INIT_ERROR',
        e.toString(),
      );
    }
  }

  void _onVideoPlayerUpdate() {
    if (_controller == null) return;

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    if (duration.inMilliseconds > 0) {
      final progress = position.inMilliseconds / duration.inMilliseconds;

      // Track VAST events based on progress
      _trackVastEvents(progress);
    }

    // Check if video completed
    if (_controller!.value.position >= _controller!.value.duration &&
        !_isCompleted &&
        _controller!.value.duration.inMilliseconds > 0) {
      _onVideoCompleted();
    }
  }

  void _trackVastEvents(double progress) {
    if (_vastAd == null) return;

    final linearCreative = _vastAd!.creatives
        .whereType<VastLinearCreative>()
        .firstOrNull;

    if (linearCreative == null) return;

    // Track events based on progress
    if (progress >= 0.0 && progress < 0.25) {
      _trackEvent('start', linearCreative);
    } else if (progress >= 0.25 && progress < 0.5) {
      _trackEvent('firstQuartile', linearCreative);
    } else if (progress >= 0.5 && progress < 0.75) {
      _trackEvent('midpoint', linearCreative);
    } else if (progress >= 0.75 && progress < 1.0) {
      _trackEvent('thirdQuartile', linearCreative);
    }
  }

  void _trackEvent(String event, VastLinearCreative linearCreative) {
    final trackingEvents = linearCreative.trackingEvents
        .where((tracking) => tracking.event == event)
        .toList();

    for (final tracking in trackingEvents) {
      // Send tracking request
      http.get(Uri.parse(tracking.url)).catchError((e) {
        // Ignore tracking errors
        return http.Response('', 500);
      });
    }
  }

  Future<void> _playVideo() async {
    if (_controller != null && !_isPlaying) {
      await _controller!.play();
      setState(() {
        _isPlaying = true;
      });
      widget.callback?.onVideoAdStarted(widget.placementId);
    }
  }

  Future<void> _pauseVideo() async {
    if (_controller != null && _isPlaying) {
      await _controller!.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _onVideoCompleted() {
    setState(() {
      _isCompleted = true;
      _isPlaying = false;
    });

    // Track completion event
    if (_vastAd != null) {
      final linearCreative = _vastAd!.creatives
          .whereType<VastLinearCreative>()
          .firstOrNull;

      if (linearCreative != null) {
        _trackEvent('complete', linearCreative);
      }
    }

    widget.callback?.onVideoAdCompleted(widget.placementId);
  }

  void _onVideoSkipped() {
    setState(() {
      _isSkipped = true;
      _isPlaying = false;
    });

    widget.callback?.onVideoAdSkipped(widget.placementId);
  }

  void _onAdClicked() {
    if (_vastAd != null) {
      final linearCreative = _vastAd!.creatives
          .whereType<VastLinearCreative>()
          .firstOrNull;

      if (linearCreative != null) {
        // Track click events
        for (final click in linearCreative.videoClicks) {
          if (click.type == 'ClickTracking') {
            http.get(Uri.parse(click.url)).catchError((e) {
              // Ignore tracking errors
              return http.Response('', 500);
            });
          } else if (click.type == 'ClickThrough') {
            // Handle click-through URL
            // In a real implementation, you would open the URL
            SDKLogger.info('Click-through URL: ${click.url}');
          }
        }
      }
    }

    widget.callback?.onAdClicked(widget.placementId);
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
                    Text('Loading video ad...'),
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
                      _errorMessage ?? 'Video ad failed to load',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadVastAd,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _controller != null && _controller!.value.isInitialized
            ? Stack(
                children: [
                  GestureDetector(
                    onTap: _onAdClicked,
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                  // Video controls overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(179),
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Play/Pause button
                          IconButton(
                            onPressed: _isPlaying ? _pauseVideo : _playVideo,
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                          ),
                          // Skip button (if not completed)
                          if (!_isCompleted && !_isSkipped)
                            IconButton(
                              onPressed: _onVideoSkipped,
                              icon: const Icon(
                                Icons.skip_next,
                                color: Colors.white,
                              ),
                            ),
                          // Progress indicator
                          Expanded(
                            child: VideoProgressIndicator(
                              _controller!,
                              allowScrubbing: false,
                              colors: const VideoProgressColors(
                                playedColor: Colors.white,
                                backgroundColor: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : const Center(child: Text('Video player not initialized')),
      ),
    );
  }
}
