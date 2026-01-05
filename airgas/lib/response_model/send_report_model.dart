class SendReportModel {
  bool? status;
  String? message;
  int? tripId;

  SendReportModel({this.status, this.message, this.tripId});

  SendReportModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    tripId = json['trip_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    data['trip_id'] = this.tripId;
    return data;
  }
}
