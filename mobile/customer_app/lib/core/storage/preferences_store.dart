import 'package:shared_preferences/shared_preferences.dart';

class PreferencesStore {
  static const _selectedBranchKey = 'customer.selected_branch';

  Future<String?> readSelectedBranch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedBranchKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSelectedBranch(String branchId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedBranchKey, branchId);
    } catch (_) {
      // Preferences are a convenience only.
    }
  }
}
