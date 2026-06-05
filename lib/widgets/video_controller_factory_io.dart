import 'dart:io';

import 'package:video_player/video_player.dart';

VideoPlayerController createPlatformVideoController(String source) {
  final uri = Uri.tryParse(source);
  if (uri != null && uri.hasScheme && uri.scheme != 'file') {
    return VideoPlayerController.networkUrl(uri);
  }

  if (uri != null && uri.scheme == 'file') {
    return VideoPlayerController.file(File.fromUri(uri));
  }

  return VideoPlayerController.file(File(source));
}

bool canCreatePlatformVideoController(String source) {
  return source.trim().isNotEmpty;
}
