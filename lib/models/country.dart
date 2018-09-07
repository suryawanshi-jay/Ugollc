class Country {
  int id;
  String name;

  Country.fromJSON(Map json) {
    id = json["country_id"];
    name = json["name"];
  }
}