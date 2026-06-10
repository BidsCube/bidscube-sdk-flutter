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
  });

  @override
  Widget build(BuildContext context) {
    final label = isAvailable ? 'Skip' : 'Skip in $countdownSeconds';

    return Positioned(
      top: topPadding,
      right: 12,
      child: PointerInterceptor(
        child: Material(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: isAvailable ? onPressed : null,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                label,
                style: TextStyle(
                  color: isAvailable ? Colors.white : Colors.white70,
                  fontSize: 14,
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

  const EndCardImageCloseButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: 10,
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 32,
            height: 32,
            child: Icon(Icons.close, color: Colors.white, size: 18),
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
