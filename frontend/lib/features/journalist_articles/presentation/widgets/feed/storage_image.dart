import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class StorageImage extends StatelessWidget {
  final String path;
  final Future<String> Function(String path) getUrl;

  const StorageImage({super.key, required this.path, required this.getUrl});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getUrl(path),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container(color: Colors.black);

        return CachedNetworkImage(
          imageUrl: snapshot.data!,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.black),
          errorWidget: (_, __, ___) => Container(color: Colors.black),
          fadeInDuration: const Duration(milliseconds: 120),
          memCacheWidth: 1080,
        );
      },
    );
  }
}
