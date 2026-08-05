import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:interactive_media_ads/interactive_media_ads.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:async';

import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'video_ad_overlay_controls.dart';
import '../core/companion_tracking.dart';
import '../core/video_ad_session_controller.dart';
import '../core/video_ad_request_loader.dart';

/// Flutter-only VAST playback via Google's IMA package.
///
/// Reward is granted **only** on [VideoAdFormat.rewarded] + [AdEventType.complete].
class ImaVastVideoAdView extends StatefulWidget {
  final String placementId;
  final AdCallback? callback;
  final double width;
  final double height;
  final String baseUrl;
  final AdType adType;
  final AdPosition position;
  final double? borderRadius;

  /// Distinguishes interstitial-style vs rewarded completions.
  final VideoAdFormat videoAdFormat;

  /// When set, bypasses the ad server and feeds this XML directly to IMA.
  /// Intended for QA / test mode only.
  final String? vastXmlOverride;

  /// Called when the user closes the interstitial (X button).
  final VoidCallback? onDismiss;

  const ImaVastVideoAdView({
    super.key,
    required this.placementId,
    this.callback,
    this.width = 320,
    this.height = 240,
    this.baseUrl = Constants.baseURL,
    this.adType = AdType.video,
    this.videoAdFormat = VideoAdFormat.interstitial,
    this.position = AdPosition.unknown,
    this.borderRadius,
    this.vastXmlOverride,
    this.onDismiss,
  });

  @override
  State<ImaVastVideoAdView> createState() => _ImaVastVideoAdViewState();
}

class _ImaVastVideoAdViewState extends State<ImaVastVideoAdView>
    with WidgetsBindingObserver {
  late final AdDisplayContainer _adDisplayContainer;
  AdsLoader? _adsLoader;
  AdsManager? _adsManager;

  VideoPlayerController? _contentVideoController;
  bool _shouldShowContentVideo = false;
  Timer? _contentProgressTimer;

  bool _isLoading = true;
  bool _hasError = false;
  AdPosition _currentPosition = AdPosition.unknown;

  final ContentProgressProvider _contentProgressProvider =
      ContentProgressProvider();

  // Parsed VAST metadata (companion is optional).
  VastCompanionCreative? _companion;
  String? _previewImageUrl;
  String? _endCardClickUrl;
  String _adTitle = '';
  int? _skipOffsetSeconds = Constants.defaultSkipOffsetSeconds;
  bool _hasNonLinearPostVideo = false;

  late VideoAdSessionController _session;
  final CompanionTracking _companionTracking = CompanionTracking();
  final VideoAdRequestLoader _videoAdRequestLoader = VideoAdRequestLoader();

  // End card + skip overlay state.
  bool _showEndCard = false;
  bool _showManualCloseButton = false;
  bool _skipAvailable = false;
  int _skipCountdown = 0;
  Timer? _skipCountdownTimer;
  DateTime? _videoStartedAt;

  // -------- Idempotent lifecycle flags --------
  bool _hasLoaded = false;
  bool _hasDisplayed = false;
  bool _hasStarted = false;
  bool _hasCompleted = false;
  bool _hasSkipped = false;
  bool _hasClosed = false;
  bool _hasRewarded = false;
  bool _hasFailedOrAbortedFlow = false;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = _createSession(hasCompanion: false);
    _initializeAdContainer();
    _loadVastAd();
  }

  bool get _autoClose => BidscubeSDK.config?.autoClose ?? false;

  VideoAdSessionController _createSession({required bool hasCompanion}) {
    return VideoAdSessionController(
      autoClose: _autoClose,
      isRewarded: _isRewarded,
      hasCompanion: hasCompanion,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _contentProgressTimer?.cancel();
    _skipCountdownTimer?.cancel();
    _contentVideoController?.dispose();

    if (!_hasClosed) {
      if (_hasStarted &&
          !_hasCompleted &&
          !_hasSkipped &&
          !_hasFailedOrAbortedFlow) {
        _notifySkipped();
      }
      _closeAdSession(syncSession: false);
    } else {
      _adsManager?.destroy();
    }
    super.dispose();
  }

  bool get _isRewarded => widget.videoAdFormat == VideoAdFormat.rewarded;

  void _notifyLoaded() {
    if (_hasLoaded) return;
    _hasLoaded = true;
    widget.callback?.onAdLoaded(widget.placementId);
  }

  void _notifyDisplayed() {
    if (_hasDisplayed) return;
    _hasDisplayed = true;
    widget.callback?.onAdDisplayed(widget.placementId);
  }

  void _notifyStarted() {
    if (_hasStarted) return;
    _hasStarted = true;
    _videoStartedAt = DateTime.now();
    _startSkipCountdown();
    widget.callback?.onVideoAdStarted(widget.placementId);
  }

  void _notifyCompleted() {
    if (_hasCompleted) return;
    _hasCompleted = true;
    widget.callback?.onVideoAdCompleted(widget.placementId);

    if (_isRewarded) {
      _notifyRewarded();
    }
  }

  void _notifyRewarded() {
    if (!_isRewarded || _hasRewarded || !_hasCompleted) return;
    _hasRewarded = true;
    widget.callback?.onUserRewarded(widget.placementId);
  }

  void _notifySkipped() {
    if (_hasSkipped) return;
    _hasSkipped = true;
    widget.callback?.onVideoAdSkipped(widget.placementId);
  }

  void _notifyClosed() {
    if (_hasClosed) return;
    _hasClosed = true;
    widget.callback?.onAdClosed(widget.placementId);
  }

  void _notifyFailed(String code, String message) {
    if (_hasFailedOrAbortedFlow) return;
    _hasFailedOrAbortedFlow = true;
    widget.callback?.onAdFailed(widget.placementId, code, message);
  }

  void _parseVastMetadata(String vastXml) {
    final parsed = VastParser.tryParse(vastXml);
    if (parsed == null) {
      return;
    }

    _adTitle = parsed.adTitle;
    _companion = parsed.preferredCompanion;
    _previewImageUrl = parsed.previewImageUrl;
    _endCardClickUrl = parsed.endCardClickUrl;
    _skipOffsetSeconds = parsed.skipOffsetSeconds;
    _hasNonLinearPostVideo = parsed.creatives.any(
      (creative) => creative is VastNonLinearCreative,
    );
    _session = _createSession(hasCompanion: parsed.hasCompanion);
    SDKLogger.info(
      'VAST metadata parsed: skipOffset=${_skipOffsetSeconds ?? 'none'}s, '
      'title=${_adTitle.isEmpty ? 'n/a' : _adTitle}, '
      'companion=${_companion?.resourceType.name ?? 'none'}, '
      'autoClose=$_autoClose',
    );
  }

  void _startSkipCountdown() {
    _skipCountdownTimer?.cancel();
    final offset = _skipOffsetSeconds ?? Constants.defaultSkipOffsetSeconds;
    if (offset <= 0) {
      return;
    }

    void tick() {
      if (!mounted || _showEndCard || _showManualCloseButton) {
        return;
      }

      final elapsed = _videoStartedAt == null
          ? 0
          : DateTime.now().difference(_videoStartedAt!).inSeconds;
      final remaining = offset - elapsed;

      setState(() {
        if (remaining <= 0) {
          _skipCountdown = 0;
          _skipAvailable = true;
        } else {
          _skipCountdown = remaining;
          _skipAvailable = false;
        }
      });
    }

    tick();
    _skipCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _showEndCard || _showManualCloseButton) {
        timer.cancel();
        return;
      }
      tick();
      if (_skipAvailable) {
        timer.cancel();
      }
    });
  }

  void _stopSkipCountdown() {
    _skipCountdownTimer?.cancel();
    _skipCountdownTimer = null;
  }

  void _releasePlayerResources() {
    _session.releasePlayer();
    final manager = _adsManager;
    if (manager == null) return;
    _adsManager = null;
    manager.destroy();
  }

  void _applyPostVideoUi() {
    if (!mounted || _hasClosed) return;
    _stopSkipCountdown();

    if (_session.closed) {
      _closeAdSession(syncSession: false);
      return;
    }

    setState(() {
      _showEndCard = _session.showEndCard;
      _showManualCloseButton = _session.showManualCloseButton;
    });

    if (_session.showEndCard) {
      _releasePlayerResources();
      unawaited(_companionTracking.fireViewTracking(_companion));
    }
  }

  void _onLinearVideoFinished({required bool skipped}) {
    if (skipped) {
      _session.onLinearVideoSkipped();
    } else {
      _session.onLinearVideoComplete(
        holdForInteractiveContent: _hasNonLinearPostVideo,
      );
    }
    _applyPostVideoUi();
  }

  Future<void> _handleEndCardClick() async {
    widget.callback?.onAdClicked(widget.placementId);
    await _companionTracking.fireClickTracking(_companion);
    final url = _endCardClickUrl;
    if (url == null || url.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _closeAdSession({bool syncSession = true}) {
    if (_hasClosed) return;
    if (syncSession) {
      _session.closeSession();
    }
    _stopSkipCountdown();
    _releasePlayerResources();
    _notifyClosed();
    if (mounted) {
      setState(() {
        _isDismissed = true;
        _showEndCard = false;
        _showManualCloseButton = false;
      });
    }
    widget.onDismiss?.call();
  }

  void _handleManualClose() {
    _closeAdSession();
  }

  Future<void> _handleSkipTap() async {
    if (!_skipAvailable || _hasSkipped) {
      return;
    }

    _stopSkipCountdown();
    SDKLogger.info('Skip tapped for placement ${widget.placementId}');

    try {
      await _adsManager?.skip();
    } catch (e) {
      SDKLogger.warning('IMA skip() failed, forcing skip flow: $e');
    }

    // Inline VAST via AdsRequest.withAdsResponse may not emit AdEventType.skipped.
    if (!_hasSkipped) {
      _forceSkip();
    }
  }

  void _forceSkip() {
    if (_hasSkipped) return;
    _notifySkipped();
    _onLinearVideoFinished(skipped: true);
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

                  switch (event.type) {
                    case AdEventType.loaded:
                      _notifyLoaded();
                      manager.start();
                      break;
                    case AdEventType.started:
                      _notifyDisplayed();
                      _notifyStarted();
                      break;
                    case AdEventType.complete:
                      _notifyCompleted();
                      _onLinearVideoFinished(skipped: false);
                      break;
                    case AdEventType.skipped:
                      _notifySkipped();
                      _onLinearVideoFinished(skipped: true);
                      break;
                    case AdEventType.skippableStateChanged:
                      if (mounted) {
                        setState(() => _skipAvailable = true);
                      }
                      break;
                    case AdEventType.allAdsCompleted:
                      _session.endInteractivePostVideoContent();
                      if (!_hasClosed && (_hasCompleted || _hasSkipped)) {
                        _applyPostVideoUi();
                      } else if (!_hasClosed && _autoClose) {
                        _closeAdSession();
                      }
                      break;
                    case AdEventType.contentPauseRequested:
                      _pauseContent();
                      break;
                    case AdEventType.contentResumeRequested:
                      _resumeContent();
                      break;
                    case AdEventType.clicked:
                      widget.callback?.onAdClicked(widget.placementId);
                      break;
                    default:
                      break;
                  }
                },
                onAdErrorEvent: (AdErrorEvent event) {
                  SDKLogger.error(
                    'IMA AdErrorEvent: ${event.error.message}',
                    null,
                  );
                  _session.markFailed();
                  _notifyFailed(
                    'IMA_ERROR',
                    event.error.message ?? 'Unknown IMA error',
                  );
                  _closeAdSession(syncSession: false);
                  _resumeContent();
                },
              ),
            );

            manager.init(
              settings: AdsRenderingSettings(
                enablePreloading: true,
                uiElements: const <AdUIElement>{},
              ),
            );
          },
          onAdsLoadError: (AdsLoadErrorData data) {
            SDKLogger.error('IMA AdsLoadError: ${data.error.message}', null);
            _notifyFailed(
              'IMA_LOAD_ERROR',
              data.error.message ?? 'Unknown IMA load error',
            );
            _resumeContent();
          },
        );
      },
    );
  }

  Future<void> _loadVastAd() async {
    widget.callback?.onAdLoading(widget.placementId);
    try {
      final override = widget.vastXmlOverride?.trim();
      if (override != null && override.isNotEmpty) {
        final vastXml = override;
        _parseVastMetadata(vastXml);
        setState(() => _isLoading = false);
        await Future.delayed(const Duration(milliseconds: 500));
        if (widget.callback?.onAdRenderOverride == null) {
          await _requestAds(_adDisplayContainer, vastXml);
        }
        return;
      }

      final apiURL = await URLBuilder.buildAdRequestURL(
        placementId: widget.placementId,
        adType: widget.adType,
        position: widget.position,
        baseURL: widget.baseUrl,
        userId: BidscubeSDK.config?.userId,
      );

      if (apiURL == null) {
        throw Exception('Failed to build API URL for VAST request');
      }

      final config = BidscubeSDK.config ?? SDKConfig(baseURL: widget.baseUrl);
      final loadResult = await _videoAdRequestLoader.loadFromUrl(
        apiURL: apiURL,
        config: config,
        headers: await _requestHeaders(),
      );

      if (!loadResult.isSuccess) {
        SDKLogger.error(
          'VAST ad request failed: ${loadResult.errorCode} ${loadResult.errorMessage}',
          null,
        );
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        _notifyFailed(
          loadResult.errorCode ?? 'LOAD_ERROR',
          loadResult.errorMessage ?? 'Video ad request failed',
        );
        return;
      }

      final resolved = loadResult.payload!;
      if (resolved.position != AdPosition.unknown && mounted) {
        setState(() => _currentPosition = resolved.position);
      }

      final overrideCallback = widget.callback?.onAdRenderOverride;
      final admForOverride =
          resolved.adsResponse ?? resolved.vastXml ?? resolved.adTagUrl;

      if (overrideCallback != null &&
          admForOverride != null &&
          admForOverride.isNotEmpty) {
        SDKLogger.info(
          'Calling onAdRenderOverride for placement ${widget.placementId}',
        );
        overrideCallback(
          widget.placementId,
          admForOverride,
          resolved.position != AdPosition.unknown
              ? resolved.position
              : _currentPosition,
        );
        return;
      }

      if (resolved.adTagUrl != null && resolved.adTagUrl!.isNotEmpty) {
        setState(() => _isLoading = false);
        await Future.delayed(const Duration(milliseconds: 500));
        await _requestAdsByAdTagUrl(
          _adDisplayContainer,
          resolved.adTagUrl!,
        );
        return;
      }

      final inlineVast = resolved.adsResponse ?? resolved.vastXml;
      if (inlineVast != null && inlineVast.isNotEmpty) {
        _parseVastMetadata(inlineVast);
        setState(() => _isLoading = false);
        await Future.delayed(const Duration(milliseconds: 500));
        await _requestAds(_adDisplayContainer, inlineVast);
        return;
      }

      throw Exception('No playable VAST payload received from server');
    } catch (e) {
      SDKLogger.error('VAST ad request failed', e);
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      _notifyFailed('LOAD_ERROR', e.toString());
    }
  }

  Future<void> _requestAds(AdDisplayContainer container, String vastXml) async {
    try {
      await _adsLoader?.requestAds(
        AdsRequest.withAdsResponse(
          adsResponse: vastXml,
          contentProgressProvider: _contentProgressProvider,
        ),
      );
    } catch (e) {
      SDKLogger.error('Failed to request ads', e);
      _notifyFailed('REQUEST_ERROR', e.toString());
    }
  }

  Future<void> _requestAdsByAdTagUrl(
    AdDisplayContainer container,
    String adTagUrl,
  ) async {
    try {
      await _adsLoader?.requestAds(
        AdsRequest(
          adTagUrl: adTagUrl,
          contentProgressProvider: _contentProgressProvider,
        ),
      );
    } catch (e) {
      SDKLogger.error('Failed to request ads by ad tag URL', e);
      _notifyFailed('REQUEST_ERROR', e.toString());
    }
  }

  Future<Map<String, String>> _requestHeaders() async {
    final userAgent = await URLBuilder.buildBrowserUserAgent();
    return {'User-Agent': userAgent, 'Accept': '*/*'};
  }

  Future<void> _resumeContent() async {
    setState(() => _shouldShowContentVideo = true);

    if (_adsManager != null) {
      _contentProgressTimer = Timer.periodic(
        const Duration(milliseconds: 200),
        (_) async {
          if (_contentVideoController?.value.isInitialized != true) return;
          final progress = await _contentVideoController!.position;
          if (progress != null) {
            await _contentProgressProvider.setProgress(
              progress: progress,
              duration: _contentVideoController!.value.duration,
            );
          }
        },
      );
    }

    await _contentVideoController?.play();
  }

  Future<void> _pauseContent() {
    setState(() => _shouldShowContentVideo = false);
    _contentProgressTimer?.cancel();
    _contentProgressTimer = null;
    return _contentVideoController?.pause() ?? Future.value();
  }

  BidscubePositionStyle _getPositionBasedStyle() {
    switch (_currentPosition) {
      case AdPosition.unknown:
        return BidscubePositionStyle(
          backgroundColor: Colors.white,
          borderRadius: widget.borderRadius ?? 0.0,
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
          borderRadius: widget.borderRadius ?? 0.0,
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
          borderRadius: widget.borderRadius ?? 0.0,
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
          borderRadius: widget.borderRadius ?? 0.0,
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
          borderRadius: widget.borderRadius ?? 0.0,
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
          borderRadius: widget.borderRadius ?? 0.0,
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
          borderRadius: widget.borderRadius ?? 0.0,
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
          borderRadius: widget.borderRadius ?? 0.0,
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

  Widget _buildVideoControlsOverlay(BuildContext context) {
    if (!_hasStarted || _showEndCard) {
      return const SizedBox.shrink();
    }
    if (!_showManualCloseButton &&
        (_skipOffsetSeconds ?? Constants.defaultSkipOffsetSeconds) <= 0) {
      return const SizedBox.shrink();
    }

    final topPadding = widget.position == AdPosition.fullScreen
        ? MediaQuery.paddingOf(context).top + 8
        : 8.0;
    final bottomPadding = widget.position == AdPosition.fullScreen
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;

    return PointerInterceptor(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            bottom: bottomPadding,
            child: Container(width: 132, height: 52, color: Colors.black),
          ),
          if (_showManualCloseButton)
            Positioned(
              top: topPadding,
              right: 12,
              child: EndCardImageCloseButton(onPressed: _handleManualClose),
            ),
          if (!_showManualCloseButton)
            VideoAdSkipButton(
              isAvailable: _skipAvailable,
              countdownSeconds: _skipCountdown,
              onPressed: _handleSkipTap,
              topPadding: topPadding,
            ),
        ],
      ),
    );
  }

  bool get _isFullScreenLayout =>
      widget.position == AdPosition.fullScreen ||
      _currentPosition == AdPosition.fullScreen;

  Size _layoutSize(BoxConstraints constraints) {
    if (_isFullScreenLayout &&
        constraints.hasBoundedWidth &&
        constraints.hasBoundedHeight) {
      return Size(constraints.maxWidth, constraints.maxHeight);
    }
    return Size(widget.width, widget.height);
  }

  Widget _wrapLayout(Widget child, Size size) {
    if (_isFullScreenLayout) {
      return SizedBox(width: size.width, height: size.height, child: child);
    }
    return Center(
      child: SizedBox(width: size.width, height: size.height, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.callback?.onAdRenderOverride != null) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    if (_isDismissed) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _layoutSize(constraints);

        if (_showEndCard) {
          return _wrapLayout(
            VideoEndCardView(
              companion: _companion,
              previewImageUrl: _previewImageUrl,
              adTitle: _adTitle,
              clickUrl: _endCardClickUrl,
              width: size.width,
              height: size.height,
              onClose: _handleManualClose,
              onTap: _endCardClickUrl != null ? _handleEndCardClick : null,
            ),
            size,
          );
        }

        final positionStyle = _getPositionBasedStyle();

        if (_isLoading) {
          return _wrapLayout(
            Container(
              decoration: BoxDecoration(
                color: positionStyle.backgroundColor,
                borderRadius: BorderRadius.circular(
                  positionStyle.borderRadius ?? 0,
                ),
                border: positionStyle.border,
                boxShadow: positionStyle.boxShadow,
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
            size,
          );
        }

        if (_hasError) {
          return _wrapLayout(
            Container(
              decoration: BoxDecoration(
                color: positionStyle.backgroundColor,
                borderRadius: BorderRadius.circular(
                  positionStyle.borderRadius ?? 0,
                ),
                border: positionStyle.border,
                boxShadow: positionStyle.boxShadow,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, color: Colors.grey, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'Ad not loaded or placement ID does not exist',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            size,
          );
        }

        return _wrapLayout(
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(widget.borderRadius ?? 0.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius ?? 0.0),
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: <Widget>[
                  Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        width: size.width,
                        height: size.height,
                        child: _adDisplayContainer,
                      ),
                    ),
                  ),
                  if (_shouldShowContentVideo &&
                      _contentVideoController?.value.isInitialized == true)
                    Center(child: VideoPlayer(_contentVideoController!)),
                  _buildVideoControlsOverlay(context),
                ],
              ),
            ),
          ),
          size,
        );
      },
    );
  }
}
