import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'database/database_helper.dart';

class StorageService {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  // ============================================================================
  // SESSION MANAGEMENT (Menggunakan SharedPreferences)
  // ============================================================================

  /// Set session user (login)
  static Future<void> setSession(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_user_id', user.id);
      await prefs.setBool('is_logged_in', true);
      
      if (kDebugMode) {
        debugPrint('✅ Session set untuk user: ${user.name} (ID: ${user.id})');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error setSession: $e');
    }
  }

  /// Get current session user
  static Future<User?> getSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      
      if (!isLoggedIn) return null;
      
      final userId = prefs.getInt('current_user_id');
      if (userId == null) return null;
      
      final user = await _dbHelper.getUserById(userId);
      
      if (kDebugMode && user != null) {
        debugPrint('📖 Get session: ${user.name} (ID: ${user.id})');
      }
      
      return user;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getSession: $e');
      return null;
    }
  }

  /// Logout user (clear session)
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');
      await prefs.setBool('is_logged_in', false);
      
      if (kDebugMode) debugPrint('✅ User logged out');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error logout: $e');
    }
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_logged_in') ?? false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // USERS MANAGEMENT (SQLite)
  // ============================================================================

  /// Get all users dari SQLite
  static Future<List<User>> getUsers() async {
    try {
      final users = await _dbHelper.getAllUsers();
      
      if (kDebugMode) {
        debugPrint('📖 GET USERS: ${users.length} users');
      }
      
      return users;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getUsers: $e');
      return [];
    }
  }

  /// Save user baru (register) ke SQLite
  static Future<bool> saveUser(User user) async {
    try {
      final result = await _dbHelper.insertUser(user);
      
      if (kDebugMode) {
        debugPrint('💾 SAVE USER: ${user.name} (${user.email}) - Result: $result');
      }
      
      return result > 0;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error saveUser: $e');
      return false;
    }
  }

  /// Login user dengan email dan password
  static Future<User?> loginUser(String email, String password) async {
    try {
      final user = await _dbHelper.loginUser(email, password);
      
      if (user != null) {
        await setSession(user);
        if (kDebugMode) {
          debugPrint('✅ LOGIN SUCCESS: ${user.name} (${user.email})');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ LOGIN FAILED: Email atau password salah');
        }
      }
      
      return user;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loginUser: $e');
      return null;
    }
  }

  /// Get user by email
  static Future<User?> getUserByEmail(String email) async {
    try {
      return await _dbHelper.getUserByEmail(email);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getUserByEmail: $e');
      return null;
    }
  }

  // ============================================================================
  // EVENTS MANAGEMENT (SQLite)
  // ============================================================================

  /// Get all events dari SQLite
  static Future<List<Event>> getEvents(int userId) async {
    try {
      final events = await _dbHelper.getAllEvents();
      
      if (kDebugMode) {
        debugPrint('📖 GET EVENTS untuk userId: $userId');
        debugPrint('   Total events: ${events.length}');
        for (var event in events) {
          debugPrint('      - ${event.name} (ID: ${event.id})');
        }
      }
      
      return events;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getEvents: $e');
      return [];
    }
  }

  /// Save event baru ke SQLite
  static Future<bool> saveEvent(Event event) async {
    try {
      final result = await _dbHelper.insertEvent(event);
      
      if (kDebugMode) {
        debugPrint('💾 SAVE EVENT: ${event.name} - Result: $result');
      }
      
      return result > 0;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error saveEvent: $e');
      return false;
    }
  }

  /// Save multiple events (backward compatibility)
  static Future<void> saveEvents(int userId, List<Event> events) async {
    try {
      if (kDebugMode) {
        debugPrint('💾 SAVE EVENTS untuk userId: $userId');
        debugPrint('   Total events: ${events.length}');
        debugPrint('⚠️ NOTE: Data sudah otomatis tersimpan di SQLite');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error saveEvents: $e');
    }
  }

  /// Update event di SQLite
  static Future<bool> updateEvent(Event event) async {
    try {
      final result = await _dbHelper.updateEvent(event);
      
      if (kDebugMode) {
        debugPrint('🔄 UPDATE EVENT: ${event.name} - Result: $result');
      }
      
      return result > 0;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error updateEvent: $e');
      return false;
    }
  }

  /// Delete event dari SQLite
  static Future<bool> deleteEvent(int eventId) async {
    try {
      final result = await _dbHelper.deleteEvent(eventId);
      
      if (kDebugMode) {
        debugPrint('🗑️ DELETE EVENT ID: $eventId - Result: $result');
      }
      
      return result > 0;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error deleteEvent: $e');
      return false;
    }
  }

  // ============================================================================
  // TICKETS MANAGEMENT (SQLite)
  // ============================================================================

  /// Get all tickets dari SQLite
  static Future<List<Ticket>> getTickets(int userId) async {
    try {
      final tickets = await _dbHelper.getAllTickets();
      
      if (kDebugMode) {
        debugPrint('📖 GET TICKETS untuk userId: $userId');
        debugPrint('   Total tickets: ${tickets.length}');
      }
      
      return tickets;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getTickets: $e');
      return [];
    }
  }

  /// Get tickets by event ID
  static Future<List<Ticket>> getTicketsByEventId(int eventId) async {
    try {
      final tickets = await _dbHelper.getTicketsByEventId(eventId);
      
      if (kDebugMode) {
        debugPrint('📖 GET TICKETS for eventId: $eventId - ${tickets.length} tickets');
      }
      
      return tickets;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getTicketsByEventId: $e');
      return [];
    }
  }

  /// Save ticket baru ke SQLite
  static Future<bool> saveTicket(Ticket ticket) async {
    try {
      final result = await _dbHelper.insertTicket(ticket);
      
      if (kDebugMode) {
        debugPrint('💾 SAVE TICKET: ${ticket.code} - Result: $result');
      }
      
      return result > 0;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error saveTicket: $e');
      return false;
    }
  }

  /// Save multiple tickets (backward compatibility)
  static Future<void> saveTickets(int userId, List<Ticket> tickets) async {
    try {
      if (kDebugMode) {
        debugPrint('💾 SAVE TICKETS untuk userId: $userId');
        debugPrint('   Total tickets: ${tickets.length}');
        debugPrint('⚠️ NOTE: Data sudah otomatis tersimpan di SQLite');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error saveTickets: $e');
    }
  }

  /// Update ticket di SQLite
  static Future<bool> updateTicket(Ticket ticket) async {
    try {
      final result = await _dbHelper.updateTicket(ticket);
      
      if (kDebugMode) {
        debugPrint('🔄 UPDATE TICKET: ${ticket.code} - Result: $result');
      }
      
      return result > 0;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error updateTicket: $e');
      return false;
    }
  }

  /// Scan ticket (mark as scanned)
  static Future<bool> scanTicket(int ticketId) async {
    try {
      final result = await _dbHelper.scanTicket(ticketId);
      
      if (kDebugMode) {
        debugPrint('📱 SCAN TICKET ID: $ticketId - Result: $result');
      }
      
      return result > 0;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error scanTicket: $e');
      return false;
    }
  }

  /// Get ticket by code (untuk scan QR)
  static Future<Ticket?> getTicketByCode(String code) async {
    try {
      final ticket = await _dbHelper.getTicketByCode(code);
      
      if (kDebugMode) {
        if (ticket != null) {
          debugPrint('✅ TICKET FOUND: ${ticket.code} - ${ticket.buyerName}');
        } else {
          debugPrint('❌ TICKET NOT FOUND: $code');
        }
      }
      
      return ticket;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getTicketByCode: $e');
      return null;
    }
  }

  /// Delete ticket dari SQLite
  static Future<bool> deleteTicket(int ticketId) async {
    try {
      final result = await _dbHelper.deleteTicket(ticketId);
      
      if (kDebugMode) {
        debugPrint('🗑️ DELETE TICKET ID: $ticketId - Result: $result');
      }
      
      return result > 0;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error deleteTicket: $e');
      return false;
    }
  }

  // ============================================================================
  // STATISTICS & UTILITIES
  // ============================================================================

  /// Get total events count
  static Future<int> getTotalEventsCount() async {
    try {
      return await _dbHelper.getTotalEventsCount();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getTotalEventsCount: $e');
      return 0;
    }
  }

  /// Get total tickets count
  static Future<int> getTotalTicketsCount() async {
    try {
      return await _dbHelper.getTotalTicketsCount();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getTotalTicketsCount: $e');
      return 0;
    }
  }

  /// Get scanned tickets count
  static Future<int> getScannedTicketsCount() async {
    try {
      return await _dbHelper.getScannedTicketsCount();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getScannedTicketsCount: $e');
      return 0;
    }
  }

  /// Get total revenue
  static Future<double> getTotalRevenue() async {
    try {
      return await _dbHelper.getTotalRevenue();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getTotalRevenue: $e');
      return 0.0;
    }
  }

  // ============================================================================
  // MIGRATION & DEBUG UTILITIES
  // ============================================================================

  /// Clear all data (untuk testing/reset)
  static Future<void> clearAllData() async {
    try {
      await _dbHelper.clearAllData();
      await logout();
      
      if (kDebugMode) {
        debugPrint('🗑️ ALL DATA CLEARED (SQLite + Session)');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error clearAllData: $e');
    }
  }

  /// Debug: Print all data
  static Future<void> debugPrintAllData() async {
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('DEBUG: ALL DATA');
      debugPrint('═══════════════════════════════════════');
      
      final users = await getUsers();
      debugPrint('👥 USERS (${users.length}):');
      for (var user in users) {
        debugPrint('   - ${user.name} (${user.email})');
      }
      
      final events = await _dbHelper.getAllEvents();
      debugPrint('\n🎉 EVENTS (${events.length}):');
      for (var event in events) {
        debugPrint('   - ${event.name} (${event.ticketsSold}/${event.capacity})');
      }
      
      final tickets = await _dbHelper.getAllTickets();
      debugPrint('\n🎫 TICKETS (${tickets.length}):');
      for (var ticket in tickets) {
        debugPrint('   - ${ticket.code} - ${ticket.buyerName} (Scanned: ${ticket.isScanned})');
      }
      
      final session = await getSession();
      debugPrint('\n🔐 SESSION:');
      if (session != null) {
        debugPrint('   - Logged in as: ${session.name}');
      } else {
        debugPrint('   - Not logged in');
      }
      
      debugPrint('═══════════════════════════════════════\n');
    }
  }
}