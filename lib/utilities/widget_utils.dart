import 'package:flutter/material.dart';

class WidgetUtils {
  static addTap(Widget child, Function tapHandler) {
    return new GestureDetector(child: child, onTap: tapHandler,);
  }
}