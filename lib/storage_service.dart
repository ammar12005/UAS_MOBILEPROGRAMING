import 'dart:convert';
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
      print('🟢 LOAD Users: ${data != null ? "Ada data" : "Kosong"}');
      if (data == null) return [];
      return (json.decode(data) as List).map((u) => User.fromJson(u)).toList();
    } catch (e) {
      print('❌ Error load users: $e');
      return [];
    }
  }

  static Future<void> saveUsers(List<User> users) async {
    try {
      final jsonData = json.encode(users.map((u) => u.toJson()).toList());
      await _box.put('${_prefix}users', jsonData);
      print('🔵 SAVE Users: ${users.length} users');
      
      final verify = _box.get('${_prefix}users');
      print('🔵 Verifikasi Users: ${verify != null ? "✅ Tersimpan" : "❌ Gagal"}');
    } catch (e) {
      print('❌ Error save users: $e');
    }
  }

  // Session Management
  static Future<void> setSession(User user) async {
    try {
      final jsonData = json.encode(user.toJson());
      
      await _box.put('${_prefix}current_user', jsonData);
      await _box.put('${_prefix}is_logged_in', 'true');
      await _box.put('${_prefix}user_id', user.id);
      
      print('🔵 SAVE Session: ${user.name} (ID: ${user.id})');
      
      final verifyUser = _box.get('${_prefix}current_user');
      final verifyLogin = _box.get('${_prefix}is_logged_in');
      final verifyId = _box.get('${_prefix}user_id');
      
      print('🔵 Verifikasi Session:');
      print('   - User data: ${verifyUser != null ? "✅" : "❌"}');
      print('   - Login status: ${verifyLogin == 'true' ? "✅" : "❌"}');
      print('   - User ID: ${verifyId == user.id ? "✅" : "❌"}');
    } catch (e) {
      print('❌ Error save session: $e');
    }
  }

  static Future<User?> getSession() async {
    try {
      final isLoggedIn = _box.get('${_prefix}is_logged_in');
      print('🟢 LOAD Session: Status login = "$isLoggedIn"');
      
      if (isLoggedIn != 'true') {
        print('🟢 Not logged in');
        return null;
      }
      
      final data = _box.get('${_prefix}current_user');
      if (data == null) {
        print('❌ User data tidak ada!');
        return null;
      }
      
      final user = User.fromJson(json.decode(data));
      print('🟢 User loaded: ${user.name} (ID: ${user.id})');
      return user;
      
    } catch (e) {
      print('❌ Error load session: $e');
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      await _box.delete('${_prefix}current_user');
      await _box.put('${_prefix}is_logged_in', 'false');
      await _box.delete('${_prefix}user_id');
      print('🔴 LOGOUT berhasil');
    } catch (e) {
      print('❌ Error logout: $e');
    }
  }

  // Events Management
  static Future<List<Event>> getEvents(int userId) async {
    try {
      final data = _box.get('${_prefix}events_$userId');
      print('🟢 LOAD Events untuk user $userId: ${data != null ? "Ada data" : "Kosong"}');
      if (data == null) return [];
      
      final events = (json.decode(data) as List).map((e) => Event.fromJson(e)).toList();
      print('🟢 Total events loaded: ${events.length}');
      return events;
    } catch (e) {
      print('❌ Error load events: $e');
      return [];
    }
  }

  static Future<void> saveEvents(int userId, List<Event> events) async {
    try {
      final jsonData = json.encode(events.map((e) => e.toJson()).toList());
      await _box.put('${_prefix}events_$userId', jsonData);
      print('🔵 SAVE Events untuk user $userId: ${events.length} events');
      
      final saved = _box.get('${_prefix}events_$userId');
      print('🔵 Verifikasi Events: ${saved != null ? "✅ Tersimpan di Hive!" : "❌ GAGAL!"}');
    } catch (e) {
      print('❌ Error save events: $e');
    }
  }

  // Tickets Management
  static Future<List<Ticket>> getTickets(int userId) async {
    try {
      final data = _box.get('${_prefix}tickets_$userId');
      print('🟢 LOAD Tickets untuk user $userId: ${data != null ? "Ada data" : "Kosong"}');
      if (data == null) return [];
      return (json.decode(data) as List).map((t) => Ticket.fromJson(t)).toList();
    } catch (e) {
      print('❌ Error load tickets: $e');
      return [];
    }
  }

  static Future<void> saveTickets(int userId, List<Ticket> tickets) async {
    try {
      final jsonData = json.encode(tickets.map((t) => t.toJson()).toList());
      await _box.put('${_prefix}tickets_$userId', jsonData);
      print('🔵 SAVE Tickets untuk user $userId: ${tickets.length} tickets');
    } catch (e) {
      print('❌ Error save tickets: $e');
    }
  }
}