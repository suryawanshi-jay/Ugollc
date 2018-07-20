import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class PrefsManager {
  static Future<String> getString(String pref) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      return prefs.getString(pref);
    } catch (exc) {
      return null;
    }
  }

  static setStringGroup(Map<String, String> group) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    group.forEach((String pref, value) {
      prefs.setString(pref, value);
    });
  }

  static clearPref(String pref) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(pref);
  }
}