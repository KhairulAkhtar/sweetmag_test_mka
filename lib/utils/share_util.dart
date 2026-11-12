import 'package:flutter/material.dart';

// color darkpurple
Color darkPurple() {
  return Color(int.parse('#2d2d3a'.substring(1, 7), radix: 16) + 0xFF000000);
}

// color light purple
Color lightPurple() {
  return Color(int.parse('#8b5cf6'.substring(1, 7), radix: 16) + 0xFF000000);
}

// view order and product detail background color
Color background() {
  return Color(int.parse('#FEF9F8'.substring(1, 7), radix: 16) + 0xFF000000);
}
