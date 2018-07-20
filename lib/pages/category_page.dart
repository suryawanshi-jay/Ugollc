import 'package:flutter/material.dart';
import 'package:ugo_flutter/models/cart.dart';
import 'package:ugo_flutter/models/category.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/widgets/custom_expansion_tile.dart';
import 'package:ugo_flutter/widgets/list_divider.dart';

class CategoryPage extends StatelessWidget {
  final List<Category> featuredCategories;
  final List<int> hiddenCategoryIDs;
  final List<SimpleCategory> categories;
  final Cart cart;
  final Function(dynamic) updateCart;

  CategoryPage(this.featuredCategories, this.categories, this.cart, {this.updateCart, this.hiddenCategoryIDs});

  Map<String, Map<int, String>> categoryHierarchy() {
    return new Map.fromIterable(
      categories,
      key: (SimpleCategory category) => category.name,
      value: (SimpleCategory category) => category.subcategoriesForList()
    );
  }

  @override
  Widget build(BuildContext context) {
    var hierarchy = categoryHierarchy();

    List<Widget> expansionList = [];

    featuredCategories.forEach((Category category) =>
      expansionList.add(
        new CategorySpecialCollection(
          category,
          cart,
          updateCart: updateCart,
        )
      )
    );
    hierarchy.forEach((category, subcategories) {
      hiddenCategoryIDs.forEach((id) => subcategories.remove(id));
      if (subcategories.length > 0) {
        expansionList.add(new CategoryExpansionTile(category, subcategories, cart, updateCart: updateCart,));
      }
    });

    return new Container(
      child: new ListView(
        children: expansionList
      ),
    );
  }
}

class CategorySpecialCollection extends StatelessWidget {
  final Category category;
  final Cart cart;
  final Function(dynamic) updateCart;

  CategorySpecialCollection(this.category, this.cart, {this.updateCart});

  @override
  Widget build(BuildContext context) {
    return new Container(
      margin: new EdgeInsets.only(bottom: 5.0),
      child: new ListDivider(category.name, cart, updateCart: updateCart, barColor: Colors.grey[350], categoryID: category.id, textColor: UgoGreen, fontSize: 24.0,),
    );
  }
}

class CategoryExpansionTile extends StatelessWidget {
  final String superCategory;
  final Map<int, String> parentCategories;
  final Cart cart;
  final Function(dynamic) updateCart;

  CategoryExpansionTile(this.superCategory, this.parentCategories, this.cart, {this.updateCart});

  List<Widget> parentCategoryList() {
    List<Widget> categoryRows = [];

    parentCategories.forEach((id, name) {
      final categoryRow = new Container(
        color: Colors.grey[200],
        padding: new EdgeInsets.only(left: 40.0),
        child: new ListDivider(name, cart, updateCart: updateCart,barColor: Colors.grey[200], categoryID: id, textColor: Colors.grey[700], onlyCaret: true,)
      );
      categoryRows.add(categoryRow);
    });

    return categoryRows;
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      color: Colors.grey[350],
      margin: new EdgeInsets.only(bottom: 5.0),
      child: new CustomExpansionTile(
        header: new Container(
          padding: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          child: new Text(
            superCategory,
            style: new TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: UgoGreen,
              fontFamily: 'JosefinSans'
            )
          ),
        ),
        children: parentCategoryList(),
      ),
    );
  }
}

