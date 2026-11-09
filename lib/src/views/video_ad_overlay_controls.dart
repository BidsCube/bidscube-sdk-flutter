import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// Skip control rendered above the IMA platform view (top-right).
class VideoAdSkipButton extends StatelessWidget {
  final bool isAvailable;
  final int countdownSeconds;
  final VoidCallback onPressed;
  final double topPadding;

  const VideoAdSkipButton({
    super.key,
    required this.isAvailable,
    required this.countdownSeconds,
    required this.onPressed,
    this.topPadding = 8,
    this.enlarged = false,
  });

  final bool enlarged;

  @override
  Widget build(BuildContext context) {
    final label = isAvailable ? 'Skip' : 'Skip in $countdownSeconds';
    final radius = enlarged ? 28.0 : 20.0;
    final fontSize = enlarged ? 22.0 : 14.0;
    final horizontal = enlarged ? 28.0 : 16.0;
    final vertical = enlarged ? 16.0 : 10.0;

    return Positioned(
      top: topPadding,
      right: 12,
      child: PointerInterceptor(
        child: Material(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            autofocus: enlarged && isAvailable,
            focusColor: Colors.white24,
            onTap: isAvailable ? onPressed : null,
            borderRadius: BorderRadius.circular(radius),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontal,
                vertical: vertical,
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isAvailable ? Colors.white : Colors.white70,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Close control placed on the preview image (end card only).
class EndCardImageCloseButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enlarged;

  const EndCardImageCloseButton({
    super.key,
    required this.onPressed,
    this.enlarged = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = enlarged ? 56.0 : 32.0;
    final iconSize = enlarged ? 28.0 : 18.0;
    return Positioned(
      top: 10,
      right: 10,
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        child: InkWell(
          autofocus: enlarged,
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(Icons.close, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }
}

class EndCardStarRating extends StatelessWidget {
  final double rating;

  const EndCardStarRating({super.key, this.rating = 4.5});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(5, (index) {
        final starValue = index + 1;
        IconData icon;
        if (rating >= starValue) {
          icon = Icons.star;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, color: const Color(0xFFFF9800), size: 20);
      }),
    );
  }
}
