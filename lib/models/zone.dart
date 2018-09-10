class Zone {
  int id;
  String name;

  Zone.fromJSON(Map json) {
    id =  int.parse(json["zone_id"]);
    name = json["name"];
  }
}