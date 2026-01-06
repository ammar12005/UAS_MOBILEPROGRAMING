import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';

// --- STORAGE SERVICE ---
class StorageService {
  static const String _prefix = 'emp_v2_';
  static Box get _box => Hive.box('eventManagerStorage');

  // Users Management
  static Future<List<User>> getUsers() async {
    try {
      final data = _box.get('${_prefix}users');
      if (data == null) {
        if (kDebugMode) {
          debugPrint('StorageService: No users found in storage');
        }
        return [];
      }
      final users = (json.decode(data) as List).map((u) => User.fromJson(u)).toList();
      if (kDebugMode) {
        debugPrint('StorageService: Retrieved ${users.length} users');
      }
      return users;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService Error (getUsers): $e');
      }
      return [];
    }
  }

  static Future<void> saveUsers(List<User> users) async {
    try {
      final jsonData = json.encode(users.map((u) => u.toJson()).toList());
      await _box.put('${_prefix}users', jsonData);
      if (kDebugMode) {
        debugPrint('StorageService: Saved ${users.length} users');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService Error (saveUsers): $e');
      }
    }
  }

  // Session Management
  static Future<void> setSession(User user) async {
    try {
      final jsonData = json.encode(user.toJson());
      
      await _box.put('${_prefix}current_user', jsonData);
      await _box.put('${_prefix}is_logged_in', 'true');
      await _box.put('${_prefix}user_id', user.id);
      
      if (kDebugMode) {
        debugPrint('StorageService: Session set for user: ${user.email}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService Error (setSession): $e');
      }
    }
  }

  static Future<User?> getSession() async {
    try {
      final isLoggedIn = _box.get('${_prefix}is_logged_in');
      
      if (isLoggedIn != 'true') {
        if (kDebugMode) {
          debugPrint('StorageService: No active session found');
        }
        return null;
      }
      
      final data = _box.get('${_prefix}current_user');
      if (data == null) {
        if (kDebugMode) {
          debugPrint('StorageService: Session exists but user data is null');
        }
        return null;
      }
      
      final user = User.fromJson(json.decode(data));
      if (kDebugMode) {
        debugPrint('StorageService: Retrieved session for user: ${user.email}');
      }
      return user;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService Error (getSession): $e');
      }
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      await _box.delete('${_prefix}current_user');
      await _box.put('${_prefix}is_logged_in', 'false');
      await _box.delete('${_prefix}user_id');
      
      if (kDebugMode) {
        debugPrint('StorageService: User logged out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService Error (logout): $e');
      }
    }
  }

  // Events Management
  static Future<List<Event>> getEvents(int userId) async {
    try {
      final data = _box.get('${_prefix}events_$userId');
      if (data == null) {
        if (kDebugMode) {
          debugPrint('StorageService: No events found for user $userId');
        }
        return [];
      }
      
      final events = (json.decode(data) as List).map((e) => Event.fromJson(e)).toList();
      if (kDebugMode) {
        debugPrint('StorageService: Retrieved ${events.length} events for user $userId');
      }
      return events;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService Error (getEvents): $e');
      }
      return [];
    }
  }

  static Future<void> saveEvents(int userId, List<Event> events) async {
    try {
      final jsonData = json.encode(events.map((e) => e.toJson()).toList());
      await _box.put('${_prefix}events_$userId', jsonData);
      if (kDebugMode) {
        debugPrint('StorageService: Saved ${events.length} events for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService Error (saveEvents): $e');
      }
    }
  }

  // Tickets Management
  static Future<List<Ticket>> getTickets(int userId) async {
    try {
      final data = _box.get('${_prefix}tickets_$userId');
      if (data == null) {
        if (kDebugMode) {
          debugPrint('StorageService: No tickets found for user $userId');
        }
        return [];
      }
      final tickets = (json.decode(data) as List).map((t) => Ticket.fromJson(t)).toList();
      if (kDebugMode) {
        debugPrint('StorageService: Retrieved ${tickets.length} tickets for user $userId');
      }
      return tickets;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService Error (getTickets): $e');
      }
      return [];
    }
  }

  static Future<void> saveTickets(int userId, List<Ticket> tickets) async {
    try {
      final jsonData = json.encode(tickets.map((t) => t.toJson()).toList());
      await _box.put('${_prefix}tickets_$userId', jsonData);
      if (kDebugMode) {
        debugPrint('StorageService: Saved ${tickets.length} tickets for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService Error (saveTickets): $e');
      }
    }
  }

  // Utility: Clear all data (untuk testing/debugging)
  static Future<void> clearAllData() async {
    try {
      await _box.clear();
      if (kDebugMode) {
        debugPrint('StorageService: All data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService Error (clearAllData): $e');
      }
    }
  }

  // Utility: Get all keys (untuk debugging)
  static Future<List<String>> getAllKeys() async {
    try {
      final keys = _box.keys.map((k) => k.toString()).toList();
      if (kDebugMode) {
        debugPrint('StorageService: Total keys in storage: ${keys.length}');
        for (var key in keys) {
          debugPrint('  - $key');
        }
      }
      return keys;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('StorageService Error (getAllKeys): $e');
      }
      return [];
    }
  }
}