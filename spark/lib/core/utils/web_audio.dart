// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Simple HTML5 audio player for Flutter Web.
class WebAudio {
  html.AudioElement? _el;

  bool get isPlaying => _el != null && !(_el!.paused);

  Future<void> play(String url) async {
    await stop();
    _el = html.AudioElement(url);
    _el!.crossOrigin = 'anonymous';
    await _el!.play();
  }

  Future<void> pause() async {
    _el?.pause();
  }

  Future<void> stop() async {
    _el?.pause();
    _el?.src = '';
    _el = null;
  }

  void dispose() {
    _el?.pause();
    _el = null;
  }
}
