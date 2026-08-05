import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/vast_parser.dart';
import 'video_ad_overlay_controls.dart';

/// End card shown after video complete when [autoClose] is false and a Companion exists.
class VideoEndCardView extends StatefulWidget {
  final VastCompanionCreative? companion;
  final String? previewImageUrl;
  final String adTitle;
  final String? clickUrl;
  final VoidCallback onClose;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const VideoEndCardView({
    super.key,
    this.companion,
    this.previewImageUrl,
    this.adTitle = '',
    this.clickUrl,
    required this.onClose,
    this.onTap,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  @override
  State<VideoEndCardView> createState() => _VideoEndCardViewState();
}

class _VideoEndCardViewState extends State<VideoEndCardView> {
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _initWebCompanionIfNeeded();
  }

  void _initWebCompanionIfNeeded() {
    final companion = widget.companion;
    if (companion == null) return;

    switch (companion.resourceType) {
      case VastCompanionResourceType.html:
        final html = companion.htmlResource?.trim();
        if (html == null || html.isEmpty) return;
        _webViewController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadHtmlString(html);
      case VastCompanionResourceType.iframe:
        final url = companion.iframeResourceUrl?.trim();
        if (url == null || url.isEmpty) return;
        final uri = Uri.tryParse(url);
        if (uri == null) return;
        _webViewController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(uri);
      case VastCompanionResourceType.staticImage:
      case VastCompanionResourceType.none:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final title = widget.adTitle.trim().isNotEmpty ? widget.adTitle.trim() : 'Ad';
    final companion = widget.companion;
    final useRichEndCard =
        companion != null &&
        companion.resourceType != VastCompanionResourceType.staticImage &&
        companion.resourceType != VastCompanionResourceType.none;

    if (useRichEndCard && _webViewController != null) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            WebViewWidget(controller: _webViewController!),
            Positioned(
              top: topPadding + 8,
              right: 12,
              child: EndCardImageCloseButton(onPressed: widget.onClose),
            ),
            if (widget.clickUrl != null && widget.onTap != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: widget.onTap),
                ),
              ),
          ],
        ),
      );
    }

    final imageUrl =
        companion?.staticResourceUrl ?? widget.previewImageUrl?.trim();

    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          topPadding + 8,
          16,
          bottomPadding + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 6,
              child: _PreviewImageSection(
                previewImageUrl: imageUrl,
                adTitle: title,
                onClose: widget.onClose,
                onTap: widget.clickUrl != null ? widget.onTap : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            const EndCardStarRating(),
            const SizedBox(height: 6),
            Text(
              '10 k',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price',
                        style: TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'FREE',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.clickUrl != null && widget.onTap != null)
                  FilledButton(
                    onPressed: widget.onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0084FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Install Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewImageSection extends StatelessWidget {
  final String? previewImageUrl;
  final String adTitle;
  final VoidCallback onClose;
  final VoidCallback? onTap;

  const _PreviewImageSection({
    required this.previewImageUrl,
    required this.adTitle,
    required this.onClose,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: onTap,
                child: _PreviewImage(
                  previewImageUrl: previewImageUrl,
                  adTitle: adTitle,
                ),
              ),
              EndCardImageCloseButton(onPressed: onClose),
            ],
          ),
        );
      },
    );
  }
}

class _PreviewImage extends StatelessWidget {
  final String? previewImageUrl;
  final String adTitle;

  const _PreviewImage({required this.previewImageUrl, required this.adTitle});

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = previewImageUrl?.trim();
    if (trimmedUrl != null && trimmedUrl.isNotEmpty) {
      return Image.network(
        trimmedUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            _PreviewPlaceholder(adTitle: adTitle),
      );
    }
    return _PreviewPlaceholder(adTitle: adTitle);
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  final String adTitle;

  const _PreviewPlaceholder({required this.adTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFECECEC),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 56, color: Colors.grey[500]),
            if (adTitle.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  adTitle,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
