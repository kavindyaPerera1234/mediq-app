import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../constants/app_accessibility.dart';

// Conditionally import js only on web
import 'voice_speaker_stub.dart'
    if (dart.library.js) 'voice_speaker_web.dart' as speaker;

class VoiceGuidanceService {
  /// Notifier indicating if voice announcement audio is actively speaking
  static final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);
  static Timer? _speakTimer;

  /// Speaks the given text aloud if Voice Guidance is enabled (or forced during tests)
  static void speak(String text, {BuildContext? context, bool force = false}) {
    if (!force && !AppAccessibility.isVoiceGuidance.value) return;

    _speakTimer?.cancel();
    isSpeaking.value = true;
    final words = text.split(RegExp(r'\s+')).length;
    final durationSec = (words * 0.45).clamp(4.0, 16.0).toInt();
    _speakTimer = Timer(Duration(seconds: durationSec), () {
      isSpeaking.value = false;
    });

    // 1. Native Flutter Semantics announcement for TalkBack / VoiceOver / Narrator
    SemanticsService.announce(text, TextDirection.ltr);

    // 2. Audible speech via Web Speech API & Hospital Chime
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
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: durationSec),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// Immediately cancels any active spoken audio
  static void stop({BuildContext? context}) {
    _speakTimer?.cancel();
    isSpeaking.value = false;
    try {
      speaker.stopSpeaking();
    } catch (_) {}
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }
}
