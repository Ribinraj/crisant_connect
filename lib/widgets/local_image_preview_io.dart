import 'dart:io';

import 'package:flutter/material.dart';

class LocalImagePreview extends StatelessWidget {
  final String source;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  const LocalImagePreview({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(source);
    final file = uri != null && uri.scheme == 'file'
        ? File.fromUri(uri)
        : File(source);

    return Image.file(file, fit: fit, errorBuilder: errorBuilder);
  }
}
