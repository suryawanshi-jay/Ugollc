import 'package:flutter/material.dart';
import 'package:ugo_flutter/models/cart.dart';
import 'package:ugo_flutter/pages/list_page.dart';
import 'package:ugo_flutter/utilities/constants.dart';

class CircleProductWidget extends StatelessWidget {
  final String name;
  final int categoryID;
  final String thumbImage;
  final Cart cart;
  final Function(dynamic) updateCart;

  CircleProductWidget(this.name, this.categoryID, this.thumbImage, this.cart, {this.updateCart});

  @override
  Widget build(BuildContext context) {
    var nameWords = name.split(" ");
    var text = nameWords.map((word) => word[0].toUpperCase()).join();

    return new Expanded(
      child: new Container(
        margin: new EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 20.0),
        child: new Column(
//          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            new GestureDetector(
              child: new Container(
                margin: new EdgeInsets.only(bottom: 10.0),
                child: new AspectRatio(
                  aspectRatio: 1.0,
                  child: thumbImage == null || thumbImage == ""
                  ? new Container(
                    decoration: new ShapeDecoration(
                      shape: new CircleBorder(),
                      color: UgoGreen,
                    ),
                    child: new Center(child: new Text(
                        text,
                        style: new TextStyle(color: Colors.white, fontSize: 36.0),
                      )
                    )
                  )
                  : new Image.network(thumbImage, fit: BoxFit.cover,),
                ),
              ),
              onTap: () {
                Navigator.push(context,
                  new MaterialPageRoute(
                    builder: (BuildContext context) => new ListPage(name, categoryID, cart, updateCart: updateCart,)
                  )
                );
              },
            ),
            new Text(this.name, textAlign: TextAlign.center,),
          ],
        )
      )
    );
  }
}
