import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/services/audio_service.dart';
import 'data/services/proxy_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize audio service for background playback
  await initAudioService();

  // Initialize Riverpod container to start services
  final container = ProviderContainer();

  // Start the proxy server
  try {
    await container.read(proxyServiceProvider).start();
  } catch (e) {
    print('Failed to start proxy service: $e');
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const LyraApp()),
  );
}
