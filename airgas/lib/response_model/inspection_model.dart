class InspectionReportModel {
  bool? status;
  String? type;
  List<Checklist>? checklist;

  InspectionReportModel({this.status, this.type, this.checklist});

  InspectionReportModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    type = json['type'];
    if (json['checklist'] != null) {
      checklist = <Checklist>[];
      json['checklist'].forEach((v) {
        checklist!.add(new Checklist.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['type'] = this.type;
    if (this.checklist != null) {
      data['checklist'] = this.checklist!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Checklist {
  String? group;
  List<Items>? items;

  Checklist({this.group, this.items});

  Checklist.fromJson(Map<String, dynamic> json) {
    group = json['group'];
    if (json['items'] != null) {
      items = <Items>[];
      json['items'].forEach((v) {
        items!.add(new Items.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['group'] = this.group;
    if (this.items != null) {
      data['items'] = this.items!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Items {
  String? id;
  String? label;
  bool? isSafety;

  Items({this.id, this.label, this.isSafety});

  Items.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    label = json['label'];
    isSafety = json['is_safety'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['label'] = this.label;
    data['is_safety'] = this.isSafety;
    return data;
  }
}
