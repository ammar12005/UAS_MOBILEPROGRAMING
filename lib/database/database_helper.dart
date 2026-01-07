import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'event_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel Users
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    // Tabel Events
    await db.execute('''
      CREATE TABLE events(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        location TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        price REAL NOT NULL,
        description TEXT,
        ticketsSold INTEGER DEFAULT 0
      )
    ''');

    // Tabel Tickets
    await db.execute('''
      CREATE TABLE tickets(
        id INTEGER PRIMARY KEY,
        eventId INTEGER NOT NULL,
        code TEXT NOT NULL UNIQUE,
        buyerName TEXT NOT NULL,
        buyerEmail TEXT NOT NULL,
        purchaseDate TEXT NOT NULL,
        isScanned INTEGER DEFAULT 0,
        scannedAt TEXT,
        FOREIGN KEY (eventId) REFERENCES events(id) ON DELETE CASCADE
      )
    ''');
  }

  // ============================================================================
  // EVENT OPERATIONS
  // ============================================================================

  /// Create - Tambah event
  Future<int> insertEvent(Event event) async {
    Database db = await database;
    return await db.insert('events', event.toMap());
  }

  /// Read - Ambil semua event
  Future<List<Event>> getAllEvents() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  /// Read - Ambil event berdasarkan ID
  Future<Event?> getEventById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? Event.fromMap(results.first) : null;
  }

  /// Update - Edit event
  Future<int> updateEvent(Event event) async {
    Database db = await database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  /// Delete - Hapus event
  Future<int> deleteEvent(int id) async {
    Database db = await database;
    // Tickets akan terhapus otomatis karena FOREIGN KEY CASCADE
    return await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete All - Hapus semua event
  Future<int> deleteAllEvents() async {
    Database db = await database;
    return await db.delete('events');
  }

  // ============================================================================
  // TICKET OPERATIONS
  // ============================================================================

  /// Create - Tambah ticket
  Future<int> insertTicket(Ticket ticket) async {
    Database db = await database;
    return await db.insert('tickets', ticket.toMap());
  }

  /// Read - Ambil semua ticket
  Future<List<Ticket>> getAllTickets() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tickets',
      orderBy: 'purchaseDate DESC',
    );
    return List.generate(maps.length, (i) => Ticket.fromMap(maps[i]));
  }

  /// Read - Ambil ticket berdasarkan ID
  Future<Ticket?> getTicketById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'tickets',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? Ticket.fromMap(results.first) : null;
  }

  /// Read - Ambil ticket berdasarkan event ID
  Future<List<Ticket>> getTicketsByEventId(int eventId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tickets',
      where: 'eventId = ?',
      whereArgs: [eventId],
      orderBy: 'purchaseDate DESC',
    );
    return List.generate(maps.length, (i) => Ticket.fromMap(maps[i]));
  }

  /// Read - Ambil ticket berdasarkan kode
  Future<Ticket?> getTicketByCode(String code) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'tickets',
      where: 'code = ?',
      whereArgs: [code],
    );
    return results.isNotEmpty ? Ticket.fromMap(results.first) : null;
  }

  /// Update - Edit ticket
  Future<int> updateTicket(Ticket ticket) async {
    Database db = await database;
    return await db.update(
      'tickets',
      ticket.toMap(),
      where: 'id = ?',
      whereArgs: [ticket.id],
    );
  }

  /// Update - Scan ticket
  Future<int> scanTicket(int ticketId) async {
    Database db = await database;
    return await db.update(
      'tickets',
      {
        'isScanned': 1,
        'scannedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [ticketId],
    );
  }

  /// Delete - Hapus ticket
  Future<int> deleteTicket(int id) async {
    Database db = await database;
    return await db.delete(
      'tickets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete - Hapus ticket berdasarkan event ID
  Future<int> deleteTicketsByEventId(int eventId) async {
    Database db = await database;
    return await db.delete(
      'tickets',
      where: 'eventId = ?',
      whereArgs: [eventId],
    );
  }

  /// Delete All - Hapus semua ticket
  Future<int> deleteAllTickets() async {
    Database db = await database;
    return await db.delete('tickets');
  }

  // ============================================================================
  // USER OPERATIONS
  // ============================================================================

  /// Create - Tambah user
  Future<int> insertUser(User user) async {
    Database db = await database;
    return await db.insert('users', user.toMap());
  }

  /// Read - Ambil semua user
  Future<List<User>> getAllUsers() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  /// Read - Ambil user berdasarkan ID
  Future<User?> getUserById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? User.fromMap(results.first) : null;
  }

  /// Read - Ambil user berdasarkan email
  Future<User?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return results.isNotEmpty ? User.fromMap(results.first) : null;
  }

  /// Read - Login user (cek email dan password)
  Future<User?> loginUser(String email, String password) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return results.isNotEmpty ? User.fromMap(results.first) : null;
  }

  /// Update - Edit user
  Future<int> updateUser(User user) async {
    Database db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Delete - Hapus user
  Future<int> deleteUser(int id) async {
    Database db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete All - Hapus semua user
  Future<int> deleteAllUsers() async {
    Database db = await database;
    return await db.delete('users');
  }

  // ============================================================================
  // STATISTICS & UTILITY
  // ============================================================================

  /// Get total events count
  Future<int> getTotalEventsCount() async {
    Database db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM events');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total tickets count
  Future<int> getTotalTicketsCount() async {
    Database db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM tickets');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get scanned tickets count
  Future<int> getScannedTicketsCount() async {
    Database db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tickets WHERE isScanned = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total revenue from all tickets
  Future<double> getTotalRevenue() async {
    Database db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(e.price) as total 
      FROM tickets t 
      JOIN events e ON t.eventId = e.id
    ''');
    final total = result.first['total'];
    return total != null ? (total as num).toDouble() : 0.0;
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    Database db = await database;
    await db.delete('tickets');
    await db.delete('events');
    await db.delete('users');
  }

  /// Close database connection
  Future<void> closeDatabase() async {
    Database db = await database;
    await db.close();
    _database = null;
  }
}