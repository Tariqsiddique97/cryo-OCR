class TripStopModel {
  Trip? trip;
  bool? status;

  TripStopModel({this.trip, this.status});

  TripStopModel.fromJson(Map<String, dynamic> json) {
    trip = json['trip'] != null ? new Trip.fromJson(json['trip']) : null;
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.trip != null) {
      data['trip'] = this.trip!.toJson();
    }
    data['status'] = this.status;
    return data;
  }
}

class Trip {
  int? id;
  int? status;
  String? driverName;
  String? tractorNumber;
  String? trailerNumber;
  Null? totalQuantity;
  Null? totalTripMiles;
  List<Stops>? stops;

  Trip(
      {this.id,
        this.status,
        this.driverName,
        this.tractorNumber,
        this.trailerNumber,
        this.totalQuantity,
        this.totalTripMiles,
        this.stops});

  Trip.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    status = json['status'];
    driverName = json['driver_name'];
    tractorNumber = json['tractor_number'];
    trailerNumber = json['trailer_number'];
    totalQuantity = json['total_quantity'];
    totalTripMiles = json['total_trip_miles'];
    if (json['stops'] != null) {
      stops = <Stops>[];
      json['stops'].forEach((v) {
        stops!.add(new Stops.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['status'] = this.status;
    data['driver_name'] = this.driverName;
    data['tractor_number'] = this.tractorNumber;
    data['trailer_number'] = this.trailerNumber;
    data['total_quantity'] = this.totalQuantity;
    data['total_trip_miles'] = this.totalTripMiles;
    if (this.stops != null) {
      data['stops'] = this.stops!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Stops {
  int? id;
  int? sequenceNumber;
  int? tripId;
  String? name;
  String? address;
  String? latitude;
  String? longitude;
  String? startTime;
  String? endTime;
  String? tankInformationImage;
  String? tankInformationImageTime;
  String? tankNumber;
  String? fullTrycock;
  String? attnDriverMaintain;
  String? tankLevelImage;
  String? tankLevelImageTime;
  String? psiValue;
  String? levelsValue;
  String? levelBeforeImage;
  String? levelBeforeImageTime;
  String? levelBeforeValue;
  String? levelAfterImage;
  String? levelAfterImageTime;
  String? levelAfterValue;
  String? psiBeforeImage;
  String? psiBeforeImageTime;
  String? psiBeforeValue;
  String? psiAfterImage;
  String? psiAfterImageTime;
  String? psiAfterValue;
  String? quantityImage;
  String? quantityImageTime;
  String? quantityValue;
  String? quantityUm;
  String? odometerImage;
  String? odometerImageTime;
  String? odometerValue;
  String? isTankVerified;
  int? status;
  String? createdAt;
  String? updatedAt;

  Stops(
      {this.id,
        this.sequenceNumber,
        this.tripId,
        this.name,
        this.address,
        this.latitude,
        this.longitude,
        this.startTime,
        this.endTime,
        this.tankInformationImage,
        this.tankInformationImageTime,
        this.tankNumber,
        this.fullTrycock,
        this.attnDriverMaintain,
        this.tankLevelImage,
        this.tankLevelImageTime,
        this.psiValue,
        this.levelsValue,
        this.levelBeforeImage,
        this.levelBeforeImageTime,
        this.levelBeforeValue,
        this.levelAfterImage,
        this.levelAfterImageTime,
        this.levelAfterValue,
        this.psiBeforeImage,
        this.psiBeforeImageTime,
        this.psiBeforeValue,
        this.psiAfterImage,
        this.psiAfterImageTime,
        this.psiAfterValue,
        this.quantityImage,
        this.quantityImageTime,
        this.quantityValue,
        this.quantityUm,
        this.odometerImage,
        this.odometerImageTime,
        this.odometerValue,
        this.isTankVerified,
        this.status,
        this.createdAt,
        this.updatedAt});

  Stops.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sequenceNumber = json['sequence_number'];
    tripId = json['trip_id'];
    name = json['name'];
    address = json['address'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    tankInformationImage = json['tank_information_image'];
    tankInformationImageTime = json['tank_information_image_time'];
    tankNumber = json['tank_number'];
    fullTrycock = json['full_trycock'];
    attnDriverMaintain = json['attn_driver_maintain'];
    tankLevelImage = json['tank_level_image'];
    tankLevelImageTime = json['tank_level_image_time'];
    psiValue = json['psi_value'];
    levelsValue = json['levels_value'];
    levelBeforeImage = json['level_before_image'];
    levelBeforeImageTime = json['level_before_image_time'];
    levelBeforeValue = json['level_before_value'];
    levelAfterImage = json['level_after_image'];
    levelAfterImageTime = json['level_after_image_time'];
    levelAfterValue = json['level_after_value'];
    psiBeforeImage = json['psi_before_image'];
    psiBeforeImageTime = json['psi_before_image_time'];
    psiBeforeValue = json['psi_before_value'];
    psiAfterImage = json['psi_after_image'];
    psiAfterImageTime = json['psi_after_image_time'];
    psiAfterValue = json['psi_after_value'];
    quantityImage = json['quantity_image'];
    quantityImageTime = json['quantity_image_time'];
    quantityValue = json['quantity_value'];
    quantityUm = json['quantity_um'];
    odometerImage = json['odometer_image'];
    odometerImageTime = json['odometer_image_time'];
    odometerValue = json['odometer_value'];
    isTankVerified = json['is_tank_verified'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['sequence_number'] = this.sequenceNumber;
    data['trip_id'] = this.tripId;
    data['name'] = this.name;
    data['address'] = this.address;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['start_time'] = this.startTime;
    data['end_time'] = this.endTime;
    data['tank_information_image'] = this.tankInformationImage;
    data['tank_information_image_time'] = this.tankInformationImageTime;
    data['tank_number'] = this.tankNumber;
    data['full_trycock'] = this.fullTrycock;
    data['attn_driver_maintain'] = this.attnDriverMaintain;
    data['tank_level_image'] = this.tankLevelImage;
    data['tank_level_image_time'] = this.tankLevelImageTime;
    data['psi_value'] = this.psiValue;
    data['levels_value'] = this.levelsValue;
    data['level_before_image'] = this.levelBeforeImage;
    data['level_before_image_time'] = this.levelBeforeImageTime;
    data['level_before_value'] = this.levelBeforeValue;
    data['level_after_image'] = this.levelAfterImage;
    data['level_after_image_time'] = this.levelAfterImageTime;
    data['level_after_value'] = this.levelAfterValue;
    data['psi_before_image'] = this.psiBeforeImage;
    data['psi_before_image_time'] = this.psiBeforeImageTime;
    data['psi_before_value'] = this.psiBeforeValue;
    data['psi_after_image'] = this.psiAfterImage;
    data['psi_after_image_time'] = this.psiAfterImageTime;
    data['psi_after_value'] = this.psiAfterValue;
    data['quantity_image'] = this.quantityImage;
    data['quantity_image_time'] = this.quantityImageTime;
    data['quantity_value'] = this.quantityValue;
    data['quantity_um'] = this.quantityUm;
    data['odometer_image'] = this.odometerImage;
    data['odometer_image_time'] = this.odometerImageTime;
    data['odometer_value'] = this.odometerValue;
    data['is_tank_verified'] = this.isTankVerified;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
