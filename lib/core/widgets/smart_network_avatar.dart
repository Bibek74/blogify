import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class SmartNetworkAvatar extends StatefulWidget {
  final double radius;
  final List<String> imageUrls;
  final Widget fallback;
  final Color? backgroundColor;

  const SmartNetworkAvatar({
    super.key,
    required this.radius,
    required this.imageUrls,
    required this.fallback,
    this.backgroundColor,
  });

  @override
  State<SmartNetworkAvatar> createState() => _SmartNetworkAvatarState();
}

class _SmartNetworkAvatarState extends State<SmartNetworkAvatar> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant SmartNetworkAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.imageUrls, widget.imageUrls)) {
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;
    final imageProvider = (_index < urls.length)
        ? NetworkImage(urls[_index])
        : null;
    final imageErrorHandler = imageProvider == null
        ? null
        : (exception, stackTrace) {
            if (!mounted) return;
            if (_index < urls.length) {
              setState(() {
                _index += 1;
              });
            }
          };

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      backgroundImage: imageProvider,
      onBackgroundImageError: imageErrorHandler,
      child: imageProvider == null ? widget.fallback : null,
    );
  }
}
