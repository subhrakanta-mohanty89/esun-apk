// Part of eSun Flutter App — design system
/// Consistent 20px horizontal screen padding wrapper.

import 'package:flutter/material.dart';

class ScreenPadding extends StatelessWidget {
  final Widget child;

  const ScreenPadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: child,
    );
  }
}
