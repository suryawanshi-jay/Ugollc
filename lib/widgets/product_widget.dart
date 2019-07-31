import 'dart:ui';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ugo_flutter/models/cart.dart';
import 'package:ugo_flutter/pages/product_page.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/utilities/constants.dart';

class ProductWidget extends StatelessWidget {
  final int id;
  final String quantity;
  final String name;
  final String price;
  final String imageUrl;
  final Cart cart;
  final Function(dynamic) updateCart;

  ProductWidget(this.id,this.quantity , this.name, this.cart,{this.price = "\$0.99", this.imageUrl, this.updateCart});

  @override
  Widget build(BuildContext context) {
    Widget image = new Placeholder();
    if (imageUrl != null) {
      image = new Image.network(imageUrl);
    }
    
    return new Container(
      margin: new EdgeInsets.all(10.0),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          new Builder(
            builder: (BuildContext context) {
              return new GestureDetector(
                child: new Container(
//              color: Colors.grey[300],
                  margin: new EdgeInsets.only(bottom: 10.0),
                  child: new AspectRatio(
                    aspectRatio: 1.0,
                    child: image,
                  ),

                ),
                onTap: () {
                  if(int.parse(quantity) <= 0){
                    Scaffold.of(context).showSnackBar(
                        new SnackBar(
                          content: new Text("Sorry $name is out of stock", style: new TextStyle(fontSize: 18.0),),
                          backgroundColor: Colors.red,
                        )
                    );
                  }else {
                    Navigator.push(context,
                      new MaterialPageRoute(
                        builder: (BuildContext context) => new ProductPage(id, cart, updateCart: updateCart,))
                     );
                  }
                },
                onLongPress: () {
                  if(int.parse(quantity) <= 0){
                    Scaffold.of(context).showSnackBar(
                        new SnackBar(
                          content: new Text("Sorry $name is out of stock", style: new TextStyle(fontSize: 18.0),),
                          backgroundColor: Colors.red,
                        )
                    );
                  } else {
                    ApiManager.request(
                      OCResources.ADD_CART_PRODUCT,
                      (json) async {
                        final analytics = new FirebaseAnalytics();
                        final numPrice = double.parse(price.replaceAll(PRICE_REGEXP, ""));
                        await analytics.logAddToCart(
                          itemId: id.toString(),
                          itemName: name,
                          itemCategory: "Long Press",
                          quantity: 1, price: numPrice,
                        );
                        if (updateCart != null) {
                          updateCart(json);
                        }
                        Scaffold.of(context).showSnackBar(
                          new SnackBar(
                            content: new Text("Added 1 x $name to cart.", style: new TextStyle(fontSize: 18.0), ),
                            backgroundColor: UgoGreen,
                          )
                        );
                      },
                      params: {
                        "product_id": id.toString(),
                        "quantity": "1",
                      },
                      context: context
                    );
                  }
                },
              );
            },
          ),


          new Text(name ?? "",
            textAlign: TextAlign.center,
            style: new TextStyle(
//              fontSize: 16.0
            fontWeight: FontWeight.w600
            ),
          ),


          new Text(price ?? "",
            style: new TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11.0,
              color: Colors.grey[700],
            ),
          )
        ],
      )
    );
  }
}
