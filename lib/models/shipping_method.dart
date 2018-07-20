class ShippingMethod {
  String title;
  String id;
  String displayCost;
  double cost;

  ShippingMethod.fromJSON(Map json) {
    title = json["title"];
    id = json["quote"].first["code"];
    displayCost = json["quote"].first["display_cost"];
    cost = json["quote"].first["cost"].toDouble();
  }
}