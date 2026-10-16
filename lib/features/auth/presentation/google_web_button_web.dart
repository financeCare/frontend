import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

// GIS จำกัดความกว้างปุ่มสูงสุด 400px
Widget buildGoogleWebButton({double? width}) {
  return web.renderButton(
    configuration: web.GSIButtonConfiguration(
      type: web.GSIButtonType.standard,
      theme: web.GSIButtonTheme.outline,
      size: web.GSIButtonSize.large,
      text: web.GSIButtonText.continueWith,
      shape: web.GSIButtonShape.rectangular,
      logoAlignment: web.GSIButtonLogoAlignment.center,
      locale: 'th',
      minimumWidth: width?.clamp(1, 400).toDouble(),
    ),
  );
}
