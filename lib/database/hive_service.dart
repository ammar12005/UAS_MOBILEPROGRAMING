import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models.dart';

class HiveService {
  static const String _eventsBox = 'events';
  static const String _ticketsBox = 'tickets';
  static const String _usersBox = 'users';
  static const String _settingsBox = 'settings';

  static Future<void> init() async {
    // Initialize Hive untuk web (IndexedDB) dan mobile
    await Hive.initFlutter();
    
    // Open all boxes
    await Hive.openBox<Map>(_eventsBox);
    await Hive.openBox<Map>(_ticketsBox);
    await Hive.openBox<Map>(_usersBox);
    await Hive.openBox<dynamic>(_settingsBox);
    
    if (kIsWeb) {
      debugPrint('🌐 Hive initialized for WEB (IndexedDB)');
    } else {
      debugPrint('📱 Hive initialized for Mobile/Desktop');
    }
    
    debugPrint('✅ Hive initialized successfully');
    debugPrint('📦 Events box: ${Hive.box<Map>(_eventsBox).length} items');
    debugPrint('📦 Users box: ${Hive.box<Map>(_usersBox).length} items');
    debugPrint('📦 Settings box: ${Hive.box<dynamic>(_settingsBox).length} items');
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
    await box.flush();
    debugPrint('✅ User created: ${user.email}');
  }

  static Future<void> updateUser(User user) async {
    final box = Hive.box<Map>(_usersBox);
    await box.put(user.id.toString(), user.toJson());
    await box.flush();
    debugPrint('✅ User updated: ${user.email}');
  }

  // === SESSION/SETTINGS OPERATIONS ===
  static String? getCurrentUserEmail() {
    try {
      final box = Hive.box<dynamic>(_settingsBox);
      final email = box.get('currentUserEmail') as String?;
      debugPrint('📖 Current session: ${email ?? "none"}');
      return email;
    } catch (e) {
      debugPrint('❌ Error reading session: $e');
      return null;
    }
  }

  static Future<void> saveCurrentUserEmail(String email) async {
    try {
      final box = Hive.box<dynamic>(_settingsBox);
      
      // Save to box
      await box.put('currentUserEmail', email);
      
      // Force flush
      await box.flush();
      
      // Small delay untuk web
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Verify save
      final saved = box.get('currentUserEmail');
      debugPrint('💾 Session saved: $email');
      debugPrint('✅ Verified in box: $saved');
      
      if (saved != email) {
        debugPrint('⚠️ WARNING: Save verification failed!');
        debugPrint('   Expected: $email');
        debugPrint('   Got: $saved');
        
        // Retry
        await box.put('currentUserEmail', email);
        await box.flush();
        final retry = box.get('currentUserEmail');
        debugPrint('🔄 Retry result: $retry');
      }
    } catch (e) {
      debugPrint('❌ Error saving session: $e');
      rethrow;
    }
  }

  static Future<void> clearCurrentUser() async {
    try {
      final box = Hive.box<dynamic>(_settingsBox);
      await box.delete('currentUserEmail');
      await box.flush();
      debugPrint('🗑️ Session cleared');
    } catch (e) {
      debugPrint('❌ Error clearing session: $e');
    }
  }

  // === EVENT OPERATIONS ===
  static Future<List<Event>> getAllEvents() async {
    final box = Hive.box<Map>(_eventsBox);
    final events = box.values
        .map((e) => Event.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    events.sort((a, b) => a.date.compareTo(b.date));
    
    debugPrint('📖 Loaded ${events.length} events');
    return events;
  }

  static Future<void> createEvent(Event event) async {
    final box = Hive.box<Map>(_eventsBox);
    await box.put(event.id.toString(), event.toJson());
    await box.flush();
    
    debugPrint('✅ Event saved: ${event.name} (ID: ${event.id})');
    debugPrint('📦 Total events: ${box.length}');
  }

  static Future<void> updateEvent(Event event) async {
    final box = Hive.box<Map>(_eventsBox);
    await box.put(event.id.toString(), event.toJson());
    await box.flush();
    debugPrint('✅ Event updated: ${event.name}');
  }

  static Future<void> deleteEvent(int id) async {
    final box = Hive.box<Map>(_eventsBox);
    await box.delete(id.toString());
    await box.flush();
    debugPrint('🗑️ Event deleted: $id');
  }

  static Future<Event?> getEventById(int id) async {
    final box = Hive.box<Map>(_eventsBox);
    final data = box.get(id.toString());
    if (data != null) {
      return Event.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  // === TICKET OPERATIONS ===
  static Future<List<Ticket>> getAllTickets() async {
    final box = Hive.box<Map>(_ticketsBox);
    final tickets = box.values
        .map((t) => Ticket.fromJson(Map<String, dynamic>.from(t)))
        .toList();
    
    debugPrint('📖 Loaded ${tickets.length} tickets');
    return tickets;
  }

  static Future<void> createTicket(Ticket ticket) async {
    final box = Hive.box<Map>(_ticketsBox);
    await box.put(ticket.id.toString(), ticket.toJson());
    await box.flush();
    debugPrint('✅ Ticket created: ${ticket.code}');
  }

  static Future<void> deleteTicket(int id) async {
    final box = Hive.box<Map>(_ticketsBox);
    await box.delete(id.toString());
    await box.flush();
    debugPrint('🗑️ Ticket deleted: $id');
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
      debugPrint('❌ Error calculating revenue: $e');
      return 0.0;
    }
  }

  static Future<void> clearAllData() async {
    await Hive.box<Map>(_eventsBox).clear();
    await Hive.box<Map>(_ticketsBox).clear();
    await Hive.box<Map>(_usersBox).clear();
    await Hive.box<dynamic>(_settingsBox).clear();
    
    // Flush semua box
    await Hive.box<Map>(_eventsBox).flush();
    await Hive.box<Map>(_ticketsBox).flush();
    await Hive.box<Map>(_usersBox).flush();
    await Hive.box<dynamic>(_settingsBox).flush();
    
    debugPrint('🗑️ All data cleared');
  }
}