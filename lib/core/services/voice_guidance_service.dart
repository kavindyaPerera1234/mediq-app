import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../constants/app_accessibility.dart';

// Conditionally import js only on web
import 'voice_speaker_stub.dart'
    if (dart.library.js) 'voice_speaker_web.dart' as speaker;

class VoiceGuidanceService {
  /// Speaks the given text aloud if Voice Guidance is enabled
  static void speak(String text, {BuildContext? context}) {
    if (!AppAccessibility.isVoiceGuidance.value) return;

    // 1. Native Flutter Semantics announcement for TalkBack / VoiceOver / Narrator
    SemanticsService.announce(text, TextDirection.ltr);

    // 2. Audible speech via Web Speech API (when running on Chrome/Edge Web)
    try {
      speaker.speakAloud(text);
    } catch (e) {
      debugPrint("Voice speech notice: $e");
    }

    // 3. Visual feedback banner if context is available
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.volume_up_rounded, color: Colors.amberAccent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
