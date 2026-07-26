import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Whether the Google/Facebook social-auth buttons should be shown.
///
/// Hidden on iOS (no CFBundleURLTypes registered — see OAUTH_SETUP.md).
/// `kIsWeb` must be checked FIRST: `Platform.isIOS` comes from dart:io and
/// throws UnsupportedError at runtime on Flutter web.
bool get showSocialAuth => kIsWeb || !Platform.isIOS;
