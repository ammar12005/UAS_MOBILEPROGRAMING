import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';

class StorageService {
  static const String _prefix = 'emp_v2_';
  static Box get _box => Hive.box('eventManagerStorage');

  // --- Users Management ---
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
      await _box.flush();
    } catch (e) {
      if (kDebugMode) debugPrint('Error saveUsers: $e');
    }
  }

  // --- Session Management ---
  static Future<void> setSession(User user) async {
    try {
      await _box.put('${_prefix}current_user', json.encode(user.toJson()));
      await _box.put('${_prefix}is_logged_in', 'true');
      await _box.put('${_prefix}user_id', user.id);
      await _box.flush();
    } catch (e) {
      if (kDebugMode) debugPrint('Error setSession: $e');
    }
  }

  static Future<User?> getSession() async {
    try {
      if (_box.get('${_prefix}is_logged_in') != 'true') return null;
      final data = _box.get('${_prefix}current_user');
      if (data == null) return null;
      return User.fromJson(json.decode(data));
    } catch (e) {
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      await _box.delete('${_prefix}current_user');
      await _box.put('${_prefix}is_logged_in', 'false');
      await _box.flush();
    } catch (e) {
      if (kDebugMode) debugPrint('Error logout: $e');
    }
  }

  // --- Events Management ---
  static Future<List<Event>> getEvents(int userId) async {
    try {
      final data = _box.get('${_prefix}events_$userId');
      if (data == null) return [];
      return (json.decode(data) as List).map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveEvents(int userId, List<Event> events) async {
    try {
      final jsonData = json.encode(events.map((e) => e.toJson()).toList());
      await _box.put('${_prefix}events_$userId', jsonData);
      await _box.flush();
    } catch (e) {
      if (kDebugMode) debugPrint('Error saveEvents: $e');
    }
  }

  // --- Tickets Management (MEMPERBAIKI ERROR image_6cc83e.jpg) ---
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
      await _box.flush();
    } catch (e) {
      if (kDebugMode) debugPrint('Error saveTickets: $e');
    }
  }
}