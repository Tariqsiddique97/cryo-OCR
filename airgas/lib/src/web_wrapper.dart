import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// A simple wrapper to render a Sign-In button on web
Widget renderButton() {
  return ElevatedButton.icon(
    onPressed: () async {
      try {
        await GoogleSignIn.instance.authenticate();
      } catch (e) {
        debugPrint('Google Sign-In failed: $e');
      }
    },
    icon: const Icon(Icons.login),
    label: const Text("SIGN IN WITH GOOGLE"),
  );
}
