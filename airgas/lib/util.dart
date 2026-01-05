import 'package:get_storage/get_storage.dart';

class LocalStorages {
  final storage = GetStorage();

  saveTankNumber({required String TankNumber}) {
    storage.write("TankNumber", TankNumber);
  }

  String? getTankNumber() {
    return storage.read("TankNumber");
  }

  saveTrailorNumber({required String trailorNumber}) {
    storage.write("trailorNumber", trailorNumber);
  }

  String? gettrailorNumber() {
    return storage.read("trailorNumber");
  }

  saveToken({required String token}) {
    storage.write("kUserToken", token);
  }

  String? getToken() {
    return storage.read("kUserToken");
  }

  saveEmail({required String email}) {
    storage.write("kUserEmail", email);
  }

  String? getEmail() {
    return storage.read("kUserEmail");
  }

  saveRegisterNumber({required String registerNumber}) {
    storage.write("registerNumber", registerNumber);
  }

  String? getRegisterNumber() {
    return storage.read("registerNumber");
  }

  savePhoneNumber({required String phoneNumber}) {
    storage.write("phoneNumber", phoneNumber);
  }

  String? getPhoneNumber() {
    return storage.read("phoneNumber");
  }

  saveImage({required String Image}) {
    storage.write("Image", Image);
  }

  String? getImage() {
    return storage.read("Image");
  }
  void clearImage() {
    storage.remove("Image");
  }

  saveTanksNumber({required String tanksNumber}) {
    storage.write("tanksNumber", tanksNumber);
  }

  String? getTanksNumber() {
    return storage.read("tanksNumber");
  }

  saveEndTime({required String EndTime}) {
    storage.write("EndTime", EndTime);
  }

  String? getEndTime() {
    return storage.read("EndTime");
  }  saveTankInformationTime({required String tankInformationTIme}) {
    storage.write("tankInformationTIme", tankInformationTIme);
  }

  String? getTankInformationTime() {
    return storage.read("tankInformationTIme");
  }

}
