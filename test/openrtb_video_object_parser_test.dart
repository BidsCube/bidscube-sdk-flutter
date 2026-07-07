import 'package:flutter_test/flutter_test.dart';
import 'package:bidscube_sdk_flutter/src/openrtb/openrtb_video_object_parser.dart';

void main() {
  group('OpenRtbVideoObjectParser', () {
    test('finds video object from openrtb.video', () {
      final video = OpenRtbVideoObjectParser.findVideoObject({
        'openrtb': {
          'video': {'podid': 'pod-1', 'poddur': 60},
        },
      });
      expect(video?['podid'], 'pod-1');
    });

    test('finds video object from openRtb.video fallback', () {
      final video = OpenRtbVideoObjectParser.findVideoObject({
        'openRtb': {
          'video': {'podid': 'pod-2'},
        },
      });
      expect(video?['podid'], 'pod-2');
    });

    test('finds video object from root video fallback', () {
      final video = OpenRtbVideoObjectParser.findVideoObject({
        'video': {'podid': 'pod-root'},
      });
      expect(video?['podid'], 'pod-root');
    });

    test('intValue accepts int, double, num, and string', () {
      expect(OpenRtbVideoObjectParser.intValue(15), 15);
      expect(OpenRtbVideoObjectParser.intValue(15.9), 15);
      expect(OpenRtbVideoObjectParser.intValue(' 20 '), 20);
      expect(OpenRtbVideoObjectParser.intValue('00:00:15'), 15);
    });

    test('malformed numeric values return null', () {
      expect(OpenRtbVideoObjectParser.intValue('not-a-number'), isNull);
      expect(OpenRtbVideoObjectParser.doubleValue('bad'), isNull);
      expect(OpenRtbVideoObjectParser.intValue(double.nan), isNull);
    });

    test('intArrayValue accepts mixed lists and ignores invalid entries', () {
      expect(
        OpenRtbVideoObjectParser.intArrayValue([15, 30.0, '10', 'bad', 5]),
        [15, 30, 10, 5],
      );
    });

    test('intArrayValue supports rqdDurs-style values via intArrayValue', () {
      expect(OpenRtbVideoObjectParser.intArrayValue(['15', 30, 'bad']), [
        15,
        30,
      ]);
    });
  });
}
