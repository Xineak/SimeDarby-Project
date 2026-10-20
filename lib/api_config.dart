import 'package:flutter/foundation.dart';

// Edge/Chrome -> localhost; Android emulator -> 10.0.2.2
final String apiBaseUrl = kIsWeb
    ? 'http://localhost:5000'
    : (defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5000'
        : 'http://localhost:5000');
