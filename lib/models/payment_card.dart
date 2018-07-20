class PaymentCard {
  String id;
  String brand;
  int expMonth;
  int expYear;
  String last4;

  PaymentCard.fromJSON(Map json) {
    id = json["id"];
    brand = json["brand"];
    expMonth = json["exp_month"];
    expYear = json["exp_year"];
    last4 = json["last4"];
  }
}