import 'dart:io';
import 'package:flutter/material.dart';
import '../data/care_info.dart';
import '../db/database_service.dart';
import '../services/notification_service.dart';
import '../services/onboarding_keys.dart';
import '../services/photo_paths.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/plants_backdrop.dart';
import '../widgets/toxicity_warning.dart';
import 'plant_detail_screen.dart';

const _kRoMonthsShort = [
  'ianuarie',
  'februarie',
  'martie',
  'aprilie',
  'mai',
  'iunie',
  'iulie',
  'august',
  'septembrie',
  'octombrie',
  'noiembrie',
  'decembrie',
];

class _RoomGroup {
  final String? room;
  final List<PlantRow> plants;

  const _RoomGroup({required this.room, required this.plants});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  // La nivel de sesiune, nu de instanță: sincronizarea automată la vreme
  // rulează o singură dată per pornire a aplicației, nu de fiecare dată
  // când revii pe tab-ul "Plantele mele" — altfel datele de udare s-ar tot
  // deplasa la fiecare refresh.
  static bool _autoSyncedThisSession = false;

  List<PlantRow> _plants = [];
  List<ReminderWithPlant> _due = [];
  WeatherReading? _weather;
  bool _syncingWeather = false;
  String? _selectedRoom;

  // Shared between the room chips and the dragged plant card so that
  // whichever room is currently a drop target can stand out (its neighbors
  // and the dragged card itself dim) without needing any z-order tricks.
  final ValueNotifier<String?> _hoveredRoom = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    refresh();
    _loadWeather();
  }

  @override
  void dispose() {
    _hoveredRoom.dispose();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    final weather = await WeatherService.instance.getCurrentWeather();
    if (mounted && weather != null) {
      setState(() => _weather = weather);
    }

    // Rulează sincronizarea o dată per sesiune chiar și fără temperatură
    // (ex. permisiune de locație refuzată) — ajustarea după lună tot se
    // aplică, doar cea după temperatură lipsește.
    if (!_autoSyncedThisSession) {
      _autoSyncedThisSession = true;
      await _syncWateringToWeather();
    }
  }

  Future<void> _syncWateringToWeather() async {
    if (_syncingWeather) return;
    setState(() => _syncingWeather = true);
    try {
      await NotificationService.instance.recalculateAllWateringReminders();
      await refresh();
    } finally {
      if (mounted) setState(() => _syncingWeather = false);
    }
  }

  Future<void> refresh() async {
    final plants = await DatabaseService.instance.getPlants();
    final due = await DatabaseService.instance.getDueReminders();
    if (!mounted) return;
    setState(() {
      _plants = plants;
      _due = due;
    });
  }

  Future<void> _onMarkDone(ReminderWithPlant item) async {
    await NotificationService.instance.markReminderDoneAndReschedule(
      item.reminder,
      item.plantCommonName,
    );
    await refresh();
  }

  Future<void> _moveToRoom(PlantRow plant, String room) async {
    if (plant.room == room) return;
    await DatabaseService.instance.updatePlantRoom(id: plant.id, room: room);
    await refresh();
    if (!mounted) return;
    await maybeShowToxicityRoomWarning(
      context: context,
      plantName: plant.commonName,
      room: room,
      level: getCareInfo(plant.scientificName).toxicityLevel,
    );
  }

  /// Groups plants by room, sorted alphabetically, with plants that have no
  /// room in their own bucket. If nobody has a room assigned yet, that
  /// bucket is returned without a label so the list looks exactly like the
  /// flat, ungrouped view it used to be.
  List<_RoomGroup> _groupedByRoom() {
    final byRoom = <String, List<PlantRow>>{};
    final unassigned = <PlantRow>[];
    for (final plant in _plants) {
      final room = plant.room;
      if (_selectedRoom != null && room != _selectedRoom) continue;
      if (room == null || room.isEmpty) {
        unassigned.add(plant);
      } else {
        byRoom.putIfAbsent(room, () => []).add(plant);
      }
    }

    final roomNames = byRoom.keys.toList()..sort();
    return [
      for (final name in roomNames)
        _RoomGroup(room: name, plants: byRoom[name]!),
      if (unassigned.isNotEmpty)
        _RoomGroup(
          room: roomNames.isEmpty ? null : 'Fără cameră',
          plants: unassigned,
        ),
    ];
  }

  Widget _roomChipsRow() {
    return Container(
      key: OnboardingKeys.roomChipsRow,
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: kCommonRooms.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final room = kCommonRooms[i];
            return _RoomChip(
              room: room,
              selected: _selectedRoom == room,
              hoveredRoom: _hoveredRoom,
              onTap: () => setState(
                () => _selectedRoom = _selectedRoom == room ? null : room,
              ),
              onWillAccept: (plant) => plant.room != room,
              onAccept: (plant) => _moveToRoom(plant, room),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PlantsBackdrop(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: refresh,
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                        child: Text(
                          'Plantele mele',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 26,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      if (_weather != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                          child: GestureDetector(
                            onTap: _syncingWeather
                                ? null
                                : _syncWateringToWeather,
                            child: _WeatherNote(
                              weather: _weather!,
                              syncing: _syncingWeather,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_due.isNotEmpty) ...[
                              _SectionLabel(
                                'De făcut acum',
                                color: AppColors.accent300,
                              ),
                              const SizedBox(height: 8),
                              for (final item in _due) ...[
                                _DueCard(
                                  item: item,
                                  onMarkDone: () => _onMarkDone(item),
                                ),
                                const SizedBox(height: 10),
                              ],
                              const SizedBox(height: 14),
                            ],
                            _SectionLabel(
                              'Plantele tale',
                              color: AppColors.neutral500,
                            ),
                            if (_plants.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Ține apăsat și trage o plantă peste o cameră ca s-o muți acolo.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.neutral500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_plants.isNotEmpty)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(
                      height: 68,
                      child: _roomChipsRow(),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    child: _plants.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Nu ai adăugat încă nicio plantă.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Mergi la tab-ul "Identifică" ca să scanezi prima ta plantă.',
                                    style: TextStyle(
                                      color: AppColors.neutral400,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final group in _groupedByRoom()) ...[
                                _RoomSection(
                                  group: group,
                                  onDropPlant: group.room == null
                                      ? null
                                      : (plant) =>
                                            _moveToRoom(plant, group.room!),
                                  plantCardBuilder: (plant) => _PlantCard(
                                    plant: plant,
                                    hoveredRoom: _hoveredRoom,
                                    onOpen: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PlantDetailScreen(
                                            plantId: plant.id,
                                          ),
                                        ),
                                      );
                                      refresh();
                                    },
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _StickyHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}

/// A room chip in the top row. While a plant is dragged over it, it scales
/// up in place to signal it as the drop target; the other chips (and the
/// dragged card, via [hoveredRoom]) fade back so the hovered one reads as
/// being in front, without needing any real z-order/overlay trickery.
class _RoomChip extends StatelessWidget {
  final String room;
  final bool selected;
  final ValueNotifier<String?> hoveredRoom;
  final VoidCallback onTap;
  final bool Function(PlantRow plant) onWillAccept;
  final void Function(PlantRow plant) onAccept;

  const _RoomChip({
    required this.room,
    required this.selected,
    required this.hoveredRoom,
    required this.onTap,
    required this.onWillAccept,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<PlantRow>(
      onWillAcceptWithDetails: (details) {
        final accept = onWillAccept(details.data);
        if (accept) hoveredRoom.value = room;
        return accept;
      },
      onLeave: (_) {
        if (hoveredRoom.value == room) hoveredRoom.value = null;
      },
      onAcceptWithDetails: (details) {
        hoveredRoom.value = null;
        onAccept(details.data);
      },
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        final style = hovering
            ? AppTagStyle.accent
            : selected
            ? AppTagStyle.selected
            : AppTagStyle.outline;
        return ValueListenableBuilder<String?>(
          valueListenable: hoveredRoom,
          builder: (context, currentlyHovered, child) {
            final dimmed = currentlyHovered != null && currentlyHovered != room;
            return Center(
              child: AnimatedOpacity(
                opacity: dimmed ? 0.25 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: child,
              ),
            );
          },
          // Slide the enlarged label up and clear of the dragged card, which
          // sits centered on the finger right over this chip — otherwise the
          // two texts would land on top of each other and neither reads.
          child: AnimatedSlide(
            offset: hovering ? const Offset(0, -1.6) : Offset.zero,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: AnimatedScale(
              scale: hovering ? 3.0 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: AppTag(text: room, style: style, onTap: onTap),
            ),
          ),
        );
      },
    );
  }
}

/// Frames a room's plants in a bordered container with the room name as a
/// header; also a drop target so dragging a plant card here re-assigns it.
/// When [group.room] is null (nobody has a room yet), it renders as a plain
/// list with no frame/header, same as the old flat view.
class _RoomSection extends StatelessWidget {
  final _RoomGroup group;
  final void Function(PlantRow plant)? onDropPlant;
  final Widget Function(PlantRow plant) plantCardBuilder;

  const _RoomSection({
    required this.group,
    required this.onDropPlant,
    required this.plantCardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final cards = Column(
      children: [
        for (final plant in group.plants) ...[
          plantCardBuilder(plant),
          const SizedBox(height: 10),
        ],
      ],
    );

    if (group.room == null) return cards;

    return DragTarget<PlantRow>(
      onWillAcceptWithDetails: (details) => details.data.room != group.room,
      onAcceptWithDetails: (details) => onDropPlant?.call(details.data),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: hovering ? AppColors.accent : AppColors.divider,
              width: hovering ? 1.5 : 1,
            ),
            color: hovering
                ? AppColors.accent.withValues(alpha: 0.06)
                : Colors.transparent,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.room_outlined,
                      size: 15,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      group.room!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w500,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              cards,
            ],
          ),
        );
      },
    );
  }
}

/// Small transparency note explaining that watering reminders factor in the
/// outdoor temperature and current month, instead of silently changing them.
class _WeatherNote extends StatelessWidget {
  final WeatherReading weather;
  final bool syncing;

  const _WeatherNote({required this.weather, this.syncing = false});

  @override
  Widget build(BuildContext context) {
    final tempC = weather.tempC;
    final month = _kRoMonthsShort[DateTime.now().month - 1];
    final hint = tempC > 22
        ? 'udare mai deasă'
        : (tempC < 18 ? 'udare mai rară' : 'udare normală');
    return Row(
      children: [
        if (syncing)
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.neutral500,
            ),
          )
        else
          Icon(
            weatherIconForCode(weather.weatherCode),
            size: 14,
            color: AppColors.neutral500,
          ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            syncing
                ? 'Se recalculează udarea după vreme...'
                : '${tempC.round()}°C afară · $month · $hint · atinge pentru reactualizare',
            style: TextStyle(fontSize: 11, color: AppColors.neutral500),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionLabel(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 0.9,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}

class _DueCard extends StatelessWidget {
  final ReminderWithPlant item;
  final VoidCallback onMarkDone;

  const _DueCard({required this.item, required this.onMarkDone});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accent800,
              shape: BoxShape.circle,
            ),
            child: Icon(
              reminderTypeIcon(item.reminder.type),
              color: AppColors.accent200,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.reminder.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  item.plantCommonName,
                  style: TextStyle(fontSize: 12, color: AppColors.neutral400),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onMarkDone,
            child: const Text('Marchează făcut'),
          ),
        ],
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  final PlantRow plant;
  final VoidCallback onOpen;
  final ValueNotifier<String?> hoveredRoom;

  const _PlantCard({
    required this.plant,
    required this.onOpen,
    required this.hoveredRoom,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<PlantRow>(
      data: plant,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 220,
          child: ValueListenableBuilder<String?>(
            valueListenable: hoveredRoom,
            builder: (context, currentlyHovered, child) {
              return AnimatedOpacity(
                opacity: currentlyHovered != null ? 0.3 : 0.9,
                duration: const Duration(milliseconds: 150),
                child: child,
              );
            },
            child: _content(elevated: true),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: _content()),
      child: _content(onOpen: onOpen),
    );
  }

  Widget _content({VoidCallback? onOpen, bool elevated = false}) {
    final meta = lightMeta(lightNeedFromDb(plant.light));
    return AppCard(
      onTap: onOpen,
      elevated: elevated,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
                plant.photoPath != null &&
                    File(PhotoPaths.resolve(plant.photoPath!)).existsSync()
                ? Image.file(
                    File(PhotoPaths.resolve(plant.photoPath!)),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 40,
                      height: 40,
                      color: AppColors.neutral800,
                    ),
                  )
                : Container(width: 40, height: 40, color: AppColors.neutral800),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.commonName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  plant.scientificName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 5,
                  children: [
                    AppTag(
                      text: '${plant.effectiveWateringDays} zile',
                      icon: Icons.water_drop_outlined,
                    ),
                    AppTag(text: meta.tag, icon: meta.icon),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.neutral600, size: 14),
        ],
      ),
    );
  }
}
