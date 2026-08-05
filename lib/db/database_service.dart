import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class PlantRow {
  final int id;
  final String commonName;
  final String scientificName;
  final String? photoPath;
  final double? confidence;
  final String light;
  final int wateringDays;
  final bool misting;
  final bool toxicToPets;
  final List<String> tips;
  final int createdAt;
  final String? room;
  // Prezent doar când rândul vine dintr-un query care face join cu
  // reminderul de udare — intervalul curent (ajustat după vreme/lună),
  // spre deosebire de `wateringDays`, care rămâne baza fixă a speciei.
  final int? currentWateringDays;

  PlantRow({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.photoPath,
    required this.confidence,
    required this.light,
    required this.wateringDays,
    required this.misting,
    required this.toxicToPets,
    required this.tips,
    required this.createdAt,
    required this.room,
    this.currentWateringDays,
  });

  factory PlantRow.fromMap(Map<String, Object?> map) => PlantRow(
    id: map['id'] as int,
    commonName: map['commonName'] as String,
    scientificName: map['scientificName'] as String,
    photoPath: map['photoPath'] as String?,
    confidence: (map['confidence'] as num?)?.toDouble(),
    light: map['light'] as String,
    wateringDays: map['wateringDays'] as int,
    misting: (map['misting'] as int) == 1,
    toxicToPets: (map['toxicToPets'] as int) == 1,
    tips: (jsonDecode(map['tips'] as String) as List).cast<String>(),
    createdAt: map['createdAt'] as int,
    room: map['room'] as String?,
    currentWateringDays: map['currentWateringDays'] as int?,
  );

  int get effectiveWateringDays => currentWateringDays ?? wateringDays;
}

class ReminderRow {
  final int id;
  final int plantId;
  final String type;
  final String label;
  final int intervalDays;
  final int nextDueAt;
  final int? lastDoneAt;
  final int? notificationId;

  ReminderRow({
    required this.id,
    required this.plantId,
    required this.type,
    required this.label,
    required this.intervalDays,
    required this.nextDueAt,
    required this.lastDoneAt,
    required this.notificationId,
  });

  factory ReminderRow.fromMap(Map<String, Object?> map) => ReminderRow(
    id: map['id'] as int,
    plantId: map['plantId'] as int,
    type: map['type'] as String,
    label: map['label'] as String,
    intervalDays: map['intervalDays'] as int,
    nextDueAt: map['nextDueAt'] as int,
    lastDoneAt: map['lastDoneAt'] as int?,
    notificationId: map['notificationId'] as int?,
  );
}

class PlantPhotoRow {
  final int id;
  final int plantId;
  final String path;
  final String? note;
  final int createdAt;

  PlantPhotoRow({
    required this.id,
    required this.plantId,
    required this.path,
    required this.note,
    required this.createdAt,
  });

  bool get hasPhoto => path.isNotEmpty;

  factory PlantPhotoRow.fromMap(Map<String, Object?> map) => PlantPhotoRow(
    id: map['id'] as int,
    plantId: map['plantId'] as int,
    path: map['path'] as String,
    note: map['note'] as String?,
    createdAt: map['createdAt'] as int,
  );
}

class ReminderWithPlant {
  final ReminderRow reminder;
  final String plantCommonName;
  final String? plantPhotoPath;

  ReminderWithPlant({
    required this.reminder,
    required this.plantCommonName,
    required this.plantPhotoPath,
  });
}

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final dbPath = join(await getDatabasesPath(), 'plants_planner.db');
    _db = await openDatabase(
      dbPath,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE plants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            commonName TEXT NOT NULL,
            scientificName TEXT NOT NULL,
            photoPath TEXT,
            confidence REAL,
            light TEXT NOT NULL,
            wateringDays INTEGER NOT NULL,
            misting INTEGER NOT NULL DEFAULT 0,
            toxicToPets INTEGER NOT NULL DEFAULT 0,
            tips TEXT NOT NULL DEFAULT '[]',
            createdAt INTEGER NOT NULL,
            room TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plantId INTEGER NOT NULL REFERENCES plants(id) ON DELETE CASCADE,
            type TEXT NOT NULL,
            label TEXT NOT NULL,
            intervalDays INTEGER NOT NULL,
            nextDueAt INTEGER NOT NULL,
            lastDoneAt INTEGER,
            notificationId INTEGER
          )
        ''');
        await db.execute(_createPlantPhotosSql);
        await db.execute(_createSpeciesCareCacheSql);
        await db.execute(_createTrefleSpeciesCareCacheSql);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(_createPlantPhotosSql);
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE plants ADD COLUMN room TEXT');
        }
        if (oldVersion < 4) {
          await db.execute("ALTER TABLE plant_photos ADD COLUMN note TEXT");
          await db.execute(_createSpeciesCareCacheSql);
        }
        if (oldVersion < 5) {
          await db.execute(_createTrefleSpeciesCareCacheSql);
        }
      },
    );
    return _db!;
  }

  static const _createTrefleSpeciesCareCacheSql = '''
    CREATE TABLE trefle_species_care_cache (
      scientificName TEXT PRIMARY KEY,
      json TEXT NOT NULL,
      fetchedAt INTEGER NOT NULL
    )
  ''';

  static const _createPlantPhotosSql = '''
    CREATE TABLE plant_photos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      plantId INTEGER NOT NULL REFERENCES plants(id) ON DELETE CASCADE,
      path TEXT NOT NULL,
      note TEXT,
      createdAt INTEGER NOT NULL
    )
  ''';

  static const _createSpeciesCareCacheSql = '''
    CREATE TABLE species_care_cache (
      scientificName TEXT PRIMARY KEY,
      json TEXT NOT NULL,
      fetchedAt INTEGER NOT NULL
    )
  ''';

  Future<int> addPlant({
    required String commonName,
    required String scientificName,
    required String? photoPath,
    required double? confidence,
    required String light,
    required int wateringDays,
    required bool misting,
    required bool toxicToPets,
    required List<String> tips,
    String? room,
  }) async {
    final database = await db;
    return database.insert('plants', {
      'commonName': commonName,
      'scientificName': scientificName,
      'photoPath': photoPath,
      'confidence': confidence,
      'light': light,
      'wateringDays': wateringDays,
      'misting': misting ? 1 : 0,
      'toxicToPets': toxicToPets ? 1 : 0,
      'tips': jsonEncode(tips),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'room': room,
    });
  }

  Future<void> updatePlantRoom({required int id, required String? room}) async {
    final database = await db;
    await database.update(
      'plants',
      {'room': room},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<PlantRow>> getPlants() async {
    final database = await db;
    final rows = await database.rawQuery('''
      SELECT plants.*, reminders.intervalDays as currentWateringDays
      FROM plants
      LEFT JOIN reminders ON reminders.plantId = plants.id AND reminders.type = 'udare'
      ORDER BY plants.createdAt DESC
    ''');
    return rows.map(PlantRow.fromMap).toList();
  }

  Future<PlantRow?> getPlant(int id) async {
    final database = await db;
    final rows = await database.query(
      'plants',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return PlantRow.fromMap(rows.first);
  }

  Future<void> updatePlantPhoto({
    required int id,
    required String photoPath,
  }) async {
    final database = await db;
    await database.update(
      'plants',
      {'photoPath': photoPath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePlant(int id) async {
    final database = await db;
    await database.delete('reminders', where: 'plantId = ?', whereArgs: [id]);
    await database.delete(
      'plant_photos',
      where: 'plantId = ?',
      whereArgs: [id],
    );
    await database.delete('plants', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addPlantPhoto({
    required int plantId,
    required String path,
    String? note,
  }) async {
    final database = await db;
    return database.insert('plant_photos', {
      'plantId': plantId,
      'path': path,
      'note': note,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<PlantPhotoRow>> getPhotosForPlant(int plantId) async {
    final database = await db;
    final rows = await database.query(
      'plant_photos',
      where: 'plantId = ?',
      whereArgs: [plantId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(PlantPhotoRow.fromMap).toList();
  }

  Future<void> deletePlantPhoto(int id) async {
    final database = await db;
    await database.delete('plant_photos', where: 'id = ?', whereArgs: [id]);
  }

  Future<String?> getCachedSpeciesCare(String scientificName) async {
    final database = await db;
    final rows = await database.query(
      'species_care_cache',
      where: 'scientificName = ?',
      whereArgs: [scientificName],
    );
    if (rows.isEmpty) return null;
    return rows.first['json'] as String;
  }

  Future<void> setCachedSpeciesCare(String scientificName, String json) async {
    final database = await db;
    await database.insert('species_care_cache', {
      'scientificName': scientificName,
      'json': json,
      'fetchedAt': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getCachedTrefleCare(String scientificName) async {
    final database = await db;
    final rows = await database.query(
      'trefle_species_care_cache',
      where: 'scientificName = ?',
      whereArgs: [scientificName],
    );
    if (rows.isEmpty) return null;
    return rows.first['json'] as String;
  }

  Future<void> setCachedTrefleCare(String scientificName, String json) async {
    final database = await db;
    await database.insert('trefle_species_care_cache', {
      'scientificName': scientificName,
      'json': json,
      'fetchedAt': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> addReminder({
    required int plantId,
    required String type,
    required String label,
    required int intervalDays,
    required int nextDueAt,
    int? lastDoneAt,
    int? notificationId,
  }) async {
    final database = await db;
    return database.insert('reminders', {
      'plantId': plantId,
      'type': type,
      'label': label,
      'intervalDays': intervalDays,
      'nextDueAt': nextDueAt,
      'lastDoneAt': lastDoneAt,
      'notificationId': notificationId,
    });
  }

  Future<List<ReminderRow>> getRemindersForPlant(int plantId) async {
    final database = await db;
    final rows = await database.query(
      'reminders',
      where: 'plantId = ?',
      whereArgs: [plantId],
      orderBy: 'nextDueAt ASC',
    );
    return rows.map(ReminderRow.fromMap).toList();
  }

  Future<List<ReminderWithPlant>> getDueReminders({int? now}) async {
    final database = await db;
    final cutoff = now ?? DateTime.now().millisecondsSinceEpoch;
    final rows = await database.rawQuery(
      '''
      SELECT reminders.*, plants.commonName as plant_commonName, plants.photoPath as plant_photoPath
      FROM reminders JOIN plants ON plants.id = reminders.plantId
      WHERE reminders.nextDueAt <= ?
      ORDER BY reminders.nextDueAt ASC
    ''',
      [cutoff],
    );

    return rows
        .map(
          (r) => ReminderWithPlant(
            reminder: ReminderRow.fromMap(r),
            plantCommonName: r['plant_commonName'] as String,
            plantPhotoPath: r['plant_photoPath'] as String?,
          ),
        )
        .toList();
  }

  /// Updates a reminder's next-due date and interval without touching
  /// `lastDoneAt` — used to re-sync an already-scheduled reminder (e.g. a
  /// weather-based watering recalculation) without pretending it was just
  /// completed.
  Future<void> updateReminderDueDate({
    required int id,
    required int nextDueAt,
    required int intervalDays,
    required int? notificationId,
  }) async {
    final database = await db;
    await database.update(
      'reminders',
      {
        'nextDueAt': nextDueAt,
        'intervalDays': intervalDays,
        'notificationId': notificationId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateReminderSchedule({
    required int id,
    required int nextDueAt,
    required int lastDoneAt,
    required int? notificationId,
    int? intervalDays,
  }) async {
    final database = await db;
    await database.update(
      'reminders',
      {
        'nextDueAt': nextDueAt,
        'lastDoneAt': lastDoneAt,
        'notificationId': notificationId,
        if (intervalDays != null) 'intervalDays': intervalDays,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setReminderNotificationId(int id, int? notificationId) async {
    final database = await db;
    await database.update(
      'reminders',
      {'notificationId': notificationId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteReminder(int id) async {
    final database = await db;
    await database.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }
}
