import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../network/service_provider.dart';
import '../../response_model/login_model.dart';

class LoginController extends GetxController{
  TextEditingController usernameInput = TextEditingController();
  TextEditingController passwordInput = TextEditingController();

  LoginModel loginModel = LoginModel();

  Future loginApi() async {
    try {
      loginModel = await ServiceProvider().login(
        username: usernameInput.text.trim(),
        password: passwordInput.text.trim(),
      );
    } catch (e) {
      print('Error occurred: $e');
    }
  }
}