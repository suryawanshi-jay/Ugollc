import 'package:flutter/material.dart';
import 'package:ugo_flutter/models/cart.dart';

import 'package:ugo_flutter/pages/list_page.dart';
import 'package:ugo_flutter/utilities/constants.dart';

class ListDivider extends StatelessWidget {
  final String text;
  final Color barColor;
  final Color textColor;
  final int categoryID;
  final Cart cart;
  final Function(dynamic) updateCart;
  final double fontSize;
  final bool showMore;
  final bool onlyCaret;

  ListDivider(
    this.text,
    this.cart,
    {
      this.barColor: UgoGreen,
      this.textColor: Colors.white,
      this.categoryID,
      this.updateCart,
      this.fontSize: 18.0,
      this.showMore: true,
      this.onlyCaret: false,
    }
  );

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      child: new Container(
        padding: new EdgeInsets.all(10.0),
        color: barColor,
        child: new Row(
          children: [
            new Expanded(
              child: new Text(
                this.text,
                softWrap: true,
                style: new TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                  color: textColor,
                  fontFamily: "JosefinSans",
                  letterSpacing: 0.5,
                ),
              ),
            ),
            showMore
              ? new Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  onlyCaret
                    ? new Icon(Icons.chevron_right, color: textColor,)
                    : new Text("See More",
                    style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                      color: textColor,
                      fontFamily: "JosefinSans",
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            )
            : new Container(),
          ],
        ),
      ),
      onTap: this.categoryID == null ? null : 
        () {
          Navigator.push(context,
            new MaterialPageRoute(
              builder: (BuildContext context) => new ListPage(text, categoryID, cart, updateCart: updateCart,)
            )
          );
        },
    );
  }
}
