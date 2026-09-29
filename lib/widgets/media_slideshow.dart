import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/constants/app_colors.dart';
import '../models/content_media.dart';
import 'app_video_player.dart';

/// Displays a post's [ContentMedia] list as a swipeable slideshow.
///
/// A post can now mix images, videos and audio. Each slide renders according to
/// its own type:
///
///  * **image** - a cached network image
///  * **video** - [AppVideoPlayer] with full controls
///  * **audio** - an audio bar with play/pause, seek and volume
///
/// Videos pause when the user swipes away from them, so a backgrounded clip
/// does not keep playing out of sight.
class MediaSlideshow extends StatefulWidget {
  const MediaSlideshow({
    super.key,
    required this.media,
    this.aspectRatio = 16 / 9,
    this.autoPlaySeconds = 5,
    this.showIndicator = true,
    this.intrinsicAspect = false,
  });

  final List<ContentMedia> media;

  /// Fallback ratio used when the current item's true size is unknown.
  final double aspectRatio;

  /// Delay before advancing past a still image. Videos and audio advance when
  /// they finish, not on this timer.
  final int autoPlaySeconds;

  final bool showIndicator;

  /// Size the slideshow to each item's own proportions instead of a fixed box.
  ///
  /// The detail view sets this so a portrait phone photo is shown 9:16 and a
  /// widescreen video 16:9, rather than both being squeezed into one shape.
  /// Needs [ContentMedia.width] and `.height`, which are recorded at upload
  /// time from the Cloudinary response. Items with no known size fall back to
  /// [aspectRatio].
  final bool intrinsicAspect;

  @override
  State<MediaSlideshow> createState() => _MediaSlideshowState();
}

class _MediaSlideshowState extends State<MediaSlideshow> {
  late final PageController _pageController;
  Timer? _advanceTimer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scheduleAdvance();
  }

  @override
  void didUpdateWidget(MediaSlideshow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.length != widget.media.length) {
      _index = 0;
      _scheduleAdvance();
    }
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _scheduleAdvance() {
    _advanceTimer?.cancel();
    // Only stills auto-advance, and only when there is somewhere to go.
    if (widget.media.length < 2) return;
    if (_current.isVideo || _current.isAudio) return;

    _advanceTimer = Timer(Duration(seconds: widget.autoPlaySeconds), () {
      if (!mounted || _index >= widget.media.length - 1) return;
      _goTo(_index + 1);
    });
  }

  ContentMedia get _current => widget.media[_index];

  void _goTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: _placeholder(),
      );
    }

    // Single item: no carousel affordances needed, just the one slide.
    if (widget.media.length == 1) {
      return _wrap(_slide(widget.media.first));
    }

    return _wrap(
      Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.media.length,
              onPageChanged: (index) {
                setState(() => _index = index);
                _scheduleAdvance();
              },
              itemBuilder: (context, index) => _slide(widget.media[index]),
            ),
          ),
          if (widget.showIndicator)
            Positioned(
              top: 8,
              right: 8,
              child: _Badge(text: '${_index + 1}/${widget.media.length}'),
            ),
          if (widget.showIndicator)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: _Dots(count: widget.media.length, active: _index),
            ),
        ],
      ),
    );
  }

  /// Optionally pins the slideshow to the current slide's real proportions, so
  /// the preview is not forced through one shape for every media type.
  Widget _wrap(Widget child) {
    if (!widget.intrinsicAspect) return child;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: _current.aspectRatio ?? widget.aspectRatio,
        child: child,
      ),
    );
  }

  Widget _slide(ContentMedia item) {
    if (item.isVideo) {
      // Only the visible slide plays; PageView builds neighbours too, so
      // autoPlay is keyed to the current index.
      return AppVideoPlayer(
        key: ValueKey(item.url),
        url: item.url,
        autoPlay: widget.media[_index].url == item.url,
      );
    }

    if (item.isAudio) {
      return _AudioSlide(key: ValueKey(item.url), url: item.url);
    }

    return CachedNetworkImage(
      imageUrl: item.url,
      fit: BoxFit.cover,
      placeholder: (context, _) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
      ),
      errorWidget: (context, _, __) => const Center(
        child: Icon(Icons.broken_image, color: Colors.white54, size: 32),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.black26,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.white38),
    );
  }
}

/// Audio playback. `video_player` handles audio-only URLs through the same
/// pipeline, so this reuses one controller type rather than adding a second
/// audio plugin.
class _AudioSlide extends StatefulWidget {
  const _AudioSlide({super.key, required this.url});

  final String url;

  @override
  State<_AudioSlide> createState() => _AudioSlideState();
}

class _AudioSlideState extends State<_AudioSlide> {
  VideoPlayerController? _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not play this audio');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: _error != null
          ? Text(_error!, style: const TextStyle(color: Colors.white70))
          : !_ready
              ? const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
              : _buildControls(),
    );
  }

  Widget _buildControls() {
    final controller = _controller!;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = controller.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.audiotrack, color: AppColors.primary, size: 36),
            const SizedBox(height: 12),
            SizedBox(
              width: 260,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppColors.primary,
                  bufferedColor: Colors.white38,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _fmt(value.position),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    setState(() {
                      value.isPlaying ? controller.pause() : controller.play();
                    });
                  },
                  icon: Icon(
                    value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _fmt(value.duration),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    final next = value.volume == 0 ? 1.0 : 0.0;
                    controller.setVolume(next);
                  },
                  icon: Icon(
                    value.volume == 0 ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: isActive ? 18 : 6,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white54,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
