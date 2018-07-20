class SimpleOrder extends Object {
  int id;
  String name;
  String status;
  DateTime date;
  int products;
  String total;

  SimpleOrder.fromJSON(Map json) {
    id = json["order_id"];
    name = json["name"];
    status = json["status"];
//    date = DateTime.parse(json["date_added"]);
    products = json["products"];
    total = json["total"];

    final _dateParts = json["date_added"].split("/");
    date = DateTime.parse("${_dateParts[2]}-${_dateParts[1]}-${_dateParts[0]}");
//    date = new DateTime(
//      int.parse(_dateParts[2]), int.parse(_dateParts[1]), _dateParts[0]);
  }
}

class Order {
  int id;
  String date;
  String invoiceNo;
  String firstName;
  String lastName;
  String telephone;
  String fax;
  String email;
  String shippingMethod;
  String shippingFirstName;
  String shippingLastName;
  String shippingAddress1;
  String shippingAddress2;
  String shippingPostcode;
  String shippingCity;
  String shippingZone;
  String shippingCountry;
  String shippingAddressFormat;
  String paymentMethod;
  List<OrderProduct> products;
  List<OrderTotal> totals;
  List<OrderHistory> histories;
  String comment;

  Order.fromJSON(Map json) {
    id = json["order_id"];
    date = json["date_added"];
    invoiceNo = json["invoice_no"];
    firstName = json["firstname"];
    lastName = json["lastname"];
    telephone = json["telephone"];
    fax = json["fax"];
    email = json["email"];
    shippingMethod = json["shipping_method"];
    shippingFirstName = json["shipping_firstname"];
    shippingLastName = json["shipping_lastname"];
    shippingAddress1 = json["shipping_address_1"];
    shippingAddress2 = json["shipping_address_2"];
    shippingPostcode = json["shipping_postcode"];
    shippingCity = json["shipping_city"];
    shippingZone = json["shipping_zone"];
    shippingAddressFormat = json["shipping_address_formate"];
    shippingCountry = json["shipping_country"];
    paymentMethod = json["payment_method"];
    comment = json["comment"];

    products = json["products"] == null
      ? []
      : json["products"].map((Map product) =>
        new OrderProduct.fromJSON(product)).toList();
    totals = json["totals"] == null
      ? []
      : json["totals"].map((Map total) =>
        new OrderTotal.fromJSON(total)).toList();
    histories = json["history"] == null
      ? []
      : json["history"].map((Map history) =>
        new OrderHistory.fromJSON(history)).toList();

  }
}

class OrderProduct {
  String name;
  String model;
  int quantity;
  String price;
  String total;
  int orderProductID;

  OrderProduct.fromJSON(Map json) {
    name = json["name"];
    model = json["model"];
    quantity = json["quantity"];
    price = json["price"];
    total = json["total"];
    orderProductID = json["order_product_id"];
  }
}

class OrderTotal {
  String title;
  String text;

  OrderTotal.fromJSON(Map json) {
    title = json["title"];
    text = json["text"];
  }
}

class OrderHistory {
  String date;
  String status;
  String comment;

  OrderHistory.fromJSON(Map json) {
    date = json["date_added"];
    status = json["status"];
    comment = json["comment"];
  }
}