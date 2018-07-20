class Address {
  int id;
  String firstName;
  String lastName;
  String company;
  String address1;
  String address2;
  String zip;
  String city;
  int zoneID;
  String zone;
  String zoneCode;
  int countryID;
  String country;
  String isoCode2;
  String isoCode3;
  String addressFormat;

  Address.fromJSON(Map json) {
    id = json["address_id"];
    firstName = json["firstname"];
    lastName = json["lastname"];
    company = json["company"];
    address1 = json["address_1"];
    address2 = json["address_2"];
    zip = json["postcode"];
    city = json["city"];
    zoneID = json["zone_id"];
    zone = json["zone"];
    zoneCode = json["zone_code"];
    countryID = json["country_id"];
    country = json["country"];
    isoCode2 = json["iso_code_2"];
    isoCode3 = json["iso_code_3"];
    addressFormat = json["address_format"];
  }
}