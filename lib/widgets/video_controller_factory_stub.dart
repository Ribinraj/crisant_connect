import 'package:video_player/video_player.dart';

VideoPlayerController createPlatformVideoController(String source) {
  final uri = Uri.tryParse(source);
  if (uri != null && uri.hasScheme) {
    return VideoPlayerController.networkUrl(uri);
  }

  throw UnsupportedError('Local video previews are not supported here');
}

bool canCreatePlatformVideoController(String source) {
  final uri = Uri.tryParse(source.trim());
  return uri != null && uri.hasScheme;
}
