import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pc_profile.dart';

class StorageService {
  static const _profilesKey = 'pc_profiles';

  Future<List<PcProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_profilesKey);
    if (json == null) {
      // Migrate old single-profile format
      final old = prefs.getString('pc_profile');
      if (old != null) {
        final profile = PcProfile.fromJson(jsonDecode(old));
        await saveProfiles([profile]);
        await prefs.remove('pc_profile');
        return [profile];
      }
      return [];
    }
    final List<dynamic> list = jsonDecode(json);
    return list.map((e) => PcProfile.fromJson(e)).toList();
  }

  Future<void> saveProfiles(List<PcProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(profiles.map((p) => p.toJson()).toList());
    await prefs.setString(_profilesKey, json);
  }

  /// Adds [profile] unless a PC with the same IP+port already exists.
  ///
  /// Returns the conflicting profile when a duplicate is found, or `null` on
  /// success. The caller is responsible for showing a localized message.
  Future<PcProfile?> addProfile(PcProfile profile) async {
    final profiles = await loadProfiles();
    // Check for duplicate IP+port
    final duplicate = profiles
        .where(
            (p) => p.ipAddress == profile.ipAddress && p.port == profile.port)
        .toList();
    if (duplicate.isNotEmpty) {
      return duplicate.first;
    }
    profiles.add(profile);
    await saveProfiles(profiles);
    return null; // no error
  }

  Future<void> updateProfile(PcProfile profile) async {
    final profiles = await loadProfiles();
    final index = profiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      profiles[index] = profile;
      await saveProfiles(profiles);
    }
  }

  Future<void> deleteProfile(String id) async {
    final profiles = await loadProfiles();
    profiles.removeWhere((p) => p.id == id);
    await saveProfiles(profiles);
  }
}
