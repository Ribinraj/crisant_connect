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
    return errorBuilder?.call(
          context,
          UnsupportedError('Local image previews are not supported here'),
          null,
        ) ??
        const SizedBox.shrink();
  }
}
