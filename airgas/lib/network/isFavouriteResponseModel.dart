class IsFavouriteResponseModel {
  int? statusCode;
  String? msg;

  IsFavouriteResponseModel({this.statusCode, this.msg});

  IsFavouriteResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['statusCode'] = this.statusCode;
    data['msg'] = this.msg;
    return data;
  }
}
