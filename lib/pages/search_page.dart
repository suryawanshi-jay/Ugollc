import "package:flutter/material.dart";
import 'package:ugo_flutter/models/cart.dart';
import 'package:ugo_flutter/models/product.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/widgets/product_widget.dart';

class SearchPage extends StatelessWidget {
  final Cart cart;
  final Function(dynamic) updateCart;
  final List<SimpleProduct> products;
  final TextField searchField;

  final rowCount = 3;

  SearchPage(this.cart, this.searchField, {this.updateCart, this.products});

  List<Widget> listRows() {
    if (products == null || products.length == 0) {
      return [];
    }

    products.removeWhere((product) => product.name == DRIVER_TIP_NAME);

    final productWidgets = products.map((product) {
      return new ProductWidget(
        product.id,
        product.quantity,
        product.name,
        cart,
        price: product.price,
        imageUrl: product.thumbImage,
        updateCart: updateCart,
      );
    }).toList();
    
    List<Widget> rows = [];
    List<Widget> currentRowItems = [];
    if (productWidgets.length > 0) {
      for (int i = 0; i < productWidgets.length; i++) {
        Widget currentItem = new Expanded(child: productWidgets[i]);

        currentRowItems.add(currentItem);

        if ((i+1) % rowCount == 0 || i+1 == productWidgets.length) {
          // fill in with additional empty expanded elements
          while (currentRowItems.length < rowCount) {
            currentRowItems.add(new Expanded(child: new Container()));
          }
          rows.add(new Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: currentRowItems,
          ));
          currentRowItems = [];
        }
      }
    } else {
      return [new Container()];
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      color: Colors.white,
      padding: new EdgeInsets.symmetric(horizontal: 10.0),
      child: new Column(
        children: <Widget>[
          searchField,
          new Expanded(
            child: new ListView(
              children: listRows(),
            )
          )
        ],
      )
    );
  }
}
