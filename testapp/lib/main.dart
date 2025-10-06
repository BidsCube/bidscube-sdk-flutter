import 'package:flutter/material.dart';
import 'package:testapp/views/consent_test_view.dart';
import 'package:testapp/views/sdk_test_view.dart';
import 'package:testapp/views/windowed_ad_test_view.dart';
import 'package:testapp/widgets/custom_filled_button.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BidsCube SDK Test App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TestHomePage(),
    );
  }
}

class TestHomePage extends StatelessWidget {
  const TestHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'BidsCubeTestLauncher',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select test view to launch',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),

            CustomFilledButton(
              label: 'SDK Test View',
              color: const Color(0xFF4CAF50),
              destination: const SDKTestView(),
            ),
            CustomFilledButton(
              label: 'Consent Test View',
              color: const Color(0xFFFF9800),
              destination: const ConsentTestView(),
            ),
            CustomFilledButton(
              label: 'Windowed Ad View',
              color: const Color(0xFF2196F3),
              destination: const WindowedAdTestView(),
            ),
          ],
        ),
      ),
    );
  }
}
