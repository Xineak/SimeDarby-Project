import 'package:flutter/foundation.dart';

final String apiBaseUrl = kIsWeb
    ? 'https://simedarby-project-yfdr.onrender.com'
    : (defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:5000'
          : 'http://localhost:5000');
