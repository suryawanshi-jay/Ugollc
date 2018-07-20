import 'package:flutter/material.dart';
import 'package:html/dom.dart';
import "package:html/parser.dart";

class Product extends Object {
  int id;
  String title;
  String model;
  String description;
  String thumbImage;
  String image;
  List<ProductImage> images;
  String price;
  String tax;
  String special;
  List<Discount> discounts;
  List<Option> options;
  String manufacturer;
  int rewardPoints;
  int rewardPointsToBuy;
  List<AttributeGroup> attributeGroups;
  int minimumQuantity;
  int stockStatus;
  List<RelatedProduct> relatedProducts;
  int rating;
  String reviews;
  bool reviewEnabled;
  List<Recurring> recurrings;

  Product.fromJSON(Map json) {
    id = json["product_id"];
    title = json["title"];
    model = json["model"];
    description = json["description"];
    thumbImage = json["thumb_image"];
    image = json["image"];
    images = json["images"] == null ? [] : json["images"].map((Map image) {
      return new ProductImage.fromJSON(image);
    }).toList();
    price = json["price"];
    tax = json["tax"] ?? "";
    special = json["special"] ?? "";
    discounts = json["discounts"] == null ? [] : json["discounts"].map((Map discount) {
      return new Discount.fromJSON(discount);
    }).toList();
    options = json["options"] == null ? [] : json["options"].map((Map option) {
      return new Option.fromJSON(option);
    }).toList();
    manufacturer = json["manufacturer"] ?? "";
    rewardPoints = json["reward_points"];
    rewardPointsToBuy = json["reward_points_to_buy"];
    attributeGroups = json["attribute_groups"] == null ? [] : json["attribute_groups"].map((Map group) {
      return new AttributeGroup.fromJSON(group);
    }).toList();
    minimumQuantity = json["minimum_quantity"];
    stockStatus = int.parse(json["stock_status"], onError: (value) => 0);
    relatedProducts = json["related_products"] == null ? [] : json["related_products"].map((Map related) {
      return new RelatedProduct.fromJSON(related);
    }).toList();
    rating = json["rating"];
    reviews = json["reviews"];
    reviewEnabled = json["review_enabled"];
    recurrings = json["recurrings"] == null ? [] : json["recurrings"].map((Map recurring) {
      return new Recurring.fromJSON(recurring);
    }).toList();
  }

  richTextDescription() {
    final document = parse(description);
    final elements = new FilteredElementList(document.body);

    final first = elements.removeAt(0);

    final list = elements.map((element) =>
      new TextSpan(
        text: "${element.text}\n\n",
        style: const TextStyle(fontSize: 14.0),
      )
    ).toList();

    return new RichText(
      text: new TextSpan(
        text: "${first.text}\n\n",
        style: new TextStyle(
          color: Colors.grey[800],
          fontSize: 18.0,
        ),
        children: list
      ),
    );
  }
}

class ProductImage extends Object {
  String thumbImage;
  String image;

  ProductImage.fromJSON(Map json) {
    thumbImage = json["thumb_image"];
    image = json["image"];
  }
}

class Discount extends Object {
  int quantity;
  String price;

  Discount.fromJSON(Map json) {
    quantity = json["quantity"];
    price = json["price"];
  }
}

class Option extends Object {
  int productOptionID;
  List<ProductOptionValue> productOptionValues;
  String value;
  int optionID;
  String name;
  String type;
  bool required;

  Option.fromJSON(Map json) {
    productOptionID = json["product_option_id"];
    productOptionValues = json["product_option_value"] == null
      ? []
      : json["product_option_value"].map((Map value) {
        return new ProductOptionValue.fromJSON(value);
      }).toList();
    value = json["value"];
    optionID = json["option_id"];
    name = json["name"];
    type = json["type"];
    required = json["required"];
  }
}

class ProductOptionValue extends Object {
  int id;
  int optionValueID;
  String name;
  String image;
  String price;
  String pricePrefix;

  ProductOptionValue.fromJSON(Map json) {
    id = json["product_option_value_id"];
    optionValueID = json["option_value_id"];
    name = json["name"];
    image = json["image"];
    price = json["price"];
    pricePrefix = json["price_prefix"];
  }
}

class AttributeGroup extends Object {
  int id;
  String name;
  List<Attribute> attributes;

  AttributeGroup.fromJSON(Map json) {
    id = json["attribute_group_id"];
    name = json["name"];
    attributes = json["attribute"] == null ? [] : json["attribute"].map((Map attr) {
      return new Attribute.fromJSON(attr);
    }).toList();
  }
}

class Attribute extends Object {
  int id;
  String name;
  String text;

  Attribute.fromJSON(Map json) {
    id = json["attribute_id"];
    name = json["name"];
    text = json["text"];
  }
}

class RelatedProduct extends Object {
  int id;
  String name;
  String description;
  String price;
  String special;
  bool tax;
  int rating;
  String thumbImage;

  RelatedProduct.fromJSON(Map json) {
    id = json["product_id"];
    name = json["name"];
    description = json["description"];
    price = json["price"];
    special = json["special"];
    tax = json["tax"];
    rating = json["rating"];
    thumbImage = json["thumb_image"];
  }
}

class Recurring extends Object {
  int id;
  int languageID;
  String name;

  Recurring.fromJSON(Map json) {
    id = json["recurring_id"];
    languageID = json["language_id"];
    name = json["name"];
  }
}

class SimpleProduct extends Object {
  int id;
  String name;
  String description;
  String price;
  String special;
  String tax;
  int rating;
  String thumbImage;

  SimpleProduct.fromJSON(Map json) {
    id = json["product_id"];
    name = json["name"];
    description = json["description"];
    price = json["price"];
    special = json["special"];
    tax = json["tax"];
    rating = json["rating"];
    thumbImage = json["thumb_image"];
  }
}

