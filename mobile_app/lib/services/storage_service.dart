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

  Future<void> addProfile(PcProfile profile) async {
    final profiles = await loadProfiles();
    profiles.add(profile);
    await saveProfiles(profiles);
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
