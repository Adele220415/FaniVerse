import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/constants/app_colors.dart';

/// A video player with the controls the app was missing: play/pause, a scrub
/// bar, elapsed/total time, mute and volume, plus fullscreen.
///
/// One [VideoPlayerController] is created per URL. Because a post can hold
/// several videos in a slideshow, the controller is created lazily and disposed
/// when the widget leaves the tree, so scrolling a feed does not accumulate
/// open media sessions.
class AppVideoPlayer extends StatefulWidget {
  const AppVideoPlayer({
    super.key,
    required this.url,
    this.autoPlay = false,
    this.loop = true,
    this.showControls = true,
  });

  final String url;

  /// Start playing as soon as the controller is ready. Off by default because
  /// autoplaying several videos in a feed is hostile.
  final bool autoPlay;

  final bool loop;

  /// When false, only the video surface is rendered (used for thumbnails).
  final bool showControls;

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  VideoPlayerController? _controller;
  String? _error;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  @override
  void didUpdateWidget(AppVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeController();
      _initialise();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Future<void> _initialise() async {
    setState(() {
      _initialised = false;
      _error = null;
    });

    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(widget.loop);
      if (widget.autoPlay) {
        await controller.play();
      }
      setState(() => _initialised = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not play this video');
      debugPrint('video init failed for ${widget.url}: $e');
    }
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _MessageBox(
        icon: Icons.videocam_off_outlined,
        message: _error!,
        onRetry: _initialise,
      );
    }

    final controller = _controller;
    if (controller == null || !_initialised) {
      return const Center(
        child: SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        if (widget.showControls) ...[
          // Tapping the surface toggles playback. GestureDetector wraps the
          // video rather than sitting on top of the control bar so the bar
          // keeps its own taps.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggle(controller),
            ),
          ),
          _buildControls(controller),
        ],
      ],
    );
  }

  void _toggle(VideoPlayerController controller) {
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  Widget _buildControls(VideoPlayerController controller) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final value = controller.value;
          final position = value.position;
          final duration = value.duration;

          return Column(
            children: [
              // Play/pause, centred over the video.
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: _RoundButton(
                    icon: value.isPlaying ? Icons.pause : Icons.play_arrow,
                    onPressed: () => _toggle(controller),
                    size: 56,
                  ),
                ),
              ),
              // Scrubber, times and volume.
              Container(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _formatDuration(position),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        colors: const VideoProgressColors(
                          playedColor: AppColors.primary,
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    const SizedBox(width: 4),
                    _VolumeButton(controller: controller),
                    IconButton(
                      onPressed: _openFullscreen,
                      icon: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                      tooltip: 'Fullscreen',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openFullscreen() {
    final controller = _controller;
    if (controller == null || !_initialised) return;

    // Orientation is only meaningful on mobile; on web and desktop the
    // landscape box is a no-op, so fullscreen is just a bigger surface.
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (context, animation, secondary) => _FullscreenVideo(url: widget.url),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  /// `m:ss` for short clips, `h:mm:ss` once past an hour.
  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      final h = d.inHours.toString().padLeft(2, '0');
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
    final m = d.inMinutes.toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _VolumeButton extends StatelessWidget {
  const _VolumeButton({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final volume = controller.value.volume;
        final muted = volume == 0;
        final icon = muted
            ? Icons.volume_off
            : volume < 0.5
                ? Icons.volume_down
                : Icons.volume_up;

        return PopupMenuButton<double>(
          tooltip: 'Volume',
          icon: Icon(icon, color: Colors.white, size: 20),
          color: AppColors.surface,
          onSelected: (value) {
            controller.setVolume(value);
            controller.setVolume(value == 0 ? 0 : value);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 0.0, child: Text('Mute')),
            PopupMenuItem(value: 0.25, child: Text('25%')),
            PopupMenuItem(value: 0.5, child: Text('50%')),
            PopupMenuItem(value: 0.75, child: Text('75%')),
            PopupMenuItem(value: 1.0, child: Text('100%')),
          ],
        );
      },
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onPressed, this.size = 40});

  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          height: size,
          width: size,
          child: Icon(icon, color: Colors.white, size: size * 0.55),
        ),
      ),
    );
  }
}

class _FullscreenVideo extends StatelessWidget {
  const _FullscreenVideo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: AppVideoPlayer(url: url, autoPlay: true, loop: true),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Close',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.icon, required this.message, this.onRetry});

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }
}
