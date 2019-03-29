import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ugo_flutter/models/cart.dart';
import 'package:ugo_flutter/pages/loading_screen.dart';
import 'package:ugo_flutter/widgets/cart_button.dart';
import 'package:ugo_flutter/widgets/product_widget.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/utilities/constants.dart';

class ListPage extends StatefulWidget {
  final String title;
  final int categoryID;
  final Cart cart;
  final Function(dynamic) updateCart;

  ListPage(this.title, this.categoryID, this.cart, {this.updateCart});

  @override
  _ListPageState createState() => new _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final rowCount = 3;
  Cart _cart;
  bool _loading = false;

  List<Map> _categoryProducts = [];
  final _analytics = new FirebaseAnalytics();

  @override
  initState() {
    super.initState();
    _cart = widget.cart;
    setState(() => _loading = true);
    ApiManager.request(
      OCResources.GET_CATEGORY, 
      (json) async {
        setState(() => _categoryProducts = json["category"]["products"]);
        setState(() => _loading = false);
        await _analytics.logViewItemList(itemCategory: widget.title);
      },
      resourceID: widget.categoryID.toString(),
      params: {
       // "sort": "name",
      }
    );
  }

  _updateCart(json) {
    setState(() => _cart = new Cart.fromJSON(json["cart"]));
    widget.updateCart(json);
  }

  Widget headerRow() {
    return new Container(
      padding: new EdgeInsets.all(10.0),
      color: Colors.grey[350],
      child: new Row(
        children: [
          new Text(
            widget.title,
            style: new TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
              color: UgoGreen,
              fontFamily: 'JosefinSans'
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> listRows() {
    final productWidgets = _categoryProducts.map((product) {
      return new ProductWidget(
        product["product_id"], 
        product["name"],
        _cart,
        price: product["price"],
        imageUrl: product["thumb_image"],
        updateCart: _updateCart,
      );
    }).toList();

    List<Widget> rows = [];
    List<Widget> currentRowItems = [];
    for (int i = 0; i < productWidgets.length; i++) {
      Widget currentItem = new Expanded(child: productWidgets[i]);

      currentRowItems.add(currentItem);

      if ((i+1) % this.rowCount == 0 || i+1 == productWidgets.length) {
        // fill in with additional empty expanded elements
        while (currentRowItems.length < this.rowCount) {
          currentRowItems.add(new Expanded(child: new Container()));
        }
        rows.add(new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: currentRowItems,
        ));
        currentRowItems = [];
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return new LoadingScreen(loadingText: "LOADING PRODUCTS . . .");
    }

    return new Scaffold(
      appBar: new AppBar(
        title: new Image.asset("assets/images/ugo_logo.png"),
        actions: [
          new CartButton(_cart, updateCart: _updateCart),
        ],
      ),
      body: new Container(
        color: Colors.white,
        child: new Column(
          children: <Widget>[
            headerRow(),
            new Expanded(
              child: new ListView(
                children: listRows(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
