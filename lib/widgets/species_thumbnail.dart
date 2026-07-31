import 'package:flutter/material.dart';
import '../services/species_thumbnail_service.dart';
import '../theme/app_theme.dart';

/// Small circular species photo, fetched by scientific name. Falls back to a
/// leaf icon while loading or if no photo is found.
class SpeciesThumbnail extends StatelessWidget {
  final String scientificName;
  final double size;

  const SpeciesThumbnail({super.key, required this.scientificName, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: FutureBuilder<String?>(
          future: SpeciesThumbnailService.instance.getThumbnailUrl(scientificName),
          builder: (context, snapshot) {
            final url = snapshot.data;
            if (url != null) {
              return Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              );
            }
            return _placeholder();
          },
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.neutral800,
      child: Icon(Icons.eco_outlined, size: size * 0.55, color: AppColors.neutral500),
    );
  }
}
