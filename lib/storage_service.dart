import 'models.dart';
import 'database/hive_service.dart';

class StorageService {
  static Future<User?> getSession() async {
    final email = HiveService.getCurrentUserEmail();
    if (email != null) {
      return await HiveService.getUserByEmail(email);
    }
    return null;
  }

  static Future<void> saveSession(String email) async {
    await HiveService.saveCurrentUserEmail(email);
  }

  static Future<void> logout() async {
    await HiveService.clearCurrentUser();
  }

  static Future<void> clearAll() async {
    await HiveService.clearAllData();
  }
}