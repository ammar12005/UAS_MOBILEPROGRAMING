import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';

class HiveService {
  static const String _eventsBox = 'events';
  static const String _ticketsBox = 'tickets';
  static const String _usersBox = 'users';
  static const String _settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(_eventsBox);
    await Hive.openBox<Map>(_ticketsBox);
    await Hive.openBox<Map>(_usersBox);
    await Hive.openBox<dynamic>(_settingsBox);
  }

  // === USER OPERATIONS ===
  static Future<User?> getUserByEmail(String email) async {
    final box = Hive.box<Map>(_usersBox);
    for (var userData in box.values) {
      if (userData['email'].toString().toLowerCase() == email.toLowerCase()) {
        return User.fromJson(Map<String, dynamic>.from(userData));
      }
    }
    return null;
  }

  static Future<void> createUser(User user) async {
    final box = Hive.box<Map>(_usersBox);
    await box.put(user.id.toString(), user.toJson());
  }

  static Future<void> updateUser(User user) async {
    final box = Hive.box<Map>(_usersBox);
    await box.put(user.id.toString(), user.toJson());
  }

  // === SESSION/SETTINGS OPERATIONS ===
  static String? getCurrentUserEmail() {
    final box = Hive.box<dynamic>(_settingsBox);
    return box.get('currentUserEmail') as String?;
  }

  static Future<void> saveCurrentUserEmail(String email) async {
    final box = Hive.box<dynamic>(_settingsBox);
    await box.put('currentUserEmail', email);
  }

  static Future<void> clearCurrentUser() async {
    final box = Hive.box<dynamic>(_settingsBox);
    await box.delete('currentUserEmail');
  }

  // === EVENT OPERATIONS (DILENGKAPI) ===
  static Future<List<Event>> getAllEvents() async {
    final box = Hive.box<Map>(_eventsBox);
    final events = box.values
        .map((e) => Event.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    // Urutkan berdasarkan tanggal terdekat
    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  static Future<void> createEvent(Event event) async {
    final box = Hive.box<Map>(_eventsBox);
    await box.put(event.id.toString(), event.toJson());
  }

  static Future<void> updateEvent(Event event) async {
    final box = Hive.box<Map>(_eventsBox);
    await box.put(event.id.toString(), event.toJson());
  }

  static Future<void> deleteEvent(int id) async {
    final box = Hive.box<Map>(_eventsBox);
    await box.delete(id.toString());
  }

  static Future<Event?> getEventById(int id) async {
    final box = Hive.box<Map>(_eventsBox);
    final data = box.get(id.toString());
    if (data != null) {
      return Event.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  // === TICKET OPERATIONS (DILENGKAPI) ===
  static Future<List<Ticket>> getAllTickets() async {
    final box = Hive.box<Map>(_ticketsBox);
    return box.values
        .map((t) => Ticket.fromJson(Map<String, dynamic>.from(t)))
        .toList();
  }

  static Future<void> createTicket(Ticket ticket) async {
    final box = Hive.box<Map>(_ticketsBox);
    await box.put(ticket.id.toString(), ticket.toJson());
  }

  static Future<void> deleteTicket(int id) async {
    final box = Hive.box<Map>(_ticketsBox);
    await box.delete(id.toString());
  }

  // === UTILITY & STATISTICS ===
  static Future<double> getTotalRevenue() async {
    try {
      final tickets = await getAllTickets();
      double total = 0;
      for (var ticket in tickets) {
        final event = await getEventById(ticket.eventId);
        if (event != null) {
          total += (event.price) * (ticket.quantity ?? 1);
        }
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  static Future<void> clearAllData() async {
    await Hive.box<Map>(_eventsBox).clear();
    await Hive.box<Map>(_ticketsBox).clear();
    await Hive.box<Map>(_usersBox).clear();
    await Hive.box<dynamic>(_settingsBox).clear();
  }
}