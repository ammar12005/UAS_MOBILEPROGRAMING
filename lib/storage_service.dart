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
      if (data == null) return [];
      return (json.decode(data) as List).map((u) => User.fromJson(u)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveUsers(List<User> users) async {
    try {
      final jsonData = json.encode(users.map((u) => u.toJson()).toList());
      await _box.put('${_prefix}users', jsonData);
    } catch (e) {
      // Handle error silently or use proper logging
    }
  }

  // Session Management
  static Future<void> setSession(User user) async {
    try {
      final jsonData = json.encode(user.toJson());
      
      await _box.put('${_prefix}current_user', jsonData);
      await _box.put('${_prefix}is_logged_in', 'true');
      await _box.put('${_prefix}user_id', user.id);
    } catch (e) {
      // Handle error silently or use proper logging
    }
  }

  static Future<User?> getSession() async {
    try {
      final isLoggedIn = _box.get('${_prefix}is_logged_in');
      
      if (isLoggedIn != 'true') {
        return null;
      }
      
      final data = _box.get('${_prefix}current_user');
      if (data == null) {
        return null;
      }
      
      final user = User.fromJson(json.decode(data));
      return user;
      
    } catch (e) {
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      await _box.delete('${_prefix}current_user');
      await _box.put('${_prefix}is_logged_in', 'false');
      await _box.delete('${_prefix}user_id');
    } catch (e) {
      // Handle error silently or use proper logging
    }
  }

  // Events Management
  static Future<List<Event>> getEvents(int userId) async {
    try {
      final data = _box.get('${_prefix}events_$userId');
      if (data == null) return [];
      
      final events = (json.decode(data) as List).map((e) => Event.fromJson(e)).toList();
      return events;
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveEvents(int userId, List<Event> events) async {
    try {
      final jsonData = json.encode(events.map((e) => e.toJson()).toList());
      await _box.put('${_prefix}events_$userId', jsonData);
    } catch (e) {
      // Handle error silently or use proper logging
    }
  }

  // Tickets Management
  static Future<List<Ticket>> getTickets(int userId) async {
    try {
      final data = _box.get('${_prefix}tickets_$userId');
      if (data == null) return [];
      return (json.decode(data) as List).map((t) => Ticket.fromJson(t)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveTickets(int userId, List<Ticket> tickets) async {
    try {
      final jsonData = json.encode(tickets.map((t) => t.toJson()).toList());
      await _box.put('${_prefix}tickets_$userId', jsonData);
    } catch (e) {
      // Handle error silently or use proper logging
    }
  }
}