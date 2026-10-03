// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Web implementation using Web Speech Synthesis API
void speakAloud(String text) {
  try {
    final sanitized = text.replaceAll("'", "\\'").replaceAll('"', '\\"');
    js.context.callMethod('eval', [
      "if ('speechSynthesis' in window) { "
      "  window.speechSynthesis.cancel(); "
      "  const u = new SpeechSynthesisUtterance('$sanitized'); "
      "  u.rate = 0.95; "
      "  u.pitch = 1.0; "
      "  u.lang = 'en-US'; "
      "  window.speechSynthesis.speak(u); "
      "}"
    ]);
  } catch (_) {
    // Graceful fallback if Web Speech is blocked by browser policies
  }
}
