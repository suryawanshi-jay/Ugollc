import 'package:ugo_flutter/utilities/constants.dart';

class Cart extends Object {
  List<CartProduct> products;
  List<CartVoucher> vouchers;
  List<CartTotal> totals;

  String weight;
  bool couponStatus;
  String coupon;
  bool voucherStatus;
  String voucher;
  bool rewardStatus;
  int reward;
  int maxRewardPointsToUse;
  bool shippingStatus;
  String errorWarning;

  Cart.fromJSON(Map json) {
    products = json["products"] == null ? [] : json["products"].map((Map product) =>
      new CartProduct.fromJSON(product)
    ).toList();
    vouchers = json["vouchers"] == null ? [] : json["vouchers"].map((Map voucher) =>
      new CartVoucher.fromJSON(voucher)
    ).toList();
    totals = json["totals"] == null ? [] : json["totals"].map((Map total) =>
      new CartTotal.fromJSON(total)
    ).toList();

    weight = json["weight"];
    couponStatus = json["coupon_status"];
    coupon = json["coupon"];
    voucherStatus = json["voucher_status"];
    voucher = json["voucher"];
    rewardStatus = json["reward_status"];
    reward = json["reward"];
    maxRewardPointsToUse = json["max_reward_points_to_use"];
    shippingStatus = json["shipping_status"];
    errorWarning = json["error_warning"];
  }

  int productCount() {
    var sum = 0;
    products.forEach((product) => sum += product.quantity);
    return sum;
  }

  int nonTipCount() {
    var sum = 0;
    products.forEach((product) {
      if (product.name != DRIVER_TIP_NAME) {
        sum += product.quantity;
      }
    });
    return sum;
  }
}

class CartProduct extends Object {
  String key;
  String name;
  String model;
  List<CartProductOption> options;
  String recurring;
  int quantity;
  String reward;
  int points;
  String price;
  String total;
  String thumbImage;
  bool inStock;

  CartProduct.fromJSON(Map json) {
    key = json["key"];
    name = json["name"];
    model = json["model"];
    options = json["option"] == null ? [] : json["option"].map((Map option) {
      new CartProductOption.fromJSON(option);
    }).toList();
    recurring = json["recurring"];
    quantity = json["quantity"];
    reward = json["reward"];
    points = json["points"];
    price = json["price"];
    total = json["total"];
    thumbImage = json["thumb_image"];
    inStock = json["in_stock"];
  }
}

class CartProductOption extends Object {
  String name;
  String value;

  CartProductOption.fromJSON(Map json) {
    name = json["name"];
    value = json["value"];
  }
}

class CartVoucher extends Object {
  String key;
  String description;
  String amount;

  CartVoucher.fromJSON(Map json) {
    key = json["key"];
    description = json["description"];
    amount = json["amount"];
  }
}

class CartTotal extends Object {
  String title;
  String text;

  CartTotal.fromJSON(Map json) {
    title = json["title"];
    text = json["text"];
  }
}