import 'package:flutter/material.dart';

// Función helper para agregar padding inferior para evitar overlapping
Widget withBottomPadding(BuildContext context, Widget child, {double extraPadding = 16.0}) {
  final bottomInsets = MediaQuery.of(context).viewPadding.bottom;
  
  return Padding(
    padding: EdgeInsets.only(
      bottom: bottomInsets + extraPadding,
    ),
    child: child,
  );
}