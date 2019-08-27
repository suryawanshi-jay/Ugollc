import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ugo_flutter/models/cart.dart';
import 'package:ugo_flutter/models/product.dart';
import 'package:ugo_flutter/pages/loading_screen.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/widgets/cart_button.dart';

class ProductPage extends StatefulWidget {
  final int productID;
  final Cart cart;
  final Function(dynamic) updateCart;

  ProductPage(this.productID, this.cart, {this.updateCart});

  @override
  _ProductPageState createState() => new _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  Product _product;
  int _quantity = 1;
  Cart _cart;
  bool _adding = false;
  String restrictionMsg;
  bool showRestrictionMsg = false;
  int rewardPointsToBuy;
  bool showRewardPoint = false;
  bool showDesc = false;

  final _analytics = new FirebaseAnalytics();

  @override
  initState() {
    super.initState();

    _cart = widget.cart;
    ApiManager.request(
      OCResources.GET_PRODUCT,
      (json) async {
        final product = new Product.fromJSON(json["product"]);
        setState(() => _product = product);
        setState(() => rewardPointsToBuy = json["product"]["reward_points_needed_to_buy"]);
        if(rewardPointsToBuy > 0){
          setState(() => showRewardPoint = true);
        }

        final numPrice = double.parse(product.price.replaceAll(PRICE_REGEXP, ""));
        await _analytics.logViewItem(
          itemId: product.id.toString(),
          itemName: product.title,
          itemCategory: "",
          price: numPrice,
        );
      },
      resourceID: widget.productID.toString(),
    );
  }

  _updateCart(json) {
    setState(() => _cart = new Cart.fromJSON(json["cart"]));
    widget.updateCart(json);
  }

  _addToCart(context) {
    setState(() => _adding = true);
    ApiManager.request(
      OCResources.ADD_CART_PRODUCT,
      (json) async {
        final numPrice = double.parse(_product.price.replaceAll(PRICE_REGEXP, ""));
        await _analytics.logAddToCart(
          itemId: _product.id.toString(),
          itemName: _product.title,
          itemCategory: "Add Product Button",
          quantity: _quantity,
          price: numPrice,
        );

        _updateCart(json);
        setState(() => _adding = false);

        Scaffold.of(context).showSnackBar(
          new SnackBar(
            content: new Text("Added $_quantity x ${_product.title} to cart.", style: new TextStyle(fontSize: 18.0),),
            backgroundColor: UgoGreen,
          )
        );
      },
      params: {
        "product_id": _product.id.toString(),
        "quantity": _quantity.toString(),
      },
      errorHandler: (error) {
        ApiManager.defaultErrorHandler(error);
        setState(() => _adding = false);
        setState(() => restrictionMsg = error['errors'][0]['message']);
        if(restrictionMsg.startsWith('Products marked with ***')) {
          setState(() => restrictionMsg = "This product is not available in the desired quantity or not in stock! ");
        }
        setState(() => showRestrictionMsg =true);
      },
      context: context
    );
  }

  Widget _quantityRow() {
    if (_product.stockStatus <= 0) {
      return new Padding(
        padding: const EdgeInsets.symmetric(vertical: 30.0),
        child: new Row(
          children: <Widget>[
            new Expanded(
              child: new RaisedButton(
                child: new Text(
                  "Currently Out of Stock",
                  textAlign: TextAlign.center,
                  style: new TextStyle(fontSize: 18.0, color: Colors.white),
                ),
              )
            ),
          ],
        ),
      );
    }
    
    return new Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: new Row(
        children: <Widget>[
          new Text(
            "Quantity",
            style: new TextStyle(fontSize: 24.0)
          ),
          new Expanded(child: new Container(),),
          new IconButton(
            icon: new Icon(Icons.remove_circle),
            onPressed: _quantity <= 1 ? null :
              () {
              setState(() => _quantity -= 1);
            },
            iconSize: 44.0,
            color: UgoGreen,
          ),
          new Text(
            _quantity.toString(),
            style: new TextStyle(fontSize: 24.0),
          ),
          new IconButton(
            icon: new Icon(Icons.add_circle),
            onPressed: _quantity >= _product.stockStatus ? null :
              () {
              setState(() => _quantity += 1);
            },
            iconSize: 44.0,
            color: UgoGreen,
          ),
        ],
      ),
    );
  }

  Widget productDetails() {
    if(_product.description != ""){
      setState(() => showDesc = true);
    }
    List<Widget> list = [
      new Padding(padding: new EdgeInsets.only(top: 15.0)),
      new Text(
        _product.title,
        style: new TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold
        ),
      ),
      new Text(_product.manufacturer),
      new Container(
//              color: Colors.grey[300],
        margin: new EdgeInsets.fromLTRB(30.0, 5.0, 30.0, 10.0),
        child: new AspectRatio(aspectRatio: 1.0,
          child: new Image.network(_product.image),
        ),
      ),
      new Row(
        children: <Widget>[
          new Text(
            _product.price,
            textAlign: TextAlign.left,
            style: new TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold
            ),
          ),

        ],
      ),
      new Padding(padding: const EdgeInsets.only(top: 10.0),),
      showRewardPoint ? new Row(
        children: <Widget>[
          new Text("Price in reward points : ${rewardPointsToBuy}",
            textAlign: TextAlign.left,
            style: new TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.bold
            ),
          ),
        ],
      ): new Container(),
      new Padding(padding: const EdgeInsets.only(top: 10.0),),
       showDesc ? _product.richTextDescription() : new Container(),
    ];

    list.add(_quantityRow());

    if (_product.stockStatus > 0) {
      showRestrictionMsg ? list.add(new Row(
        children: <Widget>[
          new SizedBox(width: 300.0, height:50.0, child :
          new Text(
            restrictionMsg,
            textAlign: TextAlign.left,
            style: new TextStyle(
                fontSize: 12.0,
                color:Colors.red
            ),
          )),
        ],
      )):list.add(new Container());
      list.add(new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Builder(
            builder: (BuildContext context) {
              return new Expanded(
                child: new RaisedButton(
                  onPressed: () => _addToCart(context),
                  color: UgoGreen,
                  child: new Text(
                    "Add to Cart",
                    style: new TextStyle(fontSize: 18.0, color: Colors.white),
                  ),
                )
              );
            }
          ),
        ],
      ));
    }

    return new Container(
      color: Colors.white,
      padding: new EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
      child: new Center(
        child: new ListView(
          padding: new EdgeInsets.only(bottom: 20.0),
          children: list,
        )
      )
    );
  }

  Widget pageDisplay() {
    return _product == null ? new LoadingContainer() : productDetails();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Product Details"),
        actions: [
          new CartButton(_cart, updateCart: _updateCart,),
        ],
      ),
      body: pageDisplay()
    );
  }
}

