// Web-only implementation to clear Supabase auth tokens

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void clearWebAuthStorage() {
  try {
    // Supabase stores in localStorage keys like sb-<project-ref>-auth-token
    final keys = <String>[];
    for (var i = 0; i < html.window.localStorage.length; i++) {
      final key = html.window.localStorage.keys.elementAt(i);
      if (key.startsWith('sb-') && key.endsWith('-auth-token')) {
        keys.add(key);
      }
    }
    for (final k in keys) {
      html.window.localStorage.remove(k);
    }
  } catch (_) {}
}


