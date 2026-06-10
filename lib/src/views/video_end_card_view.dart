import 'package:flutter/material.dart';

import 'video_ad_overlay_controls.dart';

/// End card shown after video complete or skip.
class VideoEndCardView extends StatelessWidget {
  final String? previewImageUrl;
  final String adTitle;
  final String? clickUrl;
  final VoidCallback onClose;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const VideoEndCardView({
    super.key,
    this.previewImageUrl,
    this.adTitle = '',
    this.clickUrl,
    required this.onClose,
    this.onTap,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final title = adTitle.trim().isNotEmpty ? adTitle.trim() : 'Ad';

    return Container(
      width: width,
      height: height,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, bottomPadding + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 6,
              child: _PreviewImageSection(
                previewImageUrl: previewImageUrl,
                adTitle: title,
                onClose: onClose,
                onTap: clickUrl != null ? onTap : null,
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
                if (clickUrl != null && onTap != null)
                  FilledButton(
                    onPressed: onTap,
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
