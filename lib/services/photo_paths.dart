import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// iOS does not guarantee the app's Documents directory absolute path stays
/// the same across app updates/relaunches (the sandbox container UUID can
/// rotate) — so a full path stored in the database can silently point
/// nowhere later, even though the plant row itself is intact. Store only the
/// filename and reconstruct the absolute path against the *current*
/// Documents directory whenever we need to read a file.
class PhotoPaths {
  PhotoPaths._();

  static String? _docsDirPath;

  static Future<void> init() async {
    _docsDirPath = (await getApplicationDocumentsDirectory()).path;
  }

  /// Call right after copying a captured/picked file into the Documents
  /// directory — returns what should be persisted in the database.
  static String toStored(String absolutePath) => p.basename(absolutePath);

  /// Call whenever a stored path is read back from the database, before
  /// using it as a [File] — resolves both new (filename-only) entries and
  /// legacy entries that still hold a full (possibly stale) absolute path.
  static String resolve(String storedPath) {
    final docsDir = _docsDirPath;
    if (docsDir == null) return storedPath;
    if (!p.isAbsolute(storedPath)) return p.join(docsDir, storedPath);
    if (storedPath.startsWith(docsDir)) return storedPath;
    // Legacy absolute path from a previous container — recover by filename
    // under the current Documents directory.
    return p.join(docsDir, p.basename(storedPath));
  }
}
