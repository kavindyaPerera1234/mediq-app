// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Web implementation using Web Audio Hospital Chime + Web Speech Synthesis API
void speakAloud(String text) {
  try {
    final sanitized = text.replaceAll("'", "\\'").replaceAll('"', '\\"').replaceAll('\n', ' ');
    js.context.callMethod('eval', [
      """
      (function() {
        try {
          // 1. Play Hospital Announcement Chime (Ding-Dong 🔔) via Web Audio API
          const AudioCtx = window.AudioContext || window.webkitAudioContext;
          if (AudioCtx) {
            const ctx = new AudioCtx();
            if (ctx.state === 'suspended') {
              ctx.resume();
            }
            const now = ctx.currentTime;
            
            // First chime tone (high - 659.25 Hz - E5)
            const osc1 = ctx.createOscillator();
            const gain1 = ctx.createGain();
            osc1.type = 'sine';
            osc1.frequency.setValueAtTime(659.25, now);
            gain1.gain.setValueAtTime(0.18, now);
            gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.45);
            osc1.connect(gain1);
            gain1.connect(ctx.destination);
            osc1.start(now);
            osc1.stop(now + 0.45);

            // Second chime tone (pleasant - 523.25 Hz - C5)
            const osc2 = ctx.createOscillator();
            const gain2 = ctx.createGain();
            osc2.type = 'sine';
            osc2.frequency.setValueAtTime(523.25, now + 0.22);
            gain2.gain.setValueAtTime(0.20, now + 0.22);
            gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.85);
            osc2.connect(gain2);
            gain2.connect(ctx.destination);
            osc2.start(now + 0.22);
            osc2.stop(now + 0.85);
          }
        } catch (e) {
          console.warn('Audio chime warning:', e);
        }

        // 2. Synthesize Speech Announcement
        if ('speechSynthesis' in window) {
          try {
            window.speechSynthesis.cancel();
            if (window.speechSynthesis.paused) {
              window.speechSynthesis.resume();
            }
            const u = new SpeechSynthesisUtterance('$sanitized');
            u.rate = 0.92;
            u.pitch = 1.0;
            
            // Detect Sinhala / Tamil / English characters
            if (/[\\u0D80-\\u0DFF]/.test('$sanitized')) {
              u.lang = 'si-LK';
            } else if (/[\\u0B80-\\u0BFF]/.test('$sanitized')) {
              u.lang = 'ta-LK';
            } else {
              u.lang = 'en-US';
            }
            
            // Delay voice slightly to follow the chime naturally
            setTimeout(function() {
              window.speechSynthesis.speak(u);
            }, 300);
          } catch (e) {
            console.warn('TTS warning:', e);
          }
        }
      })();
      """
    ]);
  } catch (_) {
    // Graceful fallback if Web Speech / Audio is blocked
  }
}
