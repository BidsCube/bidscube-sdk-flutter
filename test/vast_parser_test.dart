import 'package:flutter_test/flutter_test.dart';
import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';
import 'package:bidscube_sdk_flutter/src/openrtb/video_ad_payload_resolver.dart';

const _vastWithPreview = '''
<VAST version="4.2">
  <Ad id="12345">
    <InLine>
      <AdTitle>Sample Skippable VAST Ad With Preview</AdTitle>
      <Creatives>
        <Creative id="1" sequence="1">
          <Linear skipoffset="00:00:05">
            <Duration>00:00:30</Duration>
            <VideoClicks>
              <ClickThrough><![CDATA[https://www.google.com]]></ClickThrough>
            </VideoClicks>
            <MediaFiles>
              <MediaFile delivery="progressive" type="video/mp4">
                <![CDATA[https://example.com/video.mp4]]>
              </MediaFile>
            </MediaFiles>
          </Linear>
        </Creative>
        <Creative sequence="2">
          <CompanionAds>
            <Companion width="1280" height="720">
              <StaticResource creativeType="image/jpeg">
                <![CDATA[https://www.gstatic.com/webp/gallery/3.jpg]]>
              </StaticResource>
              <CompanionClickThrough>
                <![CDATA[https://www.google.com]]>
              </CompanionClickThrough>
            </Companion>
          </CompanionAds>
        </Creative>
      </Creatives>
    </InLine>
  </Ad>
</VAST>''';

const _vastWithoutPreview = '''
<VAST version="3.0">
  <Ad id="20">
    <InLine>
      <AdTitle><![CDATA[Doordash-35min-burger-3-1x1.mp4]]></AdTitle>
      <Creatives>
        <Creative>
          <Linear>
            <Duration>00:00:12.867</Duration>
            <MediaFiles>
              <MediaFile delivery="progressive" type="video/mp4">
                <![CDATA[https://example.com/video.mp4]]>
              </MediaFile>
            </MediaFiles>
          </Linear>
        </Creative>
      </Creatives>
    </InLine>
  </Ad>
</VAST>''';

void main() {
  group('VastParser companion preview', () {
    test('parses preview and click URL from companion creative', () {
      final parsed = VastParser.tryParse(_vastWithPreview);
      expect(parsed, isNotNull);
      expect(
        parsed!.previewImageUrl,
        'https://www.gstatic.com/webp/gallery/3.jpg',
      );
      expect(parsed.endCardClickUrl, 'https://www.google.com');
      expect(parsed.skipOffsetSeconds, 5);
      expect(parsed.adTitle, 'Sample Skippable VAST Ad With Preview');
    });

    test('returns null preview when companion is absent', () {
      final parsed = VastParser.tryParse(_vastWithoutPreview);
      expect(parsed, isNotNull);
      expect(parsed!.previewImageUrl, isNull);
      expect(parsed.endCardClickUrl, isNull);
      expect(parsed.skipOffsetSeconds, isNull);
      expect(parsed.adTitle, 'Doordash-35min-burger-3-1x1.mp4');
    });

    test('tryParse returns null for invalid XML', () {
      expect(VastParser.tryParse('<not-vast></not-vast>'), isNull);
    });

    test('parseSkipOffsetSeconds handles HH:MM:SS and seconds', () {
      expect(VastParser.parseSkipOffsetSeconds('00:00:05'), 5);
      expect(VastParser.parseSkipOffsetSeconds('00:01:30'), 90);
      expect(VastParser.parseSkipOffsetSeconds('10'), 10);
      expect(VastParser.parseSkipOffsetSeconds(null), isNull);
    });

    test('parses inline Bidscube JSON adm with skipoffset', () {
      const jsonBody =
          '{"adm":"<?xml version=\\"1.0\\" encoding=\\"UTF-8\\"?>'
          '<VAST version=\\"3.0\\"><Ad id=\\"test-inline-1\\"><InLine>'
          '<AdTitle>Inline Test Video</AdTitle>'
          '<Creatives><Creative sequence=\\"1\\">'
          '<Linear skipoffset=\\"00:00:05\\"><Duration>00:00:15</Duration>'
          '<MediaFiles><MediaFile delivery=\\"progressive\\" type=\\"video/mp4\\">'
          '<![CDATA[https://example.com/video.mp4]]></MediaFile></MediaFiles>'
          '</Linear></Creative></Creatives></InLine></Ad></VAST>","position":4}';

      final resolved = VideoAdPayloadResolver.resolve(content: jsonBody);
      expect(resolved, isNotNull);
      expect(resolved!.vastXml, contains('skipoffset="00:00:05"'));
      expect(resolved.position, AdPosition.header);

      final parsed = VastParser.tryParse(resolved.vastXml!);
      expect(parsed, isNotNull);
      expect(parsed!.skipOffsetSeconds, 5);
      expect(parsed.adTitle, 'Inline Test Video');
    });
  });
}
