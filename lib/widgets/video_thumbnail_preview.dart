import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/widgets/video_controller_factory.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoThumbnailPreview extends StatefulWidget {
  final String source;
  final Widget fallback;
  final bool showPlayBadge;
  final double playBadgeSize;

  const VideoThumbnailPreview({
    super.key,
    required this.source,
    required this.fallback,
    this.showPlayBadge = true,
    this.playBadgeSize = 42,
  });

  @override
  State<VideoThumbnailPreview> createState() => _VideoThumbnailPreviewState();
}

class _VideoThumbnailPreviewState extends State<VideoThumbnailPreview> {
  VideoPlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant VideoThumbnailPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _disposeController();
      _initializeController();
    }
  }

  void _initializeController() {
    final source = widget.source.trim();
    if (!canCreateVideoPreviewController(source)) {
      _hasError = true;
      return;
    }

    try {
      final controller = createVideoPreviewController(source);
      _controller = controller;
      controller
        ..setLooping(false)
        ..setVolume(0);
      controller
          .initialize()
          .then((_) async {
            if (!mounted) return;
            await controller.pause();
            await controller.seekTo(Duration.zero);
            if (mounted) setState(() {});
          })
          .catchError((_) {
            if (mounted) setState(() => _hasError = true);
          });
    } catch (_) {
      _hasError = true;
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _hasError = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = controller?.value.isInitialized ?? false;

    if (_hasError || controller == null || !isReady) {
      return widget.fallback;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _CoverVideo(controller: controller),
        if (widget.showPlayBadge)
          Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: Appcolors.kwhitecolor.withValues(alpha: 0.9),
              size: widget.playBadgeSize,
            ),
          ),
      ],
    );
  }
}

class _CoverVideo extends StatelessWidget {
  final VideoPlayerController controller;

  const _CoverVideo({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = controller.value.size;
    if (size.width <= 0 || size.height <= 0) {
      return VideoPlayer(controller);
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}
