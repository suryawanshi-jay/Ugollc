class Country {
  int id;
  String name;

  Country(this.id, this.name);

  Country.fromJSON(Map json) {
    id = json["country_id"];
    name = json["name"];
  }

  int get hashCode => name.hashCode;

  bool operator==(Object other) => other is Country && other.name == name;
}
