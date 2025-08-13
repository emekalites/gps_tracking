import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  late Database _db;
  late String _dbPath;

  /// Call this before using any other method.
  /// If dbPath is provided, it will open that file (useful if you compute
  /// the path in the main isolate and pass it to a background isolate).
  Future<void> init({String? dbPath}) async {
    if (dbPath != null) {
      _dbPath = dbPath;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      _dbPath = '${dir.path}/locations.db';
    }

    _db = sqlite3.open(_dbPath);

    _db.execute('''
      CREATE TABLE IF NOT EXISTS locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL,
        altitude REAL,
        heading REAL,
        speed REAL,
        timestamp TEXT,
        sent INTEGER DEFAULT 0
      )
    ''');

    // Ensure 'sent' column exists (for older DBs)
    final ResultSet pragma = _db.select("PRAGMA table_info('locations')");
    final columns = pragma.map((r) => r['name'] as String).toList();
    if (!columns.contains('sent')) {
      _db.execute('ALTER TABLE locations ADD COLUMN sent INTEGER DEFAULT 0;');
    }
  }

  String get dbPath => _dbPath;

  void insertLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? heading,
    double? speed,
    String? timestamp,
  }) {
    _db.execute(
      '''
      INSERT INTO locations (latitude, longitude, accuracy, altitude, heading, speed, timestamp, sent)
      VALUES (?, ?, ?, ?, ?, ?, ?, 0)
      ''',
      [latitude, longitude, accuracy, altitude, heading, speed, timestamp],
    );
  }

  /// Return one unsent location (oldest) or null.
  Map<String, dynamic>? getOneUnsentLocation() {
    final ResultSet rows = _db.select('SELECT * FROM locations WHERE sent = 0 ORDER BY id ASC LIMIT 1');
    if (rows.isEmpty) return null;
    final row = rows.first;
    return {
      'id': row['id'],
      'latitude': row['latitude'],
      'longitude': row['longitude'],
      'accuracy': row['accuracy'],
      'altitude': row['altitude'],
      'heading': row['heading'],
      'speed': row['speed'],
      'timestamp': row['timestamp'],
    };
  }

  void markLocationAsSent(int id) {
    _db.execute('UPDATE locations SET sent = 1 WHERE id = ?', [id]);
  }

  List<Map<String, dynamic>> getAllLocations() {
    final ResultSet result = _db.select('SELECT * FROM locations ORDER BY id DESC');
    return result
        .map(
          (row) => {
            'id': row['id'],
            'latitude': row['latitude'],
            'longitude': row['longitude'],
            'accuracy': row['accuracy'],
            'altitude': row['altitude'],
            'heading': row['heading'],
            'speed': row['speed'],
            'timestamp': row['timestamp'],
            'sent': row['sent'],
          },
        )
        .toList();
  }

  void close() => _db.dispose();
}
