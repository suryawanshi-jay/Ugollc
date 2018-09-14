class Zone {
  int id;
  String name;

  Zone(this.id, this.name);

  Zone.fromJSON(Map json) {
    id =  int.parse(json["zone_id"]);
    name = json["name"];
  }

  int get hashCode => name.hashCode;

  bool operator==(Object other) => other is Zone && other.name == name;
}