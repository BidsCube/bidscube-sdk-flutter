import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:interactive_media_ads/interactive_media_ads.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

/// IMA VAST Video Ad View Widget
/// Uses Google's Interactive Media Ads SDK for proper VAST video ad handling
class ImaVastVideoAdView extends StatefulWidget {
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

  /// Ad type
  final AdType adType;

  /// Ad position
  final AdPosition position;

  const ImaVastVideoAdView({
    Key? key,
    required this.placementId,
    this.callback,
    this.width = 320,
    this.height = 240,
    this.baseUrl = Constants.baseURL,
    this.adType = AdType.video,
    this.position = AdPosition.unknown,
  }) : super(key: key);

  @override
  State<ImaVastVideoAdView> createState() => _ImaVastVideoAdViewState();
}

class _ImaVastVideoAdViewState extends State<ImaVastVideoAdView>
    with WidgetsBindingObserver {
  // IMA SDK components
  late final AdDisplayContainer _adDisplayContainer;
  AdsLoader? _adsLoader;
  AdsManager? _adsManager;

  // Content video player
  VideoPlayerController? _contentVideoController;
  bool _shouldShowContentVideo = false;
  Timer? _contentProgressTimer;

  // State management
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _vastXml;

  // Content progress provider for mid-roll ads
  final ContentProgressProvider _contentProgressProvider =
      ContentProgressProvider();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAdContainer();
    _loadVastAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _contentProgressTimer?.cancel();
    _contentVideoController?.dispose();
    _adsManager?.destroy();
    super.dispose();
  }

  void _initializeAdContainer() {
    _adDisplayContainer = AdDisplayContainer(
      onContainerAdded: (AdDisplayContainer container) {
        _adsLoader = AdsLoader(
          container: container,
          onAdsLoaded: (OnAdsLoadedData data) {
            final AdsManager manager = data.manager;
            _adsManager = data.manager;

            manager.setAdsManagerDelegate(
              AdsManagerDelegate(
                onAdEvent: (AdEvent event) {
                  SDKLogger.info(
                    'IMA AdEvent: ${event.type} => ${event.adData}',
                  );
                  widget.callback?.onAdLoaded(widget.placementId);

                  switch (event.type) {
                    case AdEventType.loaded:
                      manager.start();
                      widget.callback?.onAdDisplayed(widget.placementId);
                    case AdEventType.contentPauseRequested:
                      _pauseContent();
                    case AdEventType.contentResumeRequested:
                      _resumeContent();
                    case AdEventType.allAdsCompleted:
                      manager.destroy();
                      _adsManager = null;
                      widget.callback?.onVideoAdCompleted(widget.placementId);
                    case AdEventType.clicked:
                      widget.callback?.onAdClicked(widget.placementId);
                    case AdEventType.complete:
                      widget.callback?.onVideoAdCompleted(widget.placementId);
                    case _:
                  }
                },
                onAdErrorEvent: (AdErrorEvent event) {
                  SDKLogger.error(
                    'IMA AdErrorEvent: ${event.error.message}',
                    null,
                  );
                  widget.callback?.onAdFailed(
                    widget.placementId,
                    'IMA_ERROR',
                    event.error.message ?? 'Unknown IMA error',
                  );
                  _resumeContent();
                },
              ),
            );

            manager.init(
              settings: AdsRenderingSettings(enablePreloading: true),
            );
          },
          onAdsLoadError: (AdsLoadErrorData data) {
            SDKLogger.error('IMA AdsLoadError: ${data.error.message}', null);
            widget.callback?.onAdFailed(
              widget.placementId,
              'IMA_LOAD_ERROR',
              data.error.message ?? 'Unknown IMA load error',
            );
            _resumeContent();
          },
        );

        // Request ads once container is ready
        if (_vastXml != null) {
          _requestAds(container);
        }
      },
    );
  }

  Future<void> _loadVastAd() async {
    widget.callback?.onAdLoading(widget.placementId);

    try {
      // For IMA SDK, we need a URL that returns VAST XML, not the XML content itself
      // Use a sample VAST URL for demo purposes
      _vastXml =
          'https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/vmap_ad_samples&sz=640x480&cust_params=sample_ar%3Dpremidpost&ciu_szs=300x250&gdfp_req=1&ad_rule=1&output=vmap&unviewed_position_start=1&env=vp&impl=s&cmsid=496&vid=short_onecue&correlator=';
      SDKLogger.info('Using sample VAST URL for IMA SDK');

      setState(() {
        _isLoading = false;
      });

      // Initialize content video
      await _initializeContentVideo();
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

  Future<void> _initializeContentVideo() async {
    _contentVideoController = VideoPlayerController.networkUrl(
      Uri.parse(
        'https://storage.googleapis.com/gvabox/media/samples/stock.mp4',
      ),
    );

    await _contentVideoController!.initialize();
    _contentVideoController!.addListener(() {
      if (_contentVideoController!.value.isCompleted) {
        _adsLoader?.contentComplete();
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _requestAds(AdDisplayContainer container) async {
    if (_vastXml == null) return;

    try {
      await _adsLoader?.requestAds(
        AdsRequest(
          adTagUrl: _vastXml!,
          contentProgressProvider: _contentProgressProvider,
        ),
      );
    } catch (e) {
      SDKLogger.error('Failed to request ads', e);
      widget.callback?.onAdFailed(
        widget.placementId,
        'REQUEST_ERROR',
        e.toString(),
      );
    }
  }

  Future<void> _resumeContent() async {
    setState(() {
      _shouldShowContentVideo = true;
    });

    if (_adsManager != null) {
      _contentProgressTimer = Timer.periodic(
        const Duration(milliseconds: 200),
        (Timer timer) async {
          if (_contentVideoController?.value.isInitialized == true) {
            final Duration? progress = await _contentVideoController!.position;
            if (progress != null) {
              await _contentProgressProvider.setProgress(
                progress: progress,
                duration: _contentVideoController!.value.duration,
              );
            }
          }
        },
      );
    }

    await _contentVideoController?.play();
  }

  Future<void> _pauseContent() {
    setState(() {
      _shouldShowContentVideo = false;
    });
    _contentProgressTimer?.cancel();
    _contentProgressTimer = null;
    return _contentVideoController?.pause() ?? Future.value();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                'Ad Error',
                style: TextStyle(
                  color: Colors.red[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: <Widget>[
            // The display container must be on screen before any Ads can be loaded
            _adDisplayContainer,
            if (_shouldShowContentVideo &&
                _contentVideoController?.value.isInitialized == true)
              VideoPlayer(_contentVideoController!),
          ],
        ),
      ),
    );
  }
}
