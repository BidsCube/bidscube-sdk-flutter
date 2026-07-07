import 'dart:convert';

import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';

class OpenRtbTestFixtures {
  OpenRtbTestFixtures._();

  static String vastAd({
    required int sequence,
    required int durationSeconds,
    String id = 'ad',
  }) {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    final duration =
        '00:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return '''
<Ad sequence="$sequence" id="$id">
  <InLine>
    <Creatives>
      <Creative>
        <Linear>
          <Duration>$duration</Duration>
          <MediaFiles>
            <MediaFile delivery="progressive" type="video/mp4"><![CDATA[https://example.com/$id.mp4]]></MediaFile>
          </MediaFiles>
        </Linear>
      </Creative>
    </Creatives>
  </InLine>
</Ad>''';
  }

  static String vastDocument(List<String> ads) {
    return '<VAST version="3.0">\n${ads.join('\n')}\n</VAST>';
  }

  static String get rawVast =>
      vastDocument([vastAd(sequence: 1, durationSeconds: 15)]);

  static Map<String, dynamic> legacyRootAdmJson() => {
    'adm': rawVast,
    'position': 6,
  };

  static Map<String, dynamic> structuredPodJson() => {
    'openrtb': {
      'video': {
        'podid': 'pod-1',
        'poddur': 60,
        'rqddurs': [15, 30],
        'maxseq': 3,
      },
    },
    'bids': [
      {
        'adm': vastDocument([
          vastAd(sequence: 2, durationSeconds: 30, id: 'second'),
        ]),
        'slotinpod': 2,
        'duration': 30,
      },
      {
        'adm': vastDocument([
          vastAd(sequence: 1, durationSeconds: 15, id: 'first'),
        ]),
        'slotinpod': 1,
        'duration': 15,
      },
    ],
  };

  static Map<String, dynamic> dynamicPodJson() => {
    'openrtb': {
      'video': {'podid': 'pod-dynamic', 'poddur': 30},
    },
    'bids': [
      {
        'adm': vastDocument([
          vastAd(sequence: 1, durationSeconds: 45, id: 'too-long'),
        ]),
        'duration': 45,
      },
      {
        'adm': vastDocument([
          vastAd(sequence: 2, durationSeconds: 15, id: 'ok'),
        ]),
        'duration': 15,
      },
      {
        'adm': vastDocument([
          vastAd(sequence: 3, durationSeconds: 10, id: 'also-ok'),
        ]),
        'duration': 10,
      },
    ],
  };

  static Map<String, dynamic> hybridPodJson() => {
    'openrtb': {
      'video': {
        'podid': 'pod-hybrid',
        'poddur': 40,
        'rqddurs': [15],
        'maxseq': 4,
      },
    },
    'bids': [
      {
        'adm': vastDocument([
          vastAd(sequence: 1, durationSeconds: 15, id: 'fixed'),
        ]),
        'slotinpod': 1,
        'duration': 15,
      },
      {
        'adm': vastDocument([
          vastAd(sequence: 2, durationSeconds: 10, id: 'dynamic-a'),
        ]),
        'duration': 10,
      },
      {
        'adm': vastDocument([
          vastAd(sequence: 3, durationSeconds: 20, id: 'dynamic-b'),
        ]),
        'duration': 20,
      },
    ],
  };

  static Map<String, dynamic> seatbidJson() => {
    'seatbid': [
      {
        'bid': [
          {
            'id': 'bid-1',
            'impid': 'imp-1',
            'adm': vastDocument([
              vastAd(sequence: 1, durationSeconds: 15, id: 'seat-1'),
            ]),
            'crid': 'creative-1',
            'price': 1.2,
            'ext': {'slotinpod': 1, 'duration': 15, 'podid': 'pod-seat'},
          },
        ],
      },
    ],
    'openrtb': {
      'video': {
        'podid': 'pod-seat',
        'poddur': 60,
        'rqddurs': [15],
        'maxseq': 3,
      },
    },
  };

  static Map<String, dynamic> multiPodSeatbidJson() => {
    'seatbid': [
      {
        'bid': [
          {
            'id': 'bid-b',
            'adm': vastDocument([
              vastAd(sequence: 1, durationSeconds: 10, id: 'pod-b'),
            ]),
            'ext': {'podid': 'pod-b', 'slotinpod': 1, 'duration': 10},
          },
        ],
      },
      {
        'bid': [
          {
            'id': 'bid-a',
            'adm': vastDocument([
              vastAd(sequence: 1, durationSeconds: 15, id: 'pod-a'),
            ]),
            'ext': {'podid': 'pod-a', 'slotinpod': 1, 'duration': 15},
          },
        ],
      },
    ],
    'openrtb': {
      'video': {'podid': 'pod-a'},
    },
  };

  static Map<String, dynamic> singleAdmMultiAdVastJson({int slotInPod = 1}) => {
    'adm': vastDocument([
      vastAd(sequence: 1, durationSeconds: 15, id: 'seq-1'),
      vastAd(sequence: 2, durationSeconds: 20, id: 'seq-2'),
    ]),
    'slotinpod': slotInPod,
    'openrtb': {
      'video': {
        'podid': 'pod-multi-ad',
        'rqddurs': [15, 20],
        'maxseq': 2,
      },
    },
  };

  static String jsonString(Map<String, dynamic> object) {
    return jsonEncode(object);
  }

  static SDKConfig defaultConfig({
    bool openRtbEnabled = true,
    OpenRtbPodDurationValidationMode validation =
        OpenRtbPodDurationValidationMode.lenient,
  }) {
    return SDKConfig(
      baseURL: 'https://example.com',
      openRtbPodMetadataEnabled: openRtbEnabled,
      videoPodDurationValidationMode: validation,
    );
  }
}
