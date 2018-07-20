import 'package:ugo_flutter/models/product.dart';

class Category extends Object {
  int id;
  String name;
  String description;
  String thumbImage;
  int totalProducts;
  int parentID;

  List<SimpleProduct> products;
  List<FilterGroup> filterGroups;

  Category.fromJSON(Map json, {int parent}) {
    id = json["category_id"];
    name = json["name"];
    description = json["description"];
    thumbImage = json["thumb_image"];
    totalProducts = json["total_products"];
    if (parent != null) {
      parentID = parent;
    }

    products = json["products"] == null ? [] : json["products"].map((Map product) {
      return new SimpleProduct.fromJSON(product);
    }).toList();

    filterGroups = json["filtergroups"] == null ? [] : json["filtergroups"].map((Map filterGroup) {
      return new FilterGroup.fromJSON(filterGroup);
    }).toList();
  }

  List<SimpleProduct> previewProducts() {
    return [
      products[0],
      products[1],
      products[2]
    ];
  }

  bool filterDisplay(String filterGroupName, String filterName) {
    List<FilterGroup> displayGroups = this.filterGroups.where((FilterGroup group) {
      return group.name == filterGroupName;
    }).toList();

    if (displayGroups.length == 0) {
      return false;
    }

    var homeGroup = displayGroups[0].filters.where((Filter filter) {
      return filter.name == filterName;
    }).toList();

    return homeGroup.length > 0;
  }
}

class FilterGroup extends Object {
  int id;
  String name;
  List<Filter> filters;

  FilterGroup.fromJSON(Map json) {
    id = json["filter_group_id"];
    name = json["name"];
    filters = json["filter"] == null ? [] : json["filter"].map((Map filter) {
      return new Filter.fromJSON(filter);
    }).toList();
  }
}

class Filter extends Object {
  int id;
  String name;

  Filter.fromJSON(Map json) {
    id = json["filter_id"];
    name = json["name"];
  }
}

// Object retrieved from getting the Categories List
class SimpleCategory extends Object {
  int id;
  String name;
  String description;
  String thumbImage;
  int totalProducts;
  List<SimpleCategory> categories;

  SimpleCategory.fromJSON(Map json) {
    id = json["category_id"];
    name = json["name"];
    description = json["description"];
    thumbImage = json["thumb_image"];
    totalProducts = json["total_products"];

    categories = json["categories"] == null ? [] : json["categories"].map((Map category) {
      return new SimpleCategory.fromJSON(category);
    }).toList();
  }

  Map<int, String> subcategoriesForList() {
    return new Map.fromIterable(
      categories,
      key: (SimpleCategory category) => category.id,
      value: (SimpleCategory category) => category.name);
  }
}