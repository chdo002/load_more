// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

bool isMobile() {
  RegExp exp = RegExp(r'\b(ios|android)\b', caseSensitive: false);
  return exp.hasMatch(html.window.navigator.userAgent);
}
