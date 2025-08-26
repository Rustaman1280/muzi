import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AlbumArtWidget extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double borderRadius;

  const AlbumArtWidget({
    super.key,
    this.imageUrl,
    this.size = 60.0,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPlaceholder(),
                errorWidget: (context, url, error) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.music_note,
        size: size * 0.5,
        color: Colors.grey[600],
      ),
    );
  }
}
