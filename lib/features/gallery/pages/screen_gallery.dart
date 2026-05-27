import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/core/responsiveutils.dart';
import 'package:crisant_connect/core/urls.dart';
import 'package:crisant_connect/features/gallery/blocs/media_library_bloc/media_library_bloc.dart';
import 'package:crisant_connect/features/gallery/models/uploads_response.dart';
import 'package:crisant_connect/widgets/app_background.dart';
import 'package:crisant_connect/widgets/crisant_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

class ScreenGallery extends StatefulWidget {
  const ScreenGallery({super.key});

  @override
  State<ScreenGallery> createState() => _ScreenGalleryState();
}

class _ScreenGalleryState extends State<ScreenGallery> {
  int _selectedFilter = 0;

  static const _filters = ['All Media', 'Images', 'Videos'];

  @override
  void initState() {
    super.initState();
    context.read<MediaLibraryBloc>().add(FetchMediaLibraryRequested());
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);

    return AppBackground(
      opacity: 0.35,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: CrisantAppBar()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.wp(6.2),
                ResponsiveUtils.hp(2.8),
                ResponsiveUtils.wp(6.2),
                ResponsiveUtils.hp(16),
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _GalleryIntro(),
                  SizedBox(height: ResponsiveUtils.hp(2.6)),
                  _FilterRow(
                    filters: _filters,
                    selectedIndex: _selectedFilter,
                    onSelected: (index) =>
                        setState(() => _selectedFilter = index),
                  ),
                  SizedBox(height: ResponsiveUtils.hp(3.1)),
                  BlocBuilder<MediaLibraryBloc, MediaLibraryState>(
                    builder: (context, state) {
                      if (state is MediaLibraryLoading ||
                          state is MediaLibraryInitial) {
                        return const _AssetsLoading();
                      }

                      if (state is MediaLibraryFailure) {
                        return _AssetsError(
                          message: state.message,
                          onRetry: () => context.read<MediaLibraryBloc>().add(
                            FetchMediaLibraryRequested(),
                          ),
                        );
                      }

                      final media = state is MediaLibrarySuccess
                          ? state.media
                          : const <MediaAsset>[];
                      return _AssetGrid(assets: _filteredAssets(media));
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<MediaAsset> _filteredAssets(List<MediaAsset> assets) {
    if (_selectedFilter == 1) {
      return assets.where((asset) => asset.isImage).toList();
    }
    if (_selectedFilter == 2) {
      return assets.where((asset) => asset.isVideo).toList();
    }
    return assets;
  }
}

class _GalleryIntro extends StatelessWidget {
  const _GalleryIntro();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media Library',
          style: TextStyle(
            color: const Color(0xFF111827),
            fontSize: ResponsiveUtils.sp(8.3).clamp(30, 38),
            fontWeight: FontWeight.w900,
            height: 1.04,
          ),
        ),
        SizedBox(height: ResponsiveUtils.hp(1.1)),
        Text(
          'Browse creative media',
          style: TextStyle(
            color: Appcolors.ktextdark,
            fontSize: ResponsiveUtils.sp(4.6).clamp(17, 21),
            fontWeight: FontWeight.w500,
            height: 1.28,
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _FilterRow({
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: List.generate(filters.length, (index) {
          final selected = index == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: ResponsiveUtils.wp(3.2)),
            child: ChoiceChip(
              label: Text(filters[index]),
              selected: selected,
              onSelected: (_) => onSelected(index),
              showCheckmark: false,
              backgroundColor: Appcolors.kgreyColor.withValues(alpha: 0.18),
              selectedColor: const Color(0xFFB34708),
              labelStyle: TextStyle(
                color: selected ? Appcolors.kwhitecolor : Appcolors.ktextdark,
                fontSize: ResponsiveUtils.sp(3.8).clamp(14, 17),
                fontWeight: FontWeight.w800,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.wp(3.4).clamp(13, 18),
                vertical: 12,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AssetGrid extends StatelessWidget {
  final List<MediaAsset> assets;

  const _AssetGrid({required this.assets});

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return const _EmptyAssets();
    }

    final spacing = ResponsiveUtils.wp(4.4).clamp(14, 22).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 680 ? 3 : 2;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final tileHeight = tileWidth * 1.32;

        return Wrap(
          spacing: spacing,
          runSpacing: ResponsiveUtils.hp(2.6).clamp(18, 26).toDouble(),
          children: assets
              .map(
                (asset) => SizedBox(
                  width: tileWidth,
                  height: tileHeight,
                  child: _AssetTile(asset: asset),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _AssetTile extends StatelessWidget {
  final MediaAsset asset;

  const _AssetTile({required this.asset});

  Future<void> _openVideoPlayer(BuildContext context) async {
    if (!asset.isVideo || asset.url.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VideoPlayerSheet(asset: asset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: asset.isVideo ? () => _openVideoPlayer(context) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (asset.isImage && asset.url.isNotEmpty)
              Image.network(
                asset.resolvedUrl(Endpoints.mediaBaseUrl),
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (_, _, _) => _AssetFallback(asset: asset),
              )
            else
              _AssetFallback(asset: asset),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Appcolors.kblackcolor.withValues(alpha: 0.06),
                    Appcolors.kblackcolor.withValues(alpha: 0),
                    Appcolors.kblackcolor.withValues(alpha: 0.16),
                  ],
                ),
              ),
            ),
            if (asset.isImage)
              Positioned(
                top: 16,
                right: 14,
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Appcolors.kwhitecolor.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Appcolors.kblackcolor.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.image_rounded,
                    size: 24,
                    color: const Color(0xFFB34708),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    asset.name.isEmpty ? asset.storedName : asset.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Appcolors.kwhitecolor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    asset.formattedSize,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Appcolors.kwhitecolor.withValues(alpha: 0.86),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerSheet extends StatefulWidget {
  final MediaAsset asset;

  const _VideoPlayerSheet({required this.asset});

  @override
  State<_VideoPlayerSheet> createState() => _VideoPlayerSheetState();
}

class _VideoPlayerSheetState extends State<_VideoPlayerSheet> {
  late final VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(
            Uri.parse(widget.asset.resolvedUrl(Endpoints.mediaBaseUrl)),
          )
          ..setLooping(false)
          ..initialize()
              .then((_) {
                if (!mounted) return;
                setState(() {});
                _controller.play();
              })
              .catchError((_) {
                if (mounted) setState(() => _hasError = true);
              });
    _controller.addListener(_onVideoChanged);
  }

  void _onVideoChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _controller.value.isInitialized;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            decoration: const BoxDecoration(
              color: Appcolors.kwhitecolor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8DDD9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.asset.name.isEmpty
                            ? widget.asset.storedName
                            : widget.asset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1A2028),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            color: const Color(0xFF111827),
                            child: AspectRatio(
                              aspectRatio: isReady
                                  ? _controller.value.aspectRatio
                                  : 16 / 9,
                              child: _hasError
                                  ? const Center(
                                      child: Icon(
                                        Icons.error_outline_rounded,
                                        color: Appcolors.kwhitecolor,
                                        size: 38,
                                      ),
                                    )
                                  : isReady
                                  ? VideoPlayer(_controller)
                                  : const Center(
                                      child: CircularProgressIndicator(
                                        color: Appcolors.kprimarycolor,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (isReady && !_hasError) ...[
                          VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: Appcolors.kprimarycolor,
                              bufferedColor: Color(0xFFFFD3C8),
                              backgroundColor: Color(0xFFE8DDD9),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              IconButton.filled(
                                onPressed: () {
                                  _controller.value.isPlaying
                                      ? _controller.pause()
                                      : _controller.play();
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: Appcolors.kprimarycolor,
                                  foregroundColor: Appcolors.kwhitecolor,
                                ),
                                icon: Icon(
                                  _controller.value.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _formatDuration(_controller.value.position),
                                style: const TextStyle(
                                  color: Color(0xFF5A3A33),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                ' / ',
                                style: TextStyle(
                                  color: Color(0xFF7A6C66),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _formatDuration(_controller.value.duration),
                                style: const TextStyle(
                                  color: Color(0xFF7A6C66),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _AssetFallback extends StatelessWidget {
  final MediaAsset asset;

  const _AssetFallback({required this.asset});

  @override
  Widget build(BuildContext context) {
    final colors = asset.isVideo
        ? const [Color(0xFF102A43), Color(0xFF315C72), Color(0xFFF37A65)]
        : const [Color(0xFF3A2017), Color(0xFFD56F45), Color(0xFFFFD4C7)];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          asset.isVideo ? Icons.play_circle_fill_rounded : Icons.image_rounded,
          color: Appcolors.kwhitecolor.withValues(alpha: 0.72),
          size: 52,
        ),
      ),
    );
  }
}

class _AssetsLoading extends StatelessWidget {
  const _AssetsLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Appcolors.kprimarycolor),
      ),
    );
  }
}

class _AssetsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AssetsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Appcolors.kredcolor,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF28313D),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyAssets extends StatelessWidget {
  const _EmptyAssets();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.collections_rounded, color: Color(0xFF96A3B2), size: 36),
          SizedBox(height: 10),
          Text(
            'No assets found',
            style: TextStyle(
              color: Color(0xFF28313D),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
