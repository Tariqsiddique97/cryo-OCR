import 'package:airgas/authentication/tractor_number_screen.dart';
import 'package:airgas/controller/auth_controller/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../util.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  var controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: GetBuilder(
        init: controller,
        builder: (value) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Text(
                  "Fleet Tracker",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Create an account",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter your email to sign up for this app",
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Username Field
                TextField(
                  controller: controller.usernameInput,
                  decoration: InputDecoration(
                    hintText: "username:",
                    hintStyle: GoogleFonts.inter(),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password Field
                TextField(
                  controller: controller.passwordInput,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "password:",
                    hintStyle: GoogleFonts.inter(),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      controller.loginApi().whenComplete(() {
                        if (controller.loginModel.status == true) {
                          LocalStorages().saveToken(
                            token: controller.loginModel.token ?? "",
                          );
                          Get.to(TruckNumberScreen());
                        } else {
                          print("==>> Not Success");
                        }
                      });
                    },
                    child: Text(
                      "Continue",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Divider with "or"
                // Row(
                //   children: [
                //     const Expanded(child: Divider(thickness: 1)),
                //     Padding(
                //       padding: const EdgeInsets.symmetric(horizontal: 12),
                //       child: Text(
                //         "or",
                //         style: GoogleFonts.poppins(
                //           fontSize: 14,
                //           color: Colors.black54,
                //         ),
                //       ),
                //     ),
                //     const Expanded(child: Divider(thickness: 1)),
                //   ],
                // ),
                //
                // const SizedBox(height: 24),
                //
                // // Continue with Google
                // Image.asset(AssetsScreen.iconsGoogle),
                //
                // const SizedBox(height: 20),
                //
                // // Continue with Apple
                // Image.asset(AssetsScreen.iconsApple),
                const SizedBox(height: 24),

                // Terms and Privacy
                Text.rich(
                  TextSpan(
                    text: "By clicking continue, you agree to our ",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                    children: [
                      TextSpan(
                        text: "Terms of Service",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: " and "),
                      TextSpan(
                        text: "Privacy Policy",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
