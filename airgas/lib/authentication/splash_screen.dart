import 'package:airgas/authentication/login.dart';
import 'package:airgas/authentication/tractor_number_screen.dart';
import 'package:airgas/dashboard/TankSiteScreen.dart';
import 'package:airgas/dashboard/bottomnavigation_screen.dart';
import 'package:airgas/util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      final token = LocalStorages().getToken();

      if (token == null || token.isEmpty) {

        Get.off(() => LoginScreen());
      } else {

        Get.off(() => TruckNumberScreen());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "Fleet Tracker",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
