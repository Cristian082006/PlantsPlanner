import 'package:flutter/material.dart';
import '../data/care_info.dart';
import '../theme/app_theme.dart';

/// Shows a warning dialog when a plant with moderate/severe pet toxicity is
/// assigned to a room — a no-op for none/mild toxicity.
Future<void> maybeShowToxicityRoomWarning({
  required BuildContext context,
  required String plantName,
  required String room,
  required ToxicityLevel level,
}) async {
  if (level != ToxicityLevel.moderate && level != ToxicityLevel.severe) return;
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.accent2_300),
          const SizedBox(width: 8),
          const Expanded(child: Text('Atenție la animale')),
        ],
      ),
      content: Text(
        '„$plantName" are ${toxicityLevelLabelRo(level).toLowerCase()} pentru animale de companie. '
        'Dacă ai un animal cu acces în camera „$room", ține planta la distanță sau într-un loc ridicat, '
        'mai ales dacă are tendința să mestece frunze.',
        style: TextStyle(color: AppColors.text),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Am înțeles')),
      ],
    ),
  );
}
