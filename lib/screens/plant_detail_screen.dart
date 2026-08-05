import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../data/care_info.dart';
import '../db/database_service.dart';
import '../services/notification_service.dart';
import '../services/photo_paths.dart';
import '../theme/app_theme.dart';
import '../widgets/plants_backdrop.dart';
import '../widgets/toxicity_warning.dart';
import 'diagnose_screen.dart';
import 'light_meter_screen.dart';

const _kClearRoomValue = '__clear_room__';

enum _JournalEntryKind { camera, gallery, noteOnly }

const _kRoMonths = [
  'ian',
  'feb',
  'mar',
  'apr',
  'mai',
  'iun',
  'iul',
  'aug',
  'sep',
  'oct',
  'nov',
  'dec',
];

String _formatDateRo(DateTime date) {
  return '${date.day} ${_kRoMonths[date.month - 1]} ${date.year}';
}

class PlantDetailScreen extends StatefulWidget {
  final int plantId;

  const PlantDetailScreen({super.key, required this.plantId});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  PlantRow? _plant;
  List<ReminderRow> _reminders = [];
  List<PlantPhotoRow> _photos = [];

  /// The watering reminder's actual (weather/month-adjusted) interval, if a
  /// reminder exists yet — falls back to the species base while reminders
  /// are still loading.
  int get _currentWateringIntervalDays {
    for (final reminder in _reminders) {
      if (reminder.type == 'udare') return reminder.intervalDays;
    }
    return _plant?.wateringDays ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final plant = await DatabaseService.instance.getPlant(widget.plantId);
    final reminders = await DatabaseService.instance.getRemindersForPlant(
      widget.plantId,
    );
    final photos = await DatabaseService.instance.getPhotosForPlant(
      widget.plantId,
    );
    if (!mounted) return;
    setState(() {
      _plant = plant;
      _reminders = reminders;
      _photos = photos;
    });
  }

  Future<void> _addJournalEntry({ImageSource? source}) async {
    String? storedPath;
    if (source != null) {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
      );
      if (picked == null || !mounted) return;

      final docsDir = await getApplicationDocumentsDirectory();
      final fileName =
          'plant_journal_${widget.plantId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fullPath = p.join(docsDir.path, fileName);
      await File(picked.path).copy(fullPath);
      storedPath = PhotoPaths.toStored(fullPath);
    }

    if (!mounted) return;
    final note = await _promptForNote(hasPhoto: storedPath != null);
    if (note == null) return; // renunțat din dialog
    if (storedPath == null && note.trim().isEmpty) return; // nimic de salvat

    await DatabaseService.instance.addPlantPhoto(
      plantId: widget.plantId,
      path: storedPath ?? '',
      note: note.trim().isEmpty ? null : note.trim(),
    );
    if (storedPath != null) {
      // Cea mai recentă poză din jurnal devine și poza principală a
      // plantei, afișată în lista "Plantele mele" și în capul ecranului.
      await DatabaseService.instance.updatePlantPhoto(
        id: widget.plantId,
        photoPath: storedPath,
      );
    }
    await _refresh();
  }

  Future<String?> _promptForNote({required bool hasPhoto}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hasPhoto ? 'Notiță (opțional)' : 'Notiță'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: TextStyle(color: AppColors.text),
          decoration: const InputDecoration(
            hintText: 'Ex: a înflorit, am repotat, frunză nouă...',
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Renunță'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Salvează'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickJournalEntrySource() async {
    final choice = await showModalBottomSheet<_JournalEntryKind>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: AppColors.accent),
              title: Text('Fă o poză', style: TextStyle(color: AppColors.text)),
              onTap: () => Navigator.pop(ctx, _JournalEntryKind.camera),
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library_outlined,
                color: AppColors.accent,
              ),
              title: Text(
                'Alege din galerie',
                style: TextStyle(color: AppColors.text),
              ),
              onTap: () => Navigator.pop(ctx, _JournalEntryKind.gallery),
            ),
            ListTile(
              leading: Icon(Icons.edit_note, color: AppColors.accent),
              title: Text(
                'Doar o notiță',
                style: TextStyle(color: AppColors.text),
              ),
              onTap: () => Navigator.pop(ctx, _JournalEntryKind.noteOnly),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    switch (choice) {
      case _JournalEntryKind.camera:
        await _addJournalEntry(source: ImageSource.camera);
        break;
      case _JournalEntryKind.gallery:
        await _addJournalEntry(source: ImageSource.gallery);
        break;
      case _JournalEntryKind.noteOnly:
        await _addJournalEntry();
        break;
      case null:
        break;
    }
  }

  Future<void> _deleteJournalPhoto(PlantPhotoRow photo) async {
    await DatabaseService.instance.deletePlantPhoto(photo.id);
    await _refresh();
  }

  Future<void> _onMarkDone(ReminderRow reminder) async {
    await NotificationService.instance.markReminderDoneAndReschedule(
      reminder,
      _plant!.commonName,
    );
    await _refresh();
  }

  Future<void> _onDelete() async {
    final plant = _plant;
    if (plant == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Șterge planta'),
        content: Text(
          'Sigur vrei să ștergi „${plant.commonName}"?',
          style: TextStyle(color: AppColors.text),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulează'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    for (final r in _reminders) {
      await NotificationService.instance.cancel(r.notificationId);
    }
    await DatabaseService.instance.deletePlant(plant.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _editRoom() async {
    final plant = _plant;
    if (plant == null) return;
    // showModalBottomSheet<String>'s future resolves to null both when the
    // user dismisses without choosing AND when we'd want to represent "no
    // room" — so use a sentinel for "clear the room" instead of null.
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cameră',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final room in kCommonRooms)
                    AppTag(
                      text: room,
                      style: plant.room == room
                          ? AppTagStyle.accent
                          : AppTagStyle.outline,
                      onTap: () => Navigator.pop(ctx, room),
                    ),
                  if (plant.room != null)
                    AppTag(
                      text: 'Fără cameră',
                      style: AppTagStyle.outline,
                      onTap: () => Navigator.pop(ctx, _kClearRoomValue),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null) return;
    final newRoom = result == _kClearRoomValue ? null : result;
    await DatabaseService.instance.updatePlantRoom(id: plant.id, room: newRoom);
    await _refresh();

    if (newRoom != null && mounted) {
      await maybeShowToxicityRoomWarning(
        context: context,
        plantName: plant.commonName,
        room: newRoom,
        level: getCareInfo(plant.scientificName).toxicityLevel,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plant = _plant;
    if (plant == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final meta = lightMeta(lightNeedFromDb(plant.light));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PlantsBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                child: Row(
                  children: [
                    AppGhostIconButton(
                      icon: Icons.chevron_left,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Detalii plantă',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    AppGhostIconButton(
                      icon: Icons.delete_outline,
                      onPressed: _onDelete,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    if (plant.photoPath != null &&
                        File(PhotoPaths.resolve(plant.photoPath!)).existsSync())
                      Image.file(
                        File(PhotoPaths.resolve(plant.photoPath!)),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Container(height: 200, color: AppColors.surface),
                      )
                    else
                      Container(height: 200, color: AppColors.surface),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plant.commonName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            plant.scientificName,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.neutral400,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _editRoom,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.room_outlined,
                                  size: 14,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  plant.room ?? 'Adaugă cameră',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Îngrijire',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.neutral400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _CareRow(
                            icon: Icons.water_drop_outlined,
                            text:
                                'Udare: la fiecare $_currentWateringIntervalDays zile'
                                '${_currentWateringIntervalDays != plant.wateringDays ? ' (ajustat din ${plant.wateringDays}, vreme/lună)' : ''}',
                          ),
                          _CareRow(icon: meta.icon, text: meta.tag),
                          if (plant.misting)
                            const _CareRow(
                              icon: Icons.water_outlined,
                              text: 'Beneficiază de pulverizare frecventă',
                            ),
                          if (plant.toxicToPets)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: _CareRow(
                                icon: Icons.pets,
                                text:
                                    '${toxicityLevelLabelRo(getCareInfo(plant.scientificName).toxicityLevel)} pentru animale de companie',
                                color: AppColors.accent2_300,
                                fontSize: 13,
                              ),
                            ),
                          for (final tip in plant.tips)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '· $tip',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.neutral400,
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DiagnoseScreen(
                                    plantCommonName: plant.commonName,
                                  ),
                                ),
                              ),
                              icon: const Icon(
                                Icons.health_and_safety_outlined,
                              ),
                              label: const Text(
                                'Diagnostichează boli sau dăunători',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LightMeterScreen(
                                    plantName: plant.commonName,
                                    targetLight: lightNeedFromDb(plant.light),
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.wb_sunny_outlined),
                              label: const Text('Măsoară lumina aici'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Text(
                                'Jurnal',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.neutral400,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _pickJournalEntrySource,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      size: 16,
                                      color: AppColors.accent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Adaugă în jurnal',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_photos.isEmpty)
                            Text(
                              'Adaugă poze și notițe în timp ca să vezi evoluția plantei.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.neutral400,
                              ),
                            )
                          else
                            Column(
                              children: [
                                for (final entry in _photos) ...[
                                  _JournalTimelineEntry(
                                    entry: entry,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => _JournalPhotoViewer(
                                          photo: entry,
                                          onDelete: () async {
                                            await _deleteJournalPhoto(entry);
                                            if (context.mounted) {
                                              Navigator.of(context).pop();
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    onDelete: () => _deleteJournalPhoto(entry),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ],
                            ),
                          const SizedBox(height: 20),
                          Text(
                            'Remindere',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.neutral400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final reminder in _reminders) ...[
                            AppCard(
                              child: Row(
                                children: [
                                  Icon(
                                    reminderTypeIcon(reminder.type),
                                    color: AppColors.accent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reminder.label,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.text,
                                          ),
                                        ),
                                        Text(
                                          'Următor: ${_formatDateRo(DateTime.fromMillisecondsSinceEpoch(reminder.nextDueAt))} · la fiecare ${reminder.intervalDays} zile',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.neutral400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => _onMarkDone(reminder),
                                    child: const Text('Marchează făcut'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row in the plant's journal timeline — a photo, a note, or both. Photo
/// entries open the full-screen viewer (which owns delete); note-only
/// entries delete directly from an inline icon since there's nothing to
/// zoom into.
class _JournalTimelineEntry extends StatelessWidget {
  final PlantPhotoRow entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _JournalTimelineEntry({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(entry.createdAt);
    return AppCard(
      onTap: entry.hasPhoto ? onTap : null,
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.hasPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.file(
                File(PhotoPaths.resolve(entry.path)),
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 52,
                  height: 52,
                  color: AppColors.neutral800,
                ),
              ),
            )
          else
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.accent800,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.edit_note,
                color: AppColors.accent200,
                size: 22,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateRo(date),
                  style: TextStyle(fontSize: 11, color: AppColors.neutral400),
                ),
                if (entry.note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.note!,
                    style: TextStyle(fontSize: 13, color: AppColors.text),
                  ),
                ],
              ],
            ),
          ),
          if (!entry.hasPhoto)
            GestureDetector(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.neutral500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _JournalPhotoViewer extends StatelessWidget {
  final PlantPhotoRow photo;
  final VoidCallback onDelete;

  const _JournalPhotoViewer({required this.photo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(photo.createdAt);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  AppGhostIconButton(
                    icon: Icons.chevron_left,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDateRo(date),
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Image.file(
                  File(PhotoPaths.resolve(photo.path)),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (photo.note != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  photo.note!,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Șterge poza'),
        content: const Text('Sigur vrei să ștergi această poză din jurnal?'),
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulează'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }
}

class _CareRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final double fontSize;

  const _CareRow({
    required this.icon,
    required this.text,
    this.color,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? AppColors.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: fontSize,
            color: color == null ? AppColors.accent : textColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: fontSize, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
