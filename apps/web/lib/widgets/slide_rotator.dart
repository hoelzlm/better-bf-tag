import 'dart:async';
import 'dart:typed_data';

import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rotates through [slides] in the monitor standby (ADR 0014, "Monitor"):
/// slide `i` is shown for its `durationSeconds`, then `i + 1` (cyclic); a
/// single slide is never rotated. When [slides] is updated, the currently
/// shown slide is kept (by id) if it still exists in the new list -- the
/// timer keeps running, only the index is recomputed -- otherwise rotation
/// restarts at index 0.
///
/// Uses a plain [Timer] (not an injected clock): widget tests drive it
/// deterministically via `WidgetTester.pump(duration)`, which fakes time
/// for timers created during the pumped frame (same approach as
/// `flutter_test`'s own animation driving).
class SlideRotator extends StatefulWidget {
  const SlideRotator({super.key, required this.slides});

  final List<Slide> slides;

  @override
  State<SlideRotator> createState() => _SlideRotatorState();
}

class _SlideRotatorState extends State<SlideRotator> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  @override
  void didUpdateWidget(covariant SlideRotator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.slides, widget.slides)) {
      return;
    }
    if (widget.slides.isEmpty) {
      _timer?.cancel();
      _timer = null;
      _index = 0;
      return;
    }
    final currentId = (_index < oldWidget.slides.length)
        ? oldWidget.slides[_index].id
        : null;
    final newIndex =
        currentId == null ? -1 : widget.slides.indexWhere((s) => s.id == currentId);
    if (newIndex == -1) {
      // The current slide is gone (or there was none): restart rotation.
      _index = 0;
      _scheduleNext();
    } else {
      // Still there, possibly at a different position: keep the timer
      // running (ADR 0014: "Timer läuft weiter"), just fix up the index.
      _index = newIndex;
      if (_timer == null) {
        _scheduleNext();
      }
    }
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = null;
    if (widget.slides.length <= 1) {
      return; // Single (or no) slide: no rotation.
    }
    final current = widget.slides[_index];
    _timer = Timer(Duration(seconds: current.durationSeconds), _advance);
  }

  void _advance() {
    if (!mounted || widget.slides.isEmpty) {
      return;
    }
    setState(() {
      _index = (_index + 1) % widget.slides.length;
    });
    _scheduleNext();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.slides;
    if (slides.isEmpty) {
      return const SizedBox.shrink();
    }
    final index = _index < slides.length ? _index : 0;
    final slide = slides[index];
    return _SlideView(key: ValueKey(slide.id), slide: slide);
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({super.key, required this.slide});

  final Slide slide;

  @override
  Widget build(BuildContext context) {
    final image = slide.image;
    return Padding(
      key: Key('slide-${slide.id}'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            slide.title,
            key: const Key('slide-title'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (image != null) ...[
                  Expanded(
                    child: _SlideImage(slideId: slide.id, version: image.version),
                  ),
                  const SizedBox(width: 24),
                ],
                Expanded(
                  flex: image != null ? 1 : 2,
                  child: SingleChildScrollView(
                    child: MarkdownBody(
                      key: const Key('slide-body'),
                      data: slide.body,
                      // ADR 0014: images embedded in the Markdown itself are
                      // not loaded.
                      imageBuilder: (uri, title, alt) =>
                          const SizedBox.shrink(),
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Colors.white, fontSize: 24),
                        strong: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        em: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontStyle: FontStyle.italic,
                        ),
                        h1: const TextStyle(color: Colors.white, fontSize: 32),
                        h2: const TextStyle(color: Colors.white, fontSize: 28),
                        listBullet:
                            const TextStyle(color: Colors.white, fontSize: 24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loads and shows a slide's image via [SlideImageLoader]; nothing while
/// loading or on error (ADR 0014: "Bild steht neben bzw. über dem Text").
class _SlideImage extends ConsumerStatefulWidget {
  const _SlideImage({required this.slideId, required this.version});

  final String slideId;
  final String version;

  @override
  ConsumerState<_SlideImage> createState() => _SlideImageState();
}

class _SlideImageState extends ConsumerState<_SlideImage> {
  late Future<Uint8List> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _SlideImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slideId != widget.slideId ||
        oldWidget.version != widget.version) {
      _future = _load();
    }
  }

  Future<Uint8List> _load() =>
      ref.read(slideImageLoaderProvider).load(widget.slideId, widget.version);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        return Image.memory(
          snapshot.data!,
          key: const Key('slide-image'),
          fit: BoxFit.contain,
        );
      },
    );
  }
}
