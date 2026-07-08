import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bidscube_sdk_flutter/src/core/adm_markup_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ad Content Extraction Tests', () {
    test('Extract HTML from document.write with unquoted content', () {
      final adm =
          r'''document.write(<div style=\"position: relative; width:300px; height:250px; overflow: hidden;\"><div style=\"width:300px; height: 250px; margin-left: -150px; margin-top: -125px; position: absolute; top: 50%; left: 50%;\"><span id=\"banner_test\">https://wegetads.com/creatives/test?cid=123\\<script type=\"application/javascript\" src=\"https://s110.bcc-ssp.com/cdata?key=test\"><\/script><img src=\"https://s110.bcc-ssp.com/?c=b&m=i&h=test\" width=\"1\" height=\"1\" alt=\"\" style=\"position: absolute\"><script type=\"application/javascript\">(function () { let wrapper = document.getElementById(\"banner_test\"); wrapper.addEventListener(\"click\", function () { let s = document.createElement(\"script\"); s.type = \"text/javascript\"; s.async = true; s.src = \"https://s110.bcc-ssp.com/?c=b&m=c&h=test\"; document.body.appendChild(s); }); })();<\/script></span></div></div>);''';

      final content = AdmMarkupExtractor.extractRenderMarkup(adm);

      expect(content.contains('<div'), true);
      expect(content.contains('<script'), true);
      expect(content.contains('</div>'), true);
      expect(content.contains('style="'), true);
      expect(content.contains('document.write'), false);
      expect(content.contains('{ "adm"'), false);

      log('Extracted content preview: ${content.substring(0, 200)}');
    });

    test('Unwrap loose JSON adm envelope with document.write', () {
      final adm =
          r'''{ "adm" : document.write(<div id="banner">Hello</div>); }''';

      final content = AdmMarkupExtractor.extractRenderMarkup(adm);

      expect(content, '<div id="banner">Hello</div>');
      expect(content.contains('{ "adm"'), false);
      expect(content.contains('document.write'), false);
    });

    test('Unwrap strict JSON adm envelope', () {
      const adm = r'{ "adm": "<a href=\"https://example.com\"><img src=\"https://cdn.example/b.png\"/></a>" }';

      final content = AdmMarkupExtractor.extractRenderMarkup(adm);

      expect(content.contains('<img'), true);
      expect(content.contains('{ "adm"'), false);
    });

    test('admFromResponse normalizes map and string adm values', () {
      final fromString = AdmMarkupExtractor.admFromResponse({
        'adm':
            r'{ "adm" : document.write(<span>Banner</span>); }',
      });

      expect(fromString, '<span>Banner</span>');

      final fromMap = AdmMarkupExtractor.admFromResponse({
        'adm': {'adm': '<img src="https://cdn.example/a.png" />'},
      });

      expect(fromMap, '<img src="https://cdn.example/a.png" />');
    });

    test('Strip embedded adm JSON literal inside banner span', () {
      final adm =
          r'''document.write(<div style="position: relative; width:300px; height:250px;"><span id="banner_test">{
  "adm": "<div id="wrapper_test"><a href="https://example.com"><img src="https://cdn.example/b.png"></a><script type="application/javascript"></script>"
}
<script type="application/javascript">(function(){})();</script></span></div>);''';

      final content = AdmMarkupExtractor.extractRenderMarkup(adm);

      expect(content.contains('"adm"'), false);
      expect(content.contains('{\n  "adm"'), false);
      expect(content.contains('wrapper_test'), true);
      expect(content.contains('<script type="application/javascript">'), true);
    });

    test('Strip embedded adm JSON literal from live-style payload', () async {
      final uri = Uri.parse(
        'https://ssp-bcc-ads.com/sdk?placementId=20212&c=b&m=api&res=js'
        '&app=1&bundle=com.example.testapp&name=test&app_store_url='
        '&language=en&deviceWidth=320&deviceHeight=480&ua=Test&ifa=&dnt=0',
      );
      final client = HttpClient();
      try {
        final request = await client.getUrl(uri);
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        final data = json.decode(body) as Map<String, dynamic>;
        final content = AdmMarkupExtractor.extractRenderMarkup(
          data['adm'] as String,
        );

        expect(content.contains('"adm"'), false);
        expect(content.contains(RegExp(r'^\s*\{\s*$', multiLine: true)), false);
        expect(content.contains('<div'), true);
      } finally {
        client.close(force: true);
      }
    });

    test('Clean up URL text node before script tag', () {
      final content =
          r'<span id="banner_test">https://wegetads.com/test\<script type="text/javascript">alert("test");</script></span>';

      final cleaned = AdmMarkupExtractor.extractRenderMarkup(content);

      expect(cleaned.contains('https://wegetads.com'), false);
      expect(cleaned.contains('<span id="banner_test"><script'), true);

      log('Cleaned content: $cleaned');
    });
  });
}
