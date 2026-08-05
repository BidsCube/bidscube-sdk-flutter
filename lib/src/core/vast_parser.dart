import 'package:xml/xml.dart';

import 'constants.dart';

/// VAST (Video Ad Serving Template) parser for handling video ads.
class VastParser {
  /// Parse VAST XML and extract video ad information.
  static Future<VastAd?> parseVast(String vastXml) async {
    return tryParse(vastXml);
  }

  /// Parses VAST XML without throwing — returns null on failure.
  static VastAd? tryParse(String vastXml) {
    try {
      final document = XmlDocument.parse(vastXml);
      final vastElement = document.rootElement;

      if (vastElement.name.local != 'VAST') {
        return null;
      }

      final adElement = vastElement.findAllElements('Ad').firstOrNull;
      if (adElement == null) {
        return null;
      }

      final inlineElement = adElement.findAllElements('InLine').firstOrNull;
      if (inlineElement == null) {
        return null;
      }

      return _parseInlineAd(inlineElement);
    } catch (_) {
      return null;
    }
  }

  static VastAd _parseInlineAd(XmlElement inlineElement) {
    final adSystem =
        inlineElement.findAllElements('AdSystem').firstOrNull?.innerText ??
        'Unknown';

    final adTitle =
        inlineElement
            .findAllElements('AdTitle')
            .firstOrNull
            ?.innerText
            .trim() ??
        '';

    final description =
        inlineElement.findAllElements('Description').firstOrNull?.innerText ??
        '';

    final creatives = <VastCreative>[];
    final creativeElements = inlineElement.findAllElements('Creative');

    for (final creativeElement in creativeElements) {
      final creative = _parseCreative(creativeElement);
      if (creative != null) {
        creatives.add(creative);
      }
    }

    final trackingEvents = <String, List<String>>{};
    for (final creative in creatives) {
      if (creative is VastLinearCreative) {
        for (final tracking in creative.trackingEvents) {
          trackingEvents[tracking.event] = trackingEvents[tracking.event] ?? [];
          trackingEvents[tracking.event]!.add(tracking.url);
        }
      }
    }

    return VastAd(
      adSystem: adSystem,
      adTitle: adTitle,
      description: description,
      creatives: creatives,
      trackingEvents: trackingEvents,
    );
  }

  static VastCreative? _parseCreative(XmlElement creativeElement) {
    final linearElement = creativeElement.findElements('Linear').firstOrNull;
    if (linearElement != null) {
      return _parseLinearCreative(linearElement);
    }

    final companionAdsElement = creativeElement
        .findElements('CompanionAds')
        .firstOrNull;
    if (companionAdsElement != null) {
      return _parseCompanionCreative(companionAdsElement);
    }

    final nonLinearElement = creativeElement
        .findElements('NonLinear')
        .firstOrNull;
    if (nonLinearElement != null) {
      return _parseNonLinearCreative(nonLinearElement);
    }

    return null;
  }

  static VastCompanionCreative _parseCompanionCreative(
    XmlElement companionAdsElement,
  ) {
    final companionElement = companionAdsElement
        .findElements('Companion')
        .firstOrNull;

    String? staticResourceUrl;
    String staticResourceType = '';
    String? htmlResource;
    String? iframeResourceUrl;
    String? clickThroughUrl;
    final clickTrackingUrls = <String>[];
    final viewTrackingUrls = <String>[];

    if (companionElement != null) {
      final staticResourceElement = companionElement
          .findElements('StaticResource')
          .firstOrNull;
      if (staticResourceElement != null) {
        staticResourceUrl = staticResourceElement.innerText.trim();
        staticResourceType =
            staticResourceElement.getAttribute('creativeType') ?? '';
      }

      final htmlResourceElement = companionElement
          .findElements('HTMLResource')
          .firstOrNull;
      if (htmlResourceElement != null) {
        htmlResource = htmlResourceElement.innerText.trim();
      }

      final iframeResourceElement = companionElement
          .findElements('IFrameResource')
          .firstOrNull;
      if (iframeResourceElement != null) {
        iframeResourceUrl = iframeResourceElement.innerText.trim();
      }

      final clickThroughElement = companionElement
          .findElements('CompanionClickThrough')
          .firstOrNull;
      if (clickThroughElement != null) {
        clickThroughUrl = clickThroughElement.innerText.trim();
      }

      for (final clickTracking in companionElement.findElements(
        'CompanionClickTracking',
      )) {
        final url = clickTracking.innerText.trim();
        if (url.isNotEmpty) {
          clickTrackingUrls.add(url);
        }
      }

      final trackingEventsElement = companionElement
          .findElements('TrackingEvents')
          .firstOrNull;
      if (trackingEventsElement != null) {
        for (final tracking in trackingEventsElement.findElements('Tracking')) {
          final event = tracking.getAttribute('event') ?? '';
          final url = tracking.innerText.trim();
          if (url.isEmpty) continue;
          if (event == 'creativeView' || event == 'start') {
            viewTrackingUrls.add(url);
          }
        }
      }
    }

    return VastCompanionCreative(
      staticResourceUrl: staticResourceUrl,
      staticResourceType: staticResourceType,
      htmlResource: htmlResource,
      iframeResourceUrl: iframeResourceUrl,
      clickThroughUrl: clickThroughUrl,
      clickTrackingUrls: clickTrackingUrls,
      viewTrackingUrls: viewTrackingUrls,
    );
  }

  static VastLinearCreative _parseLinearCreative(XmlElement linearElement) {
    final duration =
        linearElement.findAllElements('Duration').firstOrNull?.innerText ??
        '00:00:30';

    final skipOffsetRaw = linearElement.getAttribute('skipoffset');

    final mediaFiles = <VastMediaFile>[];
    final mediaFileElements = linearElement.findAllElements('MediaFile');

    for (final mediaFileElement in mediaFileElements) {
      final mediaFile = VastMediaFile(
        url: mediaFileElement.innerText.trim(),
        type: mediaFileElement.getAttribute('type') ?? '',
        width: int.tryParse(mediaFileElement.getAttribute('width') ?? '0') ?? 0,
        height:
            int.tryParse(mediaFileElement.getAttribute('height') ?? '0') ?? 0,
        delivery: mediaFileElement.getAttribute('delivery') ?? 'progressive',
      );
      mediaFiles.add(mediaFile);
    }

    final trackingEvents = <VastTrackingEvent>[];
    final trackingElement = linearElement
        .findAllElements('TrackingEvents')
        .firstOrNull;
    if (trackingElement != null) {
      final trackingEventElements = trackingElement.findElements('Tracking');
      for (final trackingEventElement in trackingEventElements) {
        final event = trackingEventElement.getAttribute('event') ?? '';
        final url = trackingEventElement.innerText.trim();
        if (event.isNotEmpty && url.isNotEmpty) {
          trackingEvents.add(VastTrackingEvent(event: event, url: url));
        }
      }
    }

    final videoClicks = <VastVideoClick>[];
    final videoClicksElement = linearElement
        .findAllElements('VideoClicks')
        .firstOrNull;
    if (videoClicksElement != null) {
      final clickThroughElement = videoClicksElement
          .findElements('ClickThrough')
          .firstOrNull;
      if (clickThroughElement != null) {
        videoClicks.add(
          VastVideoClick(
            type: 'ClickThrough',
            url: clickThroughElement.innerText.trim(),
          ),
        );
      }

      final clickTrackingElements = videoClicksElement.findElements(
        'ClickTracking',
      );
      for (final clickTrackingElement in clickTrackingElements) {
        videoClicks.add(
          VastVideoClick(
            type: 'ClickTracking',
            url: clickTrackingElement.innerText.trim(),
          ),
        );
      }
    }

    return VastLinearCreative(
      duration: duration,
      mediaFiles: mediaFiles,
      trackingEvents: trackingEvents,
      videoClicks: videoClicks,
      skipOffsetSeconds: parseSkipOffsetSeconds(skipOffsetRaw),
    );
  }

  static VastNonLinearCreative _parseNonLinearCreative(
    XmlElement nonLinearElement,
  ) {
    final staticResources = <VastStaticResource>[];
    final staticResourceElements = nonLinearElement.findElements(
      'StaticResource',
    );

    for (final staticResourceElement in staticResourceElements) {
      final staticResource = VastStaticResource(
        url: staticResourceElement.innerText.trim(),
        creativeType: staticResourceElement.getAttribute('creativeType') ?? '',
      );
      staticResources.add(staticResource);
    }

    final trackingEvents = <VastTrackingEvent>[];
    final trackingElement = nonLinearElement
        .findElements('TrackingEvents')
        .firstOrNull;
    if (trackingElement != null) {
      final trackingEventElements = trackingElement.findElements('Tracking');
      for (final trackingEventElement in trackingEventElements) {
        final event = trackingEventElement.getAttribute('event') ?? '';
        final url = trackingEventElement.innerText.trim();
        if (event.isNotEmpty && url.isNotEmpty) {
          trackingEvents.add(VastTrackingEvent(event: event, url: url));
        }
      }
    }

    return VastNonLinearCreative(
      staticResources: staticResources,
      trackingEvents: trackingEvents,
    );
  }

  /// Parses VAST skipoffset values such as `00:00:05` or `5`.
  static int? parseSkipOffsetSeconds(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final value = raw.trim();

    if (value.contains(':')) {
      final parts = value.split(':');
      if (parts.length == 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = int.tryParse(parts[2]) ?? 0;
        return hours * 3600 + minutes * 60 + seconds;
      }
    }

    final percentMatch = RegExp(r'^(\d+)%$').firstMatch(value);
    if (percentMatch != null) {
      return null;
    }

    return int.tryParse(value);
  }
}

/// VAST Ad data structure.
class VastAd {
  final String adSystem;
  final String adTitle;
  final String description;
  final List<VastCreative> creatives;
  final Map<String, List<String>> trackingEvents;

  VastAd({
    required this.adSystem,
    required this.adTitle,
    required this.description,
    required this.creatives,
    required this.trackingEvents,
  });

  /// Preview image URL from the first Companion > StaticResource, if present.
  String? get previewImageUrl => preferredCompanion?.staticResourceUrl;

  /// Preferred companion by priority: HTML, IFrame, Static image.
  VastCompanionCreative? get preferredCompanion {
    VastCompanionCreative? html;
    VastCompanionCreative? iframe;
    VastCompanionCreative? staticImage;

    for (final creative in creatives) {
      if (creative is! VastCompanionCreative) continue;
      if (creative.hasHtml) {
        html ??= creative;
      } else if (creative.hasIframe) {
        iframe ??= creative;
      } else if (creative.hasStaticImage) {
        staticImage ??= creative;
      }
    }

    return html ?? iframe ?? staticImage;
  }

  bool get hasCompanion => preferredCompanion != null;

  /// Click URL for the end card — CompanionClickThrough first, then Linear ClickThrough.
  String? get endCardClickUrl {
    final companionClick = preferredCompanion?.clickThroughUrl;
    if (companionClick != null && companionClick.isNotEmpty) {
      return companionClick;
    }

    for (final creative in creatives) {
      if (creative is VastLinearCreative) {
        for (final click in creative.videoClicks) {
          if (click.type == 'ClickThrough' && click.url.isNotEmpty) {
            return click.url;
          }
        }
      }
    }

    return null;
  }

  /// Skip offset in seconds from Linear skipoffset attribute, or [Constants.defaultSkipOffsetSeconds].
  int get skipOffsetSeconds {
    for (final creative in creatives) {
      if (creative is VastLinearCreative) {
        return creative.skipOffsetSeconds ??
            Constants.defaultSkipOffsetSeconds;
      }
    }
    return Constants.defaultSkipOffsetSeconds;
  }

  /// Raw skipoffset from VAST when explicitly set on Linear creative.
  int? get explicitSkipOffsetSeconds {
    for (final creative in creatives) {
      if (creative is VastLinearCreative) {
        return creative.skipOffsetSeconds;
      }
    }
    return null;
  }
}

/// Base class for VAST creatives.
abstract class VastCreative {}

/// Linear creative (video ads).
class VastLinearCreative extends VastCreative {
  final String duration;
  final List<VastMediaFile> mediaFiles;
  final List<VastTrackingEvent> trackingEvents;
  final List<VastVideoClick> videoClicks;
  final int? skipOffsetSeconds;

  VastLinearCreative({
    required this.duration,
    required this.mediaFiles,
    required this.trackingEvents,
    required this.videoClicks,
    this.skipOffsetSeconds,
  });
}

/// Companion creative (end-card preview).
class VastCompanionCreative extends VastCreative {
  final String? staticResourceUrl;
  final String staticResourceType;
  final String? htmlResource;
  final String? iframeResourceUrl;
  final String? clickThroughUrl;
  final List<String> clickTrackingUrls;
  final List<String> viewTrackingUrls;

  VastCompanionCreative({
    this.staticResourceUrl,
    this.staticResourceType = '',
    this.htmlResource,
    this.iframeResourceUrl,
    this.clickThroughUrl,
    this.clickTrackingUrls = const [],
    this.viewTrackingUrls = const [],
  });

  bool get hasHtml => htmlResource != null && htmlResource!.trim().isNotEmpty;

  bool get hasIframe =>
      iframeResourceUrl != null && iframeResourceUrl!.trim().isNotEmpty;

  bool get hasStaticImage =>
      staticResourceUrl != null && staticResourceUrl!.trim().isNotEmpty;

  VastCompanionResourceType get resourceType {
    if (hasHtml) return VastCompanionResourceType.html;
    if (hasIframe) return VastCompanionResourceType.iframe;
    if (hasStaticImage) return VastCompanionResourceType.staticImage;
    return VastCompanionResourceType.none;
  }
}

enum VastCompanionResourceType { none, html, iframe, staticImage }

/// Non-linear creative (banner/image ads).
class VastNonLinearCreative extends VastCreative {
  final List<VastStaticResource> staticResources;
  final List<VastTrackingEvent> trackingEvents;

  VastNonLinearCreative({
    required this.staticResources,
    required this.trackingEvents,
  });
}

/// Media file information.
class VastMediaFile {
  final String url;
  final String type;
  final int width;
  final int height;
  final String delivery;

  VastMediaFile({
    required this.url,
    required this.type,
    required this.width,
    required this.height,
    required this.delivery,
  });
}

/// Static resource information.
class VastStaticResource {
  final String url;
  final String creativeType;

  VastStaticResource({required this.url, required this.creativeType});
}

/// Tracking event information.
class VastTrackingEvent {
  final String event;
  final String url;

  VastTrackingEvent({required this.event, required this.url});
}

/// Video click information.
class VastVideoClick {
  final String type;
  final String url;

  VastVideoClick({required this.type, required this.url});
}
