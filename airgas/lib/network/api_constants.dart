class ApiConstants {
  static const baseUrl =
      "http://ec2-18-206-172-221.compute-1.amazonaws.com/api/";
  static const login =
      'http://ec2-18-206-172-221.compute-1.amazonaws.com/api/login';
  static const truck =
      'http://ec2-18-206-172-221.compute-1.amazonaws.com/api/trip/pending';
  static const tripSite =
      'http://ec2-18-206-172-221.compute-1.amazonaws.com/api/trip/pending';
  static const stopInProgress =
      'http://ec2-18-206-172-221.compute-1.amazonaws.com/api/trip/stop/in-progress';
  static const stopComplete =
      'http://ec2-18-206-172-221.compute-1.amazonaws.com/api/trip/stop/complete';
  static const odoMeter =
      'http://ec2-18-206-172-221.compute-1.amazonaws.com/api/trip/stop/update-odometer';
  static const sendReportApi =
      'http://ec2-18-206-172-221.compute-1.amazonaws.com/api/trip/send-report';
  static const sendInspectionReportApi =
      'http://ec2-18-206-172-221.compute-1.amazonaws.com/api/inspection-checklist?type=tractor';
  static const sendInspectionReportApiTrailor =
      'http://ec2-18-206-172-221.compute-1.amazonaws.com/api/inspection-checklist?type=trailer';
}
